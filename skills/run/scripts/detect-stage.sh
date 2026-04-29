#!/usr/bin/env bash
# Detect the current flow stage by walking the active cell's manifest.
# SKILL.md (skills/run/SKILL.md) is authoritative if logic drifts.
#
# Reads stages from ~/.flow/active-cell/cell.yaml via cell-stages.sh.
# A stage is "where we are now" if:
#   - its output handoff is missing, OR
#   - it's the consumer of the previous stage's unchecked checkboxes.
#
# Outputs:
#   <first-stage>-empty    no thread for current branch
#   <stage-name>           stage in progress
#   done                   PR open/merged or delivery key in spec frontmatter
#
# stderr: one-line rationale when FLOW_DEBUG=1

set -euo pipefail

debug() { [[ "${FLOW_DEBUG:-0}" = "1" ]] && echo "detect-stage: $*" >&2 || true; }

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

# PR check fires before manifest walk: a delivered branch is "done" regardless of state.
if [[ -n "$branch" ]] && [[ "$branch" != "HEAD" ]] && command -v gh >/dev/null 2>&1; then
  pr_state="$(gh pr view "$branch" --json state --jq .state 2>/dev/null || true)"
  if [[ "$pr_state" = "OPEN" ]] || [[ "$pr_state" = "MERGED" ]]; then
    debug "PR state=$pr_state on branch=$branch"
    echo "done"
    exit 0
  fi
fi

# Resolve thread folder (1:1 with branch). agent/threads/ canonical, agent/workstreams/ legacy.
thread=""
if [[ -n "$branch" ]] && [[ "$branch" != "HEAD" ]]; then
  shopt -s nullglob
  candidates=(agent/threads/*-"$branch"/ agent/workstreams/*-"$branch"/)
  shopt -u nullglob
  if [[ ${#candidates[@]} -gt 0 ]]; then
    thread="$(printf '%s\n' "${candidates[@]}" | sort | tail -1)"
    thread="${thread%/}"
  fi
fi

latest() {
  local prefix="$1"
  [[ -n "$thread" ]] || { echo ""; return; }
  shopt -s nullglob
  local files=("$thread"/"$prefix"-r*.md)
  shopt -u nullglob
  [[ ${#files[@]} -gt 0 ]] || { echo ""; return; }
  printf '%s\n' "${files[@]}" | sort -V | tail -1
}

has_pr_key() {
  local f
  f="$(latest "$1")"
  [[ -n "$f" ]] && grep -qE '^<!--.*pr: *[0-9]+' "$f"
}

# Locate cell-stages.sh via runtime-path. If unavailable, fall back to first-stage-empty.
runtime_path="$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || true)"
cell_stages="$runtime_path/scripts/cell-stages.sh"
if [[ ! -x "$cell_stages" ]]; then
  debug "cell-stages.sh not available; runtime-path=$runtime_path"
  echo "explore-empty"
  exit 0
fi

stages_data="$(bash "$cell_stages" 2>/dev/null || true)"
if [[ -z "$stages_data" ]]; then
  debug "manifest empty or unreadable"
  echo "explore-empty"
  exit 0
fi

# No thread for this branch yet → first-stage-empty.
if [[ -z "$thread" ]]; then
  first_name="$(printf '%s\n' "$stages_data" | head -1 | cut -d'|' -f1)"
  debug "no thread for branch=$branch; first=$first_name"
  echo "${first_name:-explore}-empty"
  exit 0
fi

# Walk stages. First stage whose output is missing OR whose handoff has unchecked items wins.
while IFS='|' read -r name output nxt; do
  [[ -n "$name" ]] || continue
  case "$output" in
    pr)
      # Final delivery stage. Spec-frontmatter pr: counts as done; PR-open already returned above.
      if has_pr_key 01-spec; then
        debug "delivery key set"
        echo "done"
        exit 0
      fi
      debug "ship in progress"
      echo "$name"
      exit 0
      ;;
    branch|"")
      # Stage with no file handoff (e.g. implement). Detection happens via prior stage's boxes;
      # if we walked here, the prior stage was complete, so this stage's output is satisfied too.
      continue
      ;;
    *)
      f="$(latest "$output")"
      if [[ -z "$f" ]]; then
        debug "missing $output handoff"
        echo "$name"
        exit 0
      fi
      if grep -qE '^- \[ \]' "$f"; then
        # Unchecked items in S's handoff = the consumer (S.next) is working through them.
        debug "unchecked in $f → $nxt"
        echo "${nxt:-$name}"
        exit 0
      fi
      # Handoff exists, fully checked → continue past.
      ;;
  esac
done <<< "$stages_data"

# Walked off the end of the manifest with everything complete.
echo "done"
