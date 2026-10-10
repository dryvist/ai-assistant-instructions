---
name: claude-projects
description: When to run work as a Claude Code project, the hosted cloud thread harness class, the client-repository fence, and the cost and disclosure limits that apply to project threads
---

# Claude Projects

A [Claude Code project](https://code.claude.com/docs/en/claude-projects) is one coordinator conversation that
starts parallel threads. A **cloud thread** runs in an Anthropic-hosted sandbox. A **local thread** runs on the
operator's Mac through Remote Control. Projects are driven from claude.ai, the desktop app or the mobile app,
never from the terminal. Every project pastes [`projects-brief.md`](../../projects-brief.md) as its instructions.

## When to use one

Use a project for a stream of GitHub-only work that spans repositories or sessions: a change rolled out per
repository, a PR fan-out, CI-failure triage, docs-sync after merges. One thread per repository replaces
hand-split claims between peer sessions.

Never use one for work that needs the private network, the secret store, an infrastructure converge or apply,
a privileged gate, or a fenced service. Run that in an interactive local session.

## Harness class: hosted cloud thread

A cloud thread is its own harness class, beside trusted-local sessions and sandbox containers. It is untrusted
in the `secrets-separation.md` sense, because project memory and PR comments reach its prompt:

- **Forge write through the App only.** It pushes and opens PRs through the Claude GitHub App, bounded by the
  App's repository selection and by org branch rulesets on `develop` and `main`. Until those rulesets exist, the
  human **Merge it** is the only merge control. This is the one exception to "no ambient forge authentication"
  in `operating-core.md`.
- **No secret-store access.** It never receives an internal credential or secret-zero value. Cloud environment
  variables never hold a secret. A network secret may hold only a scoped token for an external, public service.
- **No local hooks.** Multi-repository threads run none of the repositories' hooks or permission rules. CI gates
  are the only enforced checks. A public repository whose PRs do not run the disclosure gate is not eligible
  for a project; make the gate a required check once the org rulesets exist.

Detect it with `CLAUDE_CODE_REMOTE=true`.

**Local threads are a restricted class**: repository-local work only, per the brief. They do not inherit the
trusted-local class, even though they run as the operator. The restriction is instruction-only: a local thread
runs in auto mode with the operator's shell, so the brief is not a boundary. Keep Remote Control off except for a
named task, and give each connected checkout `.claude/settings.local.json` deny rules for credential CLIs, `ssh`,
`security` and `sudo`.

## Client-repository fence

The GitHub App's reach is wider than any project's scope, and a thread can add any repository from an owner
the project already uses. Each project's pasted instructions carry the operator's private lists of fenced
owners, repositories and local services. A thread never touches a fenced item and never names one. The
committed brief holds only placeholders; the real lists live in the pasted instructions and the operator's
local files. Text is not a boundary: the structural fix is to keep fenced repositories under an owner that no
project uses and where the App is not installed.

After each batch, review **Project settings > Memory** and delete any entry that conflicts with the brief.

## Coordination

Inside a project, the coordinator owns claims and hand-off: it reuses the thread already working in an area.
Across runtimes, the draft PR at first commit stays the claim, per `session-coordination.md`.

Cloud threads cannot reach the task tracker or the incident system. They end each report with `FOLLOW-UPS` and
`INCIDENTS` lists. A local session files them under the routing law in `AGENTS.md`.

## Models and cost

Threads are full sessions, not subagents. The delegation CLIs and `fast-subagent.sh` are local-only; a cloud
thread reports `local-only, skipped` and continues. Set the thread model below the top tier by default.
Set coordinator effort to high; this is a deliberate exception to the low-effort default.

Usage credits are never enabled. Run at most 4 threads at once; the limit is a preference, so check Overview.
Pause the project to stop all spend at once.

## Disclosure

Project instructions, project memory, routines, environment settings and Library files live on Anthropic
infrastructure. Treat them as committed text under `public-disclosure.md`, with one exception: the pasted fence
list. Never upload `*.local.md` content.

## Remote Control folders

Connect only individual repository checkouts, each with **Worktree** on. Never connect the home directory, the
workspace root, or any folder that holds `*.local.md` files.
