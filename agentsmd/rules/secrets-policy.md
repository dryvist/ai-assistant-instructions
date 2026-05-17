---
name: secrets-policy
description: Never commit secrets, person-specific defaults, or private-repo identifiers. Cross-repo PUBLIC documentation goes to docs.jacobpevans.com (source github.com/JacobPEvans/docs). Placeholders and variables EVERYWHERE — treat every repo as if any person will clone and use it right now.
---

# Secrets Policy

**CRITICAL**: Never commit sensitive data to git.
All git-committed files must use scrubbed values and variable references.

## What NOT to Commit

- API tokens, credentials, passwords
- Real IP addresses (internal or external)
- Real domain names or hostnames
- SSH private keys or certificates
- Database credentials
- AWS account IDs, ARNs, or API keys
- Encryption keys or secrets
- User-specific absolute paths

## Public vs Private Repository Separation

Never reference private repos (names, features, tools) in public repo content.
If a repo is private, treat it as if it doesn't exist when writing public-facing
docs, sites, or READMEs.
This includes repo names, project descriptions, architecture diagrams, and any
identifying details.

When updating public-facing content (GitHub Pages sites, public READMEs,
portfolios), audit for any mentions of private repositories before committing.
Use `gh repo view OWNER/REPO` to check visibility when in doubt.

**Cross-repo PUBLIC documentation lives at
[`docs.jacobpevans.com`](https://docs.jacobpevans.com)**
(source: [`github.com/JacobPEvans/docs`](https://github.com/JacobPEvans/docs)).
Per-repo install / usage / API docs stay in the repo's own `README.md` and
`docs/`. Portfolio-level, architectural, or cross-repo content goes on the
docs site. Private repo content never reaches the docs site — if
`gh repo view OWNER/REPO --json visibility` returns `PRIVATE`, treat the repo
as if it does not exist when writing for the docs site.

## Portable Defaults — Treat Every Repo as Anyone's

Every committed value should work for any person who clones the repo right
now. If a value names a person, a household network, a personal path, or a
one-off number, replace it with a placeholder, variable, or scrubbed
equivalent.

**Placeholders and variables EVERYWHERE possible. No hard-coded values.
No magic numbers. No person-specific defaults.**

| Person-specific shape (wrong) | Portable (right) |
| --- | --- |
| `username: <real-handle>` | `username: ${USER}` or `username: admin` |
| `path: /Users/<name>/git/foo` | `path: ${REPO_ROOT}` or relative path |
| `host: nas.<name>.local` | `host: ${NAS_HOST}` or `host: nas.example.local` |
| `email: <name>@<provider>.com` | `email: ${MAINTAINER_EMAIL}` |
| `api_token: "pat_<redacted>"` | `api_token: var.api_token` (Keychain / SOPS / env) |
| `timeout = 47` (no rationale) | `timeout = DEFAULT_TIMEOUT_SECONDS` (named constant with documented default) |

**Never write the real value even as a "wrong example."** The example
itself becomes committed text — use shape stand-ins (`<name>`,
`<real-handle>`, `<redacted>`) so the table teaches the pattern without
leaking the value.

Magic numbers: any literal that needs a comment to explain it should be a
named constant or variable. See [`config-secrets.md`](config-secrets.md) for
the canonical scrubbed-value table and runtime injection methods.
