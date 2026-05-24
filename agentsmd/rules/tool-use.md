---
name: tool-use
description: Prefer native tools over Bash equivalents (Read/Edit/Write/Grep/Glob). Use general-purpose subagent when files are edited.
---

# Tool Use

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
| Delegate to external AI | Bifrost or `/delegate-to-ai` | Manual model routing |

## Subagent type selection

| `subagent_type` | Use when |
| --- | --- |
| `general-purpose` | Any task that reads, writes, or edits files |
| `Explore` | Read-only research / exploration |
| `Bash` | Pure shell only; never for file ops (Bash-only agents work around missing tools with `python -c`/`sed`/`awk` and bypass audit trails) |
