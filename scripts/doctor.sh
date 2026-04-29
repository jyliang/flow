#!/usr/bin/env bash
# Sanity check: kernel installed? ~/.flow/ provisioned? active cell resolves? git OK?

set -uo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"

ok=0
fail=0

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf "  %-22s ok\n" "$label:"
        ok=$((ok + 1))
    else
        printf "  %-22s FAIL\n" "$label:"
        fail=$((fail + 1))
    fi
}

echo "Flow doctor"
echo

check "kernel skills dir"   test -d "$SKILLS_DIR"
check "kernel commands dir" test -d "$COMMANDS_DIR"
check "~/.flow/ exists"     test -d "$FLOW_HOME"
check "runtime-path"        test -f "$FLOW_HOME/runtime-path"

# Verify each kernel skill is a live symlink into a present runtime.
runtime_path=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")
if [ -n "$runtime_path" ] && [ -d "$runtime_path" ]; then
    printf "  %-22s ok (%s)\n" "runtime location:" "$runtime_path"
    ok=$((ok + 1))
else
    printf "  %-22s FAIL (clone gone? re-run make install)\n" "runtime location:"
    fail=$((fail + 1))
fi

# Active cell
if [ -L "$FLOW_HOME/active-cell" ]; then
    if [ -d "$FLOW_HOME/active-cell" ]; then
        active=$(readlink "$FLOW_HOME/active-cell")
        printf "  %-22s %s\n" "active cell:" "$(basename "$active")"
    else
        printf "  %-22s DANGLING (active-cell symlink points nowhere)\n" "active cell:"
        fail=$((fail + 1))
    fi
else
    printf "  %-22s none (run /flow to set one up)\n" "active cell:"
fi

# Cell count
cell_count=$(ls "$FLOW_HOME/cells" 2>/dev/null | wc -l | tr -d ' ')
printf "  %-22s %s\n" "cells installed:" "$cell_count"

# git available
check "git available" command -v git
check "gh available"  command -v gh

echo
if [ "$fail" -eq 0 ]; then
    echo "ready: yes"
    exit 0
else
    echo "ready: no — $fail failure(s)"
    exit 1
fi
