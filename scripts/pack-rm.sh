#!/usr/bin/env bash
# Remove a pack. Refuses if it's the active pack.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

name="${1:-}"
if [ -z "$name" ]; then
    echo "Usage: make pack-rm NAME=<pack>" >&2
    exit 1
fi

target="$FLOW_HOME/packs/$name"
if [ ! -d "$target" ]; then
    echo "Pack not found: $target" >&2
    exit 1
fi

if [ -L "$FLOW_HOME/active-pack" ]; then
    active=$(readlink "$FLOW_HOME/active-pack")
    if [ "$active" = "$target" ]; then
        echo "Cannot remove active pack. Switch first with: make pack-use NAME=<other>" >&2
        exit 1
    fi
fi

# Refuse if there are uncommitted changes.
if [ -d "$target/.git" ]; then
    if ! git -C "$target" diff --quiet || ! git -C "$target" diff --cached --quiet; then
        echo "Pack has uncommitted changes. Commit or discard them first." >&2
        exit 1
    fi
fi

read -r -p "Remove pack '$name' permanently? (y/N) " ans
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "aborted"; exit 1; }
rm -rf "$target"
echo "✓ Pack '$name' removed."
