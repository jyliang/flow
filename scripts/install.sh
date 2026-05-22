#!/usr/bin/env bash
# Install Flow (dev mode):
#   1. Register this repo as the `flow@flow` Claude Code plugin, so generated
#      flows surface under the /flow: namespace.
#   2. Put the `flow` CLI on PATH, so you can author flows.
#
# Claude Code only loads plugins whose @<marketplace> suffix matches a registered
# marketplace. We hook into the real `flow` marketplace (github.com/jyliang/flow):
# symlink its install location to this repo, register `flow@flow`. Same end state
# as `claude plugin install flow@flow`, but edits flow through live.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"
KNOWN_JSON="$PLUGINS_DIR/known_marketplaces.json"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces/flow"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"
NOW="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

mkdir -p "$PLUGINS_DIR/marketplaces" "$ROOT/commands"

# ---- 1. plugin registration (needs jq) ----
if command -v jq >/dev/null 2>&1; then
  # Point the marketplace install location at this repo (dev symlink).
  if [ -L "$MARKETPLACE_DIR" ]; then
    [ "$(readlink "$MARKETPLACE_DIR")" = "$ROOT" ] || { rm -f "$MARKETPLACE_DIR"; ln -s "$ROOT" "$MARKETPLACE_DIR"; }
  elif [ -d "$MARKETPLACE_DIR" ]; then
    mv "$MARKETPLACE_DIR" "$MARKETPLACE_DIR.bak.$(date +%s)"; ln -s "$ROOT" "$MARKETPLACE_DIR"
  else
    ln -s "$ROOT" "$MARKETPLACE_DIR"
  fi

  [ -f "$KNOWN_JSON" ] || echo '{}' > "$KNOWN_JSON"
  tmp="$(mktemp)"; jq --arg loc "$MARKETPLACE_DIR" --arg ts "$NOW" \
    '.flow = {source:{source:"github",repo:"jyliang/flow"},installLocation:$loc,lastUpdated:$ts}' \
    "$KNOWN_JSON" > "$tmp" && mv "$tmp" "$KNOWN_JSON"

  [ -f "$INSTALLED_JSON" ] || echo '{"version":2,"plugins":{}}' > "$INSTALLED_JSON"
  tmp="$(mktemp)"; jq --arg path "$ROOT" --arg ts "$NOW" \
    '.plugins["code-pipeline@flow"] = null
     | .plugins["flow@flow"] = [{scope:"user",installPath:$path,version:"dev",
         installedAt:((.plugins["flow@flow"][0].installedAt) // $ts),lastUpdated:$ts}]
     | .plugins |= with_entries(select(.value != null))' \
    "$INSTALLED_JSON" > "$tmp" && mv "$tmp" "$INSTALLED_JSON"

  if [ -f "$SETTINGS_JSON" ]; then
    tmp="$(mktemp)"; jq '.enabledPlugins["flow@flow"]=true
      | if .enabledPlugins["code-pipeline@flow"] then .enabledPlugins |= del(.["code-pipeline@flow"]) else . end' \
      "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
  fi
  echo "✓ plugin registered: flow@flow → $ROOT  (commands appear under /flow:)"
else
  echo "⚠  jq not found — skipped plugin registration. Install jq, then re-run, or"
  echo "   run: claude plugin marketplace add jyliang/flow && claude plugin install flow@flow"
fi

# ---- 2. CLI on PATH ----
pick_bindir() {
  local d
  for d in "$HOME/.local/bin" /opt/homebrew/bin /usr/local/bin "$HOME/bin"; do
    case ":$PATH:" in *":$d:"*) if [ -d "$d" ] && [ -w "$d" ]; then printf '%s\n' "$d"; return; fi ;; esac
  done
  printf '%s\n' "$HOME/.local/bin"
}
BINDIR="$(pick_bindir)"
mkdir -p "$BINDIR"
ln -sf "$ROOT/bin/flow" "$BINDIR/flow"
echo "✓ flow CLI linked: $BINDIR/flow → $ROOT/bin/flow"

case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) echo
     echo "  ⚠  $BINDIR is not on your PATH. Add it, e.g.:"
     echo "       echo 'export PATH=\"$BINDIR:\$PATH\"' >> ~/.zshrc && source ~/.zshrc" ;;
esac

echo
echo "Next: run 'flow new' to build your first flow, then /flow:<name>-step in Claude Code."
