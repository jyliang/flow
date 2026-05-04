#!/usr/bin/env bash
# Source .flow/config.sh (if present) and print normalized flow env vars.
# Precedence: environment > .flow/config.sh > built-in defaults.
# Honors the v1 legacy FLOW_TEMPLATE_DIR if FLOW_TEMPLATE_SPEC is unset.
#
# Usage: eval "$($HOME/.flow/runtime/skills/run/scripts/load-config.sh)"
#        or capture stdout KEY=VALUE lines directly.
# Exits: 0 success; non-zero if .flow/config.sh is malformed.

set -euo pipefail

env_template_spec="${FLOW_TEMPLATE_SPEC:-}"
env_stages="${FLOW_STAGES:-}"
env_test_cmd="${FLOW_TEST_CMD:-}"
env_extra="${FLOW_EXTRA_STAGES:-}"
env_hooks="${FLOW_HOOKS_DIR:-}"
legacy_dir="${FLOW_TEMPLATE_DIR:-}"

if [[ -f .flow/config.sh ]]; then
  # shellcheck disable=SC1091
  source .flow/config.sh
fi

[[ -n "$env_template_spec" ]] && FLOW_TEMPLATE_SPEC="$env_template_spec"
[[ -n "$env_stages" ]]        && FLOW_STAGES="$env_stages"
[[ -n "$env_test_cmd" ]]      && FLOW_TEST_CMD="$env_test_cmd"
[[ -n "$env_extra" ]]         && FLOW_EXTRA_STAGES="$env_extra"
[[ -n "$env_hooks" ]]         && FLOW_HOOKS_DIR="$env_hooks"

if [[ -z "${FLOW_TEMPLATE_SPEC:-}" ]] && [[ -n "$legacy_dir" ]]; then
  FLOW_TEMPLATE_SPEC="$legacy_dir/spec.md"
fi

FLOW_TEMPLATE_SPEC="${FLOW_TEMPLATE_SPEC:-$HOME/.claude/cells/code-pipeline/templates/spec.md}"
FLOW_STAGES="${FLOW_STAGES:-explore plan implement review ship}"
FLOW_TEST_CMD="${FLOW_TEST_CMD:-}"
FLOW_EXTRA_STAGES="${FLOW_EXTRA_STAGES:-}"
FLOW_HOOKS_DIR="${FLOW_HOOKS_DIR:-}"

printf 'FLOW_TEMPLATE_SPEC=%q\n' "$FLOW_TEMPLATE_SPEC"
printf 'FLOW_STAGES=%q\n' "$FLOW_STAGES"
printf 'FLOW_TEST_CMD=%q\n' "$FLOW_TEST_CMD"
printf 'FLOW_EXTRA_STAGES=%q\n' "$FLOW_EXTRA_STAGES"
printf 'FLOW_HOOKS_DIR=%q\n' "$FLOW_HOOKS_DIR"
