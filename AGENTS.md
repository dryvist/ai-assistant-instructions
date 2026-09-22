# AI Agents Configuration

## Coding behavior

Identity and posture: `soul.md`. Use evidence, make reasonable assumptions, proceed, and surface only
assumptions/tradeoffs that affect action. Ship the simplest surgical fix matching existing style; define
verifiable success criteria, use the narrowest proof, and report exactly what passed/failed. Deep
design/review/refactor work: `karpathy-guidelines` skill (`andrej-karpathy-skills`).

Tool choice: use the best-supported native/third-party/community solution; check existing flags/config first.
Custom code is the largest anti-pattern — permanent maintenance. Search `grep.app` first: thousands of hits
means idiomatic, three means a mistake.

Git workflow: start any change with `/refresh-repo`, then a new worktree. `develop` default branch →
[git-flow](agentsmd/rules/on-demand/git-flow.md): PRs target `develop` (squash-merge), `develop` → `main` by
merge commit only. Otherwise trunk flow. Always **atomic commits**, one fix/feature/section per commit. Load
the on-demand rule for the activity — `rule-tiers.md` is the index.

Knowledge base: documentation follows [Open Knowledge Format](agentsmd/rules/on-demand/okf.md) — search before
editing, capture new durable knowledge after a change.

## Where things get written (routing law, no exceptions)

Once questions are resolved and the plan approved, execute end to end in one shot with maximal orchestration,
routed per this table. GitHub is public, **pull requests only**; a PR body states WHAT the code does — never
why, what was broken, or what's still weak.

| Content | Destination |
| --- | --- |
| Incidents, outages, security findings, weaknesses | Zammad |
| Private documentation, especially secret management | the private docs site |
| Everything else, including side quests and follow-ups | Vikunja — **never a GitHub issue** |

Never put an incident narrative, security finding, credential/secret detail, unprovisioned identity, internal
topology, host name, or outage timeline in a GitHub issue, PR, comment, or commit message — "side quest" is
not an exemption.

Repo boundaries: `JacobPEvans/ai-assistant-instructions` (rules, `AGENTS.md`, workflows),
`dryvist/nix-claude-code` `data/permissions` (tool permissions), `JacobPEvans/claude-code-plugins` (commands,
skills, agents, hooks). Update the private docs site in the same session; most changes need it.

Orchestration and model routing: `model-delegation.md` (on-demand).
