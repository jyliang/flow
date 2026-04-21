#!/usr/bin/env bash
# Bootstrap a new flow: create a branch, materialize the initial spec.
# Does NOT commit; the caller (LLM or user) populates content and commits.
#
# Usage: bootstrap.sh <branch-name>
# Env:   FLOW_TEMPLATE_SPEC (override template location)
# Exits: 0 success; 2 validation or precondition failure; other non-zero on git/fs errors.

set -euo pipefail

die() { echo "bootstrap: $*" >&2; exit 2; }

branch="${1:-}"
[[ -n "$branch" ]] || die "usage: bootstrap.sh <branch-name>"
[[ "$branch" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid branch name '$branch' (expected lowercase kebab-case)"

date_str="$(date +%Y-%m-%d)"
workstream_dir="agent/workstreams/${date_str}-${branch}"

[[ ! -d "$workstream_dir" ]] || die "workstream already exists at $workstream_dir"

# Inlined config precedence (env > file > legacy > default) rather than calling
# load-config.sh to avoid subprocess + eval overhead. Kept in sync with that
# script; references/config.md documents the contract.
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

mkdir -p "$workstream_dir"
spec_file="$workstream_dir/01-spec-r1.md"
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
  "$template" > "$spec_file"

echo "branch=$branch spec=$spec_file"
