---
name: loop-cadence
description: Every heartbeat/recurring loop carries a minimum-interval gate backed by an idempotent marker file — a re-fired loop must no-op, never storm
---

# Loop Cadence

Any recurring/heartbeat loop an agent builds (cron prompts, watchdog timers,
`/loop`-style self-wakeups, retry pollers) MUST rate-limit itself with a
minimum interval enforced by a durable marker — not by trusting the scheduler.
During the 2026-07-10 overnight run a heartbeat re-fired rapidly and only an
improvised marker file stopped a probe storm. The gate is now the pattern,
not the improvisation.

## Rules

- **Min-interval gate first.** The first action of every loop body is the
  cadence check; if the last completed run is newer than the minimum interval,
  exit without doing anything (including logging noise).
- **Idempotent marker, durable path.** Store the last-fire timestamp in a
  marker file on storage that survives the process (state dir, `$HOME`,
  ZFS-backed app home) — not in process memory, which a re-spawned loop loses.
- **Write the marker AFTER the work**, so a crashed run doesn't suppress the
  retry; a *storming* scheduler is gated, a *failed* run is not.
- **Pick the interval from the probed system,** not from zero: a poller may
  never fire faster than the watched state can change.

## Snippet (bash, reusable)

```bash
MARKER="${STATE_DIR}/last-fire"          # durable, per-loop
MIN_INTERVAL=300                          # seconds — match the system's cadence
now=$(date +%s); last=$(cat "$MARKER" 2>/dev/null || echo 0)
(( now - last < MIN_INTERVAL )) && exit 0  # re-fire storms no-op here
# ... the actual loop body ...
printf '%s\n' "$now" > "$MARKER"           # only after the work succeeded
```

The same shape applies in any language: read marker → compare → work →
write marker.

## Why

Schedulers double-fire, timers drift, supervisors restart, and an agent
re-entering its own loop is indistinguishable from a fresh tick. Without the
gate, each of those becomes N× the probes, N× the API calls, N× the alerts —
a self-inflicted outage. With it, the worst case is a no-op.
