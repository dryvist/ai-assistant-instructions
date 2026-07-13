# Codex Quick Start

Codex is most useful in this workspace when it follows the same repo contracts
you already use with Claude, not when it invents a new workflow.

## Source Of Truth

- [`AGENTS.md`](../AGENTS.md) and [`CLAUDE.md`](../CLAUDE.md) in the active repo worktree are the primary instruction sources.
- [`AGENTS.md`](../AGENTS.md) is the canonical behavior layer for the workspace.
- [`claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins) is the source for workflow ideas that can be translated into Codex habits.
- `nix-ai/modules/codex.nix` is the declarative Codex config hook. It is still a placeholder today.
- [`nix-darwin/modules/darwin/homebrew.nix`](https://github.com/JacobPEvans/nix-darwin/blob/main/modules/darwin/homebrew.nix) installs the Codex CLI.
- Repo-local docs in `terraform-*`, `ansible-*`, and `nix-*` are authoritative for command wrappers and placement rules.

Do not assume `~/AGENTS.md` is a guaranteed fallback. In practice, rely on the active repo’s instruction files and your trust configuration.

## Repo Map

| Repo family | What it teaches Codex | How to use it |
| --- | --- | --- |
| `ai-assistant-instructions` | Worktree-first behavior, concise output, research-first discipline, no ad hoc scripts | Treat as the default operating model |
| `claude-code-plugins` | Git workflow, infra standards, config sync, delegation, analytics | Translate the habits, not the plugin mechanics |
| `nix-darwin` | Where Codex is installed on the machine | Use it for app installation only |
| `nix-ai` | Where Codex should eventually be configured declaratively | Use it as the config target for future parity work |
| `nix-home` / `nix-devenv` | Shells, tools, and repo dev environments | Keep Codex inside the same shells you already use |
| Terraform repos: `terraform-proxmox`, `terraform-runs-on`, `terraform-aws`, `terraform-aws-bedrock`, `terraform-aws-static-website` | Infra wrappers, inventory flow, and idempotent command patterns | Follow the repo docs exactly before making changes |
| Ansible repos: `ansible-proxmox`, `ansible-proxmox-apps`, `ansible-splunk` | Infra wrappers, inventory flow, and idempotent command patterns | Follow the repo docs exactly before making changes |

## Use This Every Session

1. Open the repo. For parallel work, use a worktree.
2. Read the repo-local `AGENTS.md` or `CLAUDE.md` first.
3. Ask Codex to summarize the repo contracts before editing anything.
4. For infra work, make Codex repeat the documented wrapper command back to you before running it.
5. Verify the change before you treat it as done.

Use this prompt shape when you want Codex aligned to your workflow:

```text
Read the repo instructions first. Summarize the relevant workflow, tool wrappers,
and constraints. Then propose the smallest safe change and wait for confirmation
before editing.
```

## Customizations To Use Now

- Add trust entries in `~/.codex/config.toml` for your repo roots so Codex can work without permission churn.
- Keep model defaults pragmatic; use higher reasoning only for architecture, reviews, and cross-repo planning.
- Keep prompts explicit about worktree boundaries, git hygiene, and repo-local command wrappers.
- Use Codex for repo-local implementation, reviews, and verification, not for guessing current ecosystem state.

Example prompt patterns:

- `Analyze this repo, summarize the workflow contracts, then tell me the safest first edit.`
- `Implement the smallest change in this worktree, then run the repo's documented validation.`
- `Review this diff for bugs, regressions, and missing tests.`
- `For this OpenTofu repo, use its documented Terrakube workspace and native OpenBao credential flow exactly.`
- `If repo docs conflict with your assumptions, trust the repo docs and call out the mismatch.`

## What To Port Next

`nix-ai` is the right home for the next round of Codex-specific customization.

Priority order:

1. Replace the `modules/codex.nix` placeholder with real declarative config.
2. Generate a Codex-specific instruction file from the canonical workspace rules.
3. Add trusted project directory management if Codex supports it declaratively.
4. Surface Codex-friendly mirrors of the habits you already enforce with Claude: worktrees, validation, repo wrappers, and review discipline.
5. Keep analytics and advanced orchestration ideas as follow-on work, not day-one requirements.

Do not try to mirror Claude plugin behavior 1:1. Port the habits that are actually transferable.

## Why This Matters

Your current Claude ecosystem is already opinionated:

- `ai-assistant-instructions` defines the shared rules.
- `claude-code-plugins` enforces the workflow.
- `nix-ai` delivers the tooling.
- The Terraform and Ansible repos define the operational constraints.

Codex will work best when it inherits those same constraints instead of acting like a generic coding assistant.
