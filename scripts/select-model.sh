#!/usr/bin/env bash
# select-model.sh - Automatic model selection based on task requirements
#
# This script implements the decision tree from the delegate-to-ai skill
# to select the best AI model for a given task considering cost, privacy, and capability needs.
#
# Usage: select-model.sh [options]
#   --task-type=<research|coding|review|decision|default>
#   --cost-sensitive (flag - prefer free local models)
#   --private (flag - sensitive data, must use local MLX)
#   --large-context (flag - need 1M+ context window)
#   --analyze-complexity=<prompt|filepath> (optional complexity analysis)
#
# Output:
#   Model: <model-name>
#   Command: <invocation-command>
#   Rationale: <explanation>
#   [Complexity: <low|medium|high>] (when --analyze-complexity is used)

set -euo pipefail

# Default values
TASK_TYPE="default"
COST_SENSITIVE=false
PRIVATE=false
LARGE_CONTEXT=false
ANALYZE_COMPLEXITY=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --task-type=*)
      TASK_TYPE="${1#*=}"
      shift
      ;;
    --cost-sensitive)
      COST_SENSITIVE=true
      shift
      ;;
    --private)
      PRIVATE=true
      shift
      ;;
    --large-context)
      LARGE_CONTEXT=true
      shift
      ;;
    --analyze-complexity=*)
      ANALYZE_COMPLEXITY="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Analyze complexity based on input metrics
