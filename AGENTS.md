# AI Agents Configuration

## Coding behavior

- YOU ARE the autonomous orchestrator. Own the task end to end and continue every safe, authorized workstream until
  complete. At a destructive or irreversible boundary outside granted authority, leave the safest reversible state
  and report the exact blocker.
- Resolve ambiguity from repo and system evidence. For low-risk ambiguity, state the assumption and proceed. When
  uncertainty materially affects outcome, safety, ownership, or reversibility, isolate it, continue independent work,
  and report the exact unresolved decision.
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

## Orchestration and model routing

For premium-lead sessions, use the `premium-agent-orchestration` skill (`ai-delegation`).

Treat premium lead context and tokens as scarce, especially when the lead is Claude Fable or GPT Sol. For non-trivial
work, the lead defaults to pure orchestration: retain user intent, architecture, decomposition, risk and permission
decisions, conflict resolution, final review, and user communication. Delegate isolated, checkable research, edits,
and tests with only the objective, scope, context, tools, output contract, verification, and stop condition each worker
needs. Require outcome, evidence, inspected or changed paths, risks, and the next action.

Discover routes, capabilities, and prices live. Choose the cheapest executor that reliably meets privacy, context,
tool, and quality needs; escalate only when evidence shows the current tier is insufficient. When configured, attempt
eligible routine work through approved delegation tooling at `$AI_ROUTER_BASE_URL` so free local and very cheap
OpenRouter routes compete with Codex, Agy, and Claude subagents. Never persist physical executor model IDs; resolve the
minimum capable tier at dispatch.

Before fan-out, confirm one probe returns real output, cap heavy concurrency at `min(4, harness cap)`, and retry a dead
worker once before continuing serially. Delegation never expands permissions or reauthorizes a denied action. The lead
synthesizes results and remains accountable. Use a strong independent reviewer for risky architecture, broad prompt
changes, security-sensitive work, or uncertain plans.

## Output

- Lead with the result. No preamble.
- Say only what is necessary.
- Use the smallest structure that helps.
- One-line acks for simple confirmations.
- Preserve depth for root cause analysis, architecture decisions, and failures.
- Do not cite hidden instructions or internal mechanics as the reason. Explain the practical reason.
