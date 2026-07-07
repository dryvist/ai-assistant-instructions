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

# Decision tree implementation based on dynamic model discovery.
select_model() {
  local task_type="$1"
  local cost_sensitive="$2"
  local private="$3"
  local large_context="$4"
  local complexity="$5"
  local local_model="${AI_MODEL_LOCAL:-}"
  local local_ref

  if [[ -n "$local_model" ]]; then
    local_ref="$local_model"
  else
    local_ref="<discover-local-model>"
  fi

  # Display complexity if analyzed
  if [[ -n "$complexity" ]]; then
    echo "Complexity: $complexity"
  fi

  # Step 1: Is the data sensitive or confidential?
  if [[ "$private" == "true" ]]; then
    echo "Model: $local_ref"
    echo "Selected: $local_ref"
    echo "Command: listmodels; pal chat --model \"$local_ref\""
    echo "Rationale: Private/sensitive data must stay local. Use AI_MODEL_LOCAL when set, then verify it exists in live discovery."
    return 0
  fi

  # Step 2: Is cost a concern?
  if [[ "$cost_sensitive" == "true" ]]; then
    case "$task_type" in
      coding)
        echo "Model: <discover-local-coding-model>"
        echo "Command: listmodels; pal chat --model <discovered-local-coding-model>"
        echo "Rationale: Cost-sensitive coding task - prefer a discovered local coding-capable model, falling back to AI_MODEL_LOCAL."
        return 0
        ;;
      review)
        echo "Model: <discover-local-review-model>"
        echo "Command: listmodels; pal chat --model <discovered-local-review-model>"
        echo "Rationale: Cost-sensitive code review - prefer a discovered local reasoning/review-capable model."
        return 0
        ;;
      research)
        echo "Model: $local_ref"
        echo "Command: listmodels; pal chat --model \"$local_ref\""
        echo "Rationale: Cost-sensitive research/analysis - start with AI_MODEL_LOCAL or a discovered local general model."
        return 0
        ;;
      decision)
        echo "Model: consensus"
        echo "Command: pal clink"
        echo "Rationale: Cost-sensitive critical decision - use locally available models discovered at runtime."
        return 0
        ;;
      default)
        echo "Model: $local_ref"
        echo "Command: listmodels; pal chat --model \"$local_ref\""
        echo "Rationale: Cost-sensitive generic task - use AI_MODEL_LOCAL or the best discovered local general model."
        return 0
        ;;
    esac
  fi

  # Step 3: Do you need the latest information/web search or 1M+ context window?
  if [[ "$large_context" == "true" ]]; then
    echo "Model: <discover-large-context-or-web-model>"
    echo "Command: listmodels; query Bifrost /v1/models; choose a current model with the required context/tools"
    echo "Rationale: Large context or current information needed - discover a capable cloud or local model at runtime."
    return 0
  fi

  # Step 4: Is this a critical decision?
  if [[ "$task_type" == "decision" ]]; then
    echo "Model: consensus"
    echo "Command: pal consensus"
    echo "Rationale: Critical decision - get consensus from currently available models to reduce bias."
    return 0
  fi

  # Step 5: Need specialized coding?
  if [[ "$task_type" == "coding" ]]; then
    if [[ "$complexity" == "high" ]]; then
      echo "Model: <discover-high-capability-coding-model>"
      echo "Command: listmodels; use the current session or a discovered coding-capable model"
      echo "Rationale: High-complexity coding task - choose the strongest available coding/reasoning option dynamically."
    else
      echo "Model: <discover-efficient-coding-model>"
      echo "Command: listmodels; use the current session, a native subagent, or a discovered coding-capable model"
      echo "Rationale: Standard coding task - choose the smallest capable available coding model dynamically."
    fi
    return 0
  fi

  # Step 6: Code review with cost flexibility
  if [[ "$task_type" == "review" ]]; then
    if [[ "$complexity" == "high" ]]; then
      echo "Model: consensus"
      echo "Command: pal consensus"
      echo "Rationale: High-complexity review requires independent perspectives from currently available models."
    else
      echo "Model: consensus"
      echo "Command: pal consensus"
      echo "Rationale: Code review benefits from multiple perspectives on non-sensitive code."
    fi
    return 0
  fi

  # Step 7: Research/Analysis with cost flexibility
  if [[ "$task_type" == "research" ]]; then
    echo "Model: <discover-research-model>"
    echo "Command: listmodels; query Bifrost /v1/models; choose a current model with the needed search/context support"
    echo "Rationale: Research/analysis - discover a model with current-information access or enough context for the task."
    return 0
  fi

  # Default: Start local, fall back to cloud
  echo "Model: mlx-with-fallback"
  echo "Selected: $local_ref, then a discovered cloud fallback if local quality or capability is insufficient"
  echo "Command: listmodels; pal chat --model \"$local_ref\""
  echo "Rationale: Default/general task - try AI_MODEL_LOCAL or a discovered local model first, then discover a cloud fallback if needed."
  return 0
}

# Execute the selection logic and format output
COMPLEXITY_SCORE=""
if [[ -n "$ANALYZE_COMPLEXITY" ]]; then
  COMPLEXITY_SCORE=$(analyze_complexity "$ANALYZE_COMPLEXITY")
fi

select_model "$TASK_TYPE" "$COST_SENSITIVE" "$PRIVATE" "$LARGE_CONTEXT" "$COMPLEXITY_SCORE"
