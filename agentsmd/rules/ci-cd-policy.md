---
description: CI/CD automation rules — marketplace actions over custom scripts, release-please conventions, action-version pinning
paths:
  - ".github/**"
  - "Makefile"
  - "scripts/**"
  - "hooks/**"
  - "tests/**"
---

# CI/CD Policy

## Prefer Native CI/CD Constructs

| Task | Use This | Not This |
| --- | --- | --- |
| CI/CD automation | Marketplace actions, reusable workflows, composite actions | Custom shell script |
| GitHub Actions logic | Expressions, `fromJSON()`, matrix strategies | Python/bash in step |

## GitHub Releases

Treat published releases as **permanent**.
Once a release is promoted from draft to published, do not modify or delete it — ever.
GitHub technically allows edits and deletions, but our policy forbids it.
If a correction is needed, create a new release rather than changing the existing one.

- Always open releases as **drafts** until fully complete
  (all assets uploaded, notes finalized).
- Promote from draft to published only when everything is ready.
- All repos use [release-please](https://github.com/googleapis/release-please)
  for automated version bumps:
  - **Patch** bumps: `fix:` commits
  - **Minor** bumps: `feat:` commits
  - **Major** bumps: human-initiated only — edit `.release-please-manifest.json` manually.
    Automated major bumps (including from `BREAKING CHANGE:` footers) are blocked
    by the release workflow.
- Conventional-commit style preference:
  - Prefer `fix:` for config tweaks, small improvements, incremental adjustments,
    and dependency updates.
  - Reserve `feat:` for genuinely new capabilities, integrations, or significant
    behavioral changes.
- Templates and reusable workflows live in
  [JacobPEvans/.github](https://github.com/JacobPEvans/.github).

## Dependency Versioning

- **Self-references (JacobPEvans/\*)**: Use `@main` or a major version tag —
  never SHA or minor/patch pins.
- **Trusted external actions**: Use version tags (major like `@v6` or full
  SemVer like `@v2.3.5`).
  Trusted orgs are listed in `JacobPEvans/.github/renovate-presets.json`.
- **Untrusted external actions**: Use SHA commit hashes — only for orgs NOT
  in the trusted list. SHA pinning is the exception, not the default.

## Runner Choice

Linux GitHub Actions jobs in JacobPEvans repos target self-hosted RunsOn
runners deployed by [terraform-runs-on](https://github.com/JacobPEvans/terraform-runs-on).
The control plane is paid for whether or not it's running jobs (~$3.50/mo
fixed App Runner + CloudWatch); workflows that stay on `ubuntu-latest`
spend GitHub Actions minutes that don't need to be spent.

| Workload | Runner |
| --- | --- |
| Linux job (lint, validate, build, test) | RunsOn — `runs-on=${{ github.run_id }}/runner=2cpu-linux-x64` |
| Nix `flake check` (Linux) | RunsOn with more RAM — `runs-on=${{ github.run_id }}/cpu=4/ram=16/family=m7+c7/extras=s3-cache` |
| `macos-latest` | GitHub-hosted — RunsOn EC2 Mac has a 24-hour minimum allocation; for short jobs `macos-latest` is cheaper despite the 10x billing multiplier |
| `windows-latest` | RunsOn — supports Windows; case-by-case |
| `*.lock.yml` from `gh-aw compile` | GitHub-hosted — lock files are regenerated; runner label must flow through the `.md` companion (gh-aw doesn't expose this yet) |
| Disabled-schedule workflow (manual `workflow_dispatch` only) | GitHub-hosted — migration saves nothing |

The leading `runs-on=${{ github.run_id }}` segment is **required** so the
RunsOn control plane can correlate the GitHub Actions `workflow_job`
webhook back to the originating run — without it the job hangs in
`queued`. Reusable workflows in `JacobPEvans/.github` accept a
`runner_label` input (default `ubuntu-latest`); callers opt in by passing
the RunsOn label string.

Full label catalog, prereqs (GitHub App allowlist), rollout playbook,
and verification steps live in
[terraform-runs-on/docs/migration-guide.md](https://github.com/JacobPEvans/terraform-runs-on/blob/main/docs/migration-guide.md).
The `/self-hosted-runners` skill (infra-standards plugin) covers
authoring-time guidance for individual workflow edits.
