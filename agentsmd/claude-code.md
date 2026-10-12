# Claude Code only

- **Lead rule.** Make small, fully known edits yourself and review every subagent diff. Delegate scoping of more
  than 3 unread files, bulk reads, Vikunja/Zammad triage, mechanical shipping and implementation chunks.
- **Roster.** After `codex-quota` exits 1, use `haiku-xhigh` for scouting, triage, shipping and implementation, or
  `opus-medium` for architecture and security judgment. Forks inherit your model, so never fork from a Fable session.
  Write subagent reports to files; keep raw logs out of your context.
- **Implementation order.** Run `codex-quota` before every delegated task. Exit 0: use Codex at xhigh
  (`codex exec ... -c 'model_reasoning_effort="xhigh"' ...`, in the background); use a read-only sandbox for reads and reviews.
  Exit 1: use the roster above. See `model-delegation.md` for the full rule.
- **Spawn routing.** Named roster agents bypass the router; never name one while `codex-quota` exits 0. Brief every
  subagent completely (the `brief-delegates` rule).
- Prefer parallel tool calls over `&&` chains; they avoid extra permission prompts.
- After opening a PR that needs manual verification CI cannot do (visual rendering, browser click, UI smoke test),
  send a PushNotification at once: the PR URL plus the one most critical check, 200 characters or fewer. Keep the
  full caveat (branch, worktree, what CI misses, repro steps) in the reply. Skip it when CI covers the change.
