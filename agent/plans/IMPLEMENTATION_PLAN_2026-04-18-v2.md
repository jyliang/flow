# Plan: Flow v2 — `.flow/config.sh` + scripted first-time setup

## Status
plan → implement

## What was done
- Read v2 spec at `agent/spec.md`.
- Committed leans on spec's 2 open questions (config filename: `.flow/config.sh`; auto-write on skip: yes).
- Designed 6-step implementation in dependency order: config schema doc → loader script → bootstrap update → command updates → first-time setup → skill pointer.

## Decisions needed (committed, flag for redirect)
- [x] **Config file name**: `.flow/config.sh` (spec open question 1). Explicit extension aids editor highlighting; matches the "bash-sourceable" semantics.
- [x] **Auto-write on skip**: yes (spec open question 2). If user skips all 3 setup questions, write `.flow/config.sh` containing commented-out defaults. Prevents the setup from re-firing on subsequent `/flow` calls.

## Verify in reality
- [ ] Confirm bash `source` of `.flow/config.sh` with set -euo pipefail fails LOUDLY on malformed content (not silently) — the security + debuggability argument in spec line 128.
- [ ] Confirm `FLOW_TEMPLATE_DIR` (v1 legacy) still works when `FLOW_TEMPLATE_SPEC` (v2) is unset — backwards compat goal from spec line 124.

## Implementation Steps

### Step 1: Write `skills/flow/references/config.md`

- [ ] Tests: docs-only; smoke test = `wc -l` under 150 and content covers schema + precedence + security note.
- [ ] Code: new file documenting:
  - The 4 env vars (`FLOW_TEMPLATE_SPEC`, `FLOW_STAGES`, `FLOW_EXTRA_STAGES`, `FLOW_HOOKS_DIR`).
  - Precedence: environment > `.flow/config.sh` > built-in defaults.
  - Backwards compat: `FLOW_TEMPLATE_DIR` honored if `FLOW_TEMPLATE_SPEC` unset.
  - v2.5 forward-compat: `FLOW_EXTRA_STAGES` / `FLOW_HOOKS_DIR` are declared but not acted on.
  - Security: config is sourced as bash; code review is the gate.
  - Example `.flow/config.sh` content.
- [ ] Test run: `wc -l skills/flow/references/config.md` ← `[PASTE TEST SUMMARY HERE]`.
- [ ] Docs accurate against the loader + bootstrap implementation below.

### Step 2: Create `skills/flow/scripts/load-config.sh`

- [ ] Tests:
  - Run in a project with no `.flow/config.sh` → outputs defaults.
  - Run in a project with `.flow/config.sh` setting `FLOW_TEMPLATE_SPEC=custom.md` → outputs custom value.
  - Env var `FLOW_TEMPLATE_SPEC=override.md` + file setting different value → env wins.
  - Malformed `.flow/config.sh` → script fails (exit non-zero), error visible.
- [ ] Code: new executable script per spec's "Config loader" section. Must:
  - `set -euo pipefail`.
  - Source `.flow/config.sh` if present.
  - Apply defaults for every exported var.
  - Print `KEY=VALUE` lines to stdout so callers can `eval $(load-config.sh)` or parse.
  - Honor legacy `FLOW_TEMPLATE_DIR` → derive `FLOW_TEMPLATE_SPEC="$FLOW_TEMPLATE_DIR/spec.md"` if the v2 var is unset.
- [ ] Test run: scripted smoke tests per above, captured. ← `[PASTE TEST SUMMARY HERE]`.
- [ ] All 4 scenarios pass.

### Step 3: Update `skills/flow/scripts/bootstrap.sh`

- [ ] Tests: regression — existing v1 smoke tests (no arg, invalid branch, valid branch, spec exists, sed escape) must still pass.
  - New scenario: `.flow/config.sh` sets `FLOW_TEMPLATE_SPEC=.flow/templates/spec.md`; bootstrap uses that file.
  - Legacy scenario: `FLOW_TEMPLATE_DIR=/somewhere` (no config file) continues to work.
- [ ] Code: modify `bootstrap.sh` to source `.flow/config.sh` (if present) at the top, then use `FLOW_TEMPLATE_SPEC` with fallback chain:
  1. Env var `FLOW_TEMPLATE_SPEC` (explicit override)
  2. `.flow/config.sh` value of `FLOW_TEMPLATE_SPEC`
  3. Legacy `FLOW_TEMPLATE_DIR/spec.md` if set
  4. Built-in `$HOME/.claude/skills/flow/templates/spec.md`
- [ ] Test run: regression tests + new config-aware tests. ← `[PASTE TEST SUMMARY HERE]`.
- [ ] Backwards compat verified; new config path verified.

