#!/usr/bin/env bash
# Link the active pack's skills into ~/.claude/skills/.
# Idempotent: removes any prior pack-symlinks first.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
SKILLS_DIR="$HOME/.claude/skills"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

if [ ! -L "$FLOW_HOME/active-pack" ]; then
    echo "No active pack." >&2
    exit 1
fi

active="$FLOW_HOME/active-pack"

# Build a set of kernel skill names to avoid clobbering them.
kernel_names=""
if [ -n "$RUNTIME_ROOT" ] && [ -d "$RUNTIME_ROOT/skills" ]; then
    for d in "$RUNTIME_ROOT/skills"/*; do
        [ -d "$d" ] || continue
        kernel_names="$kernel_names $(basename "$d")"
    done
fi

# Unlink any existing symlinks under ~/.claude/skills/ that point into ~/.flow/packs/.
for entry in "$SKILLS_DIR"/*; do
    [ -L "$entry" ] || continue
    target=$(readlink "$entry")
    case "$target" in
        "$FLOW_HOME"/packs/*|"$FLOW_HOME/active-pack"/*)
            rm -f "$entry"
            ;;
    esac
done

# Link each pack skill in.
linked=0
for dir in "$active/skills"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    # Skip if a kernel skill with this name exists.
    if echo " $kernel_names " | grep -q " $name "; then
        echo "  skip $name (kernel skill exists)" >&2
        continue
    fi
    target="$SKILLS_DIR/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  skip $name (real file/dir exists at $target)" >&2
        continue
    fi
    rm -f "$target"
    ln -s "$dir" "$target"
    linked=$((linked + 1))
done

echo "Linked $linked pack skill(s) from $(basename "$(readlink "$active")")."
