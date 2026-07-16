#!/usr/bin/env bash
# Promptstack size gate. Two invariants, both must hold:
#   (a) The always-on rule core -- every top-level agentsmd/rules/*.md whose
#       frontmatter has NO paths: key -- sums to <= 4000 body chars.
#   (b) The autonomous base prompt's fenced ```text block is <= 4000 chars.
# No dependencies beyond a POSIX shell + awk. Run locally with:
#   bash agentsmd/prompts/eval/check-core-size.sh
set -euo pipefail

MAX=4000
repo_root=$(git rev-parse --show-toplevel)
rules_dir="$repo_root/agentsmd/rules"
base="$repo_root/agentsmd/prompts/autonomous-base.md"

fail=0

# (a) Always-on core: top-level rules only (non-recursive) with no paths: key.
core_total=0
core_files=""
for f in "$rules_dir"/*.md; do
  [ -e "$f" ] || continue
  has_paths=$(awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { exit }
    infm && /^paths:/  { print "1"; exit }
  ' "$f")
  [ "$has_paths" = "1" ] && continue
  # Body = file minus a leading --- frontmatter block, if present.
  body_chars=$(awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { infm=0; next }
    !infm              { print }
  ' "$f" | wc -m | tr -d ' ')
  core_total=$((core_total + body_chars))
  core_files="$core_files ${f#"$repo_root"/}($body_chars)"
done

echo "always-on core body chars: $core_total (files:$core_files )"
if [ "$core_total" -gt "$MAX" ]; then
  echo "FAIL: always-on core $core_total > $MAX"
  fail=1
fi

# (b) Autonomous base prompt: content between the first ```text fence and its
#     closing ``` fence.
base_chars=$(awk '
  /^```text$/ && !seen { seen=1; infence=1; next }
  infence && /^```$/   { exit }
  infence              { print }
' "$base" | wc -m | tr -d ' ')

echo "autonomous-base fenced text block chars: $base_chars"
if [ "$base_chars" -gt "$MAX" ]; then
  echo "FAIL: base block $base_chars > $MAX"
  fail=1
fi

exit "$fail"
