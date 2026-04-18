#!/usr/bin/env bash
# Print one-line summary per archived PR: pr-N, date, title.
# Used by /flow-reflect for orientation without reading every archive in full.
#
# Usage: archive-summary.sh [limit]
#   limit: "all" (default), "N" for last N, or a comma-separated list like "pr-6,pr-7"

set -euo pipefail

limit="${1:-all}"

shopt -s nullglob
dirs=(agent/archive/pr-*/)
shopt -u nullglob

[[ ${#dirs[@]} -eq 0 ]] && exit 0

for dir in "${dirs[@]}"; do
  pr="$(basename "$dir" | sed 's/^pr-//')"
  spec="$dir/spec.md"
  [[ -f "$spec" ]] || continue

  title="$(head -1 "$spec" | sed 's/^# *Spec: *//')"
  date="$(grep -oE 'date: [0-9-]+' "$spec" 2>/dev/null | head -1 | sed 's/date: //' || true)"
  if [[ -z "$date" ]]; then
    date="$(date -r "$spec" +%Y-%m-%d 2>/dev/null || echo 'unknown')"
  fi

  printf 'pr-%s\t%s\t%s\n' "$pr" "$date" "$title"
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
