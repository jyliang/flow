#!/usr/bin/env bash
# Generate a unique branch name from a thesis string.
# Output: spike-<slug>-<YYYYMMDD-HHmm>
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

stamp="$(date +%Y%m%d-%H%M)"
printf 'spike-%s-%s\n' "$slug" "$stamp"
