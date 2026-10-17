---
name: dependency-automation
description: Org dependency-freshness policy — weekend cadence, auto-merge rules, and where the canonical config lives
---

# Dependency automation

Every enterprise repo inherits ONE Renovate policy from `JacobPEvans/.github`
(`renovate-presets.json` + `renovate-grouping.json`). A repo's Renovate file only extends it:
`{"extends": ["github>JacobPEvans/.github"]}`, or `github>JacobPEvans/.github:renovate-nix` for nix
repos. Do not re-derive or diverge from it per repo.

## The model

| Update | Who opens it | PR cadence | Auto-merge |
| --- | --- | --- | --- |
| Minor / patch / digest | Renovate | Sat/Sun only, 7-day release age | **yes**, after required checks |
| First-party (`JacobPEvans*/**`, `dryvist/**`, `jpe-*/**`) | Renovate | Sat/Sun only, 7-day age | yes, incl. major |
| Third-party major | Renovate | Sat/Sun only, 30-day age | no — review |
| `flake.lock` | Renovate nix `lockFileMaintenance` | Sat/Sun only, one PR per repo | yes |
| Security / CVE | Dependabot security updates | immediate | per the repo's merge rules |

## Rules of thumb

- **Weekdays stay quiet.** No non-security update PR opens Monday–Friday. Security fixes come from
  Dependabot security updates, enabled per repo in `tofu-github`; no `dependabot.yml` exists, and
  Renovate `vulnerabilityAlerts` is off.
- **Native auto-merge.** `platformAutomerge: true`: GitHub merges once required checks pass. There is
  no sweep workflow.
- **One `flake.lock` writer.** Renovate's nix `lockFileMaintenance` relocks the whole flake on
  weekends. No workflow writes another repo's lock file.
- **First-party refs float on major tags.** Actions and reusable workflows from our own orgs use
  `@vN` (for example `@v1`), never a SHA or `@main`; a release moves the tag, so consumers need no
  bump PR. Flake inputs use `?ref=vN`; Ansible collections use a range such as `>=1,<2`.
- **Third-party refs are SHA-pinned** with the exact released version as a trailing comment
  (`uses: actions/checkout@<sha> # v4.2.2`). If the project publishes no immutable version tag,
  pick another action or record an explicit exception. Non-`uses:` pins carry an explicit
  `# renovate:` annotation.
- **Majors never auto-merge except first-party.** A compatible-looking version is not a compatible API.
- **Prefer native Renovate capability over custom scripts/workflows** — debug the config.
- **Renovate PRs target the repo's default branch.** On git-flow repos that is `develop`; never add a
  repo-level `baseBranches` forcing `main`.
- When you change cadence or auto-merge, update `JacobPEvans/.github` `SECURITY.md` and the
  canonical docs page in the same change.
