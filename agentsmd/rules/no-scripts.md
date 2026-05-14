---
name: no-scripts
description: Scripts are LAST RESORT — dedicated files only. Single-line pipelines fine; multi-line logic and inline interpreters are not.
---

# No Scripts

## Iron law

Search first; script only when every search tier is empty AND the 10-line gate passes.

Scripts MUST live in `.sh`, `.py`, `.ts`, `.js`, `.rb`, `.pl` files under `scripts/`,
`.github/scripts/`, `.claude/hooks/`, `tests/`, or `plugins/<name>/hooks/`.
Never inlined elsewhere.

**Banned in non-script files:**

- YAML `run:` with control flow (`if`/`for`/`while`/`case`) or 4+ lines
- Multi-line Bash control flow in a single command
- Heredocs carrying logic (`bash <<EOF`, `python <<EOF`, generated commit bodies)
- Inline interpreters: `python -c`, `node -e`, `perl -e`, `ruby -e`, multi-line `bash -c`
- Markdown copy-paste-execute blocks with logic

**Allowed:** single-line pipelines (`|`/`&&`/`xargs`), 1–3 line YAML `run:` without control flow, one-line heredocs feeding static prose.

## Four-tier search (required before any new script)

Log one line per tier (`<tier>: <tool> — found/not-found, reason`). Empty rows reject the search.

1. Native CLIs / builtins (`jq`, `gh`, `git`, `curl`)
2. Ecosystem primitives (Ansible modules, Terraform resources, marketplace Actions, pre-commit)
3. Third-party packaged tools (Homebrew, apt, pip, npm, cargo)
4. Popular community solutions (GitHub projects, official plugins, awesome-* lists)

## 10-line gate

After an empty search: <10 non-comment lines auto-approved; 10+ requires explicit yes.
Code/shebang/heredoc/continuation count; blanks/comments don't; no semicolon-stuffing.

Hook blocks are TERMINAL DENIALS — do not route around them.

## Worked examples

### YAML `run:` with logic

Wrong:

```yaml
- run: |
    for pr in $(gh pr list --json number -q '.[].number'); do
      if [[ $(date +%H) -ge 9 && $(date +%H) -le 17 ]]; then
        gh pr merge "$pr" --squash --auto
      fi
    done
```

Right — extract to a script file, or use a native action:

```yaml
- run: .github/scripts/merge-if-quiet.sh
- uses: peter-evans/enable-pull-request-automerge@v3
```

### Multi-line Bash control flow

Wrong:

```text
while IFS= read -r branch; do
  gh api repos/x/y/git/refs/heads/$branch -X DELETE
done < /tmp/branches.txt
```

Right:

```text
gh api repos/x/y/branches --paginate --jq '.[].name' \
  | xargs -I{} gh api --method DELETE repos/x/y/git/refs/heads/{}
```

### Heredoc smuggling logic

Wrong: `git commit -m "$(cat <<'EOF' ... $(if ...) ... EOF)"`

Right: `git commit -m "feat: standard release"`

### Inline interpreters

Wrong: `python -c "import json; print(json.load(open('x.json'))['key'])"`

Right: `jq -r .key x.json`
