# Default: Finalize

**Goal:** Leave the worktree understandable, verified, and ready for the user's
next action.

## On Failure

If implementation or verification failed:

1. Do not claim success.
2. Keep the report short and specific: blocker, evidence, and next action.
3. Update a PRD or issue only when one is already part of the task or the work
   must continue across sessions.

## On Success

1. Update docs only when the behavior or public surface changed.
2. Run relevant formatting or lint checks. For Markdown, docs, or instruction
   changes, run `markdownlint-cli2 .` and the repository markdown link checker
   when one exists.
3. Commit, push, or open a pull request when the user requested delivery.
4. Report changed files and verification results without routine narration.
