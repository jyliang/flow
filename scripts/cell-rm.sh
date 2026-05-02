#!/usr/bin/env bash
# Remove a cell. Refuses if it's the active cell.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

name="${1:-}"
if [ -z "$name" ]; then
    echo "Usage: make cell-rm NAME=<cell>" >&2
    exit 1
fi

target="$FLOW_HOME/cells/$name"
if [ ! -d "$target" ]; then
    echo "Cell not found: $target" >&2
    exit 1
fi

if [ -L "$FLOW_HOME/active-cell" ]; then
    active=$(readlink "$FLOW_HOME/active-cell")
    if [ "$active" = "$target" ]; then
        echo "Cannot remove active cell. Switch first with: make cell-use NAME=<other>" >&2
        exit 1
    fi
fi

# Refuse if there are uncommitted changes.
if [ -d "$target/.git" ]; then
    if ! git -C "$target" diff --quiet || ! git -C "$target" diff --cached --quiet; then
        echo "Cell has uncommitted changes. Commit or discard them first." >&2
        exit 1
    fi
fi

read -r -p "Remove cell '$name' permanently? (y/N) " ans
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "aborted"; exit 1; }
rm -rf "$target"

# Drop the plugin registration if present.
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"
plugin_id="${name}@local-dev"
if [ -f "$INSTALLED_JSON" ] && command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg id "$plugin_id" 'del(.plugins[$id])' "$INSTALLED_JSON" > "$tmp" && mv "$tmp" "$INSTALLED_JSON"
fi

echo "✓ Cell '$name' removed."
