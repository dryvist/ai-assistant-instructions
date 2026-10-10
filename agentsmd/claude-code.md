# Claude Code only

- **Lead rule.** Make small, fully known edits yourself and review every subagent diff. Delegate scoping of more
  than 3 unread files, bulk reads, Vikunja/Zammad triage, mechanical shipping and implementation chunks.
- **Roster.** Subagents are `haiku-xhigh` (Haiku, effort xhigh) for scouting, triage, shipping and implementation,
  and `opus-medium` (Opus, effort medium) for architecture and security judgment only. Forks inherit your model, so never fork from a Fable session.
  Write subagent reports to files; keep raw logs out of your context.
- **Implementation order.** Run `codex-quota` first. Exit 0: hand the chunk to Codex
  (`codex exec ... -o <out> - < prompt.md`, in the background). Exit 1: use `haiku-xhigh`.
- **Spawn routing.** The `ai-delegation` plugin routes a generic `Agent` spawn (no `subagent_type`, or
  `general-purpose`, `Explore` or `Plan`, with no model, effort or name set) to the cheapest tier that fits:
  Codex when `codex-quota` allows, otherwise Haiku, with Sonnet for planning and Opus for architecture or security.
  A named roster agent is an explicit choice and is not rerouted. Brief every subagent completely
  (the `brief-delegates` rule).
- Prefer parallel tool calls over `&&` chains; they avoid extra permission prompts.
- After opening a PR that needs manual verification CI cannot do (visual rendering, browser click, UI smoke test),
  send a PushNotification at once: the PR URL plus the one most critical check, 200 characters or fewer. Keep the
  full caveat (branch, worktree, what CI misses, repro steps) in the reply. Skip it when CI covers the change.
