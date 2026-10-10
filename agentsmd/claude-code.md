# Claude Code only

- **Lead rule.** Make small, fully known edits yourself and review every subagent diff. Delegate scoping of more
  than 3 unread files, bulk reads, Vikunja/Zammad triage, mechanical shipping and implementation chunks.
  Brief every subagent completely: goal, exact scope, constraints, success check, output path and stop
  conditions. A vague brief is your failure, not the subagent's (`operating-core.md`).
- **Roster.** Subagents are `haiku-high` (Haiku, effort xhigh) for scouting, triage, shipping and implementation,
  and `opus-high` (Opus, effort high) for architecture and security judgment only. Forks inherit your model, so never fork from a Fable session.
  Write subagent reports to files; keep raw logs out of your context.
- **Implementation order.** Run `codex-quota` first. Exit 0: hand the chunk to Codex
  (`codex exec ... -o <out> - < prompt.md`, in the background). Exit 1: use `haiku-high`.
- **Spawn gate.** A PreToolUse hook on `Agent` denies spawns with no model, effort below high, any model other
  than Haiku or Opus, Opus on read-only scouting, and Claude implementation while Codex has quota. After a failed
  Codex run, add `[codex-fallback]` to the prompt. Read the denial reason; never route around it.
- Prefer parallel tool calls over `&&` chains; they avoid extra permission prompts.
- After opening a PR that needs manual verification CI cannot do (visual rendering, browser click, UI smoke test),
  send a PushNotification at once: the PR URL plus the one most critical check, 200 characters or fewer. Keep the
  full caveat (branch, worktree, what CI misses, repro steps) in the reply. Skip it when CI covers the change.
