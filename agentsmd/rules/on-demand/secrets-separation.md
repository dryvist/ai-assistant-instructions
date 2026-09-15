---
name: secrets-separation
description: How credentials are partitioned, scoped, and reached — separate mounts for internet-facing versus internal, engine-minted over static, one bucket per workload, certificate-first access. Read before creating, moving, or consuming any credential.
---

# Secrets separation

## The boundary is the mount, not a path prefix

Two key-value mounts, split by blast radius:

| Mount | Holds | Leak impact |
| --- | --- | --- |
| external | credentials for services reachable from the public internet | critical — exploitable by anyone, anywhere |
| internal | services that exist only inside the network | bounded by network access |

A path prefix gives no policy boundary. A separate mount does.

Keep the sub-path structure **identical** in both mounts; only the top level
differs. Do not invent a second hierarchy for external secrets.

- A credential for anything internet-hosted goes in the external mount. Unsure
  which side something belongs on? Ask — do not guess.
- **Never grant a wildcard across an external path.** Grant the single exact
  path a consumer needs. Wildcards on internal policies are the reason the
  split was needed; do not reproduce the pattern.
- **Prefer a secrets engine over static storage** wherever one exists. An
  engine that mints short-lived credentials removes the rotation problem
  instead of scheduling it.
- **Migrating a secret is not done when it is copied.** It is done when the
  original is deleted, because existing wildcards still reach the old path
  until then.

## Harness identity and trust tiers

Privileged unattended convergence runs as a **dedicated automation identity**
at the operating-system level, distinct from the interactive human account. The
human account stays interactively gated — a biometric or password prompt on
every privilege escalation — and never carries a standing password-less grant
so that an agent can converge under it. An agent that needs to converge asks
for the automation identity, not for the gate to be removed.

Classify every harness by capability, and grant to the class:

| Class | Holds |
| --- | --- |
| trusted | the credentials its declared work needs, minted per call |
| untrusted | read-only leaf access to the secret store, and no forge write credential |

An untrusted harness is one whose prompt, tool set, or output path is not fully
controlled by the operator. Read-only *leaf* access means the exact paths it
consumes — not a subtree, not a list capability over its neighbours.

**The run wrapper supplies secret zero and nothing else.** Whatever bootstraps
a process gives it exactly two things: the address of the central store, and
the login pair of the identity it runs as. Every other value the process needs
resolves from the central store at run time. A second value in the wrapper is a
second store, and it will drift.

**A migration out of the bootstrap store is complete only when both are true:**
a live consumer has been proven to work against the central store, and the
bootstrap copy has been deleted. A copy that still resolves is still the source
of truth for whoever reads it first.

## Object storage: one bucket per workload, two keys per bucket

- **Every large or distinct data store gets its own bucket.** Never separate
  two workloads by key prefix alone — a prefix gives no separate lifecycle
  policy, no separate cap, no separate key, and no blast-radius boundary.
  Backups never share with anything.
- **Exactly two scoped keys per bucket**, named after it: a read-only key
  (list and read) and a read-write key. Consumers take the narrowest one that
  works. A reader must never hold a writer key.
- Account-wide admin keys are break-glass only. Never used by a service, never
  stored where a service can read them.

## Forge credentials: minted per call, never ambient

A code-hosting CLI is **not** authenticated, on any agent harness. Nothing
logs it in at session start, nothing writes a token to disk, and no
environment file exports one. This is deliberate, not a gap to fix.

The failure it causes is one every agent hits the same way: reach for the
CLI's own status probe, read "not logged in", and hand the task back as
blocked. **A probe that finds no session is the expected state.** It is not
evidence that credentials are unavailable, and it is not a reason to stop.

Instead:

- **Mint at call time, in the shell that uses it.** A token minted in one
  command is gone by the next; obtain and use it in a single invocation. Never
  mint at environment-load time — a direnv-style loader caches its dump to
  disk, which persists the credential.
- **Take the narrowest scope.** Read for anything that only reads; a
  repo-scoped write credential only to write, and release its lease when done.
- **Interactive convenience wrappers are shell functions or aliases**, so they
  do not exist in a non-interactive agent shell. Reaching for one and finding
  nothing says nothing about whether credentials work. Use the underlying
  command the operator's local notes name.
- **Tag the mint with an identity that names the agent.** Leases and audit
  entries otherwise record only the login user, which cannot distinguish one
  harness from another or one concurrent session from the next.
- **A minted installation credential has no user identity.** A call that asks
  "who am I" is expected to be refused; use resource-scoped calls instead.

The concrete helper, its variable names, and the endpoints are
environment-specific and live in the operator's own local files — never here,
and never in any committed artifact.

## Access: certificate first, break-glass never casually

Try the rungs in order and never invert them:

1. **The certificate authority.** Mint an ephemeral keypair, get it signed,
   use the certificate, discard both. This is the normal path.
2. **A legacy shared key**, only while its retirement is unfinished. Assume it
   is absent on anything recently rebuilt.
3. **Break-glass admin credential** — last resort, only after 1 and 2 have
   actually been tried and failed. Say so in the write-up when you use it.

**The principal is not the login user.** A signed certificate carries a
principal that may be configured against a different account than the one you
type. A refusal when connecting as the principal's name is *not* evidence the
authority is missing — test as the configured login user before concluding
anything about rollout state.

**Never weaken host verification.** No disabling strict host key checking, no
accept-on-first-use flags, no discarding the known-hosts file. On an estate
where hosts are rebuilt routinely that trades real protection against
interception for convenience. Remove the one stale entry, re-verify that host,
and record why. The real fix is a host certificate authority.

## The failure signature to expect

A helper that exits successfully having exported nothing is the bug — not the
missing secret. It sends the operator looking in the wrong place. A credential
helper must fail loudly when it cannot produce a credential.

If a tool cannot authenticate, the fix is the credential path. Never a local
copy, and never a credential pasted into a file.

**A source-address or network-class refusal is not a broken credential.**
When an identity is bound to a specific network class, a login attempt from
outside that class is refused even though the credential itself is valid.
Do not diagnose this as a dead or misconfigured credential and rotate or
recreate it in response — check which network class the caller is on first.
