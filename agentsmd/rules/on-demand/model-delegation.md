---
name: model-delegation
description: Routing rules for delegated work across Codex, Claude, and the model router
---

# Model delegation

ZCode is the route for public batch work and review once Codex has no quota.
Load `delegation-ladder` in the `jpe-ai-delegation` plugin first. That sole
authored skill owns the allowlist, sensitivity, gate, fallback, and trusted
draft-PR verification rules; Claude Code and Codex consume the same copy. Codex
subscription quota is finite, and `codex-quota` gates every Codex call.

Canonical doctrine: `prompt://dryvist/auto-ai-agent/model-delegation` in the
central prompt catalog. That fragment is the public, vendor-neutral statement
and the shared autonomous base carries a distilled copy, so non-Claude agents
inherit it automatically. This rule applies across agent harnesses.

Before every delegated task — scouting, bulk reads, triage, reviews (including
security and architecture), mechanical shipping, or implementation — run
`codex-quota`. Exit 0 means every usage window is below 95% used: delegate to
Codex on the newest Luna-family model at xhigh, `codex exec -m <newest luna>
-c 'model_reasoning_effort="xhigh"' ...`, in the background. Take the model from
Codex's own model cache (the listed `-luna` slug with the lowest `priority`),
never from memory. Use a read-only sandbox for reads and reviews. Only on exit 1,
use the Claude roster: `haiku-xhigh` for scouting, triage, shipping, and
implementation; `opus-medium` for architecture and security judgment. A named
roster agent bypasses the router, so never name one while `codex-quota` exits 0.
Claude project threads are full sessions, not delegates: see
`claude-projects.md`.

## Fable is a main-session planning model only

No Fable subagents. Orchestrator-only behavior is for marathon coordination
sessions; elsewhere the lead makes small, fully known edits and reviews every
diff.

Intent, architecture, risk, final review, minimal context — delegate
checkable work according to the order above, keeping the delegator's existing
permissions. The lead still independently reviews
risky architecture, broad prompts, security, or uncertain plans before
merging delegated work. See `premium-agent-orchestration` skill
(`ai-delegation`) for the full orchestrator-vs-single-model decision, and
`subagent-resilience.md` for probe-before-fan-out.

## Delegate before you spend your own capacity

A bounded subtask does not need the model reasoning about the whole task.
Summaries, classification over a batch, structured extraction, boilerplate
drafting, and a first-pass read of unfamiliar code can be delegated; follow the
order above. Use the router for raw model API calls.

"Capable" judges the subtask, not the parent task. Do not escalate a whole job
because one step inside it is hard; split the job.

## Never hardcode a model name

Model inventories change far faster than this rule does. Names, aliases,
enabled state — and, where a deployment publishes them, per-model delegation
hints (speed class, quality class, what the entry is good for, its measured
caveats) — live in the router's published contract. Fetch them at call time and
select from what is actually served. The hints exist so that choosing a tier
never requires writing a model name down anywhere. A name you remembered or copied out of
a document is not evidence the router serves it, and a call by an unserved name
fails. Prefer a stable role alias over a concrete model id where one exists:
the alias is the part promised to keep working.

This applies to committed text too. A model id written into a rule, skill, doc
table, or config is a second spelling that will drift from the registry — the
exact duplication this doctrine exists to remove.

Rules name the roster by agent type. Model families appear only in the agent
definition files of the prompt catalog
(`auto-ai-agent/claude-code/agents/`).

## Know which limits bind you and which you must honour yourself

These are different kinds of rule, and confusing them costs money.

**The reachable model set is enforced** by the router against an allowlist you
cannot edit. A rejection there is a **correct answer**: drop to a cheaper tier
or defer, and say which. Never route around it, and never request a broader
credential to get past one — that is the denial-laundering pattern
`delegation-trust.md` forbids, applied to spend.

**Spend is usually NOT enforced.** Metering it per caller needs shared state and
a per-caller credential that a deliberately stateless router may not have. So
assume a stated budget binds you and nothing else: count against it yourself,
report what you have used, and stop when you reach it. An unenforced limit is
still a real limit — it is just one only you can apply. Never read "nothing
stopped me" as permission, and when you do not know whether a cap is enforced,
behave as though it is not.

The standing default is **$1.00 per day** on paid hosted models, tracked by you;
`openrouter-models` carries the procedure. A deployment stating its own figure
overrides it. Never operate without a number — a compliant agent is the only
thing between an account-wide credential and an unbounded bill.

A deployment that does enforce spend will say so. Trust what it states over
this rule, which describes the general case.

Free-tier endpoints frequently log prompt content provider-side. Public or
made-up material only — never secrets, credentials, private infrastructure
detail, or anyone's personal data. Anything that must not leave the estate goes
to a locally served tier or is not delegated at all.

## Router unreachable: report, never fall back silently

Bound every delegated call with an explicit timeout. On DNS failure, refused
connection, `401`, exhausted budget, or a disabled model: report what failed,
then either defer the subtask or continue on your own model as a **stated,
deliberate choice**. Silently absorbing the work back into your own context is
the exact cost the delegation was meant to avoid, and it hides the failure from
whoever pays for it.

Never respond to a router failure by reaching for a direct provider credential.
No agent holds one, and acquiring one to work around an outage replaces a
central budget with an unmetered one.

## Report what you used

Name the model or tier that produced each delegated result. A reader weighing
your output needs to know which parts came from a cheap tier; an operator
tuning spend needs the same information.

## Skills

The procedures this rule refers to are shipped as skills, not carried here —
this repository holds configuration only. They live in the `ai-delegation`
and `jpe-ai-delegation` plugins of the [`claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins)
marketplace:

- `delegate-to-ai` — executor-neutral checks: classify the task, keep sensitive
  content away from third parties, verify the exact result.
- `delegation-ladder` (`jpe-ai-delegation`) — the ladder (Codex, ZCode, OpenCode
  Go, roster), ZCode eligibility, and trusted draft-PR verification.
- `local-subagents` — when a step is worth handing off at all, how to read
  the live model menu (speed, quality, best-for, context, price) from the
  router's own contract, and how to place the call.
- `openrouter-models` — the self-enforced spend budget, the free-tier logging
  caveat, and the lane for requesting a model the router does not serve.

None depends on Claude Code: they use shell commands and available harness tools, so a
non-Claude harness consumes them straight from that repository. **That copy is
the only authored one.** A harness adopting either deletes its local version in
the same change rather than running both — two copies of a skill about spend
and egress will drift on precisely the rules that carry the risk, and whichever
consumer holds the stale one has no way to know.
