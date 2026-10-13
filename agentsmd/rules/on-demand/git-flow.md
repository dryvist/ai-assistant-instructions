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
| `develop` | Default integration branch. Protected; no direct pushes. | Squash-merged PRs, including the release PR; a merge commit only for a PR from a hotfix branch |
| `feature/*` | One change's work | Branched from fresh `develop` |
| `hotfix/*` | Urgent production fix | Branched from `main`; PR to `main`, merge commit; then a PR from the hotfix branch (never `main`) to `develop`, merge commit |

`main` is never merged back into `develop`. Stabilization fixes land on `develop` through
ordinary PRs.

release-please keeps one release PR open against `develop` with the version bump, CHANGELOG and
release notes; every release PR auto-merges when its checks pass. The PR that opened the work owns the
release: confirm the release PR merged (merge it only if green and open), confirm `develop`'s head
checks are green, then promote. Later commits take the next version. The push to
`main` tags and releases that commit, already on `main`. Never merge to
`main` without intending a release.

Promotion is a merge-commit PR from `develop` to `main`. While a promotion PR is open,
nothing else merges into `develop` (the `release-freeze` status enforces it).

### Promotion is not done at the merge

Merging the promotion PR is step one of two. A promotion to `main` is
complete only when:

1. **The merge lands** (merge commit; release-please then tags the release commit).
2. **The deployment file moves.** Any consumer that pins this repo (a flake
   input in another repo's `flake.lock`, an inventory pin, a version file)
   must pick up the promoted rev through a bump PR on the consumer's own
   **deploy branch** — not just its default branch. A dispatch workflow
   (e.g. `dispatch-flake-consumers`) notifies the consumer, which opens that
   bump PR. Verify the dispatch fired AND the bump PR merged: patch bumps
   auto-merge after the Merge Gate; a person merges minor and major bumps.
   If the consumer is itself git-flow, its own develop→main promotion is part
   of this chain.

Report a promotion as complete only with both done.

## Working a change

Before starting a change, check how far `develop` is ahead of `main`. Run
`git fetch origin`, then `git rev-list --count origin/main..origin/develop`. If the
number is 25 or more, do not start a new PR: promote `develop` to `main` first (or run
`/refresh-repo`). Start the change only when the number is below 25. `main` carries
only promotion merge commits that `develop` lacks, so its side of the count is not a
signal. This check applies to git-flow repos only; a trunk repo has no `develop`.

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
   yields `feature/feature/…`). Branch names carry the session id (see the
   session-coordination rule): `<issue>-<sid8>-<slug>`, e.g.
   `git flow feature start 123-03a3a401-fix-inventory-loader`, and the
   worktree dir matches the name. This makes branch and worktree names unique
   per session — two sessions can never collide on either. Never invent an
   issue number; for issue-less maintenance drop that segment
   (`<sid8>-<slug>`). **One session, one branch**: never commit to or push
   another session's branch.
3. Commit **atomically**: one fix, one feature, or one coherent section of
   updates per commit — never a grab-bag. Follow Conventional Commits.
   Reference the issue (`#123`) in the commit or PR; use closing keywords
   (`fixes #123`) when the change closes it.
4. Open the PR against `develop`. **Squash-merge ordinary feature PRs.** Use a
   merge commit into `develop` only when preserving multiple atomic commits
   matters: stacked work, coordinated multi-commit changes, and hotfix
   branches.
5. Hotfix exception to PR targeting: a `hotfix/*` branch starts from `main`
   and its PR targets `main` (merge commit, never squash); afterward open a
   PR from the hotfix branch (not `main`) to `develop` and merge it with a
   merge commit.
6. **Every change to `develop` goes through a PR** — the org ruleset enforces
   it, so a direct push is rejected (`GH013: Repository rule violations`).
   Never plan a "quick direct commit" to `develop`; branch and open a PR.
7. **Merging**: `gh pr merge <n> --squash` is rejected with "the base branch
   policy prohibits the merge" while required checks are still settling. Use
   `gh pr merge <n> --squash --auto` — it merges as soon as the policy is
   satisfied. The same applies to `--merge` on promotion PRs.

## Bot-owned files in rebases and merges

release-please owns `CHANGELOG.md` and its manifest files. When a rebase or
merge onto `develop` conflicts on a bot-owned file, always take the incoming
`develop` side (`git checkout --theirs <file>` during rebase) — never
hand-merge bot content, and never add a `merge=ours` gitattribute for it
(that silently discards release history). Squash your own commits into one
before rebasing across bot commits to cut the conflict surface.

## CI and automation on git-flow repos

- Required CI runs on `pull_request` targeting `develop` (and `main` for
  promotion PRs) and on `push` to `develop`. Release, tag, and production
  deploy workflows stay on `main`.
- Renovate dependency PRs target `develop` (the default branch). Do not add a
  repo-level `baseBranches` forcing `main`.

## git-flow-next usage

- `git flow feature start <name>` / `git flow release start <version>` /
  `git flow hotfix start <name>` create correctly-based branches.
- `git flow finish` from any topic branch detects the branch type, but it
  lands work by merging and pushing the target branch directly — which both
  `main` and `develop` reject here. Always finish through the PR flow above;
  `finish` is only for local branch cleanup.
- Config keys live in git config (`gitflow.branch.*`); do not override them
  per-repo without a recorded reason.
