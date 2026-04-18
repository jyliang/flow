#!/usr/bin/env bash
# Bootstrap a new flow: create a branch, materialize agent/spec.md from template.
# Does NOT commit; the caller (LLM or user) populates content and commits.
#
# Usage: bootstrap.sh <branch-name>
# Env:   FLOW_TEMPLATE_DIR (override template location; default ~/.claude/skills/flow/templates)
# Exits: 0 success; 2 validation or precondition failure; other non-zero on git/fs errors.

set -euo pipefail

die() { echo "bootstrap: $*" >&2; exit 2; }

branch="${1:-}"
[[ -n "$branch" ]] || die "usage: bootstrap.sh <branch-name>"
[[ "$branch" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid branch name '$branch' (expected lowercase kebab-case)"

[[ ! -f agent/spec.md ]] || die "spec already exists at agent/spec.md"

template_dir="${FLOW_TEMPLATE_DIR:-$HOME/.claude/skills/flow/templates}"
template="$template_dir/spec.md"
[[ -f "$template" ]] || die "template not found at $template"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git work tree"

git checkout -b "$branch"

mkdir -p agent
date_str="$(date +%Y-%m-%d)"
author="$(git config user.name || echo 'unknown')"

sed \
  -e "s|{{DATE}}|$date_str|g" \
  -e "s|{{BRANCH}}|$branch|g" \
  -e "s|{{AUTHOR}}|$author|g" \
  "$template" > agent/spec.md

echo "branch=$branch spec=agent/spec.md"
