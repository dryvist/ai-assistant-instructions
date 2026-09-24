---
name: rule-tiers
description: Index of the on-demand rule tier.
---

# Rule tiers

`AGENTS.md`, `soul.md`, `operating-core.md`, `public-disclosure.md` load every session; other rules self-load
via `paths:` frontmatter. Everything below is **not** auto-loaded — read the file under
`agentsmd/rules/on-demand/` when you begin that activity.

| When you are… | Read |
| --- | --- |
| Branching, PR, releasing | `git-flow.md` |
| Claiming a shared resource | `session-coordination.md` |
| Spawning subagents | `subagent-resilience.md` |
| Running a recurring/heartbeat loop | `loop-cadence.md` |
| Delegating, or acting after a denial | `delegation-trust.md` |
| Offloading to another model, or orchestrating/routing work | `model-delegation.md` |
| Running a `/skill` | `skill-execution-integrity.md` |
| Side quest, deferred work, maintenance window | `task-tracking.md` |
| Outage or security weakness | `incident-management.md` |
| Changing live infra | `infrastructure-conventions.md` |
| Unattended converge, credential creation/move, or "not authenticated" | `secrets-separation.md` |
| Cloning/setting up a repo, starting a change | `workspace-conventions.md` |
| Choosing tools/subagent types | `tool-use.md` |
| OKF bundle | `okf.md` |
| Editing renovate config | `dependency-automation.md` |
| Log/monitoring | `log-platform.md` |
| Authoring a skill, rule, hook, agent, or harness setting | `cost-aware-authoring.md` |
| Merging a change to behavior, config, a name, a version, or an endpoint in any repo | the private documentation source's `docs-sync` skill — find the pages that name the changed repo or file and bring them back in line in the same session |

Machine-specific instructions: the operator's own `*.local.md` files, outside version control.