### Step 4: Create `commands/flow-config.md`

- [ ] Tests:
  - Run `/flow-config` in a project with no `.flow/config.sh` → LLM runs the 3-question setup, writes config.
  - Run `/flow-config` in a project WITH existing config → LLM shows current values, offers to change each.
- [ ] Code: new command body. Delegates to flow skill with "mode=config" intent. Structure:
  - Read `.flow/config.sh` if present.
  - Ask the 3 setup questions via `AskUserQuestion`, pre-filling current values as `(Recommended)`.
  - Write (or rewrite) `.flow/config.sh` with the resulting values (commented defaults for unchanged fields).
  - Confirm completion.
- [ ] Test run: manual, deferred to post-install verification. ← `[PASTE TEST SUMMARY HERE]`.

### Step 5: Update `commands/flow.md` for first-time setup

- [ ] Tests:
  - `/flow` in fresh project (no `.flow/config.sh`, no `agent/spec.md`) → LLM runs setup first, then asks for idea.
  - `/flow` in project with `.flow/config.sh` but no `agent/spec.md` → LLM skips setup, asks for idea immediately.
  - `/flow` in project with neither (any existing `agent/`) → LLM skips setup (not first time), proceeds via flow skill.
- [ ] Code: modify `commands/flow.md` body. Add a second `!`-expanded expression that checks for `.flow/config.sh`:
  ```
  Config state: !`test -f .flow/config.sh && echo configured || echo unconfigured`
  Detected stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`

  If the detected stage is `explore-empty` AND config state is `unconfigured`, run the 3-question first-time setup (see `/flow-config`) before asking the idea prompt.

  If the detected stage is `explore-empty` AND config state is `configured`, your only first turn is "What do you want to build?" with no preamble.

  For any other stage, use the `flow` skill to advance work.
  ```
- [ ] Test run: manual, deferred. ← `[PASTE TEST SUMMARY HERE]`.

### Step 6: Update `skills/flow/SKILL.md` — pointer to config doc

- [ ] Tests: `wc -l` still under 300 (currently 67 + ~3 lines).
- [ ] Code: add a line under the "Scripts" section pointing at `references/config.md`:
  - "See `references/config.md` for per-project config schema and env var precedence."
- [ ] Test run: `wc -l skills/flow/SKILL.md && make list`. ← `[PASTE TEST SUMMARY HERE]`.

### Step 7: Verify `make install` handles new files + manual checks

- [ ] Tests:
  - `make install` → `$HOME/.claude/skills/flow/scripts/load-config.sh` is installed + executable.
  - `make install` → `$HOME/.claude/skills/flow/references/config.md` is installed.
  - `make install` → `$HOME/.claude/commands/flow-config.md` is installed.
  - Smoke-test full v1 flow still passes (regression).
- [ ] Code: likely no Makefile change needed (existing `cp -r skills/flow` handles subdirs).
- [ ] Test run: full smoke. ← `[PASTE TEST SUMMARY HERE]`.

## Architecture Decisions

- **`.flow/config.sh` is bash-sourceable**: trades YAML's prettiness for zero parsing cost. Rejected alternatives: YAML (needs yq/python), JSON (needs jq), TOML (needs tomlq). Shell sourcing matches the existing bash ecosystem.
- **Env vars are the universal override**: `FLOW_TEMPLATE_SPEC` works whether set in the config file or the shell. This unifies "shared team config" with "personal override" — no need for a user-local config file.
- **First-time setup fires on `/flow` empty-state only**: explicit `/flow-config` gives users a way to re-run the setup manually. Firing on every command is noise; never firing makes defaults invisible.
- **Auto-write on skip**: creating `.flow/config.sh` with commented defaults on the first run (even if user skips all questions) marks the project as set up. Prevents the setup from re-firing.
- **Extra-stages and hooks declared-only in v2**: these fields appear in the schema and the scripted setup for forward-compat, but `detect-stage.sh` and bootstrap ignore them. v2.5 or v3 implements the behavior. Declaring them now lets early adopters experiment without breaking changes later.

## Success Criteria
- [ ] All 7 implementation steps completed.
- [ ] All smoke tests passing.
- [ ] `.flow/config.sh` correctly loaded by bootstrap.sh and honored in both config-file and env-var forms.
- [ ] Legacy `FLOW_TEMPLATE_DIR` continues to work for one release.
- [ ] First-time setup fires on `/flow` with no config + empty workspace; skipped otherwise.
- [ ] `skills/flow/SKILL.md` still under 300 lines.
- [ ] Fresh-session verification of `/flow` and `/flow-config` noted in the PR description (user-side).
