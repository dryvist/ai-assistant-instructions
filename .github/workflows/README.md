# GitHub Actions Workflows

## Installation

These workflows live in `.github/workflows/` and run automatically — no installation step is required.
Branch protection rules reference the **Merge Gate** check (see below).

```text
# To enable on a fork or new clone:
git clone https://github.com/JacobPEvans/ai-assistant-instructions.git
# (workflows activate on next push to GitHub)
```

## Usage

Workflows trigger on pull-request events and push-to-`main`.
Open a PR to exercise the full CI Gate, or push to `main` to run the push-only wrappers.

## Merge Gatekeeper Pattern

This repository uses the **Merge Gatekeeper Pattern** for CI validation on pull requests.

### Problem Solved

GitHub branch protection only supports "always required" or "not required" status checks.
Path-filtered workflows that don't run result in pending status forever, blocking merges.

### Solution

A single `ci-gate.yml` workflow that:

1. **Always triggers** on ALL PRs (no path filters at workflow level)
2. **Detects** which file categories changed using `dorny/paths-filter`
3. **Calls** reusable workflows conditionally (skipped jobs = success)
4. **Aggregates** results into a single "Merge Gate" check via `re-actors/alls-green`

### Branch Protection Setup

Set **only** "Merge Gate" as the required status check:

```text
Settings → Rules → Rulesets → main
  → Require status checks to pass
  → Add: "Merge Gate"
```

## PR Check Names

These are the check names that appear in GitHub PR status:

| Check Name | Description |
| ---------- | ----------- |
| CI Gate / Detect Changes | Identifies which file categories changed |
| CI Gate / Claude Code Lint | Validates Claude Code configuration |
| CI Gate / Schema Validation | Validates cclint schema/config |
| CI Gate / Markdown Lint | Checks markdown formatting (shared: `dryvist/.github`) |
| CI Gate / Token Limit Check | Enforces token usage limits (shared: `dryvist/.github`) |
| CI Gate / File Size | Enforces file size limits (shared: `dryvist/.github`) |
| CI Gate / Instruction Validation | Validates required instruction files |
| CI Gate / YAML Lint | Validates YAML syntax |
| CI Gate / Merge Gate | Aggregates all check results (REQUIRED) |

## Path Filter Categories

| Category | Files | Triggers |
| -------- | ----- | -------- |
| `claude-config` | `.claude/**`, `CLAUDE.md`, `.cclintrc.jsonc` | Claude Code Lint, Schema Validation, Token Limit Check |
| `agentsmd` | `agentsmd/**` | Claude Code Lint, Instruction Validation, Token Limit Check |
| `markdown` | `**/*.md`, `.markdownlint-cli2.jsonc` | Markdown Lint, Token Limit Check, File Size |
| `yaml` | `**/*.yml`, `**/*.yaml`, `.yamllint.yml` | YAML Lint |
| `workflows` | `.github/workflows/**` | YAML Lint |

## Workflow Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│              LOCAL REUSABLE WORKFLOWS                       │
│         (Implementation - triggered via workflow_call)       │
├─────────────────────────────────────────────────────────────┤
│  _cclint.yml              │ Claude Code Lint                │
│  _validate-cclint.yml     │ Schema Validation               │
│  _validate-instructions.yml │ Instruction Validation        │
│  _yaml-lint.yml           │ YAML Lint                       │
└─────────────────────────────────────────────────────────────┘
              │
┌─────────────────────────────────────────────────────────────┐
│         SHARED REUSABLE WORKFLOWS (dryvist/.github)          │
├─────────────────────────────────────────────────────────────┤
│  _markdown-lint.yml       │ Markdown Lint                   │
│  _token-limits.yml        │ Token Limit Check                │
│  _file-size.yml           │ File Size                       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│      ci-gate.yml        │     │   Push-to-Main Wrappers │
│   (PR orchestrator)     │     │                         │
├─────────────────────────┤     ├─────────────────────────┤
│ • Detects file changes  │     │ cclint.yml              │
│ • Calls reusable flows  │     │ markdownlint.yml        │
│ • Merge Gate aggregates │     │ token-limits.yml        │
│ • ONLY required check   │     │ file-size.yml           │
└─────────────────────────┘     │ validate-cclint-schema  │
                                │ validate-instructions   │
                                │ yaml-lint.yml           │
                                └─────────────────────────┘
```

Markdown Lint, Token Limit Check, and File Size call the shared reusable
workflows in `dryvist/.github` (`_markdown-lint.yml`, `_token-limits.yml`,
`_file-size.yml`) instead of a local implementation, so lint/token/size
policy stays identical across every dryvist repo. Token Limit Check no
longer needs an `ANTHROPIC_API_KEY` secret — the shared workflow counts
tokens with the offline `tiktoken` tokenizer against this repo's own
`.token-limits.yaml`. File Size is new here: with no `.nix`/`.tf` files and
`.token-limits.yaml` already governing every `.md`, it is a no-op today but
activates automatically if either file type is added.

## Adding New Checks

1. Create reusable workflow: `_your-check.yml` with `on: workflow_call`
   (local, or in `dryvist/.github` if other repos will share it)
2. Add filter pattern under `changes.steps.filter.with.filters` in `ci-gate.yml`
3. Add job that calls the reusable workflow with appropriate `if:` condition
4. Add job name to `gate.needs` array and `allowed-skips`
5. Create push-to-main wrapper: `your-check.yml` calling the reusable workflow

## Special Handling

### Renovate Dependency PRs

PRs from `app/renovate` with titles starting with `chore(deps)` skip expensive checks
like `token-limits` to speed up dependency update merges.

### Workflows Not in Merge Gate

These workflows run independently and are not part of the Merge Gate:

- `issue-resolver.yml` - Auto-labels GitHub issues
- `link-check.yml` - Validates links (push to main only)
- `sync-symlinks.yml` - Syncs command symlinks (push to main only)
- `label-sync.yml` - Syncs GitHub labels (push to main only)

## Concurrency Control

The CI Gate uses concurrency groups to cancel in-progress runs when new commits are pushed:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```
