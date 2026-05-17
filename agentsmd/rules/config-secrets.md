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

**Each keychain read triggers a password approval prompt.** When a secret is
used across multiple commands in the same session, fetch it once into a transient
shell variable (not exported, not persisted) and reuse the variable. Never inline
`$(security find-generic-password ...)` inside each command — that prompts the
user once per command.

```bash
# WRONG — prompts on every command
curl -H "Authorization: Bearer $(security find-generic-password -s GITHUB_TOKEN -w)" https://api.github.com/user
gh auth login --with-token <<<"$(security find-generic-password -s GITHUB_TOKEN -w)"

# CORRECT — one prompt, then reuse the variable
GITHUB_TOKEN=$(security find-generic-password -s GITHUB_TOKEN -w)
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user
gh auth login --with-token <<<"$GITHUB_TOKEN"
```

The same rule applies to any other keychain-backed secret (`OPENAI_API_KEY`,
`ANTHROPIC_API_KEY`, etc.) and to any `security find-*-password` invocation.
