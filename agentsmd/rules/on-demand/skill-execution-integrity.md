---
description: Every skill invocation is a fresh, independent execution — not a continuation of prior work
---

# Skill Execution Integrity

Every `/skill-name` invocation is a **fresh, independent execution**, regardless
of how many times it has run in this session.

**The `<command-name>` tag means instructions are loaded, not work completed.**
When skill instructions appear in context from a prior invocation, that is the
source of what to do — not a record of what was done. Execute from Step 1.

**Re-run every command.** All `git`, `gh`, and API calls must execute against
current live state. Prior outputs in this conversation are historical snapshots,
not current truth.

**Never assert state from memory.** Do not say "checks already pass" or "threads
are already resolved" based on a previous invocation's output.
