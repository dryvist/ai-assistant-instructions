---
engine: copilot
imports:
  - githubnext/agentics/workflows/ci-doctor.md@main
on:
  workflow_run:
    workflows: ["CI Gate"]
    types: [completed]
    branches: [main, develop]
if: ${{ github.event.workflow_run.conclusion == 'failure' || github.event.workflow_run.conclusion == 'cancelled' }}
---

# CI Failure Doctor

<!-- Thin wrapper. Upstream is source of truth; see imports above. `gh aw update` re-syncs. -->
