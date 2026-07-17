---
name: session-coordination
description: Runtime-neutral protocol for concurrent agent sessions — session identity, claim-before-work, per-resource expiring locks with fencing, and hand-off; enforcement lives server-side, this file is the shared contract
---

# Session Coordination

Many agent sessions run at once, across runtimes. This rule is the one
contract they all follow so they stop colliding. It uses only systems that
already exist (GitHub, the secrets engine's KV store, the IaC platform's
workspace locks). There is no coordination daemon and no global mutex — a
global cross-system lease was tried once and retired for coupling independent
systems; it stays retired. Locks are per-resource, always expire, and can
always be overridden after expiry. Tracking:
dryvist/ai-assistant-instructions#749.

Enforcement lives **server-side** (branch rulesets, merge queues, CAS writes,
workspace-lock 409s). This file makes every runtime a well-behaved client;
it is not itself the safety mechanism.

## Session identity

Every session mints one identity at start and uses it everywhere:

```text
<runtime>-<host>-<8hex>        # example: claude-mbp-03a3a401
```

- `runtime`: `claude`, `codex`, `agy`, `hermes`, or the CLI's short name.
- `host`: short hostname.
- `8hex`: first 8 hex chars of the session/conversation id; if the runtime
  exposes none, generate once: `openssl rand -hex 4`.

Stamp it into branch names, worktree names, lock records, workspace lock
descriptions, and PR bodies. It is how another session (or the user) finds
out who holds what.

## Claim before work (GitHub-native)

Before starting on an issue, bug, or feature:

1. **Look for an existing claim.** An open draft PR or an assigned issue that
   covers the same work is a claim:

   ```bash
   gh pr list --state open --json number,isDraft,headRefName,title,body
   gh issue view <n> --json assignees
   ```

   If claimed, do not duplicate — pick other work, or offer consolidation
   (comment on the PR/issue with your session id and intent; the earliest
   claim wins unless its session is dead).

2. **Claim.** Self-assign the issue (when one exists) and open a **draft PR
   at first commit**, not at completion. The draft PR is the presence signal
   every runtime can read. Put the session id in the PR body.

3. **Release.** Marking the PR ready / merging / closing releases the claim.
   An abandoned claim is steal-able: a draft PR with no new commits and no
   author activity for 24h, or whose session is known dead, may be taken over
   — comment first, then continue on a **new branch** (never push to another
   session's branch).

## One session, one branch

Branches follow `feature/<issue>-<sid8>-<slug>` (see the git-flow rule).
Never check out, commit to, or push another session's branch. This makes
git-level push races structurally impossible; there are no git locks to take.

## Per-resource locks (deploy-adjacent resources only)

Shared mutable resources that git cannot serialize — an inventory group
converge, a shared publish target — take a KV lock in the secrets engine.
Never lock what a native arbiter already owns (the IaC platform queues its
own workspace runs; GitHub queues its own merges).

Lock record, one KV entry per resource at `secret/locks/<domain>/<resource>`:

```json
{
  "holder": "claude-mbp-03a3a401",
  "acquired_at": "2026-07-17T06:40:00Z",
  "expires_at": "2026-07-17T07:10:00Z",
  "fence": 7,
  "note": "converging media inventory group"
}
```

- **Acquire.** First-ever use of a path = create-if-absent:
  `bao kv put -cas=0 secret/locks/<d>/<r> ...`. Once a lock record exists,
  KV-v2 metadata persists across releases, so `cas=0` fails forever after —
  acquire a released or expired lock by reading the record, verifying it is
  released or past `expires_at`, then writing with `-cas=<latest-version>`.
  A CAS failure means someone holds it (or beat you to it) — read the
  record, report holder and expiry, back off with jitter or pick other
  work. Never busy-wait.
- **Renew** (holder only) = `-cas=<current-version>` with a later
  `expires_at`. Renew before expiry for long work; a session that cannot
  renew has lost the lock and MUST stop the protected work.
- **Release** (holder only) = `-cas=<current-version>` writing
  `{"released": true}`. Never delete the version — a deleted version reads
  back as 404, hiding the version number the next acquirer's CAS write
  needs. Always release on clean exit.
- **Steal** — only when `expires_at` is in the past (allow ≥60s clock-skew
  margin): re-read, then write with `-cas=<version-you-read>` and
  `fence: <old fence + 1>`. **Never delete metadata to steal** — a metadata
  delete can destroy a lock someone else just acquired. A failed CAS on steal
  means you lost the race; re-read and re-evaluate.
- **Fencing.** Carry the `fence` value into the protected operation's logs
  and artifacts, so work from a stale holder is detectable after a steal.
- **TTL sizing.** `expires_at` = now + expected work + margin; keep it short
  (minutes, not hours) — crashed sessions are the norm, and expiry is the
  cleanup. Sessions die without releasing; that must never require a human.

## Workspace locks (IaC platform)

The lock action itself is the decision — checking first and planning after is
a race. Plan **and** apply under the lock; put the JSON lock record above in
the lock description. Override only after `expires_at`, after re-reading to
confirm the holder has not changed, using the platform's normal unlock — and
announce it (see notifications). Details live in the infra skills.

## Hand-off and hand-back

To consolidate overlapping work onto one session:

- The yielding session pushes its branch, notes state in the draft PR
  (done / remaining / gotchas), unassigns itself, and comments
  `handing off to <session-id>`.
- The receiving session self-assigns, continues on its **own** branch (based
  on the yielded branch if useful), and closes or supersedes the old draft PR.
- Hand-back is the same protocol in reverse. The PR trail is the transfer
  record; no side channel required.

## Notifications (advisory)

Publish steals, overrides, and hand-offs to the existing ntfy topic `coord`
(`curl -d "<session-id>: stole lock <domain>/<resource> (fence n)" <ntfy>/coord`).
Advisory only — never a gate.

## Promotion follow-through

A develop→main promotion is a three-step contract (see the git-flow rule):
merge, deployment-file move in every consumer (on the consumer's deploy
branch), and a full e2e deployment from that deploy branch that validates
the promotion. For coordination
this matters twice: the promoting session owns all three steps (do not hand
back or report done after the merge alone), and other sessions must treat a
merged-but-undeployed `main` as unvalidated.

## Crash recovery expectations

- Locks: expire on their own; the next contender steals cleanly.
- Claims: draft PRs persist; the 24h-stale rule above unblocks them.
- Worktrees: a dead session's worktree is reaped by the normal sweep once its
  branch's PR is closed/merged — session-id naming ties the two together.
