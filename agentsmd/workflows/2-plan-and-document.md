# Default: Plan

**Goal:** Choose the simplest path that can be verified.

## Rules

- For routine work, keep the plan in working context and proceed.
- Write a PRD only when the user asks for one or the work is high-risk,
  multi-session, compliance-sensitive, or crosses multiple owners.
- Keep plans adaptable. If evidence changes, update the plan and continue.

## Lightweight Plan

1. Define the user-visible outcome.
2. Identify the smallest change surface.
3. Pick the verification command or evidence.
4. Note only material risks or assumptions.

## Full Discipline On Demand

When a PRD is warranted, create `.tmp/prd-<task-name>.md` with objective,
success metrics, requirements, out of scope, implementation plan, and risks.
Use this mode for explicit PRD requests, high-risk or multi-session work,
compliance-sensitive changes, cross-owner coordination, or user-requested review
gates.
