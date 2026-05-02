#!/usr/bin/env bash
# Install the active cell as a Claude Code plugin (dev mode).
#
# Cell skills appear in the picker namespaced as <cell-name>:<skill-name>
# (e.g. code-pipeline:explore). Same end state as a marketplace install —
# but pointed at the live cell repo so edits flow through.
#
# If the cell lacks a .claude-plugin/plugin.json, this script auto-generates
# one from cell.yaml so the cell can be loaded as a plugin.
#
# Idempotent: removes any prior plugin registration for cells under
# ~/.flow/cells/ that no longer match the active cell.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"
LEGACY_SKILLS_DIR="$CLAUDE_DIR/skills"

if [ ! -L "$FLOW_HOME/active-cell" ]; then
    echo "No active cell." >&2
    exit 1
fi

active_path=$(readlink "$FLOW_HOME/active-cell")
cell_name=$(basename "$active_path")

# Legacy cleanup: remove bare-name symlinks under ~/.claude/skills/ that point
# into ~/.flow/cells/ or ~/.flow/active-cell/. Predates namespacing.
legacy_cleaned=0
if [ -d "$LEGACY_SKILLS_DIR" ]; then
    for entry in "$LEGACY_SKILLS_DIR"/*; do
        [ -L "$entry" ] || continue
        target=$(readlink "$entry")
        case "$target" in
            "$FLOW_HOME"/cells/*|"$FLOW_HOME/active-cell"/*)
                rm -f "$entry"
                legacy_cleaned=$((legacy_cleaned + 1))
                ;;
        esac
    done
fi

# Ensure the cell has a plugin manifest with `name` matching the cell directory.
# Auto-generate from cell.yaml if missing; rewrite the `name` field if stale
# (e.g. cell was forked from a starter and inherited the starter's name —
# leaving it would namespace this cell's skills under the starter's name and
# collide with the starter cell).
manifest_dir="$active_path/.claude-plugin"
manifest="$manifest_dir/plugin.json"
if [ ! -f "$manifest" ]; then
    mkdir -p "$manifest_dir"
    cell_version=$(grep '^version:' "$active_path/cell.yaml" 2>/dev/null | head -1 | sed 's/version:[[:space:]]*//' | tr -d '"' || echo "0.1.0")
    cell_desc=$(grep '^description:' "$active_path/cell.yaml" 2>/dev/null | head -1 | sed 's/description:[[:space:]]*//' | tr -d '"' || echo "Flow cell")
    cat > "$manifest" <<EOF
{
  "name": "$cell_name",
  "version": "${cell_version:-0.1.0}",
  "description": "${cell_desc:-Flow cell}"
}
EOF
    echo "  generated $manifest"
elif command -v jq >/dev/null 2>&1; then
    manifest_name=$(jq -r '.name // empty' "$manifest" 2>/dev/null || echo "")
    if [ -n "$manifest_name" ] && [ "$manifest_name" != "$cell_name" ]; then
        tmp=$(mktemp)
        jq --arg n "$cell_name" '.name = $n' "$manifest" > "$tmp" && mv "$tmp" "$manifest"
        echo "  fixed $manifest (name: $manifest_name → $cell_name)"
    fi
fi

# Make sure installed_plugins.json exists.
mkdir -p "$PLUGINS_DIR"
if [ ! -f "$INSTALLED_JSON" ]; then
    echo '{"version": 2, "plugins": {}}' > "$INSTALLED_JSON"
fi

now_iso=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
plugin_id="${cell_name}@local-dev"

# Remove any other cell plugin entries under @local-dev that point into ~/.flow/cells/
# (so switching cells doesn't leave stale entries). Then upsert the active one.
tmp_json=$(mktemp)
jq --arg keep "$plugin_id" \
   --arg flow_cells "$FLOW_HOME/cells" \
   '.plugins = (
       .plugins | with_entries(
           if (.key | endswith("@local-dev")) and (.key != $keep) and (.key != "flow@local-dev")
              and ((.value[0].installPath // "") | startswith($flow_cells))
           then empty else . end
       )
   )' "$INSTALLED_JSON" > "$tmp_json"
mv "$tmp_json" "$INSTALLED_JSON"

tmp_json=$(mktemp)
jq --arg id "$plugin_id" \
   --arg path "$active_path" \
   --arg ts  "$now_iso" \
   '.plugins[$id] = [{
       scope: "user",
       installPath: $path,
       version: "dev",
       installedAt: (.plugins[$id][0].installedAt // $ts),
       lastUpdated: $ts
   }]' "$INSTALLED_JSON" > "$tmp_json"
mv "$tmp_json" "$INSTALLED_JSON"

# Count cell skills for the summary.
skill_count=0
if [ -d "$active_path/skills" ]; then
    for d in "$active_path/skills"/*; do
        [ -d "$d" ] || continue
        skill_count=$((skill_count + 1))
    done
fi

echo "✓ Active cell '$cell_name' installed as plugin '$plugin_id' ($skill_count skills, namespaced as ${cell_name}:*)"
if [ "$legacy_cleaned" -gt 0 ]; then
    echo "✓ Removed $legacy_cleaned legacy bare-name symlink(s) from ~/.claude/skills/"
fi