analyze_complexity() {
  local input="$1"
  local complexity_score=""
  local line_count=0
  local text_length=0

  # Check if input is a file path
  if [[ -f "$input" ]]; then
    # Validate path to prevent directory traversal
    local real_path
    real_path=$(realpath "$input" 2>/dev/null) || {
      echo "Error: Cannot resolve path: $input" >&2
      return 1
    }
    local cwd_real
    cwd_real=$(realpath "$PWD")
    # Prevent path traversal by ensuring the resolved path is within the current directory.
    # Paths must either be exactly the current directory or start with "$cwd_real/".
    # Running from the root directory is also disallowed for security.
    if [[ "$cwd_real" == "/" ]] || [[ "$real_path" != "$cwd_real"/* && "$real_path" != "$cwd_real" ]]; then
      echo "Error: Path must be within current directory. Traversal to '$real_path' is not allowed." >&2
      return 1
    fi

    # File-based analysis
    line_count=$(wc -l < "$input" | tr -d ' ')

    # Determine complexity by line count
    if [[ $line_count -lt 50 ]]; then
      complexity_score="low"
    elif [[ $line_count -lt 200 ]]; then
      complexity_score="medium"
    else
      complexity_score="high"
    fi
  else
    # Text-based analysis
    text_length=${#input}
    local lower_input
    lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # Check for complexity keywords
    local keyword_count=0
    for keyword in "refactor" "architecture" "security audit" "performance optimization" "system design" "rewrite" "migration"; do
      [[ "$lower_input" =~ $keyword ]] && ((keyword_count++))
    done

    # Determine complexity by length and keywords
    if [[ $text_length -lt 100 && $keyword_count -eq 0 ]]; then
      complexity_score="low"
    elif [[ $text_length -lt 500 && $keyword_count -le 1 ]]; then
      complexity_score="medium"
    else
      complexity_score="high"
    fi
  fi

  echo "$complexity_score"
}

# Resolve a capability role (default, coding, most-capable, large-context,
# quickest, tool-calling, oss) to its physical mlx-community/* model id via the
# AI-stack registry — the single source of truth written by nix-ai on each
# darwin-rebuild to ~/.config/ai-stack/registry.json. This keeps hardcoded
# physical model ids out of the routing canon: when the resident model changes,
# only the registry changes. Falls back to the 'default' role, then to the role
# name itself (a capability alias) if the registry is unavailable.
AI_STACK_REGISTRY="${AI_STACK_REGISTRY:-$HOME/.config/ai-stack/registry.json}"
model_for_role() {
  local role="$1" id=""
  if command -v jq >/dev/null 2>&1 && [[ -r "$AI_STACK_REGISTRY" ]]; then
    id=$(jq -r --arg r "$role" '.models[$r] // .models.default // empty' "$AI_STACK_REGISTRY")
  fi
  if [[ -z "$id" ]]; then
    echo "Warning: AI-stack registry unavailable; using role alias '$role'" >&2
    id="$role"
  fi
  printf '%s' "$id"
}

# Decision tree implementation based on delegate-to-ai.md routing logic
select_model() {
  local task_type="$1"
  local cost_sensitive="$2"
  local private="$3"
  local large_context="$4"
  local complexity="$5"

  # Display complexity if analyzed
  if [[ -n "$complexity" ]]; then
    echo "Complexity: $complexity"
  fi

  # Step 1: Is the data sensitive or confidential?
  if [[ "$private" == "true" ]]; then
    local m; m="$(model_for_role most-capable)"
    echo "Model: $m"
    echo "Selected: $m (single resident local model — every capability role resolves to it)"
    echo "Command: pal chat --model $m"
    echo "Rationale: Private/sensitive data must stay local. Never use cloud APIs."
    return 0
  fi

  # Step 2: Is cost a concern?
  if [[ "$cost_sensitive" == "true" ]]; then
    case "$task_type" in
      coding)
        local m; m="$(model_for_role coding)"
        echo "Model: $m"
        echo "Command: pal chat --model $m"
        echo "Rationale: Cost-sensitive coding task - using the free local model (coding role)"
        return 0
        ;;
      review)
        local m; m="$(model_for_role most-capable)"
        echo "Model: $m"
        echo "Command: pal chat --model $m"
        echo "Rationale: Cost-sensitive code review - using the free local model (most-capable role)"
        return 0
        ;;
      research)
        local m; m="$(model_for_role large-context)"
        echo "Model: $m"
        echo "Command: pal chat --model $m"
        echo "Rationale: Cost-sensitive research/analysis - using the free local model (large-context role)"
        return 0
        ;;
      decision)
        local m; m="$(model_for_role most-capable)"
        echo "Model: $m (via pal clink — fans out across local + configured models)"
        echo "Command: pal clink"
        echo "Rationale: Cost-sensitive critical decision - fan out for multiple perspectives"
        return 0
        ;;
      default)
        local m; m="$(model_for_role default)"
        echo "Model: $m"
        echo "Command: pal chat --model $m"
        echo "Rationale: Cost-sensitive generic task - using the free local model (default role)"
        return 0
        ;;
    esac
  fi

  # Step 3: Do you need the latest information/web search or 1M+ context window?
  if [[ "$large_context" == "true" ]]; then
    echo "Model: gemini-3-pro"
    echo "Command: gemini chat --model gemini-3-pro"
    echo "Rationale: 1M+ token context needed - only Gemini 3 Pro can handle this scale"
    return 0
  fi

  # Step 4: Is this a critical decision?
  if [[ "$task_type" == "decision" ]]; then
    local m; m="$(model_for_role most-capable)"
    echo "Model: consensus"
    echo "Selected: gemini-3-pro (cloud) + $m (local) + Claude"
    echo "Command: pal consensus"
    echo "Rationale: Critical decision - get consensus from multiple models to reduce bias"
    return 0
  fi

  # Step 5: Need specialized coding?
  if [[ "$task_type" == "coding" ]]; then
    if [[ "$complexity" == "high" ]]; then
      echo "Model: Claude Opus (Claude Code)"
      echo "Command: Using Claude directly (current session)"
      echo "Rationale: High-complexity coding task - Claude Opus for superior architecture and reasoning"
    else
      echo "Model: Claude Sonnet (Claude Code)"
      echo "Command: Using Claude directly (current session)"
      echo "Rationale: Standard coding task - Claude Sonnet for efficient code generation"
    fi
    return 0
  fi

  # Step 6: Code review with cost flexibility
  if [[ "$task_type" == "review" ]]; then
    local m; m="$(model_for_role most-capable)"
    if [[ "$complexity" == "high" ]]; then
      echo "Model: consensus"
      echo "Selected: Claude Opus (Claude Code) + gemini-3-pro + $m (local)"
      echo "Command: Multi-model review for high-complexity code"
      echo "Rationale: High-complexity review requires expert perspectives - adding Opus for deeper analysis"
    else
      echo "Model: consensus"
      echo "Selected: gemini-3-pro + $m (local)"
      echo "Command: pal consensus"
      echo "Rationale: Code review benefits from multiple perspectives on non-sensitive code"
    fi
    return 0
  fi

  # Step 7: Research/Analysis with cost flexibility
  if [[ "$task_type" == "research" ]]; then
    echo "Model: gemini-3-pro"
    echo "Command: gemini chat --model gemini-3-pro"
    echo "Rationale: Research/analysis - Gemini 3 Pro for 1M context and latest information"
    return 0
  fi

  # Default: Start local, fall back to cloud
  local m; m="$(model_for_role default)"
  echo "Model: mlx-with-fallback"
  echo "Selected: $m (local) → gemini-3-pro (cloud fallback)"
  echo "Command: pal chat --model $m"
  echo "Rationale: Default/general task - try local first for cost/privacy, fall back to cloud if needed"
  return 0
}

# Execute the selection logic and format output
COMPLEXITY_SCORE=""
if [[ -n "$ANALYZE_COMPLEXITY" ]]; then
  COMPLEXITY_SCORE=$(analyze_complexity "$ANALYZE_COMPLEXITY")
fi

select_model "$TASK_TYPE" "$COST_SENSITIVE" "$PRIVATE" "$LARGE_CONTEXT" "$COMPLEXITY_SCORE"
