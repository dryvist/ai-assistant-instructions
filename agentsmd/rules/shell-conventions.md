---
name: shell-conventions
description: Shell variable naming and bracing conventions — bare $VAR, name intermediates after source or destination only.
---

# Shell Conventions

## Bracing

`$VAR` is the simplest expression and is preferred. Use `${VAR}` only when
the next character would otherwise extend the variable name (a letter,
digit, or underscore) — e.g. `${VAR}suffix`, `${VAR}_backup`. Never brace
reflexively: `$HOME/anything` is correct, `${HOME}/anything` is noise.

## Naming intermediates

When a shell variable is just a pass-through — read from one name, fed to
another — name it after **either** the source or the destination. Never
invent a third name.

```bash
# Bad — CF_ACCT is neither the source name nor the destination name
CF_ACCT=$(security find-generic-password -s CF_ACCOUNT_ID -w …)
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCT

# Good — destination-named, no intermediate
export CLOUDFLARE_ACCOUNT_ID=$(security find-generic-password -s CF_ACCOUNT_ID -w …)

# Also good — source-named, used directly downstream
CF_ACCOUNT_ID=$(security find-generic-password -s CF_ACCOUNT_ID -w …)
some-tool -var "cloudflare_account_id=$CF_ACCOUNT_ID"
```

Triple-naming forces the reader to trace three layers (source name →
intermediate → consumer name) instead of one.
