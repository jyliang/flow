#!/usr/bin/env bash
# Install the flow kernel as a Claude Code plugin (dev mode).
#
# Registers the live repo as an installed plugin in ~/.claude/plugins/installed_plugins.json
# under the synthetic marketplace `local-dev`. Claude Code discovers the plugin via
# the manifest at .claude-plugin/plugin.json and namespaces its skills/commands as
# `flow:*` — identical end state to a marketplace install, but pointed at the live
# repo so dev edits flow through without re-running install.
#
# End users should install via marketplace instead:
#   claude plugin marketplace add jyliang/flow
#   claude plugin install flow@flow

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"
LEGACY_SKILLS_DIR="$CLAUDE_DIR/skills"
LEGACY_COMMANDS_DIR="$CLAUDE_DIR/commands"

PLUGIN_ID="flow@local-dev"
PLUGIN_VERSION="dev"

mkdir -p "$PLUGINS_DIR"
mkdir -p "$FLOW_HOME/cells" "$FLOW_HOME/state" "$FLOW_HOME/tools"

echo "$RUNTIME_ROOT" > "$FLOW_HOME/runtime-path"

# Stable symlink to the runtime so command bodies and stage skills can reference
# scripts/templates by a fixed path: $HOME/.flow/runtime/skills/run/scripts/...
# (Pre-namespacing, these used $HOME/.claude/skills/run/... — no longer valid
# now that the kernel is installed as a plugin, not symlinked into ~/.claude/.)
rm -f "$FLOW_HOME/runtime"
ln -s "$RUNTIME_ROOT" "$FLOW_HOME/runtime"

# Read kernel skill + command names for legacy cleanup.
kernel_skills=()
for dir in "$RUNTIME_ROOT/skills"/*; do
    [ -d "$dir" ] || continue
    kernel_skills+=("$(basename "$dir")")
done

kernel_commands=()
for f in "$RUNTIME_ROOT/commands"/*.md; do
    [ -f "$f" ] || continue
    kernel_commands+=("$(basename "$f")")
done

# Legacy cleanup: remove bare-name symlinks in ~/.claude/skills/ and ~/.claude/commands/
# that point into this repo. Pre-namespacing installs put them there.
legacy_cleaned=0
if [ -d "$LEGACY_SKILLS_DIR" ]; then
    for entry in "$LEGACY_SKILLS_DIR"/*; do
        [ -L "$entry" ] || continue
        target=$(readlink "$entry")
        case "$target" in
            "$RUNTIME_ROOT"/skills/*)
                rm -f "$entry"
                legacy_cleaned=$((legacy_cleaned + 1))
                ;;
        esac
    done
fi
if [ -d "$LEGACY_COMMANDS_DIR" ]; then
    # Old install symlinked commands by their source filename. Source files have
    # since been renamed (flow-here.md → here.md, flow-spike.md → spike.md), so
    # also clean up the legacy names if they still point here.
    legacy_command_names=("flow-here.md" "flow-spike.md" "${kernel_commands[@]}")
    for name in "${legacy_command_names[@]}"; do
        target_file="$LEGACY_COMMANDS_DIR/$name"
        [ -L "$target_file" ] || continue
        target=$(readlink "$target_file")
        case "$target" in
            "$RUNTIME_ROOT"/commands/*)
                rm -f "$target_file"
                legacy_cleaned=$((legacy_cleaned + 1))
                ;;
        esac
    done
fi

# Register (or update) the plugin entry in installed_plugins.json.
# Schema mirrors what `claude plugin install` writes for marketplace plugins.
now_iso=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
if [ ! -f "$INSTALLED_JSON" ]; then
    echo '{"version": 2, "plugins": {}}' > "$INSTALLED_JSON"
fi

tmp_json=$(mktemp)
jq --arg id "$PLUGIN_ID" \
   --arg path "$RUNTIME_ROOT" \
   --arg ver "$PLUGIN_VERSION" \
   --arg ts  "$now_iso" \
   '.plugins[$id] = [{
       scope: "user",
       installPath: $path,
       version: $ver,
       installedAt: (.plugins[$id][0].installedAt // $ts),
       lastUpdated: $ts
   }]' "$INSTALLED_JSON" > "$tmp_json"
mv "$tmp_json" "$INSTALLED_JSON"

# Copy shared Cell.mk so cells can import it without depending on runtime path.
cp "$RUNTIME_ROOT/tools/Cell.mk" "$FLOW_HOME/tools/Cell.mk" 2>/dev/null || true

skill_count=${#kernel_skills[@]}
cmd_count=${#kernel_commands[@]}

cat <<EOF
✓ Kernel installed as plugin '$PLUGIN_ID'
  → installPath: $RUNTIME_ROOT
  → $skill_count skills, $cmd_count commands (namespaced as flow:*)
  → live edits flow through — no re-install needed for kernel changes
✓ ~/.flow/ provisioned
EOF

if [ "$legacy_cleaned" -gt 0 ]; then
    echo "✓ Removed $legacy_cleaned legacy bare-name symlink(s) from ~/.claude/{skills,commands}/"
fi

cat <<EOF

Active cell: $(test -L "$FLOW_HOME/active-cell" && basename "$(readlink "$FLOW_HOME/active-cell")" || echo "none")

Next: run /flow:flow in any project to set up your first cell.
EOF
