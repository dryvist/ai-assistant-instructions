---
name: git-flow
description: Branching and merge model — develop is the default integration branch, main is production; squash into develop, merge commits only into main; atomic commits; git-flow-next drives branch lifecycle
---

# Git flow

Repos use the git-flow model as implemented by
[git-flow-next](https://github.com/gittower/git-flow-next). The `git flow`
CLI is installed and configured globally (nix-managed `gitflow.*` git config).

## Detect adoption first

Before any branch, PR, or release work, detect the repo's remote default
branch (`gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`
or `git remote show origin`).

- Default branch `develop` → the repo is on git-flow; follow this file.
- Default branch `main` → trunk flow; keep the existing squash-to-main
  process and do **not** create a `develop` branch yourself.
- Never infer adoption from the current local branch name.

## The model

| Branch | Role | Gets changes by |
| --- | --- | --- |
| `main` | Production. Protected; no direct pushes. | **Merge commits only** — squash and rebase into `main` are banned, with no exceptions |
| `develop` | Default integration branch. Protected but direct pushes allowed. | Squash-merged PRs (the default); merge commits where noted below |
| `feature/*` | One change's work | Branched from fresh `develop` |
| `release/*` | Optional final stabilization | Branched from `develop`; merge-committed to `main`; back-merged to `develop` |
| `hotfix/*` | Urgent production fix | Branched from `main`; PR to `main`, merge commit; back-merged to `develop` |

Every merge into `main` produces a release: release-please watches `main`,
opens the release PR against `main`, and tags on merge. The release PR is
merge-committed like every other PR into `main` — it is not a squash
exception. Never merge to `main` without intending a release.

Normal promotion is a merge-commit PR from `develop` to `main`. Use
`release/*` only when final stabilization needs its own branch; then
merge-commit it to `main` and back-merge to `develop` before more feature
work lands.

## Working a change

1. Create or switch to a fresh worktree based on `origin/develop`. Place it at
   the repo's top level as `.worktrees/<name>/` — beside the primary checkout,
   never nested inside it. Pass `git worktree add` an **absolute** destination
   path so the current directory cannot change where it lands, e.g.
   `git worktree add "$(dirname "$(git rev-parse --git-common-dir)")/.worktrees/<name>" origin/develop`.
   A relative `.worktrees/<name>` resolves against your cwd — from inside the
   `main/` checkout it nests as `main/.worktrees/<name>`, which is wrong.
   `git rev-parse --show-toplevel` does not fix this: run from inside `main/`
   it returns `main/`'s own root, not the outer repo root — `--git-common-dir`
   is the anchor that stays stable across every worktree.
   Create `.worktrees/` if absent; keep it gitignored. The repo root checkout
   always stays on the default branch (`develop`, or `main` on trunk repos) —
   never check a feature branch out at the root.
2. Start the feature branch there: `git flow feature start <name>` — pass the
   name WITHOUT the `feature/` prefix (the tool prepends it; passing it twice
   yields `feature/feature/…`). When a GitHub issue exists, include its number
   in the name: `git flow feature start 123-fix-inventory-loader`. Never invent
   an issue number; for issue-less maintenance use a short descriptive slug.
3. Commit **atomically**: one fix, one feature, or one coherent section of
   updates per commit — never a grab-bag. Follow Conventional Commits.
   Reference the issue (`#123`) in the commit or PR; use closing keywords
   (`fixes #123`) when the change closes it.
4. Open the PR against `develop`. **Squash-merge ordinary feature PRs.** Use a
   merge commit into `develop` only when preserving multiple atomic commits
   matters: stacked work, coordinated multi-commit changes, and release or
   hotfix back-merges.
5. Hotfix exception to PR targeting: a `hotfix/*` branch starts from `main`
   and its PR targets `main` (merge commit, never squash); immediately
   back-merge `main` into `develop` afterward.
6. Small direct commits to `develop` are permitted, but prefer a PR for
   anything reviewable.

## CI and automation on git-flow repos

- Required CI runs on `pull_request` targeting `develop` (and `main` for
  promotion PRs) and on `push` to `develop`. Release, tag, and production
  deploy workflows stay on `main`.
- Renovate dependency PRs target `develop` (the default branch). Do not add a
  repo-level `baseBranches` forcing `main`.

## git-flow-next usage

- `git flow feature start <name>` / `git flow release start <version>` /
  `git flow hotfix start <name>` create correctly-based branches.
- `git flow finish` from any topic branch detects the branch type. Prefer
  finishing via the PR flow above; use `finish` only where a PR is overkill
  (e.g. local-only cleanup) and the branch target allows direct pushes.
- Config keys live in git config (`gitflow.branch.*`); do not override them
  per-repo without a recorded reason.
