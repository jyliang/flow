#!/usr/bin/env bash
#
# Test suite for the flow CLI. Self-contained — no bats, no dependencies beyond
# what flow itself needs. Each test runs in an isolated sandbox (its own skills
# dir, commands dir, and working directory) so nothing touches your real install.
#
# Run with:  make test   (or:  bash tests/run.sh)

set -uo pipefail   # NOT -e: tests deliberately run commands that fail.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW="$REPO/bin/flow"

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no() { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; return 0; }

assert_eq()           { [ "$1" = "$2" ] && ok "$3" || no "$3" "expected [$1], got [$2]"; }
assert_contains()     { case "$1" in *"$2"*) ok "$3" ;; *) no "$3" "missing substring: $2" ;; esac; }
assert_not_contains() { case "$1" in *"$2"*) no "$3" "should not contain: $2" ;; *) ok "$3" ;; esac; }
assert_file()         { [ -f "$1" ] && ok "$2" || no "$2" "missing file: $1"; }
assert_nofile()       { [ ! -f "$1" ] && ok "$2" || no "$2" "file should be gone: $1"; }
assert_rc0()          { [ "$RC" -eq 0 ] && ok "$1" || no "$1" "exit $RC; output: $OUT"; }
assert_rcN()          { [ "$RC" -ne 0 ] && ok "$1" || no "$1" "expected nonzero exit; output: $OUT"; }

# run CMD... → captures combined output in OUT, exit code in RC.
run() { OUT="$("$@" 2>&1)"; RC=$?; }

# Fresh sandbox: skills dir with three fake skills, an empty commands dir,
# and a clean working directory. Exports the env flow reads.
sandbox() {
  SB="$(mktemp -d)"
  mkdir -p "$SB/skills/explore" "$SB/skills/plan" "$SB/skills/review" "$SB/commands"
  local s
  for s in explore plan review; do
    printf -- '---\nname: %s\ndescription: the %s skill\n---\n' "$s" "$s" > "$SB/skills/$s/SKILL.md"
  done
  export FLOW_SKILLS_DIR="$SB/skills" FLOW_COMMANDS_DIR="$SB/commands"
  cd "$SB"
}

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------

t_new_noninteractive() {
  section "flow new — non-interactive"
  sandbox
  run "$FLOW" new --name build-feature --step explore::spec --step plan::plan --step review::findings --yes
  assert_rc0 "exits 0"
  assert_file "$SB/commands/build-feature-spike.md" "writes <name>-spike.md"
  assert_file "$SB/commands/build-feature-step.md"  "writes <name>-step.md"
  assert_contains "$OUT" "/flow:build-feature-spike" "prints /flow: invocation"
}

t_spike_content() {
  section "generated spike command — content"
  sandbox
  "$FLOW" new --name bf --step explore::spec --step plan::plan --step review::findings --yes >/dev/null 2>&1
  local c; c="$(cat "$SB/commands/bf-spike.md")"
  assert_contains "$c" "description: Run the bf flow end-to-end" "command-style frontmatter (description)"
  case "$c" in *$'\nname: '*) no "no skill-style name: field" "found a name: field" ;; *) ok "no skill-style name: field" ;; esac
  assert_contains "$c" "<!-- FLOW-SPEC v1" "embeds FLOW-SPEC block"
  assert_contains "$c" "flow=bf"           "FLOW-SPEC flow="
  assert_contains "$c" "mode=spike"        "FLOW-SPEC mode=spike"
  assert_contains "$c" "step=explore::spec"   "FLOW-SPEC step 1"
  assert_contains "$c" "step=review::findings" "FLOW-SPEC step 3"
  assert_contains "$c" "spike** mode"      "uses the spike protocol"
  assert_contains "$c" "### spike-log"     "spike injects the spike-log contract"
  assert_contains "$c" "### spec"          "inlines the spec contract"
  assert_contains "$c" "# Spec: <subject>" "inlines the spec template body"
  assert_contains "$c" "| 01 | \`explore\` | \`spec\` |" "renders the chain table"
}

t_step_content() {
  section "generated step command — content"
  sandbox
  "$FLOW" new --name bf --step explore::spec --step plan::plan --yes >/dev/null 2>&1
  local c; c="$(cat "$SB/commands/bf-step.md")"
  assert_contains "$c" "step** mode"        "uses the step protocol"
  assert_contains "$c" "Yes, advance"       "step protocol offers Yes/Adjust/Pause"
  assert_not_contains "$c" "### spike-log"  "step does NOT inject spike-log when unchained"
}

t_html_and_fences() {
  section "doc-type extraction — fences & html-aware"
  sandbox
  "$FLOW" new --name rel --step explore::change-summary --yes >/dev/null 2>&1
  local c; c="$(cat "$SB/commands/rel-spike.md")"
  assert_contains "$c" '```bash' "preserves an inner fenced block from the template"
  assert_contains "$c" "### change-summary" "inlines the change-summary contract"
}

t_new_interactive() {
  section "flow new — interactive (piped)"
  sandbox
  # name=demo; explore(1)→spec(5); plan(2)→plan(4); finish
  OUT="$(printf '%s\n' demo 1 5 2 4 '' | "$FLOW" new 2>&1)"; RC=$?
  assert_rc0 "interactive wizard exits 0"
  assert_file "$SB/commands/demo-spike.md" "wizard writes spike command"
  local c; c="$(cat "$SB/commands/demo-spike.md")"
  assert_contains "$c" "step=explore::spec" "wizard captured step 1"
  assert_contains "$c" "step=plan::plan"    "wizard captured step 2"
}

