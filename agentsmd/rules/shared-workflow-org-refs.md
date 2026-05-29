---
name: shared-workflow-org-refs
description: In GitHub Actions uses: clauses, reference shared-CI repos by literal current owner — the don't-rewrite-on-sight redirect rule does NOT apply
paths:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
---

# Shared Workflow Org References

GitHub Actions reusable-workflow and action `uses:` clauses are the one place the
"don't rewrite `JacobPEvans/*` on sight — the redirect holds" rule does NOT apply.

Two hard GitHub constraints:

- `uses:` cannot contain expressions or variables — the owner is always a literal.
  `uses: ${{ vars.X }}/repo/...@ref` is rejected. No org variable can centralize it.
- `uses:` does NOT follow repository transfer/rename redirects (by design). API, git, and the browser DO follow them; Actions does not.

Consequence: when a shared-CI repo changes orgs, every consumer's `uses:` fails at parse time
(the run shows zero jobs and "workflow was not found"). There is no runtime variable that prevents this.

## Canonical homes (reference these literally)

| Shared-CI repo | Current home |
| --- | --- |
| `ai-workflows` reusable workflows | `dryvist/ai-workflows` |
| shared `.github` reusable workflows | `JacobPEvans-personal/.github` |

These two repos are fixed homes — do not move them. Moving either is a breaking change for every consumer in the org.

## Rules

- In `uses:`, always reference the literal current owner above.
- Do NOT replace a reusable-workflow call with a `gh workflow run` / checkout `vars.*` dispatcher
  just to gain a variable: that loses required-check status, inputs/outputs, and `secrets: inherit`.
- gh-aw `{{#import ...}}` references and compiled `*.lock.yml` files resolve at compile time
  via the redirect — leave them to the don't-rewrite rule and gh-aw recompilation.

## If a shared-CI repo must move anyway (sweep)

1. `gh search code 'OLD_OWNER/REPO' --owner dryvist` (and `--owner JacobPEvans-personal`), filtered to `.github/workflows/*.yml`.
2. Per consumer repo: swap only the `uses:` owner segment, preserving path and `@ref`; one PR per repo.
3. Skip `*.lock.yml`, `{{#import}}`, and docs.
4. Token tiers: dryvist repos → DRYVIST; JacobPEvans-personal repos → PRIVATE.
