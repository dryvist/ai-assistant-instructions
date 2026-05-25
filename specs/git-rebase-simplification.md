# Technical Specification: Simplify /git-rebase Command

## Issue Summary

**Problem:** The current `/git-rebase` command fails to complete because:

1. **319 lines is too long** - models lose context before reaching Step 6 (the critical push)
2. **Step 6 is buried at line 183** - the core purpose gets lost in noise
3. **Intermediate success messages** - "Rebase successful" at Step 4 makes models think they're done
4. **Permission fatigue** - each bash script requires manual approval
5. **Troubleshooting always loads** - 40+ lines of rarely-needed content

**Evidence:** In `active-pull-request` worktree, the model "completed" rebase but:

- `chore/fix-label-naming` = `main` = `7a61cdc` (same commit)
- `origin/main` = `53f6b8b` (6 commits ahead - NEVER PUSHED!)

## Problem Statement

### The Core Purpose (buried at line 183)

The **entire point** of `/git-rebase` is:

```text
feature-branch → main → origin/main
```

But the current implementation:

1. Step 4: Rebase feature onto main → prints "Rebase successful"
2. Step 5: Merge into main → prints "Main updated with branch"
3. Step 6: Push main to origin → **MODEL STOPS BEFORE THIS**

### Why Models Fail

Haiku-level models (and even Sonnet when distracted):

- See "Rebase successful" and think the task is complete
- Lose context by line 183 in a 319-line document
- Get confused between pushing the feature branch (Step 4) vs main (Step 6)
- Report success after Step 5 because main is locally updated

## Technical Approach

### Solution: Two-Skill Architecture

```text
┌────────────────────────────────────────────────┐
│  /git-rebase (PRIMARY - Max 80 lines)          │
│  ──────────────────────────────────────────────│
│  • LEAD WITH THE GOAL: Push main to origin     │
│  • Minimal validation                          │
│  • Linear execution: rebase → merge → PUSH     │
│  • Clear SUCCESS = "Pushed to origin/main"     │
│  • On failure: invoke troubleshoot skill       │
└────────────────────────────────────────────────┘
        ↓ (only if errors)
┌────────────────────────────────────────────────┐
│  /git-rebase-troubleshoot (OPTIONAL)           │
│  ──────────────────────────────────────────────│
│  • Loaded ONLY on explicit failure             │
│  • Conflict resolution guidance                │
│  • Recovery procedures                         │
│  • Diagnostic commands                         │
└────────────────────────────────────────────────┘
```

### Key Architectural Changes

#### 1. LEAD WITH THE GOAL

Current (buried at line 183):

```markdown
## Step 6: Push Main to Origin
```

New (line 1):

```markdown
# Git Rebase

**GOAL:** Push feature branch commits to origin/main.
**SUCCESS CRITERIA:** `git push origin main` completes successfully.
**YOU ARE NOT DONE UNTIL:** origin/main has been updated.
```

#### 2. Simplify to Three Commands

Current: 7 complex bash scripts with nested subshells
New: 3 simple commands with explicit success checks

```bash
# Step 1: in the main worktree
git fetch origin && git reset --hard origin/main

# Step 2: in the feature worktree
git rebase main

# Step 3: back in the main worktree
git merge --ff-only <type>/<name>

# Step 4: THE CRITICAL STEP - still in the main worktree
git push origin main
```

#### 3. Remove Troubleshooting from Primary Skill

Move ALL of these to `/git-rebase-troubleshoot`:

- "Main worktree not found" handling
- "Branch not found" handling
- "Fast-forward merge failed" handling
- "Push rejected" handling
- Conflict resolution instructions
- Recovery procedures

#### 4. Explicit Success Criteria

```markdown
## SUCCESS CHECKLIST (verify ALL before reporting success)

□ `git push origin main` returned exit code 0
□ `git rev-parse origin/main` matches local main
□ Feature branch commits are now in origin/main history

**If ANY checkbox is not checked, the task is NOT complete.**
```

## Implementation Plan

### Phase 1: Create `/git-rebase-troubleshoot`

**File:** `agentsmd/commands/git-rebase-troubleshoot.md`

Extract from current git-rebase.md:

- Lines 226-299: "Handling Rebase Conflicts" section
- Lines 270-299: "Troubleshooting" section
- Add detailed diagnostic commands
- Add recovery procedures

