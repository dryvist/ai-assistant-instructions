# Architecture Diagrams

## Ecosystem Context

Where `ai-assistant-instructions` fits within the broader JacobPEvans nix-ai system.

```mermaid
graph TD
    AAI["**ai-assistant-instructions**\nUniversal AI config layer\n(AGENTS.md · rules · workflows · permissions)"]

    NixAI["**nix-ai**\nAI tool ecosystem\n(Claude Code · Gemini · MCP servers · Whisper)"]
    NixHome["**nix-home**\nUser dev environment\n(dev tools · shell · git · linters)"]
    NixDarwin["**nix-darwin**\nmacOS system config\n(system packages · LaunchDaemons · security)"]
    NixDevenv["**nix-devenv**\nProject shells\n(per-language toolchains · importable modules)"]

    Plugins["**claude-code-plugins**\nCommands · skills · agents · hooks"]

    PerRepo["**Per-repo CLAUDE.md**\n@AGENTS.md import"]

    AAI -->|"dispatch webhook\n(trigger-nix-update)"| NixAI
    AAI -->|"@AGENTS.md\ncanonical source"| PerRepo
    Plugins -->|"marketplace install\nskills · slash commands"| PerRepo

    NixAI -->|"home.packages"| NixHome
    NixDarwin -->|"system layer"| NixHome
    NixHome -->|"imports"| NixDevenv

    style AAI fill:#d4e6ff,stroke:#4a90d9,color:#000
    style NixAI fill:#d4ffd4,stroke:#4a9d4a,color:#000
    style Plugins fill:#fff3d4,stroke:#d4a017,color:#000
    style PerRepo fill:#f0d4ff,stroke:#9b4ad9,color:#000
```

Source: [`docs/assets/ecosystem.mmd`](assets/ecosystem.mmd)

---

## Repository Architecture

Internal structure of this repository and how the pieces relate.

```mermaid
graph TD
    AGENTS["**AGENTS.md**\nCanonical config source"]
    CLAUDE["CLAUDE.md\n(@AGENTS.md import)"]
    GEMINI["GEMINI.md\n(synced document)"]
    COPILOT[".copilot/instructions.md\n(symlink → AGENTS.md)"]

    Rules["**agentsmd/rules/**\nAuto-loaded every session\n· tool-use · soul · no-scripts\n· secrets-policy · bifrost-routing\n· nix-tool-policy …"]
    Workflows["**agentsmd/workflows/**\n5-step development process\n1 Research → 2 Plan → 3 Define\n4 Implement → 5 Finalize"]
    Permissions["**agentsmd/permissions/**\nTool access control\nallow / ask / deny (JSON)"]

    Docs["**docs/**\nUser-facing guides\n· codex-quick-start\n· troubleshooting\n· github-actions"]
    Assets["**docs/assets/**\nDiagram sources (.mmd)\nSVG rendered on demand"]

    CI[".github/workflows/\nCI validation gates\n· markdownlint · token-limits\n· link-check · CodeQL · release"]

    AGENTS --> CLAUDE
    AGENTS --> GEMINI
    AGENTS --> COPILOT
    AGENTS -->|"auto-loaded"| Rules
    AGENTS -->|"governs"| Workflows
    AGENTS -->|"enforces"| Permissions
    Rules --> CI
    Permissions --> CI
    Docs --> Assets

    style AGENTS fill:#d4e6ff,stroke:#4a90d9,color:#000
    style Rules fill:#d4ffd4,stroke:#4a9d4a,color:#000
    style Workflows fill:#d4ffd4,stroke:#4a9d4a,color:#000
    style Permissions fill:#d4ffd4,stroke:#4a9d4a,color:#000
    style CI fill:#ffd4d4,stroke:#d94a4a,color:#000
```

Source: [`docs/assets/architecture.mmd`](assets/architecture.mmd)

---

## AI Agent Session Lifecycle

Sequence of events from session start through implementation for a Claude Code session.

```mermaid
sequenceDiagram
    actor Dev as Developer
    participant CC as Claude Code
    participant Repo as Per-repo CLAUDE.md
    participant AAI as ai-assistant-instructions
    participant Plugins as claude-code-plugins

    Dev->>CC: Start session
    CC->>Repo: Read CLAUDE.md
    Repo->>AAI: @AGENTS.md import resolves
    AAI-->>CC: Canonical rules + routing loaded
    CC->>AAI: Auto-load agentsmd/rules/
    AAI-->>CC: tool-use, soul, no-scripts, secrets-policy, …
    CC->>Plugins: Load installed skills & hooks
    Plugins-->>CC: PreToolUse / PostToolUse hooks active

    Dev->>CC: /refresh-repo (or other slash command)
    CC->>Plugins: Invoke skill
    Plugins-->>Dev: Result

    Dev->>CC: Implement feature
    CC->>CC: Apply rules (no-scripts, surgical changes, …)
    CC-->>Dev: Code + commit

    Note over CC,AAI: Rules re-read from disk each session — no stale cache
```

Source: [`docs/assets/session-lifecycle.mmd`](assets/session-lifecycle.mmd)

---

To render `.mmd` sources to SVG locally:

```bash
nix run nixpkgs#mermaid-cli -- -i docs/assets/ecosystem.mmd -o docs/assets/ecosystem.svg
```
