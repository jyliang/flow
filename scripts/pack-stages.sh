#!/usr/bin/env bash
# Read the active pack's manifest and emit one line per stage:
#   <name>|<output>|<next>
#
# Reads ~/.flow/active-pack/pack.yaml unless PACK_YAML is set.
# Output is consumed by detect-stage.sh; keep the format stable.
#
# Parser is intentionally minimal: handles the constrained pack.yaml shape
# this runtime produces (list of "- key: value" blocks under `stages:`).
# For richer YAML, swap this for a python or yq call.

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
yaml="${PACK_YAML:-$FLOW_HOME/active-pack/pack.yaml}"

if [ ! -f "$yaml" ]; then
    echo "pack-stages: manifest not found at $yaml" >&2
    exit 1
fi

awk '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  function strip_comment(s) { sub(/[ \t]+#.*$/, "", s); return s }
  function set_field(key, val) {
    val = strip_comment(val)
    if (key == "name") name = val
    else if (key == "output") output = val
    else if (key == "next") nxt = val
  }
  function parse_kv(line,    pos, key, val) {
    pos = index(line, ":")
    if (pos == 0) return
    key = substr(line, 1, pos - 1)
    val = trim(substr(line, pos + 1))
    set_field(key, val)
  }
  function emit() {
    if (name != "") print name "|" output "|" nxt
    name = ""; output = ""; nxt = ""
  }
  /^stages:[ \t]*$/ { in_stages = 1; next }
  in_stages && /^[A-Za-z]/ { emit(); in_stages = 0; next }
  in_stages && /^[ \t]*-[ \t]+/ {
    emit()
    line = $0
    sub(/^[ \t]*-[ \t]+/, "", line)
    parse_kv(line)
    next
  }
  in_stages && /^[ \t]+[A-Za-z_]+[ \t]*:/ {
    parse_kv(trim($0))
  }
  END { emit() }
' "$yaml"
