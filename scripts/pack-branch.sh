#!/usr/bin/env bash
# Cut a branch in the pack repo for an edit. Reflect/ingest call this before mutating skills.
# pack-branch.sh <name|""> <branch>

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

name="${1:-}"
branch="${2:?BRANCH required}"

if [ -z "$name" ]; then
    if [ -L "$FLOW_HOME/active-pack" ]; then
        target=$(readlink "$FLOW_HOME/active-pack")
        name=$(basename "$target")
    else
        echo "No active pack and NAME not given." >&2
        exit 1
    fi
else
    target="$FLOW_HOME/packs/$name"
fi

if [ ! -d "$target/.git" ]; then
    echo "Not a pack repo: $target" >&2
    exit 1
fi

# Refuse if working tree is dirty (could blend an unrelated edit into the new branch).
if ! git -C "$target" diff --quiet || ! git -C "$target" diff --cached --quiet; then
    echo "Pack working tree is dirty. Commit or stash first." >&2
    git -C "$target" status -s
    exit 1
fi

git -C "$target" checkout -b "$branch"
echo "✓ Branch '$branch' cut in pack '$name'."
