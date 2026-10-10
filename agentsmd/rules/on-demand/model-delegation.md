---
name: model-delegation
description: Offload bounded subtasks to the shared model router at the cheapest capable tier — model names fetched from the router's published contract, budgets enforced at the router, honest reporting instead of silent fallback
---

# Model delegation

ZCode is an opt-in route for public or otherwise non-sensitive batch work and
review. Load `delegate-to-ai` in the `ai-delegation` plugin first. That sole
authored skill owns the allowlist, sensitivity, gate, fallback, and trusted
draft-PR verification rules; Claude Code and Codex consume the same copy. Codex
subscription quota is finite, and `codex-quota` gates every Codex call.

Canonical doctrine: `prompt://dryvist/auto-ai-agent/model-delegation` in the
central prompt catalog. That fragment is the public, vendor-neutral statement
and the shared autonomous base carries a distilled copy, so non-Claude agents
inherit it automatically. This rule applies across agent harnesses.

A delegate may be any agent CLI the operator runs: a Claude subagent, a
`codex exec` run, or a local model through the router, chosen by fit and cost.
Implementation: Codex after `codex-quota`; otherwise `haiku-high`. Lookups and
bulk reads: the router first, then `haiku-high`.

## Fable is a main-session planning model only

No Fable subagents. Orchestrator-only behavior is for marathon coordination
sessions; elsewhere the lead makes small, fully known edits and reviews every
diff.

Intent, architecture, risk, final review, minimal context — delegate
checkable work downward only, lowest capable tier first, keeping the
delegator's existing permissions. The lead still independently reviews
risky architecture, broad prompts, security, or uncertain plans before
merging delegated work. See `premium-agent-orchestration` skill
(`ai-delegation`) for the full orchestrator-vs-single-model decision, and
`subagent-resilience.md` for probe-before-fan-out.

## Brief the delegate

The parent owns every brief. No hook checks it. A delegate starts with a blank context: it has not seen this
conversation, the files you read, the user's preferences, or what already failed. Whatever the brief omits, the
delegate guesses or skips. When that goes wrong, the parent wrote a bad brief. The delegate did not fail.

This matters more with routing. A router or classifier reads the brief to pick the cheapest tier that fits. A thin
brief looks easy, so it buys the weakest executor. A Codex delegate sees nothing but the brief.

Every brief states:

1. **Goal and intent.** What to achieve and why, in one or two sentences. The reason lets the delegate make small
   calls without asking.
2. **Scope.** The repo, absolute paths, and the branch or worktree. Name what it must not touch.
3. **Context it cannot see.** Constraints, patterns to follow (`file:line`), decisions already made, and what
   already failed. Paste the facts. Do not point at the conversation.
4. **Success criterion.** The exact command to run and the result that means done.
5. **Output contract.** The report file path, a line cap for the reply, and the evidence required (command plus
   trimmed output, `file:line`).
6. **Stop conditions.** When to stop and report instead of guessing: a gate, a refusal, an ambiguity, a second
   failure. Add the push deadline from `subagent-resilience.md`.
7. **Difficulty and risk, in plain words.** "Mechanical, one file, low risk" or "needs judgment, touches auth".
   Never a model name. The router chooses the tier.

The test: could a capable contractor with no access to this conversation finish the task from the brief alone? If
not, rewrite the brief before you spawn.

Never write "as discussed", "the bug we found", "same as before", "look into X", or "based on your findings,
implement it". The last one hands off your understanding, which is the part you cannot delegate. Do the
synthesis, then delegate the work.

A bad brief:

> Fix the failing test we found in auth and push it.

A good brief:

> Goal: make `test_refresh_token_expiry` pass without changing its assertions. It blocks the release PR.
> Scope: repo `<owner>/<repo>`, worktree `/abs/path/.worktrees/fix-token-expiry`, branch `fix/token-expiry`. Edit
> only `src/auth/session.py`. Do not touch `tests/` or `pyproject.toml`.
> Context: the failure is a UTC-versus-local comparison at `src/auth/session.py:88`. `utc_now()` already exists in
> `src/util/time.py`. Use it. Do not add a dependency.
> Done when: `pytest tests/auth -q` exits 0 and `git diff --stat` lists only `session.py`.
> Report: write the diff, the command output, and any assumption to `<scratchpad>/report-token.md`. Reply in 10
> lines or fewer.
> Stop and report instead of guessing if another test fails, the fix needs a new dependency, or you need a
> credential. Push the branch within 30 minutes, even unfinished.
> Difficulty: mechanical, one file, low risk.

## Delegate before you spend your own capacity

A bounded subtask does not need the model reasoning about the whole task.
Summaries, classification over a batch, structured extraction, boilerplate
drafting, a first-pass read of unfamiliar code — delegate those to a capable executor;
raw model API calls use the router.

Walk the tiers and stop at the first genuinely capable one:

1. **Locally served models** — no marginal cost, no egress. Default for bulk,
   repetitive, or privacy-sensitive lookups and reads. Local tiers never write code.
2. **Low-cost hosted models** through the router, free-tier endpoints included
   where the material allows it. Lookups and reads.
3. **Subscription-covered capacity exposed as a tool** — another harness made
   callable, where the work is already paid for. Codex is the current example,
   used only after `codex-quota` passes (used_percent below 90, or the window has
   reset). Implementation chunks go here first.
4. **`haiku-high`** — implementation, bulk reads, and mechanical shipping, when
   Codex is unavailable or over quota.
5. **`opus-high`** — architecture and security judgment only, as advisory input.
   The lead decides.
6. **Premium hosted models** — only after a weaker tier was actually tried and
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

Rules name the roster by agent type: `haiku-high` and `opus-high`. Model families
appear only in the agent definition files (`agentsmd/agents/`).

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
this repository holds configuration only. They live in the `ai-delegation`
plugin of the [`claude-code-plugins`](https://github.com/JacobPEvans/claude-code-plugins)
marketplace:

- `delegate-to-ai` — ZCode coding eligibility, job/live commands, and trusted
  draft-PR verification. The eligibility gate and draft-PR verification apply to
  any external executor.
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
