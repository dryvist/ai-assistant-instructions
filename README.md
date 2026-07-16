# AI Assistant Instructions

> Teaching AI assistants how to help you better. Yes, it's AI instructions written with AI assistance. We've come full circle.

[![License][license-badge]][license-url]
[![Markdown Lint][markdownlint-badge]][markdownlint-url]
[![pre-commit][precommit-badge]][precommit-url]

## What Is This?

A centralized collection of instructions, workflows, and configurations for AI coding assistants.
Drop these into your projects and get consistent, high-quality AI assistance across Claude, Copilot, and Gemini.

Think of it as a style guide, but for your AI pair programmer.

This repository maintains the generic, plugin-independent pieces:

- The canonical `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` configuration
- The auto-loaded rules in `agentsmd/rules/`
- The default development workflow in `agentsmd/workflows/`
- The CI / validation tooling that keeps all of the above honest

Boundaries between this and the other AI-configuration layers (what lives here
versus what is plugin-delivered or published to the docs site) are documented at
[`docs.jacobpevans.com/ai-development/repo-boundaries`](https://docs.jacobpevans.com/ai-development/repo-boundaries).

## Prerequisites

- **Git 2.30+** (for worktree support)
- **GitHub CLI** (`gh`) 2.0+ (for PR/issue management)
- **(Optional) Python 3.8+** for validation hooks
- **(Optional) Node.js 18+** for markdown linting

## Installation

```bash
# 1. Clone the repo
git clone https://github.com/JacobPEvans/ai-assistant-instructions.git

# 2. Copy AGENTS.md into your project
cp ai-assistant-instructions/AGENTS.md your-project/

#    Optional: copy the auto-loaded rules too
mkdir -p your-project/agentsmd
cp -r ai-assistant-instructions/agentsmd/rules your-project/agentsmd/

# 3. Create vendor symlinks so each AI tool reads the same source
cd your-project
ln -sf AGENTS.md CLAUDE.md
ln -sf AGENTS.md GEMINI.md
```

Or just browse the [documentation](docs/) and cherry-pick what you need.

### Slash commands and skills

This repository ships configuration only — no slash commands, skills, agents, or
hooks. Those are delivered as a separate, installable Claude Code plugin
marketplace. Once the marketplace is added and the plugins are enabled, commands
referenced by the workflow (for example `/refresh-repo`, `/finalize-pr`, `/ship`)
become available alongside the configuration in this repo.

## Usage

Once installed, the AI assistants read `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
automatically at session start, and the auto-loaded rules in `agentsmd/rules/`
are pulled in for every session.

See the [default workflow](#the-default-workflow) below for the expected
development loop, and [AGENTS.md](AGENTS.md) for the full set of rules, routing
decisions, and on-demand standards.

## Directory Structure

```text
.
├── AGENTS.md                  # Canonical configuration (GEMINI.md is a symlink)
├── CLAUDE.md                  # Stub — Nix wiring auto-loads AGENTS.md globally; no re-import
├── agentsmd/
│   ├── rules/                 # Auto-loaded universal and path-scoped rules
│   ├── workflows/             # Default workflow plus full-discipline guidance
│   └── docs/                  # Workflow and integration support docs
├── .copilot/instructions.md   # Symlink → AGENTS.md
├── .gemini/config.yaml        # Gemini-specific config
├── scripts/                   # Validation helpers (token limits, links)
└── .github/workflows/         # CI gates (markdown, spellcheck, link check, CodeQL, release-please)
```

## Supported AI Assistants

| Assistant | Integration | Notes |
| --------- | ----------- | ----- |
| **Claude** | `.claude/` directory | Full command support via Claude Code |
| **GitHub Copilot** | `.github/copilot-instructions.md` + prompts | Works in VS Code, GitHub.com, Visual Studio |
| **Gemini** | `.gemini/` directory | Style guide and config support |

## The Default Workflow

This repo centers on a lightweight autonomous loop:

1. **Research & Explore** - Gather enough context to act correctly
2. **Plan** - Pick the simplest verifiable path
3. **Define Success** - Choose the narrowest useful evidence
4. **Implement & Verify** - Make the smallest correct change and prove it
5. **Finalize** - Report changed files and verification results

Full PRD/test-first discipline remains available on demand for high-risk,
multi-session, compliance-sensitive, cross-owner, or explicitly gated work.
Details live in [`agentsmd/workflows/`](agentsmd/workflows/).

## Core Concepts

The documentation covers:

- **Code Standards** - Consistency across languages
- **Documentation Standards** - AI-friendly markdown
- **Infrastructure Standards** - OpenTofu, Terrakube, and OpenBao patterns
- **DRY Principle** - Why everything symlinks to one place
- **Memory Bank** - Maintaining AI context across sessions
- **Remote Commit Workflow** - Making commits via GitHub API without local clone

Browse [`agentsmd/rules/`](agentsmd/rules/) and [`agentsmd/docs/`](agentsmd/docs/).

## Need Help?

- [Codex Quick Start](docs/codex-quick-start.md) - repo analysis, prompt patterns, and Codex parity backlog
- [Documentation Home](docs/) - Getting started guides and references
- [Issues](https://github.com/JacobPEvans/ai-assistant-instructions/issues) - Report bugs or request features

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the details, though the short version
is: open a PR, don't be a jerk, and I'll probably merge it.

## Security

Found a vulnerability? Please report it responsibly. See [SECURITY.md](SECURITY.md) for details.

## License

[Apache 2.0](LICENSE) - Use it, modify it, just keep the attribution.

[license-badge]: https://img.shields.io/badge/License-Apache_2.0-blue.svg
[license-url]: LICENSE
[markdownlint-badge]: https://github.com/JacobPEvans/ai-assistant-instructions/actions/workflows/markdownlint.yml/badge.svg
[markdownlint-url]: https://github.com/JacobPEvans/ai-assistant-instructions/actions/workflows/markdownlint.yml
[precommit-badge]: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit
[precommit-url]: https://github.com/pre-commit/pre-commit

---

> Part of a [larger ecosystem of ~40 repos](https://docs.jacobpevans.com) — see how it all fits together.
