# Claude Code only

- **Lead rule.** Make small, fully known edits; review every diff. Delegate scoping >3 unread files, bulk reads, Vikunja/Zammad triage, shipping, and implementation.
- **Routing.** Follow the Delegation block in [`AGENTS.md`](../AGENTS.md); write reports to files. Forks inherit your model; never fork from Fable.
- Prefer parallel tool calls to `&&` chains; they avoid extra permission prompts.
- After a PR needs manual verification CI cannot do (visual render, browser click, UI smoke), send a PushNotification
  immediately: PR URL plus the top check, 200 characters or fewer. Put branch, worktree, missed check, and repro steps
  in the reply. Skip when CI covers it.
