---
name: public-disclosure
description: Public/committed artifacts disclose the minimum.
---

# Public Disclosure

A public, git-committed artifact (file content, commit messages, PR/issue titles/bodies) is published forever:
search-indexed, archived, cross-referenced. A PR description on a public repo is committed text, not a private
note to the reviewer.

**State what, never why or unpublished specifics.** Committed text states what the code does now — never
roadmap, rationale, or hardware/vendor names for a swappable backend. Use a capability-neutral name (a role,
not a make/model) reached by a stable identifier. A tool evaluation the user explicitly asked for is fine —
factual, about the tool, not the surrounding infra.

**Minimum topology disclosure.** Never characterize a private system's topology — hosts, addresses, ports, data
flows, what depends on what — nor gesture at one ("the internal data repo"). The bare product/tool name is fine
where routing/clarity needs it. Topology is as sensitive as a literal secret. Environment-specific identity
goes behind a variable sourced from the runtime secret store — the committed reference is only the variable
name. Avoid naming an individual lower-trust/self-hosted component when a whole-system description suffices.

**Documentation: private source only, never straight to public.** All AI-authored documentation goes to the
private documentation source; an agent never classifies content as public/private and never writes to the
public docs site directly — the publisher projection alone turns private source into a generated public-docs
PR. When a change lands in any repo, update the pages that describe it in the private source in the same
session (its `docs-sync` skill does this). The private source may record sensitive facts; it never carries a
raw live secret, private key, or recovery code — those live only in the secret store.

**Describe scrubs in categories, not mappings.** A sanitization sweep's PR/commit names the **category**
removed ("real hostnames → placeholders"), never the **real-value → placeholder mapping**
("`prod-db-3` → `db-example`") — that re-leaks what was scrubbed. Same for verification: "zero real values
remain" is fine; the grep pattern used is not.
