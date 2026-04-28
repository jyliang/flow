#!/usr/bin/env bash
# Install the kernel into ~/.claude/ and provision ~/.flow/.
# Symlinks (not copies) so runtime updates flow through without re-running install.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"

mkdir -p "$SKILLS_DIR" "$COMMANDS_DIR"
mkdir -p "$FLOW_HOME/packs" "$FLOW_HOME/state" "$FLOW_HOME/tools"

echo "$RUNTIME_ROOT" > "$FLOW_HOME/runtime-path"

# Symlink kernel skills.
skill_count=0
for dir in "$RUNTIME_ROOT/skills"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    target="$SKILLS_DIR/$name"
    if [ -L "$target" ] || [ -e "$target" ]; then
        rm -rf "$target"
    fi
    ln -s "$dir" "$target"
    skill_count=$((skill_count + 1))
done

# Symlink slash commands.
cmd_count=0
for f in "$RUNTIME_ROOT/commands"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    target="$COMMANDS_DIR/$name"
    if [ -L "$target" ] || [ -e "$target" ]; then
        rm -f "$target"
    fi
    ln -s "$f" "$target"
    cmd_count=$((cmd_count + 1))
done

# Copy shared Pack.mk so packs can import it without depending on runtime path.
cp "$RUNTIME_ROOT/tools/Pack.mk" "$FLOW_HOME/tools/Pack.mk" 2>/dev/null || true

cat <<EOF
✓ Kernel installed ($skill_count skills, $cmd_count commands symlinked)
✓ ~/.flow/ provisioned
✓ No skills installed yet — flow is an empty shell.

Next: run /flow in any project to set up your first pack.
EOF
