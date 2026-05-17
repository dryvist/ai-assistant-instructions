---
name: secrets-policy
description: No secrets, person-specific defaults, or private-repo IDs in commits. Cross-repo PUBLIC docs go to docs.jacobpevans.com. Use placeholders for anything tied to one user.
---

# Secrets Policy

Never commit: tokens, credentials, SSH keys, real IPs/hostnames/domains,
AWS account IDs, user-specific paths, or person-specific defaults. Use
placeholders or variables for anything tied to one user — every committed
value should work for any person who clones the repo right now.

Cross-repo PUBLIC documentation lives at
[`docs.jacobpevans.com`](https://docs.jacobpevans.com)
(source: [`github.com/JacobPEvans/docs`](https://github.com/JacobPEvans/docs)).
Per-repo docs stay in the repo's `README.md` and `docs/`. Private repos
never appear there — verify with `gh repo view OWNER/REPO --json visibility`
when in doubt.

Never write a real value even in a "wrong" example — the example becomes
committed text. Use shape stand-ins: `${USER}`, `${REPO_ROOT}`,
`${MAINTAINER_EMAIL}`, `${NAS_HOST}`, `<redacted>`. See `config-secrets.md`
for the canonical scrubbed-value table and runtime injection methods.
