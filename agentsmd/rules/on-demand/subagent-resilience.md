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

## The artifact clock

A live agent producing nothing is a worse failure than a dead one: it looks
healthy, so the lead keeps waiting. **Silence is no signal, never progress.**

- **Push within 30 minutes, even unfinished.** State it in every brief (full brief
  checklist: `model-delegation.md`, "Brief the delegate"). A
  branch on the remote is the only proof work exists — unpushed work is
  invisible to every PR-based check and indistinguishable from no work.
- **Verify by artifact, never by asking.** Before sending a status message,
  run the checks. They take seconds and return ground truth; a status reply
  is at best a claim:

  ```bash
  gh pr list -R <owner>/<repo> --state open
  git -C <worktree> rev-list --count origin/<base>..HEAD
  git -C <worktree> status --porcelain | wc -l
  ```

- **Two strikes, on a clock.** No artifact at 30 min → one specific
  corrective instruction. No artifact at 60 min → stop the agent, reassign
  the work with the diagnosis attached. Never poll a third time.
- **The lead lands the last mile.** If work exists on disk and is unpushed at
  the next check, the lead commits and pushes it — no further asking.
  Merging a green PR, running one diagnostic command, or rescuing an at-risk
  worktree are lead actions. Delegate what is large or context-heavy, never
  what is small and blocking.
- **Serialise the critical path.** Parallel agents against one gate waste
  slots. The blocking item gets the first slot and the lead's attention, not
  equal footing with cosmetic work.
- **A push is not done until the remote says so.** Read the remote back
  before reporting a push complete — `git ls-remote origin <branch>`, or the
  PR's `headRefOid`. A local success message describes what your git thought
  it did, not what the remote holds. Detached HEAD, a stale base, and a
  force-push landing on the wrong ref all report success locally.
- **When two instructions conflict, verify, then take the reversible side.**
  Crossed messages are normal on a fan-out — the lead's view is minutes stale
  by the time an agent reads it. Do not pick the more recent reading and act;
  check what the remote actually contains, then choose the branch of the fork
  that can be undone. Closing a PR is reversible; merging one that deletes
  work is not.

Evidence (2026-07-28 overnight run): four agents, 4.4 hours, **two merged
PRs — both from one agent**. 83% of the window produced zero merged work.
One agent held 25 files uncommitted for hours; one branch contained only the
commit that caused the bug it was meant to fix; one produced nothing. All
three were discovered by inspecting the filesystem, not by any status reply.
The lead then landed the stalled work itself in four minutes.

The same run produced two near-misses where the **remote ended up in a state
nobody intended**: a detached-HEAD push, and a revert PR left open and
mergeable that would have deleted work the lead had just endorsed — its title
read "revert at team lead's direction", so a routine sweep would have merged
it. Neither was visible locally. Both were caught by one question — *what
does the remote actually say?* — and the second was defused by closing rather
than merging, because only one of those two choices can be undone.

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
