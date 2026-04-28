#!/usr/bin/env bash
# List installed packs, mark the active one with *.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

active=""
if [ -L "$FLOW_HOME/active-pack" ]; then
    active=$(basename "$(readlink "$FLOW_HOME/active-pack")")
fi

if [ ! -d "$FLOW_HOME/packs" ] || [ -z "$(ls -A "$FLOW_HOME/packs" 2>/dev/null)" ]; then
    echo "No packs installed."
    echo "Run: make pack-init STARTER=code-pipeline NAME=<name>"
    exit 0
fi

for dir in "$FLOW_HOME/packs"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    desc=""
    if [ -f "$dir/pack.yaml" ]; then
        desc=$(grep -E '^description:' "$dir/pack.yaml" 2>/dev/null | head -1 | sed 's/^description: *//')
    fi
    marker=" "
    [ "$name" = "$active" ] && marker="*"
    printf " %s %-22s %s\n" "$marker" "$name" "$desc"
done
