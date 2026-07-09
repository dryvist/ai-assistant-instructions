# Dependency automation (trust tiers)

Every dryvist/JacobPEvans repo inherits ONE Renovate policy from `dryvist/.github`
(`renovate-presets.json` + `renovate-grouping.json`, the master). Do not re-derive or
diverge from it per repo without a recorded reason. Canonical, fuller docs:
<https://docs.jacobpevans.com/infrastructure/cicd/dependency-automation>.

## The model

**Minor/patch updates auto-merge publisher-agnostically** — any package, any ecosystem,
any publisher — after a 3-day stabilization + green CI. **Trust tiers gate ONLY majors and
PR-creation cadence, never minor/patch.**

| Update | Scope | PR cadence | Auto-merge |
| --- | --- | --- | --- |
| Minor / patch | ANY package, ANY ecosystem | twice-weekly (Mon/Thu), 3d age | **yes** — publisher-agnostic, after green CI |
| First-party (any type) | `dryvist/**`, `JacobPEvans*/**` | immediate | yes, incl. major |
| Trusted-org major | curated ~50-org allowlist | twice-weekly (Mon/Thu), 3d age | no — 3-day review PR (`dep:review`) |
| Other major | everything else | weekly, 30d age | no — 30-day hold, review |
| Security / CVE | any vulnerability alert | immediate (0-day PR) | minor/patch: yes; **major: review** |

## Rules of thumb

- **Never ship old versions** — freshness is the default; a stale pin is drift to eliminate.
- **Minor/patch is publisher-agnostic** — a non-major SemVer bump + green CI (the Merge Gate,
  plus the deterministic `dependency-review` supply-chain scan on public repos) is sufficient;
  trust is not required to auto-merge minor/patch.
- **Majors never auto-merge except first-party** — a compatible-looking version is not a
  compatible API. Trusted-org majors get a 3-day review PR; all others a 30-day hold.
- **Security majors open for review** — `vulnerabilityAlerts` surfaces a 0-day PR, but a
  security *major* is still reviewed (only non-major security auto-merges fast).
- **Supply-chain safety = the deterministic `dependency-review` native-gate** inside the
  (non-AI) Merge Gate; the AI dependency review (`dryvist/ai-workflows`) is **advisory only**,
  under the separate **AI Merge Gate**. The two gates are always distinct and both required.
- **Prefer native Renovate capability over custom scripts/workflows** — debug the config.
- **`platformAutomerge` stays false** (GitHub's merge-queue stalls; Renovate merges via API).
- Trusted GitHub Actions use semver tags; untrusted are SHA-pinned; `dryvist/*` self-refs ride `@main`.
- When you touch trust tiers, auto-merge, or schedules, update `dryvist/.github` `SECURITY.md`
  AND the canonical docs page in the same change — they must not drift.