### Phase 2: Rewrite `/git-rebase` (Max 80 lines)

**File:** `agentsmd/commands/git-rebase.md`

Structure:

```markdown
---
description: Push feature branch to origin/main via rebase
model: haiku
allowed-tools: Bash(git:*)
---

# Git Rebase

**GOAL:** Push <branch> commits to origin/main.
**SUCCESS:** `git push origin main` completes.
**NOT DONE UNTIL:** origin/main updated.

## The Three Steps

### Step 1: Update main from origin
[command]

### Step 2: Rebase branch onto main, merge into main
[command]

### Step 3: PUSH MAIN TO ORIGIN (THIS IS THE POINT)
[command]
[verify command]

## Success Checklist
[explicit verification steps]

## If Errors Occur
Run: /git-rebase-troubleshoot
```

### Phase 3: Update Permissions

Pre-approve core git commands:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git fetch:*)",
      "Bash(git log:*)",
      "Bash(git rev-parse:*)",
      "Bash(git diff:*)"
    ]
  }
}
```

## Test Plan

### Test 1: Happy Path

```bash
# Setup
git checkout -b test-branch && echo "test" >> file && git commit -am "test"

# Run
/git-rebase test-branch

# Verify
git log origin/main --oneline -3  # Should show test commit
```

### Test 2: Haiku Completion

```bash
# Run with haiku model
/model haiku
/git-rebase test-branch

# Verify model doesn't stop at "Rebase successful"
# Verify model completes push to origin/main
```

### Test 3: Failure Triggers Troubleshoot

```bash
# Setup: Create conflict
git checkout -b conflict-branch
echo "conflict" > shared-file && git commit -am "conflict"
git checkout main && echo "different" > shared-file && git commit -am "main change"

# Run
/git-rebase conflict-branch

# Verify: Model offers /git-rebase-troubleshoot
```

## Files to Create/Modify

### New File

- `agentsmd/commands/git-rebase-troubleshoot.md` (~100 lines)

### Modified Files

- `agentsmd/commands/git-rebase.md` (319 → 80 lines)
- `agentsmd/permissions/universal-claude-config.json` (add pre-approved commands)

## Success Criteria

- [ ] `/git-rebase` completes full workflow (through push to origin)
- [ ] Haiku model can follow instructions without losing context
- [ ] No intermediate "success" messages that could cause early termination
- [ ] Troubleshooting loads only when needed
- [ ] Approval prompts reduced from ~10 to ~2

## Out of Scope

- Interactive rebase (`git rebase -i`)
- Rebasing onto arbitrary branches (only main supported)
- Automated conflict resolution
- Integration with external merge tools

## Appendix: Current Failure Analysis

### What Happened in `active-pull-request`

1. Model read `/git-rebase`
2. Executed Steps 1-4 (update main, find worktree, rebase, push feature branch)
3. Saw "Rebase successful" message at Step 4
4. Executed Step 5 (merge into main locally)
5. Saw "Main updated with branch" message
6. **STOPPED** - thought task was complete
7. Never executed Step 6 (push main to origin)

### Evidence

```bash
$ # in the ai-assistant-instructions worktree for the active PR
$ git branch -vv
* chore/fix-label-naming  7a61cdc  # Local branch
  main                   7a61cdc  # Same as local - merge happened
  origin/main            53f6b8b  # 6 COMMITS AHEAD - never pushed!
```

### Root Cause

The word "successful" appears in Step 4 output:

```text
Rebase successful
Commits to push: 3
```

Haiku sees "successful" and reports task complete. The fact that Step 6 exists at line 183 is irrelevant - context was lost.

## Design Principles

### For Haiku-Level Models

1. **Lead with the goal** - First line should state what success looks like
2. **Repeat the goal** - Mention it multiple times throughout
3. **No intermediate success messages** - Only "SUCCESS" when truly done
4. **Explicit completion checklist** - Model must verify each item
5. **Short documents** - Under 100 lines, ideally under 80
6. **Linear execution** - No branching, no conditionals, no nested subshells

### Deferred Loading

Complex features load only when needed:

- Troubleshooting → separate skill
- Conflict resolution → separate skill
- Edge case handling → separate skill

This keeps the primary skill focused and short.
