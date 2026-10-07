---
name: infrastructure-conventions
description: How managed infrastructure is created, changed, and addressed — rebuild over repair, no manual touches, FQDN never a literal IP, named launchd executables. Read before changing any live guest or service.
---

# Infrastructure conventions

## Rebuild over repair

Resilience comes from being cleanly rebuildable, not from guarding things
against deletion.

- **No destroy-protection and no "don't touch" guards.** No `protection = true`,
  no destroy-blocking preconditions. A guard that stops a rebuild is a guard
  that hides the fact that the rebuild no longer works.
- Irreplaceable data lives on a persistent dataset. Configuration management
  reconstructs everything else.
- Prefer rebuild-from-source over snapshot restore. A snapshot restores the
  drift along with the service.

## Never manually touch a live guest

No SSH in and run, no one-off container exec, no hand-edited inventory pointing
at a temporary lease address.

The order is fixed: infrastructure-as-code creates the shell with a
deterministic hardware address, then a fixed address reservation, then the DNS
record, then configuration management converges it by FQDN.

Needing a manual touch is a gap in the automation. Fix the gap; do not perform
the touch and move on. If you do intervene by hand, record the automation gap
before you continue — not later.

## Always FQDN, never a hardcoded IP

In code, in documentation, and in interactive commands. Addresses are derived
from the network segment plus a host identifier, so a literal breaks silently
the moment a host moves segments. The only legitimate address literal is the
DNS record itself.

## Credentials at the least-shared tier

Generate a new credential at the narrowest tier that needs it — random, and
generate-if-absent. Promote it to a shared secret store only once a second
consumer actually exists. A credential seeded "just in case" is a credential
nobody rotates.

Fetch a credential once per session and reuse the variable. Never write it to a
temporary file or a `.env`; hold it in memory.

## Container placement

System containers by default. Reach for a full container runtime only when the
vendor ships that way and nothing else works, for ephemeral CI runners, or for
development and test. Document the exception at the top of the owning
repository's agent instructions.

High-volume network traffic must never traverse a virtualized container
network.

## macOS: named executables, never a generic interpreter

A launchd job's program is a named, single-purpose executable — never `sh`,
`bash`, `zsh`, `env`, `python` or `node`, and never the `command`/`script`
shorthand that renders `/bin/sh -c`. A process that needs a privacy permission
(screen, microphone, AppleEvents, full disk access, calendar) runs as its own
binary, spawned with responsibility disclaimed so the grant is filed under that
binary. Never request, suggest or accept a privacy grant for a shell, terminal
or temp-path client.

## Diagnosing a fast connection failure

A connection that fails in a couple of milliseconds is not an outage. On some
operating systems, local-network access is gated per-application, so a
non-system binary is refused instantly while a system binary reaches the same
host and port. Check the gate before you blame the network, and never route
around it by disabling a validity or freshness check.
