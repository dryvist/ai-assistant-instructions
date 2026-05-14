---
name: diagramming
description: Maintain inline mermaid diagrams in docs; one diagram per concern; render standalone .mmd sources to SVG via nix-shipped mermaid-cli
paths:
  - "docs/**/*.md"
  - "docs/**/*.mmd"
  - "**/*.mmd"
  - "README*"
  - "SECURITY*"
  - "CONTRIBUTING*"
  - "CODE_OF_CONDUCT*"
  - "ARCHITECTURE*"
---

# Diagramming

Required for any repo with meaningful architecture. Keep in sync with code — stale is worse than none.

- **Format**: inline fenced `mermaid` blocks (GitHub renders natively); standalone `.mmd` sources
  in `docs/assets/`. Render: `nix run nixpkgs#mermaid-cli -- -i x.mmd -o x.svg`.
- **Placement**: conventional docs at repo root (README, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT);
  other docs in `docs/`; diagram sources + SVG in `docs/assets/`.
- **Maintain**: system overview; cross-repo context; one diagram per major data flow
  (don't collapse); sequence diagrams for multi-party flows (auth, API chains, CI);
  component/deployment diagrams for non-trivial topology.
- **Style**: inline mermaid per section; standalone SVG for top-level overviews linked from README.
  One diagram per concern — showing everything shows nothing.
