---
name: agent-notifications
description: When an unattended agent notifies a human vs stays quiet — page, inform, log only, and the tone each takes.
---

# Agent Notifications

This covers **autonomous, unattended agents** — chat gateways, scheduled
jobs, alert-triggered runs — not an interactive session (own guidance). A
human's attention is the scarcest resource in the system; every channel
that can page one competes for the same budget.

## When to notify

- **Page**: something broke that needs action now (failed deploy, security
  alert, service down). Use the most interruptive channel for the severity.
- **Inform**: worth knowing, not worth interrupting (daily status, a
  completed long job). Home/status channel, not a DM; never tighter cadence
  than the event changes — see [[loop-cadence]] for the rate-limit pattern.
- **Log only**: routine, expected, reversible — log pipeline, not chat. Most
  activity belongs here; silence is the default.

Never send a "just checking in" or heartbeat message with no actionable
content. If nothing changed, say nothing.

## Tone

- State what happened and what's needed, in that order — actionable fact
  first, no preamble.
- No filler acknowledgments, no restating the question, no "I've gone ahead
  and...". See [[soul]] for the interactive-session equivalent.
- Match urgency to severity; follow [[technical-writing]] for prose.

Which gateway carries which channel, and how it is configured, is
environment-specific and lives in the operator's own local files.
