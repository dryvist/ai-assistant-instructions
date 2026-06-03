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

## Canonical home: dryvist

**dryvist is the canonical home for everything dryvist uses.** Anything a dryvist
repo consumes — reusable workflows, presets, policies — belongs under `dryvist/*`.
`JacobPEvans-personal/*` may depend on `dryvist/*`; `dryvist/*` must **never** depend
on `JacobPEvans-personal/*`. When a shared workflow is used by dryvist, its home is
`dryvist/.github` (or the relevant `dryvist/*` repo), not the personal account.

Because `uses:` does not follow redirects, reference each workflow by its literal
**current** owner from the table below until a pending relocation actually lands.

| Shared-CI workflow set | Current home | Status |
| --- | --- | --- |
| `ai-workflows` reusable workflows | `dryvist/ai-workflows` | canonical |
| Nix reusable workflows (`_nix-validate.yml`, `_nix-build.yml`) | `dryvist/.github` | canonical |
| Release-please (`_release-please.yml`) | `dryvist/.github` | canonical — org-native (dryvist release App, major-bump block, auto-merge) |
| `_markdown-lint`, `_file-size`, `_osv-scan`, `_ci-gate`, … | `JacobPEvans-personal/.github` | **pending relocation to `dryvist/.github`** |

Nix and release-please were deliberately relocated to `dryvist/.github` (the org owns
its own CI). The remaining non-Nix `.github` workflows are still in
`JacobPEvans-personal/.github` **only until they are moved the same way** — that is a
transitional home, not a permanent one. Repoint consumers via the sweep below as each
moves; do not move any back to the personal account.

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
