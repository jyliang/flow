#!/usr/bin/env bash
# Detect the current flow stage. Mirrors the 6-rule logic in
# skills/flow/SKILL.md "Detect the current stage".
# SKILL.md is authoritative; this script is an optimization.
#
# stdout: one of explore-empty | plan | implement | review | ship | done
# stderr: one-line rationale when FLOW_DEBUG=1

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

if compgen -G "agent/reviews/*.md" >/dev/null \
   && grep -lE '^- \[ \]' agent/reviews/*.md >/dev/null 2>&1; then
  debug "unchecked items in agent/reviews/"
  echo "ship"
  exit 0
fi

if compgen -G "agent/plans/*.md" >/dev/null; then
  if grep -lE '^- \[ \]' agent/plans/*.md >/dev/null 2>&1; then
    debug "unchecked items in agent/plans/"
    echo "implement"
    exit 0
  fi
  debug "plan complete, no unchecked items"
  echo "review"
  exit 0
fi

if [[ -f agent/spec.md ]]; then
  debug "spec exists, no plan"
  echo "plan"
  exit 0
fi

debug "no agent/spec.md"
echo "explore-empty"
exit 0
