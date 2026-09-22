---
name: rule-tiers
description: Index of the on-demand rule tier — activity to governing file.
---

# Rule tiers

`AGENTS.md`, `soul.md`, `operating-core.md`, `public-disclosure.md` load every session. Other rules carry
`paths:` frontmatter and load themselves when a matching file is in context.

Everything below is **not** auto-loaded — read the file under `agentsmd/rules/on-demand/`
(`~/.agents/agentsmd/rules/on-demand/`) when you begin that activity.

| When you are… | Read |
| --- | --- |
| Branching, PR, releasing | `git-flow.md` |
| Claiming a shared resource | `session-coordination.md` |
| Spawning subagents | `subagent-resilience.md` |
| Running a recurring/heartbeat loop | `loop-cadence.md` |
| Delegating, or acting after a denial | `delegation-trust.md` |
| Offloading to another model | `model-delegation.md` |
| Running a `/skill` | `skill-execution-integrity.md` |
| Side quest, deferred work, maintenance window | `task-tracking.md` |
| Outage or security weakness | `incident-management.md` |
| Changing live infra | `infrastructure-conventions.md` |
| Unattended converge, granting harness access, creating/moving a credential, or "not authenticated" | `secrets-separation.md` |
| Cloning/setting up a repo, starting a change | `workspace-conventions.md` |
| Choosing tools or subagent types | `tool-use.md` |
| OKF bundle | `okf.md` |
| Editing renovate config | `dependency-automation.md` |
| Log/monitoring question | `log-platform.md` |
| Authoring a skill, rule, hook, agent, or harness setting | `cost-aware-authoring.md` |

Machine-specific instructions live outside version control in the operator's
own `*.local.md` files.
