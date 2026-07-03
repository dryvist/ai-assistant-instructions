---
name: dependency-automation
description: Org dependency-freshness policy — trust tiers, auto-merge rules, and where the canonical config lives
paths: ["**/renovate.json*", "**/renovate-presets.json", "**/renovate-grouping.json", "**/.renovaterc*"]
---

# Dependency automation (trust tiers)

Every dryvist/JacobPEvans repo inherits ONE Renovate policy from `dryvist/.github`
(`renovate-presets.json` + `renovate-grouping.json`, the master). Do not re-derive or
diverge from it per repo without a recorded reason. Canonical, fuller docs:
<https://docs.jacobpevans.com/infrastructure/cicd/dependency-automation>.

## The tiers

| Tier | Scope | Cadence | Auto-merge |
| --- | --- | --- | --- |
| First-party | `dryvist/**`, `JacobPEvans*/**` | immediate | all types incl. major |
| Trusted | curated ~50-org allowlist | twice-weekly (Mon/Thu), 3d age | minor/patch only; **major → human review** |
| Untrusted | everything else | weekly, 3d age | AI-gated: `dryvist/ai-workflows` auto-merges only `risk:low` |
| Security/CVE | any vulnerability alert | immediate | auto-merge, overrides every tier |

## Rules of thumb

- **Never ship old versions** unless explicitly documented (rare) — freshness is the default.
- **A trust-list entry auto-merges minor/patch, not majors** — a trusted publisher is not
  proof of a compatible API. Never silently promote an org's majors to auto-merge.
- **Prefer native Renovate capability over custom scripts/workflows** — debug the config,
  don't reimplement it.
- **`platformAutomerge` stays false** (GitHub's merge-queue stalls; Renovate merges via API).
- Trusted GitHub Actions use semver tags; untrusted are SHA-pinned; `dryvist/*` self-refs ride `@main`.
- When you touch trust tiers, auto-merge, or schedules, update `dryvist/.github` `SECURITY.md`
  AND the canonical docs page in the same change — they must not drift.
