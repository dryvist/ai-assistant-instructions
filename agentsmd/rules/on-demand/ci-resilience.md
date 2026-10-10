---
name: ci-resilience
description: CI runs fast, only when relevant, and fails only for reasons the change controls; fix a failure class once in the shared workflows and roll it to every repo
---

# CI Resilience

CI must be fast, scoped to what changed, and red only for a reason the change itself controls. A failure that
repeats across repos is a **class**: fix it once in the shared workflow repository, then roll the fix to every
caller and every template repository. Never patch one repo and leave the class alive in the others.

## Rules

1. **Pin dryvist workflow refs to a full commit SHA.** Call a dryvist reusable workflow as
   `uses: dryvist/<repo>/.github/workflows/<file>@<40-hex-sha> # vX.Y.Z`. Never `@main`, `@develop`, or a bare
   `@vN`. Renovate moves the SHA and the comment together, and a person merges a major bump. Third-party actions
   stay pinned by commit SHA, bumped by Renovate's digest manager.
2. **An unmapped path runs the full suite.** A path-scope selector never fails on a path it doesn't know, and never
   silently skips the real checks. Unknown means everything for that stack.
3. **Assert against the generated set, never a literal count.** A test that pins "95 entries" breaks on every
   legitimate addition.
4. **Every job sets `timeout-minutes`,** and the gate workflow sets `concurrency` with `cancel-in-progress: true`.
   A timeout bounds run time, not queue time. So the gate's orchestration jobs (change detection, watchdog, the
   aggregator) run on a runner pool independent of the work pool. A dead pool then fails the work jobs instead of
   leaving the gate pending.
5. **Advisory AI jobs never block a merge.** On a gateway, budget or rate-limit error, the job ends neutral and
   raises an ops alert. Each purpose uses its own key with a daily budget; no shared CI key.
6. **Pre-commit runs exactly the CI hooks,** from one shared configuration, so nothing surprises at CI time.
7. **No `sudo` in workflows.** Install what a job needs through the runner image or a setup action.
8. **Never bypass or disable a check to get green.** Fix the root cause, at the shared layer when it is a class.
9. **Nested calls stay inside the called release.** A shared workflow calls its own nested workflows as
   `./.github/workflows/<file>`, which runs at the called commit. `<org>/<repo>/...@main` runs the default branch
   under every pinned caller and escapes the canary. Reach a composite action in the same repo by sparse-checking
   that repo out at `job.workflow_sha` into a path, then `uses: ./<path>/.github/actions/<name>`.
10. **Shared local resources get admission control.** Heavy local hooks (ansible-lint, molecule) take one
   machine-wide lock, so parallel sessions queue instead of overloading the workstation. A wait loop never polls
   with a process-name pattern that also matches its own command line.
11. **CI health is observable.** Every workflow run (repo, workflow, job, conclusion, duration, runner, queue time)
   flows through the observability pipeline to every sink that can hold it. A new failure class, or a rise in the
   failure rate per repo or workflow, alerts. CI silence is not CI health.

## Shape

- **Profiles, not per-repo copies.** The shared gate takes a stack profile (ansible, nix, tofu, python, docs) that
  selects path filters and jobs. Callers stay a few lines. Heavy jobs (molecule, data contracts) live once, as
  shared reusables with inputs; delete local copies.
- **Relevance.** Pull requests into the integration branch run the checks the changed paths select. The full matrix
  runs on pull requests into the release branch and on pushes to either branch.
- **Speed.** Cache keys include the lockfile or requirements hash, so a stale cache never survives a dependency
  change. Nix jobs use a store cache.
- **One required check name** per repo, enforced by one org ruleset.
- **Runner choice is one input.** Private repos run on self-hosted or on-demand runner labels through a single
  `runner_label` input, never a hardcoded hosted label.
- **Templates carry the shape.** Every template repository and starter template ships the pinned gate caller with
  its profile, timeouts, concurrency, and the shared pre-commit configuration, so a new repo starts compliant.
- **Dead references fail at PR time.** The gate resolves every `uses:` reference, so a renamed shared workflow
  breaks the PR that renames it, not a later run.

## The same shapes beyond CI

- **Shared things ship through a release channel and a canary.** That covers workflows, roles, prompt pins and
  flake inputs. A consumer never tracks another repo's default branch.
- **A new secret path ships switched off** until the policy that grants its read is live. A denied read stops
  every converge that loads that secret domain, not only the role that wanted the path.
- **No static short-lived credential.** An agent renews it, or it is non-expiring and bound to a network range.
  Spend budgets alert at 50%.
- **Timeouts and rails come from measurement:** the measured p95 times a margin, recorded with its evidence.
- **Contract tests load the inventory with no roles,** so group variables never depend on role defaults.
- **Every source-of-truth question has a metric.** A decommissioned thing emits a positive signal; silence is not
  proof.
- **No required check depends on a single external service without a named fallback.**

## When a CI failure appears

1. Classify it: is the same failure in other repos? Search the recent failed runs across the organization.
2. A class goes to the shared workflow repository, with a test or a caller run proving the fix. One repo's own
   defect is fixed in that repo.
3. Roll the fix to every caller and template. Update this rule if the class is new, and the private docs through
   `docs-sync`.
