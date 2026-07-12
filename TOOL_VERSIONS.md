# AI Assistant Instructions - Development Requirements

These are the minimum required tools and versions for using this repository.

## Installing Tools with Nix

All tools below can be installed using Nix:

- **Temporary use**: `nix-shell -p <package-name>` - Creates a temporary shell with the tool available
- **Permanent install**: Add `<package-name>` to your `environment.systemPackages` (NixOS) or
  `home.packages` (home-manager)

For each tool below, the Nix package name links to its official page on the Nix package repository.

## Required Tools

### GitHub CLI

Required for PR management, issue operations, and workflow automation.

- **Minimum version**: 2.0.0
- **Nix package**: [`gh`](https://search.nixos.org/packages?query=gh)
- **Alternative**: `brew install gh`
- **Verify**: `gh --version`

### Git

Required for version control and worktree management.

- **Minimum version**: 2.30.0
- **Nix package**: [`git`](https://search.nixos.org/packages?query=git)
- **Alternative**: `brew install git`
- **Verify**: `git --version`

### jq

Required for JSON parsing and manipulation in shell scripts.

- **Minimum version**: 1.6
- **Nix package**: [`jq`](https://search.nixos.org/packages?query=jq)
- **Alternative**: `brew install jq`
- **Verify**: `jq --version`

## Optional Tools for Development

### Pre-commit

For local hook validation.

- **Minimum version**: 2.20.0
- **Nix package**: [`pre-commit`](https://search.nixos.org/packages?query=pre-commit)
- **Alternative**: `pip install pre-commit`
- **Verify**: `pre-commit --version`

### markdownlint-cli2

For markdown linting validation.

- **Minimum version**: 0.11.0
- **Nix package**: [`markdownlint-cli2`](https://search.nixos.org/packages?query=markdownlint-cli2)
- **Alternative**: `npm install -g markdownlint-cli2`
- **Verify**: `markdownlint-cli2 --version`

### yamllint

For YAML validation.

- **Minimum version**: 1.26.0
- **Nix package**: [`yamllint`](https://search.nixos.org/packages?query=yamllint)
- **Alternative**: `pip install yamllint`
- **Verify**: `yamllint --version`

## Why Nix?

Nix provides reproducible, isolated environments without system pollution. See AGENTS.md for philosophy and permission details.
