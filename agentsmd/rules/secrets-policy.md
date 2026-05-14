---
name: secrets-policy
description: Never commit secrets, credentials, or sensitive data — use variable references; keep private repo identifiers out of public docs and READMEs
paths:
  - "**/.env*"
  - "**/*.json"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.toml"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.nix"
  - "**/Makefile"
  - "**/.github/**"
  - "**/docker-compose*"
  - "**/Dockerfile*"
  - "**/*.md"
  - "**/*.mdx"
  - "README*"
  - "docs/**"
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
