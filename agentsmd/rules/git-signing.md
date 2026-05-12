---
name: git-signing
description: Where each AI execution context gets its commit signing identity in JacobPEvans repos. Every commit must be signed; required_signatures is enforced org-wide.
paths:
  - ".github/workflows/**"
  - "**/*.prompt.md"
  - "**/modules/git/**"
  - "**/git-guards/**"
  - "flake.nix"
---

# Git Signing — Identity Per Context

Every commit lands GitHub-verified. Workflows pick one of two paths depending on
whether AI generates the diff:

- **Local `git commit` with SSH signing** — canonical for AI-driven work. The
  runner imports `GH_APP_CLAUDE_SSH_SIGNING_KEY`, configures git for SSH
  signing, and Claude (or any human) commits normally. The author is set to the
  GitHub user that owns the public counterpart of the SSH key. Reason for the
  preference: AI produces malformed JSON / base64 payloads when asked to
  construct Contents-API calls directly, but produces clean diffs when editing
  files locally.
- **Contents API via `gh api .../contents/...` or
  `octokit.repos.createOrUpdateFileContents`** — canonical for deterministic
  non-AI workflows (snake.yml, 3d-contrib.yml, cloud routines). GitHub web-flow
  signs commits made through these endpoints automatically when the call
  authenticates as a GitHub App. Use this when no AI generates content — the
  action / routine constructs the API payload, never the model.

| Context | Identity | Auth | Signing path |
| --- | --- | --- | --- |
| Local Mac | `JacobPEvans` | local user | GPG (key `31652F22BF6AC286`); nix-home reads identity from `$XDG_CONFIG_HOME/nix-home/local.nix` |
| GitHub Actions — AI-driven | `JacobPEvans` signer + bot Co-authored-by trailer | App token + `GH_APP_CLAUDE_SSH_SIGNING_KEY` | SSH via the wrapper composite action's `ssh_signing_key` input |
| GitHub Actions — deterministic | `JacobPEvans-github-actions[bot]` | App token | web-flow via Git Data API (createBlob + createTree + createCommit + updateRef) |
| Anthropic Cloud Routines | `JacobPEvans-claude[bot]` | `GH_TOKEN` (long-lived PAT) | web-flow via `gh api .../contents/...` with a nested `committer` object |
| GitHub bots (Renovate, release-please) | the bot's GitHub identity | managed by GitHub | web-flow |

For AI workflows, the entry point is the composite action
`JacobPEvans/ai-workflows/.github/actions/ai-action-with-signing@main`. For
deterministic workflows in `JacobPEvans/JacobPEvans`, see
`.github/scripts/commit-files-to-branch.js`. For cloud routines, see the
shape below.

## SSH-signed AI workflows

The composite action
`JacobPEvans/ai-workflows/.github/actions/ai-action-with-signing@main` is the
canonical entry point. It takes `ssh_signing_key`, `bot_id`, `bot_name` as
inputs and configures `anthropics/claude-code-action@v1` to sign locally:

```yaml
- uses: JacobPEvans/ai-workflows/.github/actions/ai-action-with-signing@main
  with:
    anthropic_api_key: ${{ secrets.OPENROUTER_API_KEY }}
    ssh_signing_key: ${{ secrets.GH_APP_CLAUDE_SSH_SIGNING_KEY }}
    prompt: ${{ steps.prompt.outputs.content }}
    allowed_tools: "Edit,MultiEdit,Write,Read,Glob,Grep,LS,Bash(git:*),Bash(gh pr create:*)"
    model: ${{ vars.AI_MODEL_PLAN }}
```

Verification: pull commits from the resulting PR via
`gh api repos/.../commits/<sha>` — expect
`verification.verified: true, reason: "valid"` and
`author.email: "20714140+JacobPEvans@users.noreply.github.com"`. The SSH key
(id 826672 on the JacobPEvans user account) is the public counterpart of
`GH_APP_CLAUDE_SSH_SIGNING_KEY`; rotation requires regenerating the keypair
and re-uploading the public half via `gh api user/ssh_signing_keys`.

Bot attribution goes in the commit body via
`Co-authored-by: JacobPEvans-claude[bot] <…@users.noreply.github.com>` so the
GitHub UI shows the human-plus-bot association, while the author field stays
correct for signature verification.

## Cloud-routine commit shape

Routines never run `git commit` / `git push`. All commits go through
the Contents API; GitHub web-flow signs them automatically. The routine
env supplies `GH_TOKEN`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`
(set once on the shared cloud env).

`gh api -f key.subkey=value` sends a flat key, not a nested object —
the Contents API requires `committer` as a real nested object, so the
payload must be built with `jq` and piped via `--input -`:

```bash
jq -n \
  --arg msg "..." \
  --arg content "$(base64 -w0 < file)" \
  --arg branch "..." \
  --arg cname "$GIT_COMMITTER_NAME" \
  --arg cemail "$GIT_COMMITTER_EMAIL" \
  '{message:$msg, content:$content, branch:$branch,
    committer:{name:$cname, email:$cemail}}' \
| gh api repos/{owner}/{repo}/contents/{path} -X PUT --input -
```

Branch creation: `gh api repos/.../git/refs`. PR creation: `gh pr create`. Result: `verification.verified: true, reason: "valid"`, `author.login: "JacobPEvans-claude[bot]"`.

## Defense in depth — four enforcement layers

A single regression in any layer below would have caught the snake.yml / 3d-contrib.yml unsigned-commit incident:

1. **Pre-commit hook** (`ai-assistant-instructions/scripts/check-no-runner-git-commit.sh`) blocks raw `git commit` / `git push` in workflow YAML at author time.
2. **PR-level CI gate** (`JacobPEvans/.github/.github/workflows/_signed-commits-check.yml`) fails any PR whose commits aren't `verified:true`.
3. **Repository Rulesets** with `required_signatures` on every default branch in both orgs reject unsigned pushes at the API level.
4. **Weekly audit** (`JacobPEvans/.github/.github/workflows/audit-unsigned-commits.yml`) sweeps both orgs and posts to `#github-ci-failures` if any
   unsigned commit lands.

Adding a new workflow that commits? Make sure it goes through one of the two paths in the table above. The pre-commit hook will tell you immediately if it doesn't.

## Canonical sources (single source of truth, link don't duplicate)

- Architecture: this rule.
- Cloud-routine operator setup: `docs/CLOUD_ROUTINES_AUTH.md` in `JacobPEvans/claude-code-routines`.
- Local Mac identity values: `$XDG_CONFIG_HOME/nix-home/local.nix` (gitignored, out-of-tree).
- AI-action signing wrapper: `.github/actions/ai-action-with-signing/action.yml` in `JacobPEvans/ai-workflows` (composite action; supersedes the
  never-built `_ai-action-with-signing.yml` reusable workflow this rule referenced before 2026-05).
- Contents-API helper for deterministic content: `.github/scripts/commit-files-to-branch.js` in `JacobPEvans/JacobPEvans`.

If you're about to copy-paste signing prose into another file, link here instead.

## Adding a new context

Pick a real identity (App, user, or bot — never anonymous). Decide auth:
long-lived PAT for sandboxes that can't refresh env; installation token
for actions that mint per-run. Decide signing: web-flow if commits go
through GitHub APIs; SSH/GPG if they go through `git commit`. Add a row
to the table above; document operator setup in the consuming repo.
