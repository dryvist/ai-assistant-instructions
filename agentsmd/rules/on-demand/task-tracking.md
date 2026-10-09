---
name: task-tracking
description: Where work that is not a pull request gets recorded — side quests, follow-ups, and maintenance windows. Read before deferring work or before disruptive work on a live service.
---

# Task tracking

Vikunja is the task tracker. Every side quest, follow-up, and deferred item
goes there. **Never open a GitHub issue** — GitHub carries pull requests only.

That holds for issues that already exist, not only for new ones. A forge issue
is never the tracker:

- **Migrate an open forge issue** into the task tracker, then close the forge
  issue with a pointer to where the work now lives. Carry over only what is
  safe to leave public; anything operational moves with the task, not with the
  closing comment.
- **Close a bot-generated issue and disable the generator** that filed it. A
  scanner, dependency service, or workflow that opens issues writes into a
  public artifact on a schedule and with no review — turn the issue output off
  and read its findings where the tool reports them.

Refer to Vikunja by project name and project number. Never put its URL or host
in committed text.

## Side quests and follow-ups

Found something worth doing that is not this task? Record it in Vikunja with
enough context for someone else to pick it up, then continue. Do not widen the
current change to cover it, and do not silently drop it.

Keep the entry free of anything that belongs elsewhere: an incident narrative,
a security finding, a credential detail, or internal topology goes to the
incident tracker or the private docs site, not into a task description. "It is
only a side quest" is not an exemption.

Before creating a Vikunja task or Zammad ticket, search the tracker for an open
item on the same work or fault. If one exists, comment on it or link it instead.
A recurrence of a closed fault gets a new ticket that links the prior ones.
Comment on a task once per milestone, never per step, and use bulk-update for multi-task changes.

## Finding the right project

Do not ask which project a task belongs to. Work it out:

1. **List the projects once** and read the descriptions. Each one states the
   domain it owns. Enumerate rather than guess — a project whose name looks
   obvious may be scoped to a single effort.
2. **Route by domain.** A task that clearly belongs to one domain goes to that
   domain's project. Only a task with no owning domain goes to the catch-all
   inbox.
3. **Verify the listing is complete** before concluding a project does not
   exist. Confirm the total count, and check whether the result was paginated
   or truncated.

If working this out was awkward — the listing was noisy, the descriptions were
thin, a project was mis-scoped — fix that in the same pass. Record the routing
you used here or in the operator's local configuration. A lookup that is hard
enough to prompt a question is a documentation defect, not a question.

## Maintenance windows

A maintenance window is shared, agent-visible "hands off this target" state.
Without one, a second session cannot tell that a host is mid-rebuild.

One project, `Maintenance Windows` (project 54). One task equals one window.

| Field | Value |
| --- | --- |
| Title | the affected host or service, as an FQDN — never an IP |
| `dueDate` | when the window ends |
| Label | `maintenance` |
| Description | why the window is open, and who or what opened it |
| Comments | the audit trail |

The contract:

- **Check before you start.** Before any prod change — a converge, a reboot, a
  destroy-and-rebuild, any disruptive infra change — look for an active window
  on that target. One open by someone else means hands off: coordinate, do not
  barge in.
- **An active window is `done == false` AND `due_date` in the future.** Judging
  by `done` alone answers "yes" almost always, because many tasks carry a
  placeholder date and never expire.
- **Open a window before every prod change** (converge, apply, a promotion that
  deploys, a live config edit) and close it after verification.
- **Read-only work and non-prod changes need no window.**
- Cluster bring-up and teardown windows are opened by that cluster's own automation.
- **A window is a lease, and nothing tells you when yours lapses.** An expired
  window still reads `done == false`, so a casual glance says "open" while the
  claim has actually gone. Re-check your own window's `due_date` before you
  continue work inside it, not just when you open it.
- **An empty result is not proof of no window.** Listings paginate, and a
  filter applied client-side narrows only the page already fetched — so a
  window past the first page is invisible to the query that just told you the
  target was free. Run a positive control: confirm a window you know exists
  appears in the result before trusting the absence of any other.

## Scope a window by what it claims

A window is a per-resource claim, not a global mutex. Concurrent windows are
expected — as many as there are sessions — provided none of them overlap.

That only works if each window names **both halves**:

- **Owns** — the exact resources this session may change.
- **Does not own** — the neighbouring resources it explicitly leaves free, so
  another session can claim them without asking.

Where two windows share a host, say so and say whether they conflict on timing
or on safety. A window that names only what it owns forces every other session
to assume the worst and wait.

- **Cross-link an incident by URL**: paste the incident ticket URL into the
  window's description and the window URL back into the ticket. A plain URL
  each way is enough to navigate both directions; no integration is needed.

Credentials, API routes, and the account that may write are environment
specifics. They live in the operator's local configuration, not here.
