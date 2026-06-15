# Default: Implement and Verify

**Goal:** Make the smallest correct change and prove it.

## Rules

- Keep edits surgical and consistent with local style.
- Use structured parsers or project APIs when available.
- If the plan is wrong, revise it in place and continue.
- Delegate isolated implementation only when the result can be reviewed with a
  compact diff and evidence.

## Tasks

1. Implement the smallest viable change.
2. Run the selected verification.
3. If verification fails, diagnose and fix when the fix is in scope.
4. If blocked, report the concrete blocker, evidence, and next required input.
