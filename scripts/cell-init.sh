#!/usr/bin/env bash
# cell-init.sh [STARTER] [NAME]
# Empty STARTER → scaffold an empty cell.
# STARTER given → copy <runtime>/cells/<STARTER>/ into ~/.flow/cells/<NAME>/, git init.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
RUNTIME_ROOT=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")

starter="${1:-}"
name="${2:-${starter}}"

if [ -z "$name" ]; then
    echo "Usage: make cell-init STARTER=<starter> NAME=<name>" >&2
    echo "   or: make cell-new NAME=<name>" >&2
    exit 1
fi

dest="$FLOW_HOME/cells/$name"
if [ -e "$dest" ]; then
    echo "Cell already exists: $dest" >&2
    exit 1
fi

mkdir -p "$FLOW_HOME/cells"

if [ -n "$starter" ]; then
    src="$RUNTIME_ROOT/cells/$starter"
    if [ ! -d "$src" ]; then
        echo "Starter not found: $src" >&2
        echo "Available starters:" >&2
        ls "$RUNTIME_ROOT/cells" 2>/dev/null | sed 's/^/  /' >&2
        exit 1
    fi
    cp -R "$src" "$dest"

    # If the new cell's name differs from the starter, rewrite the cell name
    # in both cell.yaml and .claude-plugin/plugin.json so Claude Code namespaces
    # this cell's skills as <name>:* (not <starter>:*, which would collide).
    if [ "$name" != "$starter" ]; then
        if [ -f "$dest/cell.yaml" ]; then
            sed -i.bak "s/^name: $starter\$/name: $name/" "$dest/cell.yaml" && rm -f "$dest/cell.yaml.bak"
        fi
        if [ -f "$dest/.claude-plugin/plugin.json" ] && command -v jq >/dev/null 2>&1; then
            tmp=$(mktemp)
            jq --arg n "$name" '.name = $n' "$dest/.claude-plugin/plugin.json" > "$tmp" && mv "$tmp" "$dest/.claude-plugin/plugin.json"
        fi
    fi
else
    mkdir -p "$dest/skills" "$dest/templates"
    cat > "$dest/cell.yaml" <<EOF
name: $name
version: 0.1.0
description: New empty cell
stages: []
delivery: ""
templates_dir: templates
EOF
    cat > "$dest/README.md" <<EOF
# $name

Empty cell scaffold. Add stage skills under \`skills/\` and define them in \`cell.yaml\`.
EOF
fi

cd "$dest"
if [ ! -d ".git" ]; then
    git init -q -b main
    git add -A
    git -c user.name="${GIT_AUTHOR_NAME:-flow}" \
        -c user.email="${GIT_AUTHOR_EMAIL:-flow@local}" \
        commit -q -m "init: $name cell from ${starter:-empty} starter"
fi

# First cell becomes active automatically.
if [ ! -L "$FLOW_HOME/active-cell" ]; then
    ln -s "$dest" "$FLOW_HOME/active-cell"
    "$RUNTIME_ROOT/scripts/cell-link.sh"
    echo "✓ Cell '$name' created and set active."
else
    echo "✓ Cell '$name' created (not active — \`make cell-use NAME=$name\` to switch)."
fi
