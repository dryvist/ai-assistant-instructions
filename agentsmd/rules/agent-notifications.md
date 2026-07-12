---
name: agent-notifications
description: When and how autonomous agents (Hermes, cron jobs, Splunk alerts) notify a human vs. stay quiet
---

# Agent Notifications

This covers **autonomous, unattended agents** — Hermes' Slack gateway, cron
jobs, Splunk-triggered alerts — not an interactive CLI session like Claude
Code, which already has its own PushNotification guidance in the caller's
CLAUDE.md. The shared rule: a human's attention is the scarcest resource in
the system. Every channel that can page a human competes for the same budget.

## When to notify

- **Page**: something broke that a human must act on now (a failed deploy, a
  security alert, a service down). Use the most interruptive channel
  available for that severity.
- **Inform**: worth knowing, not worth interrupting (a daily status summary,
  a completed long-running job). Post to the home/status channel, not a DM,
  and never at a cadence tighter than the underlying event changes — see
  [[loop-cadence]] for the rate-limit pattern this implies for any recurring
  check.
- **Log only**: routine, expected, reversible. Goes to Splunk/logs, not
  Slack. Most agent activity belongs here — silence is the default, not the
  exception.

Never send a "just checking in" or heartbeat message with no actionable
content. If nothing changed, say nothing.

## Tone

- State what happened and what's needed, in that order. Lead with the
  actionable fact, not the preamble.
- No filler acknowledgments, no restating the question back, no "I've gone
  ahead and...". See [[soul]] for the same standard applied to interactive
  sessions.
- Match urgency to severity — don't dress up a routine notice in alarming
  language, and don't bury a real page in a wall of context. Follow
  [[technical-writing]] for prose in the notification body itself.

## Cross-references

- [[soul]] — voice and autonomy for interactive (Claude Code) sessions;
  this file is the equivalent for unattended agents.
- [[loop-cadence]] — the durable-marker pattern any recurring notifier must
  use so a re-fired loop doesn't turn into a notification storm.
- Splunk-to-Slack alerting implementation (Slack App Alert Integration TA,
  Splunkbase 5735) lives in `dryvist/ansible-splunk`; Hermes' own Slack
  gateway lives in `dryvist/ansible-proxmox-apps`. Architecture overview:
  [docs.jacobpevans.com](https://docs.jacobpevans.com).
