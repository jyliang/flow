#!/usr/bin/env bash
# Switch active cell: re-point ~/.flow/active-cell and re-link symlinks.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

name="${1:-}"
if [ -z "$name" ]; then
    echo "Usage: make cell-use NAME=<cell>" >&2
    exit 1
fi

target="$FLOW_HOME/cells/$name"
if [ ! -d "$target" ]; then
    echo "Cell not found: $target" >&2
    exit 1
fi

rm -f "$FLOW_HOME/active-cell"
ln -s "$target" "$FLOW_HOME/active-cell"

"$RUNTIME_ROOT/scripts/cell-link.sh"
echo "✓ Active cell: $name"
