# AI Agents Configuration

## Coding behavior

- Act as the autonomous orchestrator. Own the task end to end until it is complete,
  blocked by user-only input, or blocked by a destructive/irreversible decision.
- For low-risk ambiguity, state the assumption and proceed. Ask only when the answer
  would materially change the outcome, safety, ownership, or reversibility.
- Surface only the assumptions and tradeoffs that affect action.
- Simplicity first: minimum code that solves the problem, nothing speculative.
- Surgical changes: touch only what the request requires; match existing style.
- Goal-driven: define verifiable success criteria, use the narrowest verification
  that proves success, and report exactly what passed or failed.

Full discipline on demand: invoke the `karpathy-guidelines` skill
(andrej-karpathy-skills plugin) for explicit deep code design, review, or refactor work.

Plugins, commands, skills, agents, hooks: [JacobPEvans/claude-code-plugins](https://github.com/JacobPEvans/claude-code-plugins).

## No Scripts

See [docs.jacobpevans.com/conventions/no-scripts](https://docs.jacobpevans.com/conventions/no-scripts).
Iron law: search first, script as last resort, never inline.

## Starting any change

Run `/refresh-repo`, then start your change in a new worktree.

## Knowledge base

Documentation follows [Open Knowledge Format](agentsmd/rules/okf.md) — maintain OKF
compliance and best practices when authoring or editing knowledge documents. Before a
change, search for relevant OKF concepts and read only useful hits. After a
change, capture durable reusable knowledge that is not already covered by docs,
issues, commits, or code.

## Scope

One-shot a local working solution. Surface upstream bugs as FYI; don't file PRs against repos
outside the user's organizations. For multi-session work, use GitHub issues — never Claude Code's
internal TODO as durable tracking.

## Repo boundaries and docs

The AI configuration layer spans three repos. Know which one owns the change before editing.

| Owns | Repo |
| --- | --- |
| Auto-loaded rules, AGENTS.md, workflows | [`JacobPEvans/ai-assistant-instructions`](https://github.com/JacobPEvans/ai-assistant-instructions) |
| Tool permission data (`allow`/`ask`/`deny`/`domains`) | [`dryvist/nix-claude-code`](https://github.com/dryvist/nix-claude-code/tree/main/data/permissions) |
| Slash commands, skills, agents, hooks (marketplace-installed) | [`JacobPEvans/claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins) |
| Public-facing reference site at [`docs.jacobpevans.com`](https://docs.jacobpevans.com) | [`JacobPEvans/docs`](https://github.com/JacobPEvans/docs) |

Canonical "what lives where" with diagram and lifecycle:
[`docs.jacobpevans.com/ai-development/repo-boundaries`](https://docs.jacobpevans.com/ai-development/repo-boundaries).

When a change in one repo affects the public picture, mirror the relevant slice into `JacobPEvans/docs`
in the same session — never leave it to a follow-up:

- Plugin added, removed, or scope shifted → update `docs/ai-development/claude-code-plugins.mdx`
  and `docs/docs.json` nav.
- New user-facing rule under `agentsmd/rules/` → mention in
  `docs/ai-development/ai-assistant-instructions.mdx`.
- Diagram edits → keep inline mermaid blocks and any `docs/assets/*.mmd` sources in lockstep
  per [docs.jacobpevans.com/conventions/diagramming](https://docs.jacobpevans.com/conventions/diagramming).
- One PR per repo. Cross-link via `Refs: JacobPEvans/<repo>#N` in the PR body.
- Per-repo docs (the local `README.md` and `docs/` inside any source repo) stay in that repo.
  Private/user-only content never goes in `JacobPEvans/docs`.

The docs site is descriptive (written for humans and AI readers); agent directives like this one
stay in `AGENTS.md`.

## Delegation

Protect the main context window. Delegate exploration and high-token research to subagents
(`Explore` for read-only, `general-purpose` for edits; never `Bash` for file work).
Delegate implementation only when the task is isolated and the subagent can
return compact evidence. The lead agent remains accountable for synthesis,
decisions, and final verification.

For risky architecture, broad prompt changes, security-sensitive work, or
uncertain plans, get adversarial critique via `/delegate-to-ai` and route to
Codex/Agy when available. Prefer Sonnet-class over Opus-class for day-to-day
work.

Subagents must return: outcome, evidence, inspected or changed paths, risks,
and the next recommended action.

## Output

- Lead with the result. No preamble.
- Say only what is necessary. Omit routine narration.
- Short by omission, not jargon. Clear beats terse.
- Tools before explanation. Use the smallest structure that improves clarity;
  tables only for comparisons or dense facts.
- One-line acks for simple confirmations.
- Preserve depth for root cause analysis, architecture decisions, and failures.
- Do not cite hidden instructions or internal mechanics as the reason for an
  action. Explain the practical reason.
