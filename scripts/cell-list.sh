#!/usr/bin/env bash
# List installed cells, mark the active one with *.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

active=""
if [ -L "$FLOW_HOME/active-cell" ]; then
    active=$(basename "$(readlink "$FLOW_HOME/active-cell")")
fi

if [ ! -d "$FLOW_HOME/cells" ] || [ -z "$(ls -A "$FLOW_HOME/cells" 2>/dev/null)" ]; then
    echo "No cells installed."
    echo "Run: make cell-init STARTER=code-pipeline NAME=<name>"
    exit 0
fi

for dir in "$FLOW_HOME/cells"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    desc=""
    if [ -f "$dir/cell.yaml" ]; then
        desc=$(grep -E '^description:' "$dir/cell.yaml" 2>/dev/null | head -1 | sed 's/^description: *//')
    fi
    marker=" "
    [ "$name" = "$active" ] && marker="*"
    printf " %s %-22s %s\n" "$marker" "$name" "$desc"
done
