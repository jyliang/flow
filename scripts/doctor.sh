#!/usr/bin/env bash
# Sanity check: kernel installed as plugin? ~/.flow/ provisioned? active cell registered? git OK?

set -uo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"

ok=0
fail=0

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf "  %-26s ok\n" "$label:"
        ok=$((ok + 1))
    else
        printf "  %-26s FAIL\n" "$label:"
        fail=$((fail + 1))
    fi
}

echo "Flow doctor"
echo

check "~/.flow/ exists"          test -d "$FLOW_HOME"
check "runtime-path"             test -f "$FLOW_HOME/runtime-path"
check "installed_plugins.json"   test -f "$INSTALLED_JSON"

# Verify runtime path exists.
runtime_path=$(cat "$FLOW_HOME/runtime-path" 2>/dev/null || echo "")
if [ -n "$runtime_path" ] && [ -d "$runtime_path" ]; then
    printf "  %-26s ok (%s)\n" "runtime location:" "$runtime_path"
    ok=$((ok + 1))
else
    printf "  %-26s FAIL (clone gone? re-run make install)\n" "runtime location:"
    fail=$((fail + 1))
fi

# Verify the `flow` marketplace is registered (Claude Code drops plugin entries
# whose @suffix isn't a known marketplace).
KNOWN_MARKETPLACES_JSON="$HOME/.claude/plugins/known_marketplaces.json"
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/flow"
if command -v jq >/dev/null 2>&1 && [ -f "$KNOWN_MARKETPLACES_JSON" ]; then
    mp_loc=$(jq -r '.flow.installLocation // empty' "$KNOWN_MARKETPLACES_JSON" 2>/dev/null)
    if [ -n "$mp_loc" ]; then
        printf "  %-26s ok (%s)\n" "flow marketplace:" "$mp_loc"
        ok=$((ok + 1))
    else
        printf "  %-26s FAIL (not in known_marketplaces.json — re-run make install)\n" "flow marketplace:"
        fail=$((fail + 1))
    fi
fi
if [ -L "$MARKETPLACE_DIR" ]; then
    mp_target=$(readlink "$MARKETPLACE_DIR")
    if [ "$mp_target" = "$runtime_path" ]; then
        printf "  %-26s ok (→ runtime)\n" "marketplace symlink:"
        ok=$((ok + 1))
    else
        printf "  %-26s STALE (→ %s, runtime is %s)\n" "marketplace symlink:" "$mp_target" "$runtime_path"
        fail=$((fail + 1))
    fi
elif [ -d "$MARKETPLACE_DIR" ]; then
    printf "  %-26s WARN (clone, not symlink — dev edits won't flow through)\n" "marketplace symlink:"
fi

# Verify the kernel plugin is registered and points at the runtime.
SETTINGS_JSON="$HOME/.claude/settings.json"
if command -v jq >/dev/null 2>&1 && [ -f "$INSTALLED_JSON" ]; then
    kernel_path=$(jq -r '.plugins["flow@flow"][0].installPath // empty' "$INSTALLED_JSON" 2>/dev/null)
    if [ -n "$kernel_path" ] && [ "$kernel_path" = "$runtime_path" ]; then
        printf "  %-26s ok (flow@flow → %s)\n" "kernel plugin:" "$kernel_path"
        ok=$((ok + 1))
    elif [ -n "$kernel_path" ]; then
        printf "  %-26s STALE (registered at %s, runtime is %s)\n" "kernel plugin:" "$kernel_path" "$runtime_path"
        fail=$((fail + 1))
    else
        printf "  %-26s FAIL (not registered — re-run make install)\n" "kernel plugin:"
        fail=$((fail + 1))
    fi

    if [ -f "$SETTINGS_JSON" ]; then
        kernel_enabled=$(jq -r '.enabledPlugins["flow@flow"] // false' "$SETTINGS_JSON" 2>/dev/null)
        if [ "$kernel_enabled" = "true" ]; then
            printf "  %-26s ok (enabled)\n" "kernel plugin enabled:"
            ok=$((ok + 1))
        else
            printf "  %-26s FAIL (disabled — run: claude plugin enable flow@flow)\n" "kernel plugin enabled:"
            fail=$((fail + 1))
        fi
    fi
fi

# Active cell.
if [ -L "$FLOW_HOME/active-cell" ]; then
    if [ -d "$FLOW_HOME/active-cell" ]; then
        active=$(readlink "$FLOW_HOME/active-cell")
        active_name=$(basename "$active")
        printf "  %-26s %s\n" "active cell:" "$active_name"
        # Verify the active cell is registered as a plugin.
        if command -v jq >/dev/null 2>&1 && [ -f "$INSTALLED_JSON" ]; then
            cell_id="${active_name}@flow"
            cell_path=$(jq -r --arg id "$cell_id" '.plugins[$id][0].installPath // empty' "$INSTALLED_JSON" 2>/dev/null)
            if [ -n "$cell_path" ] && [ "$cell_path" = "$active" ]; then
                printf "  %-26s ok (%s → %s)\n" "active cell plugin:" "$cell_id" "$cell_path"
                ok=$((ok + 1))
            else
                printf "  %-26s FAIL (run: make cell-use NAME=%s)\n" "active cell plugin:" "$active_name"
                fail=$((fail + 1))
            fi
            if [ -f "$SETTINGS_JSON" ]; then
                cell_enabled=$(jq -r --arg id "$cell_id" '.enabledPlugins[$id] // false' "$SETTINGS_JSON" 2>/dev/null)
                if [ "$cell_enabled" = "true" ]; then
                    printf "  %-26s ok (enabled)\n" "active cell enabled:"
                    ok=$((ok + 1))
                else
                    printf "  %-26s FAIL (disabled — run: claude plugin enable %s)\n" "active cell enabled:" "$cell_id"
                    fail=$((fail + 1))
                fi
            fi
        fi
    else
        printf "  %-26s DANGLING (active-cell symlink points nowhere)\n" "active cell:"
        fail=$((fail + 1))
    fi
else
    printf "  %-26s none (run /flow:flow to set one up)\n" "active cell:"
fi

# Cell count.
cell_count=$(ls "$FLOW_HOME/cells" 2>/dev/null | wc -l | tr -d ' ')
printf "  %-26s %s\n" "cells installed:" "$cell_count"

check "git available" command -v git
check "gh available"  command -v gh
check "jq available"  command -v jq

echo
if [ "$fail" -eq 0 ]; then
    echo "ready: yes"
    exit 0
else
    echo "ready: no — $fail failure(s)"
    exit 1
fi
