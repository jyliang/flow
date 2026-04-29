#!/usr/bin/env bash
# Per-cell git operations: status, link-remote, pull, push.
# cell-git.sh <op> <name|""> [extra args...]

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

op="${1:?op required}"
name="${2:-}"

if [ -z "$name" ]; then
    if [ -L "$FLOW_HOME/active-cell" ]; then
        target=$(readlink "$FLOW_HOME/active-cell")
        name=$(basename "$target")
    else
        echo "No active cell and NAME not given." >&2
        exit 1
    fi
else
    target="$FLOW_HOME/cells/$name"
fi

if [ ! -d "$target/.git" ]; then
    echo "Not a cell repo: $target" >&2
    exit 1
fi

case "$op" in
    status)
        echo "[$name]"
        git -C "$target" status -sb
        ;;
    link-remote)
        url="${3:?URL required}"
        if git -C "$target" remote get-url origin >/dev/null 2>&1; then
            git -C "$target" remote set-url origin "$url"
        else
            git -C "$target" remote add origin "$url"
        fi
        echo "✓ origin set to $url for cell '$name'"
        ;;
    pull)
        git -C "$target" pull --ff-only
        ;;
    push)
        git -C "$target" push -u origin HEAD
        ;;
    *)
        echo "Unknown op: $op" >&2
        exit 1
        ;;
esac
