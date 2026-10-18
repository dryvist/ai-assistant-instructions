---
name: model-delegation
description: Routing rules for delegated work across Codex, Claude, and the model router
---

# Model delegation

Canonical doctrine and routing: `prompt://dryvist/auto-ai-agent/model-delegation`.

Manual Codex run (the router covers `Agent` spawns only): `codex exec -m <slug> -c 'model_reasoning_effort="xhigh"'
-s <read-only|workspace-write> -o <out> - < brief.md`, in the background. `<slug>` is the listed `-luna` entry with the
lowest `priority` in `~/.codex/models_cache.json`; never write a version from memory.

## Fable is a main-session planning model only

No Fable subagents.

## Skills

The procedures this rule refers to are shipped as skills, not carried here — this repository holds configuration
only. They live in the `ai-delegation` and `jpe-ai-delegation` plugins of the
[`claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins) marketplace:

- `delegate-to-ai` — executor-neutral checks: classify the task, keep sensitive content away from third parties, verify the exact result.
- `delegation-ladder` (`jpe-ai-delegation`) — routing eligibility and trusted draft-PR verification.
- `local-subagents` — when a step is worth handing off at all, how to read the live model menu (speed, quality,
  best-for, context, price) from the router's own contract, and how to place the call.
- `openrouter-models` — the self-enforced spend budget, the free-tier logging caveat, and the lane for requesting a model the router does not serve.

None depends on Claude Code: they use shell commands and available harness tools, so a non-Claude harness consumes
them straight from that repository. **That copy is the only authored one.** A harness adopting either deletes its
local version in the same change rather than running both — two copies of a skill about spend and egress will drift
on precisely the rules that carry the risk, and whichever consumer holds the stale one has no way to know.
