# Shared GitHub Workflows

Reusable GitHub Actions workflows for this repository and the broader org.

## Overview

Shared AI reusable workflows are centralized in [ai-workflows]. That repository provides the
canonical reusable workflows for AI-powered CI tasks (PR review, issue triage, doc sync, and
linting) that supersede the former `.github-shared/workflows/` prototype in this repo. Other
org-wide shared workflows (branch protection, CodeQL, etc.) live in [.github].

All AI workflow tasks use `OPENROUTER_API_KEY` rather than `CLAUDE_CODE_OAUTH_TOKEN`. Using
subscription OAuth tokens in unattended CI violates Claude Code ToS.

## Org-Wide Workflows (via ai-workflows)

| Workflow | Purpose |
| -------- | ------- |
| `claude-review.yml` | PR review routed through OpenRouter |
| `issue-triage.yml` | Issue triage via AI models |
| `doc-sync.yml` | PR/documentation sync checks |
| `markdownlint.yml` | Markdown linting (org-wide) |

**Example usage:**

```yaml
name: PR Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    uses: JacobPEvans/ai-workflows/.github/workflows/claude-review.yml@<40-hex-sha> # vX.Y.Z
    secrets: inherit
```

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

[ai-workflows]: https://github.com/JacobPEvans/ai-workflows
[.github]: https://github.com/JacobPEvans/.github
[reusable-workflows]: https://docs.github.com/en/actions/using-workflows/reusing-workflows
[sharing-workflows]: https://docs.github.com/en/actions/administering-github-actions/sharing-workflows-secrets-and-runners-with-your-organization
