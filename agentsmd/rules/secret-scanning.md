---
name: secret-scanning
description: Multi-layer gate blocking real homelab sensitive values from public repos. Parameterize via Doppler/SOPS; never hardcode. SENSITIVE_DENYLIST contract.
---

# Secret Scanning

Real homelab-specific values — the real domain, RFC1918 subnets/IPs, Proxmox
node names, ZFS pool names, the AWS account ID, hardware serials, person paths
like `/Users/<name>` — must NEVER land in a public repo. Four enforcement layers
block them before they get committed or merged.

## The 4 layers

| Layer | Where | Catches |
| --- | --- | --- |
| 0 — this rule | Every agent session | Agents parameterize sensitive values up front |
| 1 — PreToolUse hook | `content-guards` plugin, local | Write/Edit/NotebookEdit content before it touches disk |
| 2 — pre-commit | gitleaks + local `sensitive-denylist` hook | Staged files before commit |
| 3 — CI template | `secret-scan.yml` reusable workflow (this repo) | PR's changed files before merge |
| + org | GitHub org custom secret-scanning patterns | Push-protection backstop |

## Two prongs (layers 2 and 3)

- **Structural** — a committed, value-free `.gitleaks.toml`: PEM/SSH key blocks,
  bare 12-digit numbers near `account`/`arn:aws`, RFC1918 literals. Patterns
  only, safe to publish. Test fixtures use the fake `198.18`/`198.19` block.
- **Literal** — `grep -E -f <denylist>` over changed files, catching the exact
  real values. The list is never committed.

## The `SENSITIVE_DENYLIST` contract

- **Format**: newline-separated POSIX-ERE regexes (`grep -E -f` compatible).
  `#` lines are comments; blank lines ignored. One pattern per line.
- **Local source**: the auto-readable automation keychain (same store as
  `GH_PAT_DRYVIST`), service name `SENSITIVE_DENYLIST` — no password prompt.
  The user seeds it; agents must NOT write it.
- **CI source**: the GitHub Actions secret `SENSITIVE_DENYLIST`, written by the
  workflow to a runner-temp file and masked so it never prints in logs.
- **Fail mode**: local hooks fail-OPEN with a stderr warning when the denylist
  is unavailable (fresh clones / external contributors are not blocked); CI
  fails-CLOSED when the secret is empty on a `dryvist/*` repo, and skips
  gracefully on forks where secrets are unavailable. The structural gitleaks
  scan always runs regardless.

## Agent rule

Never hardcode a sensitive value — not in source, not in a test fixture, not in
a "wrong" example, not in a commit or PR body. Parameterize via Doppler (runtime)
or SOPS (committed-encrypted). Build and test against the fake values above.
