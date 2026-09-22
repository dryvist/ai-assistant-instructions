---
name: log-platform
description: Read logs from the central log platform, never from a host — index-time bounding, and what a missing/malformed log means.
---

# Read logs from the log platform, never from the host

- Every log read and every monitoring query goes through the central log
  platform. Do not open a shell on a host to run `journalctl`, `tail`, or
  `dmesg` to answer a question about what happened, even when direct access is
  faster and you already hold it.
- **A log you cannot find in the log platform is a finding, not an
  inconvenience.** It means the pipeline dropped it and nobody knew. Missing
  entirely, landing in the wrong index, or present but lacking the field an
  alert matches on all count. Raise it and fix the pipeline the way you would
  any other defect.
- Reading a log on the host is allowed for exactly one purpose: diagnosing the
  ingestion gap itself. The gap still gets fixed. Do not use the host copy to
  answer the original question and move on — that is what leaves the pipeline
  broken for the next reader.
- The point is not the query interface. Routing every investigation through the
  shared pipeline is the only thing that keeps it honest: data nobody reads
  rots, and a host you can still log into hides the rot.
- **Bound the search on index time, not event time.** Event time is whatever
  the platform managed to parse out of the record, and bad timestamp
  extraction is common. An event-time window conflates three different
  situations — never arrived, arrived with a wrong timestamp, arrived late —
  and reports all three as an empty result, so "nothing there" is not
  evidence of absence. Ask by index time first; add event time only once you
  know the source parses correctly.
- **Put the index-time bounds in the BASE search, before the first pipe.**
  They are search terms, not a global option: appended after a pipe they become
  arguments to whatever command is last, and a platform will accept that, return
  success, and hand back nothing. An unbounded search reported as an empty
  result is indistinguishable from "no such events", so this reads as a clean
  answer to a question that was never asked.
- **Timestamps that do not parse are themselves a critical finding.** A source
  whose event time drifts from its index time breaks every time-bounded
  question asked of it: incident windows silently omit it, short-lookback
  alerts can never match it while still appearing to cover it, and
  cross-source ordering comes out false. Raise it, do not work around it by
  widening the window.
