#!/usr/bin/env bash
# Detect the current flow stage. Mirrors the rule logic in
# skills/run/SKILL.md "How to detect the current stage".
# SKILL.md is authoritative; this script is an optimization.
#
# stdout: one of explore-empty | plan | implement | review | ship | done
# stderr: one-line rationale when FLOW_DEBUG=1
#
# v3 NOTE: this still hardcodes the code-pipeline stages. Manifest-driven
# detection (reading ~/.flow/active-pack/pack.yaml) is a follow-up.

set -euo pipefail

debug() { [[ "${FLOW_DEBUG:-0}" = "1" ]] && echo "detect-stage: $*" >&2 || true; }

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

if [[ -n "$branch" ]] && [[ "$branch" != "HEAD" ]] && command -v gh >/dev/null 2>&1; then
  pr_state="$(gh pr view "$branch" --json state --jq .state 2>/dev/null || true)"
  if [[ "$pr_state" = "OPEN" ]]; then
    debug "open PR on branch=$branch"
    echo "done"
    exit 0
  fi
fi

# Resolve the active thread folder from the branch name.
# Convention: agent/threads/<YYYY-MM-DD>-<branch>/ (1:1 branch↔thread).
# Falls back to agent/workstreams/ for backward compatibility with v2 history.
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

# latest <stage-prefix> — prints the highest-rN file for that prefix, or empty.
latest() {
  local prefix="$1"
  [[ -n "$thread" ]] || { echo ""; return; }
  shopt -s nullglob
  local files=("$thread"/"$prefix"-r*.md)
  shopt -u nullglob
  [[ ${#files[@]} -gt 0 ]] || { echo ""; return; }
  printf '%s\n' "${files[@]}" | sort -V | tail -1
}

review_file="$(latest 03-review)"
plan_file="$(latest 02-plan)"
spec_file="$(latest 01-spec)"

if [[ -n "$review_file" ]] && grep -qE '^- \[ \]' "$review_file"; then
  debug "unchecked items in $review_file"
  echo "ship"
  exit 0
fi

if [[ -n "$plan_file" ]]; then
  if grep -qE '^- \[ \]' "$plan_file"; then
    debug "unchecked items in $plan_file"
    echo "implement"
    exit 0
  fi
  debug "plan complete at $plan_file, no unchecked items"
  echo "review"
  exit 0
fi

if [[ -n "$spec_file" ]]; then
  debug "spec at $spec_file, no plan"
  echo "plan"
  exit 0
fi

debug "no thread for branch=$branch"
echo "explore-empty"
exit 0
