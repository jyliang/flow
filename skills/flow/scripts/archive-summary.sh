#!/usr/bin/env bash
# Print one-line summary per archived workstream: pr-N, date, title.
# Used by /flow-reflect for orientation without reading every archive in full.
#
# Archive convention: agent/archive/<YYYY-MM-DD>-<branch-slug>/
#   Initial spec at 01-spec-r1.md, header comment: <!-- ... · pr: <N> · ... -->
#
# Usage: archive-summary.sh [limit]
#   limit: "all" (default), "N" for last N, or a comma-separated list like "pr-6,pr-7"

set -euo pipefail

limit="${1:-all}"

shopt -s nullglob
dirs=(agent/archive/*/)
shopt -u nullglob

[[ ${#dirs[@]} -eq 0 ]] && exit 0

for dir in "${dirs[@]}"; do
  shopt -s nullglob
  specs=("$dir"01-spec-r*.md)
  shopt -u nullglob
  [[ ${#specs[@]} -gt 0 ]] || continue
  spec="$(printf '%s\n' "${specs[@]}" | sort -V | head -1)"

  header="$(head -1 "$spec")"
  pr="$(printf '%s' "$header" | grep -oE 'pr: *[0-9]+' | head -1 | sed 's/pr: *//' || true)"
  date="$(printf '%s' "$header" | grep -oE 'date: *[0-9-]+' | head -1 | sed 's/date: *//' || true)"

  if [[ -z "$date" ]]; then
    folder="$(basename "$dir")"
    date="$(printf '%s' "$folder" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
  fi
  [[ -z "$date" ]] && date="unknown"

  title="$(grep -m1 '^# ' "$spec" | sed 's/^# *Spec: *//;s/^# *//')"

  pr_col="${pr:+pr-$pr}"
  pr_col="${pr_col:-pr-?}"
  printf '%s\t%s\t%s\n' "$pr_col" "$date" "$title"
done | sort -k2 | awk -v limit="$limit" '
BEGIN {
  if (limit == "all") n = -1;
  else if (limit ~ /^[0-9]+$/) n = int(limit);
  else { split(limit, sel, ","); for (i in sel) keep[sel[i]] = 1; n = -1 }
}
{
  if (length(keep) > 0) {
    if ($1 in keep) print;
  } else {
    lines[NR] = $0;
  }
}
END {
  if (length(keep) > 0) exit;
  start = (n < 0 || n >= NR) ? 1 : NR - n + 1;
  for (i = start; i <= NR; i++) print lines[i];
}
'
