#!/usr/bin/env bash
################################################################################
# check-no-runner-git-commit.sh
#
# Pre-commit hook (and CI gate) that blocks raw `git commit` / `git push`
# inside GitHub Actions workflow / composite-action YAML.
#
# Why: runners that invoke local `git commit` cannot sign without the SSH
# signing key loaded by `_ai-action-with-signing.yml`. Two profile workflows
# (snake.yml, 3d-contrib.yml) regressed to raw `git commit` + `git push` and
# produced unsigned commits on the `output` branch for months. This hook
# makes that mistake structurally impossible.
#
# Usage:
#   ./scripts/check-no-runner-git-commit.sh [file ...]
#
#   - With arguments: scans only those files (pre-commit's standard
#     pass_filenames behavior).
#   - With no arguments: scans every `.github/workflows/*.yml` and
#     `.github/actions/**/action.yml` under the current working tree
#     (so CI can call it without arguments).
#
# Exit codes:
#   0  No violations (or no relevant files).
#   1  At least one violation found.
#   2  Internal error (missing dependency, malformed input).
#
# Canonical alternatives the hook points authors at:
#   1. AI-driven workflows: call `_ai-action-with-signing.yml` from
#      JacobPEvans/ai-workflows; it imports the SSH signing key first.
#   2. Deterministic content (no AI in the loop): use
#      `actions/github-script@v9` + `octokit.repos.createOrUpdateFileContents`
#      so GitHub web-flow signs the commit.
#   3. Human-review PRs: use `peter-evans/create-pull-request@v8` with
#      `sign-commits: true`.
#
# See `agentsmd/rules/git-signing.md` for the full architecture.
################################################################################

set -euo pipefail

for cmd in yq jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "check-no-runner-git-commit: $cmd is required but not installed." >&2
    echo "  Install via Nix (nixpkgs.$cmd) or 'brew install $cmd'." >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# Path filter: only YAML under .github/workflows/ or .github/actions/.
