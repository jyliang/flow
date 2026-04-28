#!/usr/bin/env bash
# pack-init.sh [STARTER] [NAME]
# Empty STARTER → scaffold an empty pack.
# STARTER given → copy <runtime>/packs/<STARTER>/ into ~/.flow/packs/<NAME>/, git init.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

starter="${1:-}"
name="${2:-${starter}}"

if [ -z "$name" ]; then
    echo "Usage: make pack-init STARTER=<starter> NAME=<name>" >&2
    echo "   or: make pack-new NAME=<name>" >&2
    exit 1
fi

dest="$FLOW_HOME/packs/$name"
if [ -e "$dest" ]; then
    echo "Pack already exists: $dest" >&2
    exit 1
fi

mkdir -p "$FLOW_HOME/packs"

if [ -n "$starter" ]; then
    src="$RUNTIME_ROOT/packs/$starter"
    if [ ! -d "$src" ]; then
        echo "Starter not found: $src" >&2
        echo "Available starters:" >&2
        ls "$RUNTIME_ROOT/packs" 2>/dev/null | sed 's/^/  /' >&2
        exit 1
    fi
    cp -R "$src" "$dest"
else
    mkdir -p "$dest/skills" "$dest/templates"
    cat > "$dest/pack.yaml" <<EOF
name: $name
version: 0.1.0
description: New empty pack
stages: []
delivery: ""
templates_dir: templates
EOF
    cat > "$dest/README.md" <<EOF
# $name

Empty pack scaffold. Add stage skills under \`skills/\` and define them in \`pack.yaml\`.
EOF
fi

cd "$dest"
if [ ! -d ".git" ]; then
    git init -q -b main
    git add -A
    git -c user.name="${GIT_AUTHOR_NAME:-flow}" \
        -c user.email="${GIT_AUTHOR_EMAIL:-flow@local}" \
        commit -q -m "init: $name pack from ${starter:-empty} starter"
fi

# First pack becomes active automatically.
if [ ! -L "$FLOW_HOME/active-pack" ]; then
    ln -s "$dest" "$FLOW_HOME/active-pack"
    "$RUNTIME_ROOT/scripts/pack-link.sh"
    echo "✓ Pack '$name' created and set active."
else
    echo "✓ Pack '$name' created (not active — \`make pack-use NAME=$name\` to switch)."
fi
