# Default: Define Success

**Goal:** Know how the work will be proven before making the change.

## Rules

- Use the narrowest verification that proves the requested outcome.
- Prefer existing tests when they already cover the behavior.
- Add or update tests when behavior changes and the risk justifies it.
- Do not wait for approval unless the user asked for gated review or the next
  step is destructive, irreversible, cross-owner, or materially ambiguous.

## Tasks

1. Select evidence: test, lint, typecheck, build, diff review, live check, or
   source citation.
2. Add failing tests first only when that helps expose the behavior clearly.
3. Proceed to implementation once success is concrete.

## Full Discipline On Demand

When full discipline mode is active:

1. Write or update tests before implementation when behavior changes.
2. Verify the new tests fail for the expected reason when that is practical.
3. Keep the plan, tests, and approval gate linked in the pull request when the
   user requested gated review.
