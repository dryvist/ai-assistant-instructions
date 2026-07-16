---
name: public-disclosure
description: Public/committed artifacts (code, docs, commits, PR and issue titles/bodies) disclose the minimum — state, never rationale; categories, never real-value mappings.
paths: ["**/*.md", "**/*.mdx", "**/*.tf", "**/*.yml", "**/*.yaml"]
---

# Public Disclosure

Everything in a public, git-committed artifact is published forever —
search-indexed, archived, cross-referenced. This applies equally to file
content, commit messages, and PR/issue titles and bodies; a PR description
on a public repo is committed text, not a private note to the reviewer.

## State what, never why or unpublished specifics

Committed text describes what the code currently does. It does not restate
the roadmap, the operational rationale, or specific hardware/vendor names for
a swappable backend. Use capability-neutral names for infrastructure that
might change (e.g. a role name, not a machine's make/model) and reach it by a
stable identifier so the concrete backend behind it can change without a
rename. A tool evaluation the user explicitly asked for is fine — keep it
factual, about the tool, not the surrounding infrastructure.

## Minimum topology disclosure

Never name or characterize a private/internal system in a public artifact —
not even generically ("the internal data repo", "our backend service").
Existence and topology are sensitive at the same tier as literal secrets:
naming what exists and how data flows between systems maps the attack/recon
surface even when no credential leaks. Environment-specific identity (repo
names, hosts, destinations) belongs behind a variable sourced from the
runtime secret store; the committed reference is only the variable name.
Avoid naming an individual lower-trust or self-hosted software component when
a whole-system description of the improvement suffices.

## Describe scrubs in categories, not mappings

When a PR or commit describes a sanitization/scrub sweep, describe the
**category** of value removed ("real internal hostnames → placeholder
values"), never the **real-value → placeholder mapping** ("`prod-db-3` →
`db-example`"). Spelling out the mapping in the PR body re-leaks exactly what
the diff was scrubbing. The same applies to verification language — "a scan
confirms zero real values remain" is fine; pasting the actual grep pattern
used to find them is not, since the pattern itself can encode the real value.
