---
name: model-delegation
description: Offload bounded subtasks to the shared model router at the cheapest capable tier — model names fetched from the router's published contract, budgets enforced at the router, honest reporting instead of silent fallback
---

# Model delegation

Canonical doctrine: `prompt://dryvist/auto-ai-agent/model-delegation` in the
central prompt catalog. That fragment is the public, vendor-neutral statement
and the shared autonomous base carries a distilled copy, so non-Claude agents
inherit it automatically. This rule is the Claude-session view of the same
doctrine plus the local plumbing.

## Fable and Sol are pure orchestrators

Intent, architecture, risk, final review, minimal context — delegate
checkable work downward only, lowest capable tier first, keeping the
delegator's existing permissions. The lead still independently reviews
risky architecture, broad prompts, security, or uncertain plans before
merging delegated work. See `premium-agent-orchestration` skill
(`ai-delegation`) for the full orchestrator-vs-single-model decision, and
`subagent-resilience.md` for probe-before-fan-out.

## Delegate before you spend your own capacity

A bounded subtask does not need the model reasoning about the whole task.
Summaries, classification over a batch, structured extraction, boilerplate
drafting, a first-pass read of unfamiliar code — send those to the router.

Walk the tiers and stop at the first genuinely capable one:

1. **Locally served models** — no marginal cost, no egress. Default for bulk,
   repetitive, or privacy-sensitive work.
2. **Low-cost hosted models** through the router, free-tier endpoints included
   where the material allows it.
3. **Subscription-covered capacity exposed as a tool** — another harness made
   callable, where the work is already paid for.
4. **Premium hosted models** — only after a weaker tier was actually tried and
   demonstrably fell short.

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
synthetic material only — never secrets, credentials, private infrastructure
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
this repository holds configuration only. Both live in the `ai-delegation`
plugin of the [`claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins)
marketplace:

- `local-subagents` — when a step is worth handing off at all, how to read
  the live model menu (speed, quality, best-for, context, price) from the
  router's own contract, and how to place the call.
- `openrouter-models` — the self-enforced spend budget, the free-tier logging
  caveat, and the lane for requesting a model the router does not serve.

Neither depends on Claude Code: both use only shell, `curl`, and `jq`, so a
non-Claude harness consumes them straight from that repository. **That copy is
the only authored one.** A harness adopting either deletes its local version in
the same change rather than running both — two copies of a skill about spend
and egress will drift on precisely the rules that carry the risk, and whichever
consumer holds the stale one has no way to know.
