---
name: terraform-checks-placement
description: Static checks in pre-commit; cloud actions in CI via OIDC; aws-vault never appears in repo automation
paths:
  - "**/terraform-*/**"
  - "**/tf-*/**"
  - "**/tofu-*/**"
  - "**/.pre-commit-config.yaml"
  - "**/.pre-commit-config.yml"
  - "**/.github/workflows/*.yml"
  - "**/.github/workflows/*.yaml"
---

# Terraform Check Placement

**One rule to remember:** Static checks belong in pre-commit (and mirrored in CI). Credential-requiring
operations belong in CI only, via OIDC. `aws-vault` never appears in hooks, workflows, Makefiles, or scripts.

## Canonical Pattern

| Check | Pre-commit (local + CI mirror) | CI only (OIDC) | Never |
| --- | --- | --- | --- |
| `terraform fmt -check` | yes | mirrored | — |
| `terraform validate` (with `init -backend=false`) | yes | mirrored | — |
| `tflint` | yes | mirrored | — |
| `terraform_docs` | yes | mirrored | — |
| `gitleaks` / `detect-private-key` | yes | mirrored | — |
| Generic hygiene (whitespace, EOL, YAML, large files) | yes | mirrored | — |
| `terraform plan` | — | yes (OIDC, post via tfcmt) | aws-vault wrap |
| `terraform apply` | — | yes (OIDC, gated env) | aws-vault wrap |
| `trivy` / `checkov` (security) | optional | dedicated job | aws-vault wrap |
| `terragrunt validate` / `terragrunt plan` | — (delete the hook) | yes (OIDC) | as a hook |

## Hard Rules

**No credentials in hooks, ever.**
`aws-vault`, `doppler`, AWS SDK calls, and anything requiring a keychain or injected secret are forbidden
in: `entry:` fields, `args:`, Makefile targets, `justfile` recipes, and scripts called from any of these.
Pre-commit must run from a fresh checkout with no `AWS_*` env vars set.

**`terraform validate` runs with `init -backend=false`.**
No backend creds, no provider creds needed. This is how `hashicorp/terraform-provider-aws` and
`opentofu/opentofu` run their own pre-commit hooks.

**Delete `terragrunt-validate` and `terragrunt-plan` hooks entirely.**
Do not retain them under `stages: [manual]`. If a developer wants to run `terragrunt plan` locally,
they invoke it from the dev shell outside pre-commit. Matches gruntwork-io/terragrunt practice (zero
credentialed hooks).

**No `stages: [manual]` for static checks.**
If a hook is too slow to run on every commit, fix the hook (add caching, scope to changed files).
Hiding it behind `stages: [manual]` is equivalent to deleting it.

**CI auth = OIDC exclusively.**
Every job that needs AWS access must use `permissions: id-token: write` and
`aws-actions/configure-aws-credentials@v4` with `role-to-assume`. No long-lived
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in repo secrets.

**No `continue-on-error: true` on format or validation steps.**
Letting a broken fmt check silently pass defeats the purpose of the check.

**`aws-vault` is allowed only in:**

- README / docs (user-facing examples of how to run things manually)
- `.nix` files under `nix-darwin`, `nix-home`, `nix-ai`, `nix-devenv` (aliases, package inputs)
- `agentsmd/permissions/allow/core.json` (agent runtime permission — not embedded automation)

## Sensitivity: Public CI Output

GitHub Actions logs and PR comments are world-readable for public repos. Apply these controls
to every workflow that handles real credentials or plan output:

**`terraform plan` output is sensitive.** It can reveal: AWS account IDs, ARNs, internal IPv4/IPv6
ranges, internal hostnames, resource names, security-group rules, S3 bucket names, IAM principals,
EC2 AMI IDs, Proxmox node names, VM/container counts. Do not stream raw `tofu plan -no-color` to a
`run:` step without masking. Use `tfcmt --patch` (compact diff mode) when posting to PRs; gate
comments to `pull_request` from same-repo branches only — never from public forks.

**Mask before logging, not after.** The first step of every job that handles real creds must
`::add-mask::` the AWS account ID and any environment-derived domain/IP prefix. Read the account ID
from `aws sts get-caller-identity` and pipe through `::add-mask::` *before* any other step runs.

**No `TF_LOG=DEBUG` or `TF_LOG=TRACE` in CI.** Those leak provider request/response bodies (tokens,
signed URLs, full request payloads). Set `TF_LOG=ERROR` or leave unset.

**No `set -x` or `set -o xtrace`.** Bash trace mode echoes every command including variable
expansions — masking only fires on stdout content, not the command line itself.

**No `terraform show -json` artifact uploads.** Plan binary files (`tfplan`) contain resolved variable
values including `sensitive = true` strings. Default position: don't upload plan files; re-plan in the
apply job.

**`pull_request_target` is forbidden for terraform jobs.** Use `pull_request` (same-repo branches
only) or `workflow_run` for fork-PR plans with the output written to a downloadable artifact.

**trivy/checkov SARIF uploads are safe** (rule violations only), but their stdout is not — apply the
same masking.

## Audit Grep

Run before opening any PR that touches hooks, workflows, Makefiles, or scripts:

```bash
git grep -nE 'aws-vault' -- ':!*.md' ':!*.nix' ':!docs/**' ':!CLAUDE.md' ':!AGENTS.md'
```

Expected output in any non-Nix repo: empty. Any match is a violation.

## Industry Evidence

These patterns are adopted by every major Terraform ecosystem project:

- [terraform-aws-modules/terraform-aws-vpc: `.pre-commit-config.yaml`](https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/.pre-commit-config.yaml)
  — `fmt`/`validate`/`tflint`/`docs` on every commit, zero credentials.
- [antonbabenko/pre-commit-terraform README](https://github.com/antonbabenko/pre-commit-terraform#readme)
  — all static hooks use `init -backend=false`; plan/apply hooks explicitly documented as "not recommended in pre-commit."
- [hashicorp/setup-terraform README](https://github.com/hashicorp/setup-terraform#readme)
  — OIDC is the documented path for CI; no `aws-vault` anywhere in the action.
- [gruntwork-io/terragrunt](https://github.com/gruntwork-io/terragrunt) — zero credentialed hooks in any example.

## Anti-Patterns (What to Refuse)

These patterns are violations of this rule, regardless of how they are framed:

```yaml
# WRONG: aws-vault in a hook entry
- id: terragrunt-validate
  name: terragrunt validate
  entry: aws-vault exec tf-proxmox -- doppler run -- terragrunt validate
```

```yaml
# WRONG: hiding a static check behind stages: [manual]
- id: terraform_fmt
  stages: [manual]
```

```yaml
# WRONG: nix develop round-trip per commit
- id: tofu-test
  entry: nix develop github:JacobPEvans/nix-devenv?dir=shells/terraform --command bash -c "tofu test"
```

```yaml
# WRONG: long-lived access keys in CI
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
```

```yaml
# WRONG: silencing a critical check
- run: tofu fmt -check
  continue-on-error: true
```

Direnv already activates the Nix dev shell on `cd` — no `nix develop` wrapper needed inside hooks.
