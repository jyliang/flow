#!/usr/bin/env bash
# Generate a branch name for a spike from a thesis string.
# Output: spike-<slug>
#
# bootstrap.sh adds the date prefix when creating the thread folder
# (agent/threads/<YYYY-MM-DD>-<branch>/), so no timestamp needed here.
# Same-day same-slug collisions surface via bootstrap.sh's "thread
# already exists" refuse, which spike's abort protocol then handles.
#
# Usage: spike-branch.sh "<thesis>"
# Exits: 0 success; 2 usage error.

set -euo pipefail

thesis="${1:-}"
[[ -n "$thesis" ]] || { echo "usage: spike-branch.sh <thesis>" >&2; exit 2; }

slug="$(printf '%s' "$thesis" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9-' '-' \
  | sed -E 's/-+/-/g; s/^-+|-+$//g' \
  | cut -c1-40 \
  | sed -E 's/-+$//')"

[[ -z "$slug" ]] && slug="spike"

printf 'spike-%s\n' "$slug"
