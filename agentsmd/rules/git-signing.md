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

Every commit lands GitHub-verified. The mechanism is uniform — Contents API
web-flow signing — but the *identity* behind the API call depends on who's
making it.

| Context | Identity | Auth | Signing path |
| --- | --- | --- | --- |
| Local Mac | `JacobPEvans` | local user | GPG (key `31652F22BF6AC286`); nix-home reads identity from `$XDG_CONFIG_HOME/nix-home/local.nix` |
| GitHub Actions — deterministic (snake, 3d-contrib, peter-evans/create-pull-request, release-please) | `JacobPEvans-github-actions[bot]` | default `GITHUB_TOKEN` | web-flow via the action's Contents API call |
| GitHub Actions — AI workflows | `JacobPEvans-claude[bot]` | `JacobPEvans-claude` App installation token (`actions/create-github-app-token@v2`) | web-flow via `anthropics/claude-code-action@v1` with `use_commit_signing: true` and `github_token` set to the App token |
| Native cloud-routine workflows (claude-code-routines) | `JacobPEvans-claude[bot]` | same App installation token as above | same Contents API path; routine bodies run inside a regular GHA workflow now (not the Anthropic Cloud Routines sandbox, which can't mint App-class tokens) |
| GitHub bots (Renovate, release-please releases, dependabot) | the bot's GitHub identity | managed by GitHub | web-flow |

Verification for any commit: `gh api repos/<owner>/<repo>/commits/<sha>
--jq '{verified: .commit.verification.verified, reason:
.commit.verification.reason, login: .author.login}'`. Expect
`verified: true, reason: "valid"` and the `login` from the table above.

## AI workflow App-token pattern

Every reusable AI workflow in `JacobPEvans/ai-workflows` mints a
`JacobPEvans-claude` installation token immediately before calling
`anthropics/claude-code-action@v1`, then hands the token in as
`github_token`. The action's `use_commit_signing: true` sends edits through
the Contents API, which web-flow-signs every commit and attributes it to
whichever bot owns the token.

```yaml
- name: Mint JacobPEvans-claude installation token
  id: app-token
  uses: actions/create-github-app-token@v2
  with:
    app-id: ${{ vars.GH_APP_CLAUDE_BOT_ID }}
    private-key: ${{ secrets.GH_APP_CLAUDE_BOT_PRIVATE_KEY }}
    owner: ${{ github.repository_owner }}
    repositories: ${{ github.event.repository.name }}

- name: Run Claude Code
  uses: anthropics/claude-code-action@v1
  with:
    github_token: ${{ steps.app-token.outputs.token }}
    anthropic_api_key: ${{ secrets.OPENROUTER_API_KEY }}
    allowed_bots: "github-actions"
    use_commit_signing: "true"
    prompt: ${{ steps.prompt.outputs.content }}
```

Consumers don't need to import the App credentials themselves — `secrets-sync`
distributes `vars.GH_APP_CLAUDE_BOT_ID` and `secrets.GH_APP_CLAUDE_BOT_PRIVATE_KEY`
to every repo in the `*github_app_repos` set. Adding a new consumer repo:
add it to that anchor in `JacobPEvans/secrets-sync/secrets-config.yml` and
re-run the distribution workflow.

The AI never constructs Contents API payloads itself. It edits files
locally inside the workflow; `claude-code-action@v1` translates those edits
into Contents API calls on commit. So AI workflows enjoy normal file editing
ergonomics without losing signed-commit attribution.

## Deterministic GHA pattern

Workflows where no AI generates content use whichever marketplace action
fits — they sign automatically as long as the action makes its commits
through the Contents API rather than runner-side `git commit`.

| Producer | Action | Notes |
| --- | --- | --- |
| `JacobPEvans/JacobPEvans` snake / 3d-contrib | `peter-evans/create-pull-request@v8` with `sign-commits: true`, then `gh pr merge --squash` | The action wraps the Contents API for arbitrary file updates |
| Release commits (release-please) | `googleapis/release-please-action@v5` | Native web-flow signing |
| Built-in commit modes | e.g. `lowlighter/metrics` with `output_action: commit` | Action handles signing itself |

Never build a custom Contents-API or Git-Data-API helper for content the
runner can hand off to a trusted action.

## Enforcement

Branch-level `required_signatures` Repository Rulesets reject unsigned
pushes at the API. Adding a new workflow that commits? Make sure it goes
through one of the paths above; the ruleset will reject anything else at
push time.

## Canonical sources (single source of truth, link don't duplicate)

- Architecture: this rule.
- Cloud-routine operator setup: `docs/CLOUD_ROUTINES_AUTH.md` in `JacobPEvans/claude-code-routines`.
- Local Mac identity values: `$XDG_CONFIG_HOME/nix-home/local.nix` (gitignored, out-of-tree).
- AI-action App-token pattern: the reusable workflows in
  `JacobPEvans/ai-workflows/.github/workflows/` (issue-resolver, ci-fix,
  code-simplifier, post-merge-tests, post-merge-docs-review, final-pr-review).
- Native cloud-routine pattern: `JacobPEvans/claude-code-routines/.github/workflows/issue-solver.yml`.
- App credential distribution: `secrets:` block in `JacobPEvans/secrets-sync/secrets-config.yml` (`GH_APP_CLAUDE_BOT_PRIVATE_KEY`, `GH_APP_CLAUDE_BOT_ID`).

If you're about to copy-paste signing prose into another file, link here instead.

## Adding a new context

Pick a real identity (App, user, or bot — never anonymous). Decide auth:

- App installation token (`actions/create-github-app-token@v2`) when commits must be attributed to `JacobPEvans-claude[bot]`.
- Default `GITHUB_TOKEN` when commits should be attributed to `JacobPEvans-github-actions[bot]`.
- GPG/SSH-on-runner only when a workflow truly needs `git commit` on the
  runner (rebase, cherry-pick, generated patches that don't fit the
  Contents API) — document the exception inline.

Add a row to the table above; document operator setup in the consuming repo.