t_new_guards() {
  section "flow new — guard rails"
  sandbox
  run "$FLOW" new --name "Bad Name" --step explore::spec --yes
  assert_rcN "rejects invalid name"
  assert_contains "$OUT" "invalid flow name" "explains invalid name"

  run "$FLOW" new --name x --step explore::nope --yes
  assert_rcN "rejects unknown doc-type"
  assert_contains "$OUT" "unknown doc-type" "explains unknown doc-type"

  run "$FLOW" new --name x --step explorespec --yes
  assert_rcN "rejects malformed step (no ::)"

  "$FLOW" new --name dup --step explore::spec --yes >/dev/null 2>&1
  run "$FLOW" new --name dup --step explore::spec --yes
  assert_rcN "rejects duplicate flow"
  assert_contains "$OUT" "already exists" "explains duplicate"
}

t_list() {
  section "flow list"
  sandbox
  run "$FLOW" list
  assert_contains "$OUT" "No flows defined yet" "empty list message"

  "$FLOW" new --name a --step explore::spec --step plan::plan --yes >/dev/null 2>&1
  run "$FLOW" list
  assert_contains "$OUT" "a " "lists the flow name"
  assert_contains "$OUT" "[spike, step]" "shows both modes"
  assert_contains "$OUT" "explore→spec" "shows the chain"
}

t_doctypes() {
  section "flow list --doc-types"
  sandbox
  run "$FLOW" list --doc-types
  assert_rc0 "exits 0"
  local d
  for d in spec plan findings decision-record spike-log change-summary; do
    assert_contains "$OUT" "$d" "catalog lists $d"
  done
}

t_edit() {
  section "flow edit"
  sandbox
  "$FLOW" new --name e --step explore::spec --step plan::plan --yes >/dev/null 2>&1
  run "$FLOW" edit e --step explore::spec --step review::findings
  assert_rc0 "edit exits 0"
  local c; c="$(cat "$SB/commands/e-spike.md")"
  assert_contains "$c" "step=review::findings" "edit applied the new chain"
  assert_not_contains "$c" "step=plan::plan"    "edit dropped the removed step"

  run "$FLOW" edit does-not-exist
  assert_rcN "edit of unknown flow fails"
}

t_rm() {
  section "flow rm"
  sandbox
  "$FLOW" new --name r --step explore::spec --yes >/dev/null 2>&1
  run "$FLOW" rm r --yes
  assert_rc0 "rm exits 0"
  assert_nofile "$SB/commands/r-spike.md" "rm deletes spike command"
  assert_nofile "$SB/commands/r-step.md"  "rm deletes step command"

  run "$FLOW" rm nope --yes
  assert_rcN "rm of unknown flow fails"
}

t_resume() {
  section "flow resume"
  sandbox
  local rd=".flow/runs/bf/2026-05-22T10-30"
  mkdir -p "$rd"; : > "$rd/01-spec.md"; : > "$rd/02-plan.md"; : > "$rd/03-findings.md"

  run "$FLOW" resume bf/2026-05-22T10-30 --from 02
  assert_rc0 "resume exits 0"
  assert_file "$rd/.resume" "writes a .resume marker"
  assert_contains "$(cat "$rd/.resume")" "from=02" "marker records the checkpoint"
  assert_contains "$OUT" "/flow:bf-step" "prints the /flow: resume invocation"

  run "$FLOW" resume bf/2026-05-22T10-30 --from 3
  assert_rc0 "single-digit --from accepted"
  assert_contains "$(cat "$rd/.resume")" "from=03" "single digit zero-padded to 03"

  run "$FLOW" resume bf/2026-05-22T10-30
  assert_contains "$(cat "$rd/.resume")" "from=03" "default --from is the last checkpoint"

  run "$FLOW" resume bf/2026-05-22T10-30 --from 09
  assert_rcN "missing checkpoint fails"
  run "$FLOW" resume nope/nope
  assert_rcN "nonexistent run fails"
}

t_misc() {
  section "version / help / unknown"
  sandbox
  run "$FLOW" version
  assert_rc0 "version exits 0"
  assert_contains "$OUT" "flow " "version prints a version"

  run "$FLOW" help
  assert_contains "$OUT" "pipeline-builder" "help describes the tool"

  run "$FLOW" frobnicate
  assert_rcN "unknown command fails"
}

t_install_doctor() {
  section "install + doctor (sandbox HOME)"
  local sh; sh="$(mktemp -d)"
  mkdir -p "$sh/.local/bin" "$sh/.claude/plugins"
  printf '{}' > "$sh/.claude/settings.json"

  run env HOME="$sh" PATH="$sh/.local/bin:$PATH" bash "$REPO/scripts/install.sh"
  assert_rc0 "install.sh runs"
  assert_file "$sh/.local/bin/flow" "install symlinks flow onto PATH"
  if command -v jq >/dev/null 2>&1; then
    local p; p="$(jq -r '.plugins["flow@flow"][0].installPath // empty' "$sh/.claude/plugins/installed_plugins.json" 2>/dev/null)"
    assert_eq "$REPO" "$p" "install registers flow@flow → repo"
  fi

  run env HOME="$sh" PATH="$sh/.local/bin:$PATH" bash "$REPO/scripts/doctor.sh"
  assert_rc0 "doctor passes after install"
}

# ---------------------------------------------------------------------------

printf '\033[1mflow test suite\033[0m\n'
t_new_noninteractive
t_spike_content
t_step_content
t_html_and_fences
t_new_interactive
t_new_guards
t_list
t_doctypes
t_edit
t_rm
t_resume
t_misc
t_install_doctor

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
