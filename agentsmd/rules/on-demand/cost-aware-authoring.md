---
name: cost-aware-authoring
description: Authoring skills, rules, hooks, agents, or harness settings — the cost/intelligence levers ranked by impact, and the patterns that break the cache.
---

# Cost-aware authoring

Read this before adding or editing a skill, rule, hook, agent definition, or
harness setting. The levers, ranked by impact:

1. **Cache hit rate.** The single biggest lever. A cache write costs ~1.25×
   (5-minute TTL); a cache read costs a fraction of that. Anything that
   forces a fresh write — mid-session effort/model/MCP-server/system-prompt
   changes — pays that cost again for the rest of the session.
2. **Turn count.** Fewer round trips beats a shorter prompt. Batch related
   lookups into one call/subagent rather than one call per item.
3. **Model per task**, measured as cost per completed task, not cost per
   token. A cheap model that misreads something and needs a retry can cost
   more than the expensive model would have.
4. **Effort level.** Start at the lowest effort that's checkable; escalate
   only on a verified failure (see `model-delegation.md`).
5. **Output tokens.** A one-line or schema'd result from a worker beats a
   prose report; ask for `STATUS | ITEM | REASON` or JSON, not a memo.

## Orchestrator vs single model

Use an orchestrator (fan out to subagents/workers) only when the combined
work exceeds one context window, or as insurance against one runaway task in
a large batch of otherwise-routine work. For a single dependent chain, or
anything that fits one context, tune effort on one model instead — an
orchestrator loses accuracy when workers are weaker and the lead still has to
verify their output before merging. Cap fan-out concurrency (4–6 is a
reasonable default); uncapped fan-out multiplies cache writes and tail risk.

## Cache-breakers (avoid mid-session)

Changing any of these mid-session invalidates the cached prefix and forces a
full-price rewrite: effort level, model, which MCP servers are connected, and
anything injected into the system prompt (hook output, tool availability).
Decide these at session start, not partway through.

## Other practices

- **Topic-scoped loading.** A skill that isn't installed for this repo costs
  zero always-on tokens. Prefer per-project/per-topic skill groups over
  globally-enabled plugins for anything not needed in most sessions.
- **Filter in code before it reaches the model.** Route heavy tool output
  (API list calls, log queries) through a thin wrapper that returns
  `jq`-filtered fields, not the raw payload.
- **Worker output is one line or a schema**, never a prose report — a lead
  synthesizing ten one-liners is cheap; a lead synthesizing ten memos is not.
- **Keep startup context small.** Every always-on rule, skill description,
  and injected hook line is resent every turn of every session; put anything
  situational behind `rule-tiers.md` instead.
