// CI fix eligibility gates for Copilot PRs.
// Checks: failure, non-main branch, fork guard, PR author is copilot[bot], attempt limit.
module.exports = async ({ github, context, core }) => {
  const { owner, repo } = context.repo;
  const run = context.payload.workflow_run;

  if (!run) { core.setOutput('should_run', 'false'); core.info('No workflow_run in payload'); return; }
  if (run.conclusion !== 'failure') { core.setOutput('should_run', 'false'); core.info(`Not a failure: ${run.conclusion}`); return; }
  if (run.head_branch === 'main') { core.setOutput('should_run', 'false'); core.info('Main branch — excluded from Copilot CI fixes'); return; }
  if (run.head_repository?.full_name !== `${owner}/${repo}`) { core.setOutput('should_run', 'false'); core.info('Fork — skipping'); return; }

  // Find PR for this branch
  const { data: prs } = await github.rest.pulls.list({
    owner, repo, head: `${owner}:${run.head_branch}`, state: 'open'
  });
  if (prs.length === 0) { core.setOutput('should_run', 'false'); core.info(`No open PR for branch ${run.head_branch}`); return; }
  const pr = prs[0];

  // PR author must be copilot[bot]
  if (pr.user?.login !== 'copilot[bot]') {
    core.setOutput('should_run', 'false');
    core.info(`PR author is ${pr.user?.login}, not copilot[bot]`);
    return;
  }

  // Attempt limit: max 2
  const marker = '<!-- copilot-ci-fix-attempt -->';
  const comments = await github.paginate(github.rest.issues.listComments, {
    owner, repo, issue_number: pr.number, per_page: 100
  });
  const attempts = comments.filter(c => c.body?.includes(marker)).length;
  if (attempts >= 2) {
    core.setOutput('should_run', 'false');
    core.info(`Max fix attempts reached (${attempts}/2) on PR #${pr.number}`);
    return;
  }

  core.setOutput('should_run', 'true');
  core.setOutput('pr_number', pr.number.toString());
  core.setOutput('attempt', (attempts + 1).toString());
  core.info(`PR #${pr.number} eligible for fix attempt ${attempts + 1}/2`);
};
