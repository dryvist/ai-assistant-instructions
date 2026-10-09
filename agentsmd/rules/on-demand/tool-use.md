---
name: tool-use
description: Prefer native tools over Bash equivalents (Read/Edit/Write/Grep/Glob). Use a delegate with file-editing tools when files are edited.
---

# Tool Use

## Operating model

- Prefer native tools and installed plugins over shell equivalents.
- Before saying a tool, command, skill, agent, or connector is unavailable,
  discover it with the runtime's tool or plugin discovery mechanism.
- The lead makes small, fully known edits itself and reviews every diff. It
  delegates bulk reads, scoping of more than three unread files, mechanical
  shipping, and implementation chunks. It then synthesizes results, chooses the
  path, and verifies the final state.

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

The following `subagent_type` options apply to the Claude harness; other agent CLIs
are delegates too, selected by fit and cost under `model-delegation.md`.

| `subagent_type` | Use when |
| --- | --- |
| `haiku-high` | Implementation chunks, bulk reads, mechanical shipping |
| `opus-high` | Architecture and security judgment only; advisory, the lead decides |
| `Explore` | Read-only research / exploration (model not pinned; prefer `haiku-high` for bulk sweeps) |
| `Bash` | Pure shell only; never for file ops (Bash-only agents work around missing tools with `python -c`/`sed`/`awk` and bypass audit trails) |

`general-purpose` takes the harness default model unless the spawn names one.
Use it only with an explicit roster model and effort (for example `haiku`, `xhigh`).

Forks run on the lead's model. Do not fork from a Fable session.

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
