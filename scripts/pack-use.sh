#!/usr/bin/env bash
# Switch active pack: re-point ~/.flow/active-pack and re-link symlinks.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

name="${1:-}"
if [ -z "$name" ]; then
    echo "Usage: make pack-use NAME=<pack>" >&2
    exit 1
fi

target="$FLOW_HOME/packs/$name"
if [ ! -d "$target" ]; then
    echo "Pack not found: $target" >&2
    exit 1
fi

rm -f "$FLOW_HOME/active-pack"
ln -s "$target" "$FLOW_HOME/active-pack"

"$RUNTIME_ROOT/scripts/pack-link.sh"
echo "✓ Active pack: $name"
