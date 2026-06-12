# Permission System

Tool permissions are **no longer defined in this repo.** The single source of
truth is
[`dryvist/nix-claude-code` → `data/permissions/`](https://github.com/dryvist/nix-claude-code/tree/main/data/permissions):

- `allow.nix` / `ask.nix` / `deny.nix` — tool-agnostic command lists, resolved
  with `Deny > Ask > Allow` precedence (coarse tool-name allows, specific
  dangerous-subcommand asks, narrow denies).
- `domains.nix` — allowed `WebFetch` domains.
- `tool-specific.nix` — per-tool overrides (claude / codex / gemini / copilot).

`nix-ai` reads this via `nix-claude-code.lib.permissions` and its formatters
render the tool-specific output (Claude `Bash(git *)`, Gemini `ShellTool(git)`,
etc.). Nothing in `ai-assistant-instructions` consumes permissions anymore.

## To change a permission

Edit the relevant `.nix` file in `nix-claude-code/data/permissions/` and open a
PR there. The project is also moving toward an **auto-mode classifier**, where
novel commands are governed by intent at runtime rather than by a static
allow-list.

See [`dryvist/ai-assistant-instructions#680`](https://github.com/dryvist/ai-assistant-instructions/issues/680)
for the migration that retired the JSON tree formerly at `agentsmd/permissions/`.
