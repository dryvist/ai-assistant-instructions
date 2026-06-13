# AI Agents Configuration

## Coding behavior

- Surface assumptions and tradeoffs before coding; if something is unclear, stop and ask.
- Simplicity first: minimum code that solves the problem, nothing speculative.
- Surgical changes: touch only what the request requires; match existing style.
- Goal-driven: define verifiable success criteria, loop until tests prove them.

Full discipline on demand: invoke the `karpathy-guidelines` skill
(andrej-karpathy-skills plugin) when writing, reviewing, or refactoring code.

Plugins, commands, skills, agents, hooks: [JacobPEvans/claude-code-plugins](https://github.com/JacobPEvans/claude-code-plugins).

## No Scripts

See [docs.jacobpevans.com/conventions/no-scripts](https://docs.jacobpevans.com/conventions/no-scripts).
Iron law: search first, script as last resort, never inline.

## Starting any change

Run `/refresh-repo`, then start your change in a new worktree.

## Knowledge base

Documentation follows [Open Knowledge Format](agentsmd/rules/okf.md). Before a change, check for
relevant OKF concepts; after, update or create documents for any knowledge worth capturing.

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
For external model calls use Bifrost or `/delegate-to-ai`. Prefer Sonnet-class over Opus-class
for day-to-day work.

## Output

- Lead with the result. No preamble.
- Short sentences. Tools before explanation. Tables over prose.
- One-line acks for simple confirmations.
- Preserve depth for root cause analysis and architecture decisions.
