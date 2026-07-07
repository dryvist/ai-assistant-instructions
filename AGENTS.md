# AI Agents Configuration

## Coding behavior

- Act as the autonomous orchestrator. Own the task end to end until complete, user-only input is needed, or a destructive/irreversible decision blocks progress.
- For low-risk ambiguity, state the assumption and proceed. Ask only when the answer materially changes outcome, safety, ownership, or reversibility.
- Surface only the assumptions and tradeoffs that affect action.
- Simplicity first: minimum code that solves the problem.
- Make surgical changes and match existing style.
- Define verifiable success criteria, use the narrowest proof, and report exactly what passed or failed.

For deep design/review/refactor work, use the `karpathy-guidelines` skill (`andrej-karpathy-skills`).
Plugins, commands, skills, agents, hooks: [JacobPEvans/claude-code-plugins](https://github.com/JacobPEvans/claude-code-plugins).

## No Scripts

See [docs.jacobpevans.com/conventions/no-scripts](https://docs.jacobpevans.com/conventions/no-scripts). Search first, script last, never inline.

## Starting any change

Run `/refresh-repo`, then start the change in a new worktree.

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

If a change in one repo affects the public picture, mirror the relevant slice into `JacobPEvans/docs` in the same session:

- Plugin added, removed, or scope shifted -> update `docs/ai-development/claude-code-plugins.mdx` and `docs/docs.json`.
- New user-facing rule under `agentsmd/rules/` -> mention it in `docs/ai-development/ai-assistant-instructions.mdx`.
- Diagram edits -> keep inline mermaid and any `docs/assets/*.mmd` sources in lockstep.
- One PR per repo; cross-link via `Refs: JacobPEvans/<repo>#N` in the PR body.
- Per-repo docs stay local. Private or user-only content never goes in `JacobPEvans/docs`.

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

Never hard-code model IDs or maintain a static task-to-model table — availability and names drift.
Discover live: prefer `$AI_MODEL_LOCAL` for local general-purpose work, but verify it against live
model discovery before use; otherwise list current models and pick the smallest capable option for
the task. Escalate to cloud only when local models lack the context, tool support, or quality bar
the task needs.
