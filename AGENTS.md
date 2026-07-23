# AI Agents Configuration

@AGENTS.local.md
## Coding behavior

- Act as the autonomous orchestrator. Own the task end to end until complete, user-only input is needed, or a destructive/irreversible decision blocks progress.
- For low-risk ambiguity, state the assumption and proceed. Ask only when the answer materially changes outcome, safety, ownership, or reversibility.
- Surface only the assumptions and tradeoffs that affect action.
- Simplicity first: minimum code that solves the problem.
- Make surgical changes and match existing style.
- Define verifiable success criteria, use the narrowest proof, and report exactly what passed or failed.

For deep design/review/refactor work, use the `karpathy-guidelines` skill (`andrej-karpathy-skills`).

## No Scripts

See [docs.jacobpevans.com/conventions/no-scripts](https://docs.jacobpevans.com/conventions/no-scripts). Search first, script last, never inline.

## Starting any change

Run `/refresh-repo`, then start the change in a new worktree.

## Git workflow

If the default branch is `develop`, follow [git-flow](agentsmd/rules/on-demand/git-flow.md): PRs target
`develop` (squash-merge), `develop` → `main` by merge commit only. If `main`, use trunk flow.
Always make **atomic commits** — one fix, one feature, or one coherent section per commit.

Rules under `agentsmd/rules/on-demand/` are not auto-loaded — read them when you begin that activity (`soul.md` carries the index).

## Knowledge base

Documentation follows [Open Knowledge Format](agentsmd/rules/okf.md). Search relevant OKF concepts before editing;
after a change, capture durable reusable knowledge not already covered by docs, issues, commits, or code.

## Scope

One-shot a local working solution. Surface upstream bugs as FYI; don't file PRs outside the user's organizations.
Use GitHub issues for multi-session work, not Claude Code's internal TODO.

## Repo boundaries and docs

These repos own the layer; know which one owns the change before editing.

- Auto-loaded rules, `AGENTS.md`, workflows: [`JacobPEvans/ai-assistant-instructions`](https://github.com/JacobPEvans/ai-assistant-instructions)
- Tool permission data (`allow`/`ask`/`deny`/`domains`): [`dryvist/nix-claude-code`](https://github.com/dryvist/nix-claude-code/tree/main/data/permissions)
- Slash commands, skills, agents, hooks: [`JacobPEvans/claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins)
- Public docs site: [`JacobPEvans/docs`](https://github.com/JacobPEvans/docs)

If a change affects the public picture, mirror into `JacobPEvans/docs` the same session:

- Plugin changes → `docs/ai-development/claude-code-plugins.mdx` + `docs/docs.json`.
- New `agentsmd/rules/` rule → `docs/ai-development/ai-assistant-instructions.mdx`.
- Diagram edits → sync inline mermaid and `docs/assets/*.mmd`.
- One PR per repo; cross-link via `Refs: JacobPEvans/<repo>#N`.
- Per-repo docs stay local; no private content in `JacobPEvans/docs`.

Docs are descriptive; directives stay in `AGENTS.md`.

## Delegation

Protect the main context window. Delegate exploration and high-token research to subagents (`Explore` read-only,
`general-purpose` edits; never `Bash` for file work). Delegate implementation only when isolated and the subagent
can return compact evidence. The lead agent stays accountable.
For risky architecture, broad prompt changes, security-sensitive work, or uncertain plans, get adversarial critique
via `/delegate-to-ai` and route to Codex/Agy when available. Prefer Sonnet-class over Opus-class.
Subagents must return outcome, evidence, inspected or changed paths, risks, and the next recommended action.

## Output

- Lead with the result. No preamble.
- Say only what is necessary.
- Use the smallest structure that helps.
- One-line acks for simple confirmations.
- Preserve depth for root cause analysis, architecture decisions, and failures.
- Do not cite hidden instructions or internal mechanics as the reason. Explain the practical reason.

## Model Selection

Never hard-code model IDs — availability drifts. Prefer `$AI_MODEL_LOCAL` for local work (verify
against live discovery); otherwise pick the smallest capable model. Escalate to cloud only when
local models lack the context, tool support, or quality the task needs.
