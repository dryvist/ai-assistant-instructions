#!/usr/bin/env bash
# cleanup-stale-branches.sh - Safely identify and delete merged branches
#
# This script identifies feature and fix branches that have been merged into the
# repo's default branch and are safe to delete. It excludes branches with active
# open PRs. The default branch is main on trunk repos, develop on git-flow repos.
#
# Usage: cleanup-stale-branches.sh [options]
#   --local-only       (flag - only delete local branches, not remote)
#   --remote-only      (flag - only delete remote branches)
#   --apply            (flag - actually delete branches; without flag, shows what would be deleted)
#   --exclude=<branch> (comma-separated list of branch names to preserve)
#
# Output:
#   Lists branches that are safe to delete
#   If --apply is used, actually deletes them
#   If --dry-run (default), shows what would be deleted

set -euo pipefail

# Configuration
LOCAL_ONLY=false
REMOTE_ONLY=false
APPLY_CHANGES=false
EXCLUDED_BRANCHES="main,master,develop"

# Resolve the repo's default branch (main on trunk repos, develop on git-flow).
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --local-only)
      LOCAL_ONLY=true
      REMOTE_ONLY=false
      shift
      ;;
    --remote-only)
      LOCAL_ONLY=false
      REMOTE_ONLY=true
      shift
      ;;
    --apply)
      APPLY_CHANGES=true
      shift
      ;;
    --exclude=*)
      EXCLUDED_BRANCHES="${EXCLUDED_BRANCHES},${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: cleanup-stale-branches.sh [--local-only|--remote-only] [--apply] [--exclude=branch1,branch2]"
      exit 1
      ;;
  esac
done

# Helper function to check if branch is in excluded list
is_excluded() {
  local branch="$1"
  echo "$EXCLUDED_BRANCHES" | tr ',' '\n' | grep -q "^$branch$"
}

# Get list of merged PR branches (branches that have been merged via PR)
get_merged_pr_branches() {
  if command -v gh &> /dev/null; then
    gh pr list --state merged --limit 100 --json headRefName --jq '.[].headRefName' 2>/dev/null || echo ""
  fi
}

# Get list of open PR branches to avoid deleting them
get_open_pr_branches() {
  if command -v gh &> /dev/null; then
    gh pr list --state open --json headRefName --jq '.[].headRefName' 2>/dev/null || echo ""
  fi
}

# Helper function to check if branch has an open PR
has_open_pr() {
  local branch="$1"
  local open_prs
  open_prs=$(get_open_pr_branches)

  if [[ -z "$open_prs" ]]; then
    return 1
  fi

  while IFS= read -r pr_branch; do
    if [[ "$branch" == "$pr_branch" ]]; then
      return 0
    fi
  done <<< "$open_prs"

  return 1
}

# Function to get merged local branches
get_merged_local_branches() {
  git branch --merged "origin/$DEFAULT_BRANCH" --format='%(refname:short)' | while read -r branch; do
    if ! is_excluded "$branch"; then
      echo "$branch"
    fi
  done
}

# Function to get merged remote branches
get_merged_remote_branches() {
  # Get all remote branches that have been merged to the default branch
  # Filter out origin/HEAD and the default branch itself
  git branch --remotes --merged "origin/$DEFAULT_BRANCH" --format='%(refname:short)' | \
    grep "origin/" | \
    grep -v "origin/HEAD" | \
    grep -v "origin/$DEFAULT_BRANCH" | \
    sed 's|origin/||' | \
    while read -r branch; do
      if ! is_excluded "$branch"; then
        echo "$branch"
      fi
    done
}

# Main cleanup logic
main() {
  local branches_to_delete=()
  local branches_with_open_prs=()

  # Create unique temporary files and ensure cleanup on exit
  local TO_DELETE_FILE
  local WITH_OPEN_PRS_FILE
  TO_DELETE_FILE=$(mktemp)
  WITH_OPEN_PRS_FILE=$(mktemp)
  trap 'rm -f "$TO_DELETE_FILE" "$WITH_OPEN_PRS_FILE"' EXIT

  echo "Analyzing branches for safe deletion..."
  echo ""

  # Get merged PR branches from GitHub API
  local merged_branches
  merged_branches=$(get_merged_pr_branches)

  # Get open PR branches from GitHub API
  local open_branches
  open_branches=$(get_open_pr_branches)

  # Process each merged branch
  if [[ -n "$merged_branches" ]]; then
    while IFS= read -r branch; do
      if [[ -z "$branch" ]]; then
        continue
      fi

      # Check if branch has an open PR
      if echo "$open_branches" | grep -q "^$branch$"; then
        branches_with_open_prs+=("$branch")
      else
        branches_to_delete+=("$branch")
      fi
    done <<< "$merged_branches"
  fi

  # Also check for any local-only merged branches (from git)
  if [[ "$REMOTE_ONLY" != "true" ]]; then
    # Write existing lists to temp files for comparison
    printf '%s\n' "${branches_to_delete[@]}" > "$TO_DELETE_FILE" 2>/dev/null || true
    printf '%s\n' "${branches_with_open_prs[@]}" > "$WITH_OPEN_PRS_FILE" 2>/dev/null || true

    while IFS= read -r branch; do
      # Skip if already in one of our lists
      if ! grep -q "^$branch$" "$TO_DELETE_FILE" 2>/dev/null && \
         ! grep -q "^$branch$" "$WITH_OPEN_PRS_FILE" 2>/dev/null && \
         ! is_excluded "$branch"; then
        if echo "$open_branches" | grep -q "^$branch$"; then
          branches_with_open_prs+=("$branch")
        else
          branches_to_delete+=("$branch")
        fi
      fi
    done < <(get_merged_local_branches)
  fi

  # Display results
  local total_to_delete=${#branches_to_delete[@]}
  local total_preserved=${#branches_with_open_prs[@]}

  if [[ $total_to_delete -gt 0 ]]; then
    echo "Merged branches safe to delete ($total_to_delete):"
    echo "========================================"
    printf '%s\n' "${branches_to_delete[@]}" | sort
    echo ""
  fi

  if [[ $total_preserved -gt 0 ]]; then
    echo "Branches with open PRs (preserved: $total_preserved):"
    echo "========================================"
    printf '%s\n' "${branches_with_open_prs[@]}" | sort
    echo ""
  fi

  if [[ $total_to_delete -eq 0 ]]; then
    echo "No stale branches found. Repository is clean!"
    return 0
  fi

  # Apply deletions if requested
  if [[ "$APPLY_CHANGES" == "true" ]]; then
    echo "Deleting $total_to_delete branches..."
    echo ""

    if [[ ${#branches_to_delete[@]} -gt 0 ]]; then
      # Delete all local branches in one single command with all parameters
      echo "Deleting local branches..."
      git branch -d "${branches_to_delete[@]}" 2>/dev/null && echo "  ✓ Deleted local branches" || echo "  ℹ Processed local branches (some may not exist locally)"

      # Delete all remote branches in one single command with all parameters
      if [[ "$LOCAL_ONLY" != "true" ]]; then
        echo "Deleting remote branches..."
        git push origin --delete "${branches_to_delete[@]}" 2>/dev/null && echo "  ✓ Deleted remote branches" || echo "  ℹ Processed remote branches (some may not exist on remote)"
      fi
    fi

    echo ""
    echo "Cleanup summary:"
    echo "  Branches processed: $total_to_delete"
  else
    if [[ $total_to_delete -gt 0 ]]; then
      echo "To apply these deletions, run:"
      echo "  bash scripts/cleanup-stale-branches.sh --apply"
      echo ""
    fi
  fi
}

main "$@"