# Anything else is ignored — pre-commit may invoke us with the union of every
# staged file, and we shouldn't fail (or even read) unrelated YAML.
# ---------------------------------------------------------------------------
path_is_in_scope() {
  local path="$1"
  # Workflow files: flat directory, single-segment glob.
  case "$path" in
    *.github/workflows/*.yml | *.github/workflows/*.yaml) return 0 ;;
  esac
  # Composite-action files: match any depth under .github/actions/, since the
  # pre-commit `files:` regex is `actions/.+/action\.ya?ml`. Without `shopt -s
  # globstar` (which isn't portable), use a regex on the substring.
  if [[ "$path" =~ \.github/actions/.+/action\.(yml|yaml)$ ]]; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Allowlist: a `run:` scalar containing ANY of these markers is exempt
# because the `git commit` / `git push` token is either inside documentation
# embedded in a heredoc, or accompanied by infrastructure that handles
# signing properly. Single ERE alternation; order does not matter.
# ---------------------------------------------------------------------------
allowlist_pattern='gh api repos/[^[:space:]]+/contents/|peter-evans/create-pull-request|claude_signing_key|gh pr create|gh issue create|actions/github-script'

# Word-boundary detection of the two forbidden invocations. POSIX ERE has no
# `\b`, so we wrap with a character class that allows start-of-string /
# whitespace / common shell punctuation on both sides.
# shellcheck disable=SC2016  # `$` here is an ERE metachar, not a shell var.
boundary_pattern='(^|[[:space:];&|!(\{\$\`\"])(git[[:space:]]+commit|git[[:space:]]+push)([[:space:];&|!)}\$\`\"]|$)'

# ---------------------------------------------------------------------------
# scan_file: report any violation found in $1; return 0 if clean, 1 if dirty.
# ---------------------------------------------------------------------------
scan_file() {
  local file="$1"
  local base
  base="$(basename "$file")"

  # The canonical SSH-signing wrapper is, by definition, allowed to wrap
  # git commit/push — that is its whole job.
  if [ "$base" = "_ai-action-with-signing.yml" ] || [ "$base" = "_ai-action-with-signing.yaml" ]; then
    return 0
  fi

  # Extract every `run:` scalar from workflow jobs and composite actions.
  # `yq -c` emits a single compact-JSON array of run-scalar strings; we then
  # iterate with `jq` and split by a control character we know cannot occur
  # in YAML scalar content. ASCII 0x1F (Unit Separator) is the canonical
  # choice and survives bash command substitution intact.
  local runs_json
  # shellcheck disable=SC2016  # `$jobs` and `$runs` are jq variables, not shell.
  if ! runs_json="$(yq -c '
      (.jobs // {}) as $jobs
      | (.runs // {}) as $runs
      | ([$jobs | to_entries[]?.value.steps[]?] + ($runs.steps // []))
      | map(select(.run != null))
      | map(.run)
    ' "$file" 2>/dev/null)"; then
    # Per the header contract: malformed input → exit 2, not a violation.
    # Use return 2 so the outer loop can distinguish from a clean violation
    # (return 1) and propagate the right script-level exit code.
    echo "check-no-runner-git-commit: failed to parse $file (invalid YAML?)" >&2
    return 2
  fi

  case "$runs_json" in
    '' | '[]' | 'null') return 0 ;;
  esac

  # Walk each scalar. jq's `@text` plus a trailing US (0x1F) lets us split
  # in bash without losing internal newlines.
  local found_violation=0
  local run
  local sep
  sep=$(printf '\037')
  while IFS= read -r -d "$sep" run; do
    [ -z "$run" ] && continue

    # Cheap pre-filter: if the scalar mentions neither `git commit` nor
    # `git push` at all, skip the expensive boundary regex.
    case "$run" in
      *"git commit"* | *"git push"*) : ;;
      *) continue ;;
    esac

    # Allowlist: if the same run block carries a marker proving safe signing,
    # let it through.
    if [[ "$run" =~ $allowlist_pattern ]]; then
      continue
    fi

    # Word-boundary verification (avoids matching `gitops-commit`, `pushd`,
    # `git committee`, etc.).
    if [[ "$run" =~ $boundary_pattern ]]; then
      if [ "$found_violation" -eq 0 ]; then
        printf '\n%s\n' "VIOLATION: raw runner-side git commit/push detected in $file" >&2
        found_violation=1
      fi
      # Print the offending lines from the file itself so the line numbers
      # map to the YAML on disk, not the extracted scalar.
      grep -nE '(^|[[:space:]])(git[[:space:]]+commit|git[[:space:]]+push)([[:space:]]|$)' "$file" \
        | sed 's/^/  /' >&2 || true
    fi
  done < <(printf '%s' "$runs_json" | jq -j --arg sep "$sep" '.[] | . + $sep')

  if [ "$found_violation" -eq 1 ]; then
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Collect files to scan.
# ---------------------------------------------------------------------------
files=()
if [ "$#" -gt 0 ]; then
  for f in "$@"; do
    [ -f "$f" ] || continue
    path_is_in_scope "$f" || continue
    files+=("$f")
  done
else
  # No-arg mode (CI invocation): glob every workflow + composite action.
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find . -path ./node_modules -prune -o \
      \( -path '*/.github/workflows/*.yml' \
         -o -path '*/.github/workflows/*.yaml' \
         -o -path '*/.github/actions/*/action.yml' \
         -o -path '*/.github/actions/*/action.yaml' \
      \) -type f -print0)
fi

if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Scan and aggregate. Track parse errors (exit 2) separately from violations
# (exit 1) so a malformed YAML file doesn't get reported as a `git commit`
# offender — which would point the author at the wrong fix.
# ---------------------------------------------------------------------------
violated=0
parse_errored=0
for f in "${files[@]}"; do
  # `set -e` would abort on scan_file's nonzero return; use `||` so the rc
  # capture survives. Default rc=0; reassigned only when scan_file fails.
  rc=0
  scan_file "$f" || rc=$?
  if [ "$rc" -eq 1 ]; then
    violated=1
  elif [ "$rc" -eq 2 ]; then
    parse_errored=1
  fi
done

if [ "$parse_errored" -eq 1 ] && [ "$violated" -eq 0 ]; then
  # Pure parse error, no violations — surface as the contracted exit code 2.
  exit 2
fi

if [ "$violated" -eq 1 ]; then
  cat >&2 <<'GUIDANCE'

Raw `git commit` / `git push` from a workflow runner cannot be signed —
the runner has no signing key unless `_ai-action-with-signing.yml` has
imported one. Use one of these canonical alternatives:

  1. AI-driven work: call the reusable workflow
     `JacobPEvans/ai-workflows/.github/workflows/_ai-action-with-signing.yml@main`,
     which imports `GH_APP_CLAUDE_SSH_SIGNING_KEY` and configures git for
     SSH signing before Claude runs `git commit`.

  2. Deterministic content (no AI): use `actions/github-script@v9` to call
     `octokit.repos.createOrUpdateFileContents` — GitHub web-flow signs it.

  3. Human-review PR: use `peter-evans/create-pull-request@v8` with
     `sign-commits: true`.

Full architecture: agentsmd/rules/git-signing.md
GUIDANCE
  exit 1
fi

exit 0
