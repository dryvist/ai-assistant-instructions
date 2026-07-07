# AI Agents Configuration

Canonical agent instructions live in [AGENTS.md](AGENTS.md) and `agentsmd/rules/`.
Nix-managed machines auto-load both globally via
[nix-ai](https://github.com/dryvist/nix-ai), so this file deliberately does not
re-import them — doing so would load every byte twice in each session.
Non-Nix contributors: read `AGENTS.md` once before making changes.
