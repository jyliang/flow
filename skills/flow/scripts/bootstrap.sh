#!/usr/bin/env bash
# Bootstrap a new flow: create a branch, materialize agent/spec.md from template.
# Does NOT commit; the caller (LLM or user) populates content and commits.
#
# Usage: bootstrap.sh <branch-name>
# Env:   FLOW_TEMPLATE_DIR (override template location; default ~/.claude/skills/flow/templates)
# Exits: 0 success; 2 validation or precondition failure; other non-zero on git/fs errors.
#
# Future: add --overwrite and --adopt flags so /flow-adopt's recovery options
# (overwrite / adopt-into-existing) become explicit in the script's contract
# instead of LLM-inferred. Tracked for v2.

set -euo pipefail

die() { echo "bootstrap: $*" >&2; exit 2; }

branch="${1:-}"
[[ -n "$branch" ]] || die "usage: bootstrap.sh <branch-name>"
[[ "$branch" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid branch name '$branch' (expected lowercase kebab-case)"

[[ ! -f agent/spec.md ]] || die "spec already exists at agent/spec.md"

env_template="${FLOW_TEMPLATE_SPEC:-}"
if [[ -f .flow/config.sh ]]; then
  # shellcheck disable=SC1091
  source .flow/config.sh
fi
[[ -n "$env_template" ]] && FLOW_TEMPLATE_SPEC="$env_template"
if [[ -z "${FLOW_TEMPLATE_SPEC:-}" ]] && [[ -n "${FLOW_TEMPLATE_DIR:-}" ]]; then
  FLOW_TEMPLATE_SPEC="$FLOW_TEMPLATE_DIR/spec.md"
fi
template="${FLOW_TEMPLATE_SPEC:-$HOME/.claude/skills/flow/templates/spec.md}"
[[ -f "$template" ]] || die "template not found at $template"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git work tree"

git checkout -b "$branch"

mkdir -p agent
date_str="$(date +%Y-%m-%d)"
author="$(git config user.name || echo 'unknown')"

escape_for_sed() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//&/\\&}"
  s="${s//|/\\|}"
  printf '%s' "$s"
}

sed \
  -e "s|{{DATE}}|$(escape_for_sed "$date_str")|g" \
  -e "s|{{BRANCH}}|$(escape_for_sed "$branch")|g" \
  -e "s|{{AUTHOR}}|$(escape_for_sed "$author")|g" \
  "$template" > agent/spec.md

echo "branch=$branch spec=agent/spec.md"
