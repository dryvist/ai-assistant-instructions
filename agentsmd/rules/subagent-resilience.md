---
name: subagent-resilience
description: Subagent fan-outs need a health probe first, bounded concurrency, and a solo fallback — the orchestration substrate is allowed to fail without killing the mission
---

# Subagent Resilience

The subagent/spawn substrate (tmux panes, agent supervisors, `fork()` itself)
is infrastructure, and infrastructure fails. During the 2026-07-10 overnight
run, spawns started failing mid-session (`fork failed: Device not configured`,
ENXIO) with huge free resources — and one spawn returned a real agent id but
produced zero output (a phantom). A plan that *requires* subagents has no
fallback when that happens.

## Rules

- **Probe before fan-out.** Before dispatching a batch of subagents, spawn ONE
  trivial probe agent and confirm it returns real output. A dead or phantom
  substrate must be discovered by a 10-second probe, not by losing a 10-agent
  fan-out.
- **Bound concurrency.** Cap concurrent subagents explicitly (default ≤4
  in-flight for heavy agents; harness caps still apply). Excess work queues
  behind finished slots. Never fire an unbounded `.map(spawn)`.
- **Verify liveness, not just launch.** A spawn that returns an id is not a
  working agent. Treat "no transcript/output within a sane deadline" as a
  failed spawn and retry once — then fall back.
- **Solo fallback is mandatory.** Every plan built on delegation must state
  what runs single-threaded when spawning is unavailable. The mission
  degrades to serial execution — it does not abort, and it does not restart
  shared infrastructure (e.g. the tmux server) that would kill the session
  itself mid-run.
- **Don't self-amplify.** When spawns fail, do not retry-loop new spawns on a
  timer; probe occasionally (with backoff), work solo meanwhile.

## Why

The failure mode is silent partial loss: some agents finish, later ones die,
and the orchestrator keeps planning against capacity it no longer has. One
probe + a declared fallback converts "the run collapsed at 00:30" into "the
run went serial at 00:30 and still delivered."

## How to apply

At plan time, write the fan-out as: probe → bounded batches → per-agent
liveness deadline → documented solo path. Cross-ref: `tool-use.md`
(Delegation contract), the `premium-agent-orchestration` skill
(claude-code-plugins) for tiering.
