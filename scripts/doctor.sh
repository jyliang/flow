#!/usr/bin/env bash
# Sanity check the Flow install: plugin registered + enabled, CLI on PATH,
# catalog readable, commands dir writable.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"
SETTINGS_JSON="$HOME/.claude/settings.json"
COMMANDS_DIR="${FLOW_COMMANDS_DIR:-$ROOT/commands}"

ok=0; fail=0
line() { printf "  %-26s %s\n" "$1" "$2"; }
pass() { line "$1" "ok${2:+ ($2)}"; ok=$((ok+1)); }
bad()  { line "$1" "FAIL${2:+ ($2)}"; fail=$((fail+1)); }

echo "Flow doctor"
echo

# CLI on PATH.
if command -v flow >/dev/null 2>&1; then pass "flow on PATH" "$(command -v flow)"
else bad "flow on PATH" "run: make install, then add the bin dir to PATH"; fi

# Plugin registered and pointing at this repo.
if command -v jq >/dev/null 2>&1 && [ -f "$INSTALLED_JSON" ]; then
  p="$(jq -r '.plugins["flow@flow"][0].installPath // empty' "$INSTALLED_JSON" 2>/dev/null)"
  if [ "$p" = "$ROOT" ]; then pass "flow@flow plugin" "→ $p"
  elif [ -n "$p" ]; then bad "flow@flow plugin" "registered at $p, repo is $ROOT"
  else bad "flow@flow plugin" "not registered — run: make install"; fi
  if [ -f "$SETTINGS_JSON" ]; then
    [ "$(jq -r '.enabledPlugins["flow@flow"] // false' "$SETTINGS_JSON" 2>/dev/null)" = "true" ] \
      && pass "plugin enabled" || bad "plugin enabled" "claude plugin enable flow@flow"
  fi
else
  line "flow@flow plugin" "skipped (jq not installed)"
fi

# Catalog + templates.
[ -d "$ROOT/doc-types" ] && pass "doc-type catalog" || bad "doc-type catalog"
[ -f "$ROOT/templates/protocol-spike.md" ] && pass "protocol templates" || bad "protocol templates"
dt_count=$(ls "$ROOT/doc-types"/*.md 2>/dev/null | grep -vc README || echo 0)
[ "$dt_count" -ge 6 ] && pass "catalog populated" "$dt_count doc-types" || bad "catalog populated" "$dt_count, expected ≥6"

# Commands dir writable + flow count.
mkdir -p "$COMMANDS_DIR" 2>/dev/null || true
[ -w "$COMMANDS_DIR" ] && pass "commands dir writable" || bad "commands dir writable" "$COMMANDS_DIR"
flow_count=$(ls "$COMMANDS_DIR"/*-spike.md 2>/dev/null | wc -l | tr -d ' ')
line "flows defined" "$flow_count"

command -v git >/dev/null 2>&1 && pass "git available" || bad "git available"
command -v gh  >/dev/null 2>&1 && pass "gh available"  || bad "gh available"

echo
if [ "$fail" -eq 0 ]; then echo "ready: yes"; exit 0
else echo "ready: no — $fail failure(s)"; exit 1; fi
