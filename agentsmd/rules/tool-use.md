---
name: tool-use
description: Prefer native tools over Bash equivalents (Read/Edit/Write/Grep/Glob). Use general-purpose subagent when files are edited.
---

# Tool Use

## Operating model

- Prefer native tools and installed plugins over shell equivalents.
- Before saying a tool, command, skill, agent, or connector is unavailable,
  discover it with the runtime's tool or plugin discovery mechanism.
- Keep the lead agent as orchestrator: delegate context-heavy work, then
  synthesize results, choose the path, and verify the final state.

## Ecosystem alternatives

| Task | Use | Not |
| --- | --- | --- |
| File reading | `Read` | `cat`, `head`, `tail` |
| File editing | `Edit` | `sed -i`, `awk`, `python -c` |
| File creation | `Write` | `cat >`, heredocs, `echo >` |
| File search | `Grep` | `grep`, `rg`, `ag` via Bash |
| File discovery | `Glob` | `find`, `ls`, `fd` via Bash |
| JSON manipulation | `jq` via Bash | Python script |
| API calls | `curl` / `gh api` | Python/curl script |
| Multi-file git ops | Parallel Bash tool calls | Loop script |
| Workspace sweep / abandoned branches | `/refresh-repo --sweep` | Free-form sweep scripts |
| Close PR + cleanup local state | `/wrap-up purge-pr <PR_NUMBER>` | `gh pr close` alone |
| Infrastructure config | Ansible modules, Terraform resources | Configuration script |
| Infrastructure validation | `terraform validate`, `ansible-lint`, check modes | Validation script |
| State queries | `terraform output`, Ansible facts | Query script |
| Delegate to external AI | `/delegate-to-ai` (Codex / native subagent) | Manual model routing |

When a capability isn't natively provided by a standard tool, the answer is
"use the tool as-is, or don't do it" — not "write a small script." A custom
wrapper script is an unmaintained, untested-at-scale liability that duplicates
or poorly reinvents what packaged tools already do. If a desired refinement
can't be done through the tool's native config, drop that refinement rather
than scripting around the gap.

**Never pipe or dump a bare `env`** (or `printenv`), even through a filter
like `cut -d'=' -f1`. Multi-line values (private keys, license blobs) break
line-based parsing and can print secret contents into the transcript/log.
Test for a specific variable's presence with `[[ -n "$VAR" ]]` instead.

## Subagent type selection

| `subagent_type` | Use when |
| --- | --- |
| `general-purpose` | Any task that reads, writes, or edits files |
| `Explore` | Read-only research / exploration |
| `Bash` | Pure shell only; never for file ops (Bash-only agents work around missing tools with `python -c`/`sed`/`awk` and bypass audit trails) |

## Delegation contract

- Use subagents for broad codebase sweeps, log or test triage, source
  comparison, and other high-token exploration.
- Delegate edits only when the scope is isolated and the expected return can be
  checked with a compact diff or test result.
- For risky architecture, broad prompt changes, security-sensitive changes, or
  plans that feel under-specified, request adversarial critique via
  `/delegate-to-ai`; route to Codex/Agy directly when available.
- Require every delegated result to include outcome, evidence, inspected or
  changed paths, risks, and the next recommended action.
