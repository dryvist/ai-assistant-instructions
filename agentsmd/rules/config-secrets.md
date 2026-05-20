---
description: Scrub secrets from config files — use placeholder values, variable references, and secret injection methods
paths:
  - "**/.env*"
  - "**/*.json"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.toml"
  - "**/*.conf"
  - "**/*.cfg"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
---

# Config File Secrets

See `secrets-policy.md` for the broader posture. The canonical cross-repo
PUBLIC narrative — golden laws, per-tool deep dives, cross-tool flow
diagrams, local AI isolation guarantees — lives at:

- [Security overview](https://docs.jacobpevans.com/security/overview)
  — decision tree, which tool for which secret.
- [Golden laws](https://docs.jacobpevans.com/security/golden-laws)
  — the 15 non-negotiable rules. This file is one of their implementations.
- Per-tool deep dives:
  [Doppler](https://docs.jacobpevans.com/security/tools/doppler),
  [macOS Keychain](https://docs.jacobpevans.com/security/tools/macos-keychain),
  [AWS Vault](https://docs.jacobpevans.com/security/tools/aws-vault),
  [SOPS](https://docs.jacobpevans.com/security/tools/sops),
  [Bitwarden](https://docs.jacobpevans.com/security/tools/bitwarden),
  [BWS](https://docs.jacobpevans.com/security/tools/bws),
  [OpenBao](https://docs.jacobpevans.com/security/tools/openbao).

This file is the operational rules layer — load-once, apply-everywhere
agent guidance. Keep both in sync: the docs site explains the *why*,
this file enforces the *how* in code.

## Scrubbed Values

| Type | Scrubbed Value | Examples |
| --- | --- | --- |
| IPv4 Address | `192.168.0.*` | Last octet can be accurate |
| IPv6 Address | `2001:db8::*` | Documentation prefix |
| External Domain | `example.com` | Public services and APIs |
| Internal Domain | `example.local` | LAN hostnames and services |
| API Endpoint | `https://api.example.com:8006/api2/json` | Scrubbed domain pattern |
| Username | `terraform`, `admin`, `user` | Generic role-based names |
| Tokens/Keys | `your-token-here` or `<token>` | Clearly marked placeholder |

## Portable Path References

**NEVER commit absolute user paths** (`/Users/{username}/*`, `/home/{username}/*`, `$HOME/*`, `~/*`).

| Bad (User-Specific) | Good (Portable) | Use Case |
| --- | --- | --- |
| `/Users/john/.local/bin/tool` | `tool` | PATH lookup |
| `entry: /Users/john/.local/bin/ansible-lint` | `entry: ansible-lint` | Pre-commit hooks |
| `~/.ssh/id_rsa` | `# /path/to/your/ssh/key` | Templates |
| `$HOME/git/nix-config/main` | `${NIX_CONFIG_PATH}/main` | Env var for external paths |
| `/home/user/project/file.txt` | `./file.txt` | Relative paths within project |

## Variable References

Always use variable indirection for sensitive values:

```hcl
# CORRECT
provider "proxmox" {
  pm_api_url      = var.proxmox_api_endpoint
  pm_api_token_id = var.proxmox_api_token
}

# WRONG - hardcoded real values
provider "proxmox" {
  pm_api_url      = "https://192.168.0.52:8006/api2/json"
  pm_api_token_id = "terraform@pam!abc123xyz="
}
```

## Runtime Secret Injection

- **AI/Claude Projects**: macOS Keychain (`ai-secrets` keychain), never in files or env vars
- **Doppler**: `doppler run --name-transformer tf-var` for infrastructure
- **SOPS + age**: Encrypt secrets at rest in git
- **Environment Variables**: CI/CD secrets or local .env (never committed)
- **AWS Secrets Manager / Parameter Store**: For AWS deployments
- **SSH Agent**: Agent forwarding only, never commit keys

### macOS Keychain Reuse

**Each keychain read triggers a password approval prompt.** Fetch the secret
once into a shell variable, then inject the variable into every command that
needs it. Never inline `$(security find-generic-password ...)` in each command.

```bash
# WRONG — prompts on every command
TF_VAR_anthropic_key=$(security find-generic-password -s ANTHROPIC_API_KEY -w) terragrunt plan
TF_VAR_anthropic_key=$(security find-generic-password -s ANTHROPIC_API_KEY -w) terragrunt apply

# CORRECT — one prompt, then inject the variable
ANTHROPIC_API_KEY=$(security find-generic-password -s ANTHROPIC_API_KEY -w)
TF_VAR_anthropic_key=$ANTHROPIC_API_KEY terragrunt plan
TF_VAR_anthropic_key=$ANTHROPIC_API_KEY terragrunt apply
```

Applies to any keychain-backed secret and any `security find-*-password` invocation.
