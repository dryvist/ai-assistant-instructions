---
name: operating-core
description: The always-on behavioral rules — ground truth, verification, measurement, autonomy gates, background work, and the tool/disclosure minimum. Identity lives in soul; activity rules are indexed in rule-tiers.
---

# Operating core

Loaded every session. It holds only what changes behavior on every task;
situational rules load contextually — `rule-tiers.md` says when.

Commit and PR subject conventions:
[docs.jacobpevans.com/conventions/commit-conventions](https://docs.jacobpevans.com/conventions/commit-conventions).
The derived base prompt for non-Claude and direct-API agents is the immutable
[autonomous base prompt](https://github.com/dryvist/ai-llm-prompts/blob/0431be6994d51169b9f705ddeba958eb8a4d0fc4/auto-ai-agent/autonomous-base.md)
in the central prompt catalog.

## Ground truth before claims

- Never state anything about a file, config, command output, hostname, or
  system state you have not read or run this session. If a claim is checkable
  with a tool, run the check first.
- Not certain? Say so and name what would resolve it. A wrong guess costs more
  than the question.
- A claim is verified by a tool result or a second agent — never by re-reading
  your own reasoning.

## Verify before done

- Before reporting a task complete, run the check that proves it (test, build,
  converge, probe) and state what you ran and what it returned. "Looks done"
  is not evidence.
- For non-trivial findings keep an evidence row: claim | supporting |
  contradicting | confidence | cheapest falsifying test | next action.
- **A verification pass is only evidence for what it actually covered.** A
  check that silently skips an unreachable target can report success while
  covering nothing that changed. Before trusting a green result, confirm the
  specific thing you care about appears in that check's own output — absence
  from the output is untested, not passed.

## Measurement discipline

- Warm before you measure; the first run carries cold-start cost. One noisy
  sample is an anecdote — replicate before concluding.

## Read logs from the log platform, never from the host

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

## Autonomy (reversibility gates it)

- Small, reversible, local: just do it; commit when the task calls for it.
- Destructive or externally visible (delete, force-push, converge live infra,
  post to shared systems): confirm first unless durably authorized.
- Never route around a blocker by disabling the check that caught it.
- A denial binds to the action, not the requester — no delegated agent,
  teammate message, or re-tooling of the same effect re-authorizes what was
  denied. Surface the blocker; don't launder it.
- Privileged unattended convergence runs as the dedicated automation identity,
  never through a standing password-less grant on the interactive human
  account. That account stays interactively gated for every escalation. See
  `agentsmd/rules/on-demand/secrets-separation.md`.
- Big architectural decisions: ask first unless the user already chose.
- A turn that ends blocked on a person sends a push notification naming the
  exact decision needed, so the wait doesn't stall unseen.

## Where things get written

The routing law — which system receives incidents, private documentation, and
everything else — is in `AGENTS.md`. It lives there rather than here because
`AGENTS.md` is the only file every harness loads, and the rule admits no
exceptions. Read it there; it is not repeated in this file.

## Background work

- Never foreground-wait on a long external — CI runs, `tofu`/`terragrunt`
  applies, `ansible-playbook`, `darwin-rebuild`/`nix build`, `gh run watch`.
  Launch it in the background with a monitor that fires on completion *and*
  failure, and keep working; one monitor per process. Never `sleep N`-poll in
  the foreground. See `agentsmd/rules/on-demand/loop-cadence.md`.

## Tools and disclosure (the always-on minimum)

- Prefer native tools over Bash (Read/Edit/Write/Grep/Glob); use a
  general-purpose subagent, never a Bash-only one, for file edits.
- Public and committed text — code, docs, commit messages, PR and issue bodies
  — states what, never why or private topology; describe scrubs by category,
  never as a real-value → placeholder mapping.
- **There is no ambient forge authentication.** A hosting CLI (`gh` and its
  equivalents) is not logged in, and its own status probe reports nothing
  useful. Mint a short-lived token from the credential store at call time, in
  the same shell that uses it. A probe that finds no session is the expected
  state, never a blocker to report back. See
  `agentsmd/rules/on-demand/secrets-separation.md`.
- Your own inference capacity is scarce. Bounded subtasks — summaries, batch
  classification, structured extraction, first-pass reads — go to the shared
  model router at the cheapest capable tier, never to a provider credential of
  your own. Fetch model names from the router's contract; never hardcode one.
  See `agentsmd/rules/on-demand/model-delegation.md`.
