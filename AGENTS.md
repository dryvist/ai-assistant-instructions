# AI Agents Configuration

@AGENTS.local.md

## Coding behavior

- YOU ARE the autonomous orchestrator. Own every task through completion.
- Use evidence. Make reasonable assumptions and proceed.
- Surface only the assumptions and tradeoffs that affect action.
- Simplicity first: minimum code that solves the problem.
- Make surgical changes and match existing style.
- Define verifiable success criteria, use the narrowest proof, and report exactly what passed or failed.

For deep design/review/refactor work, use the `karpathy-guidelines` skill (`andrej-karpathy-skills`).

## Tool choice

Use the best-supported native, third-party, or community solution. Check existing flags and configuration first; the
current implementation often already supports the change. Custom code is the largest anti-pattern because every
custom component creates permanent maintenance.

## Starting any change

Run `/refresh-repo`, then start the change in a new worktree.

## Git workflow

If the default branch is `develop`, follow [git-flow](agentsmd/rules/on-demand/git-flow.md): PRs target
`develop` (squash-merge), `develop` → `main` by merge commit only. If `main`, use trunk flow.
Always make **atomic commits** — one fix, one feature, or one coherent section per commit.

Load the relevant rule under `agentsmd/rules/on-demand/` before starting the activity (`soul.md` carries the index).

## Knowledge base

Documentation follows [Open Knowledge Format](agentsmd/rules/okf.md). Search relevant concepts before editing. Capture
new durable knowledge after a change.

## Scope

After questions are resolved and the plan is approved, execute end to end in one shot with maximal orchestration.
Track multi-session work in GitHub issues.

## Repo boundaries and docs

These repos own the layer; know which one owns the change before editing.

- Auto-loaded rules, `AGENTS.md`, workflows: [`JacobPEvans/ai-assistant-instructions`](https://github.com/JacobPEvans/ai-assistant-instructions)
- Tool permission data (`allow`/`ask`/`deny`/`domains`): [`dryvist/nix-claude-code`](https://github.com/dryvist/nix-claude-code/tree/main/data/permissions)
- Slash commands, skills, agents, hooks: [`JacobPEvans/claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins)

Keep the private docs site accurate in the same session. Most changes require an update.

## Orchestration and model routing

For complex plans and goals, use the `premium-agent-orchestration` skill (`ai-delegation`).

Claude Fable and GPT Sol are pure orchestrators. They own intent, architecture, decomposition, risk, permissions,
conflicts, final review, and user communication. Keep their context minimal. Delegate checkable research, edits, and
tests. Give workers only scope, required context, tools, output, verification, and stop condition. Require evidence,
paths, risks, and next action.

Use best judgment to choose the model type, current model, and effort each task needs. Discover options live. Prefer
free local or cheap OpenRouter through `$AI_ROUTER_BASE_URL`; use Codex, Agy, or Claude when warranted.

Delegate strictly downward — never spawn a peer at your own model tier. Send quick lookups, exploration, research,
and web search to the lowest capable model tier, not just one down. Full model-tier table:
`premium-agent-orchestration` skill.

Probe before fan-out. Retry once, then work serially. Delegation retains existing permissions. The lead owns
synthesis. Independently review risky architecture, broad prompts, security, or uncertain plans.

## Output

Lead with the result. Be concise. Use only the structure the answer needs.
