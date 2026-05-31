#!/bin/bash

################################################################################
# sensitive-denylist-scan.sh
#
# Literal denylist prong of the multi-layer sensitive-value gate (Layer 3, CI).
# Reads newline-separated POSIX-ERE regexes from the SENSITIVE_DENYLIST env var
# (sourced in CI from the GitHub Actions secret of the same name), masks them in
# the log, writes them to a runner-temp file, and greps them across the PR's
# changed files. Fails the job on any match.
#
# Changed files are computed from the PR base/head SHAs (no third-party action),
# so the only external dependency is the gitleaks container in the sibling job.
#
# Fail mode (per the SENSITIVE_DENYLIST contract):
#   - Empty/missing denylist on a trusted (non-fork) repo -> fail CLOSED (exit 1).
#   - Empty/missing denylist on a fork (no secret)         -> skip gracefully.
#   - Match found                                          -> fail (exit 1).
#   - No match                                             -> pass (exit 0).
#
# This script never echoes a pattern or the content of a matching line; only the
# offending file path is reported.
#
# Inputs (environment):
#   SENSITIVE_DENYLIST  - newline-separated ERE regexes (CI secret). May be empty.
#   IS_FORK             - "true" when the PR head is a fork (secret unavailable).
#   BASE_SHA            - PR base commit SHA (merge target).
#   HEAD_SHA            - PR head commit SHA.
#
# Exit codes:
#   0 - No match, or graceful skip on a fork.
#   1 - Match found, or fail-closed empty denylist on a non-fork.
################################################################################

set -euo pipefail

denylist="${SENSITIVE_DENYLIST:-}"
is_fork="${IS_FORK:-false}"
base_sha="${BASE_SHA:-}"
head_sha="${HEAD_SHA:-HEAD}"

# Mask every non-empty pattern so a value can never surface in the log, even via
# a future debug change. GitHub honors ::add-mask:: for the rest of the job.
while IFS= read -r line; do
  [[ -n "$line" ]] && echo "::add-mask::$line"
done <<< "$denylist"

if [[ -z "${denylist//[$'\n\r\t ']/}" ]]; then
  if [[ "$is_fork" == "true" ]]; then
    echo "::notice::SENSITIVE_DENYLIST unavailable on fork PR; skipping literal denylist scan (structural gitleaks scan still runs)."
    exit 0
  fi
  echo "::error::SENSITIVE_DENYLIST secret is empty or missing on a trusted repo. Failing closed — seed the secret before merging."
  exit 1
fi

denylist_file="$(mktemp "${RUNNER_TEMP:-/tmp}/denylist.XXXXXX")"
trap 'rm -f "$denylist_file"' EXIT
# Drop comment and blank lines so grep -f sees only real patterns.
printf '%s\n' "$denylist" | grep -Ev '^[[:space:]]*(#|$)' > "$denylist_file" || true

if [[ ! -s "$denylist_file" ]]; then
  if [[ "$is_fork" == "true" ]]; then
    echo "::notice::SENSITIVE_DENYLIST contained only comments on fork PR; skipping literal scan."
    exit 0
  fi
  echo "::error::SENSITIVE_DENYLIST contained no usable patterns on a trusted repo. Failing closed."
  exit 1
fi

# Changed files between the PR base and head. --diff-filter=d skips deletions.
mapfile -t changed_files < <(git diff --name-only --diff-filter=d "${base_sha}...${head_sha}" 2>/dev/null || true)

if [[ "${#changed_files[@]}" -eq 0 ]]; then
  echo "::notice::No changed files to scan."
  exit 0
fi

matched=0
for file in "${changed_files[@]}"; do
  [[ -z "$file" ]] && continue
  [[ -f "$file" ]] || continue
  if grep -E -f "$denylist_file" -- "$file" >/dev/null 2>&1; then
    echo "::error file=${file}::Sensitive value matching the private denylist found in this file. Parameterize it via Doppler/SOPS; do not commit real values."
    matched=1
  fi
done

if [[ "$matched" -ne 0 ]]; then
  echo "::error::Literal denylist scan FAILED. One or more changed files contain a sensitive value. (Matching content is intentionally not printed.)"
  exit 1
fi

echo "Literal denylist scan passed: no changed file matched the private denylist."
exit 0
