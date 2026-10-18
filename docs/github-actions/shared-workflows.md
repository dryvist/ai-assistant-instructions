# Shared GitHub Workflows

Reusable GitHub Actions workflows for this repository and the broader org.

## Overview

Shared workflows live in two public repositories:

- [`.github`] holds generic CI, release, lint, and Renovate presets.
- [`.github-ai`] holds AI review and agent workflows.

Consumers call shared workflows at the floating `@v1` tag:

```yaml
name: AI Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    uses: JacobPEvans/.github-ai/.github/workflows/ai-review.yml@v1
    secrets: inherit
```

[`.github`]: https://github.com/JacobPEvans/.github
[`.github-ai`]: https://github.com/JacobPEvans/.github-ai

## Local Reusable Workflows

This repo uses several local reusable workflows orchestrated by `ci-gate.yml`:

| Workflow | Purpose |
| -------- | ------- |
| `_cclint.yml` | Claude Code linting |
| `_markdownlint.yml` | Markdown linting (local) |
| `_spellcheck.yml` | Spell checking |
| `_token-limits.yml` | Token limit enforcement |
| `_validate-cclint.yml` | CCLint schema validation |
| `_validate-instructions.yml` | Instruction file validation |
| `_yaml-lint.yml` | YAML linting |

## References

- [GitHub Reusable Workflows][reusable-workflows]
- [Sharing workflows with your organization][sharing-workflows]

[reusable-workflows]: https://docs.github.com/en/actions/using-workflows/reusing-workflows
[sharing-workflows]: https://docs.github.com/en/actions/administering-github-actions/sharing-workflows-secrets-and-runners-with-your-organization
