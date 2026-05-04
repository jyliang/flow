#!/usr/bin/env bash
# Install the flow kernel as a Claude Code plugin (dev mode).
#
# Claude Code only loads plugins whose `@<marketplace>` suffix matches a registered
# marketplace in ~/.claude/plugins/known_marketplaces.json. So we hook into the
# real `flow` marketplace (github.com/jyliang/flow): symlink its install location
# to the live dev repo, register `flow@flow` in installed_plugins.json. Dev edits
# flow through; same end state as `claude plugin install flow@flow`.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"
KNOWN_MARKETPLACES_JSON="$PLUGINS_DIR/known_marketplaces.json"
MARKETPLACES_DIR="$PLUGINS_DIR/marketplaces"
FLOW_MARKETPLACE_DIR="$MARKETPLACES_DIR/flow"
LEGACY_SKILLS_DIR="$CLAUDE_DIR/skills"
LEGACY_COMMANDS_DIR="$CLAUDE_DIR/commands"

PLUGIN_ID="flow@flow"
PLUGIN_VERSION="dev"

mkdir -p "$PLUGINS_DIR" "$MARKETPLACES_DIR"
mkdir -p "$FLOW_HOME/cells" "$FLOW_HOME/state" "$FLOW_HOME/tools"

echo "$RUNTIME_ROOT" > "$FLOW_HOME/runtime-path"

# Point the `flow` marketplace install location at the live dev repo. If a stale
# clone is present (from a prior `claude plugin marketplace add jyliang/flow`),
# move it aside so we don't overwrite user state.
now_iso=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
if [ -L "$FLOW_MARKETPLACE_DIR" ]; then
    current=$(readlink "$FLOW_MARKETPLACE_DIR")
    if [ "$current" != "$RUNTIME_ROOT" ]; then
        rm -f "$FLOW_MARKETPLACE_DIR"
        ln -s "$RUNTIME_ROOT" "$FLOW_MARKETPLACE_DIR"
        echo "  re-pointed marketplace symlink: $current → $RUNTIME_ROOT"
    fi
elif [ -d "$FLOW_MARKETPLACE_DIR" ]; then
    backup="$FLOW_MARKETPLACE_DIR.bak.$(date +%s)"
    mv "$FLOW_MARKETPLACE_DIR" "$backup"
    ln -s "$RUNTIME_ROOT" "$FLOW_MARKETPLACE_DIR"
    echo "  moved stale marketplace clone aside: $backup"
else
    ln -s "$RUNTIME_ROOT" "$FLOW_MARKETPLACE_DIR"
fi

# Ensure the marketplace is registered in known_marketplaces.json so Claude Code
# accepts `flow@flow` (and `<cell>@flow`) plugin keys.
if [ ! -f "$KNOWN_MARKETPLACES_JSON" ]; then
    echo '{}' > "$KNOWN_MARKETPLACES_JSON"
fi
tmp_km=$(mktemp)
jq --arg loc "$FLOW_MARKETPLACE_DIR" \
   --arg ts  "$now_iso" \
   '.flow = {
       source: { source: "github", repo: "jyliang/flow" },
       installLocation: $loc,
       lastUpdated: $ts
   }' "$KNOWN_MARKETPLACES_JSON" > "$tmp_km"
mv "$tmp_km" "$KNOWN_MARKETPLACES_JSON"

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
if [ ! -f "$INSTALLED_JSON" ]; then
    echo '{"version": 2, "plugins": {}}' > "$INSTALLED_JSON"
fi

# Migration: if a prior install used the synthetic `@local-dev` marketplace,
# drop those entries — they never loaded (Claude Code skips unknown marketplaces).
tmp_json=$(mktemp)
jq '.plugins = (.plugins | with_entries(
       if (.key | endswith("@local-dev")) then empty else . end
   ))' "$INSTALLED_JSON" > "$tmp_json"
mv "$tmp_json" "$INSTALLED_JSON"

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

# Enable the plugin in user settings. Plugins default to disabled — without
# this, `claude plugin list` shows the entry but the picker hides it.
SETTINGS_JSON="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_JSON" ]; then
    tmp_settings=$(mktemp)
    jq --arg id "$PLUGIN_ID" '.enabledPlugins[$id] = true' "$SETTINGS_JSON" > "$tmp_settings"
    mv "$tmp_settings" "$SETTINGS_JSON"
fi

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
