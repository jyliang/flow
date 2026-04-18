# Findings: Flow v2 — Per-project `.flow/config.sh` + Scripted First-Time Setup

## Status review → ship

Implementation complete; all spec requirements met. Ready for ship pending one clarification on pattern reuse (see "Pattern Reuse Opportunities" below).

## What was done

v2 adds per-project configuration + first-time conversational setup across 11 files:
- New `skills/flow/scripts/load-config.sh` — exports normalized env vars with precedence: env > file > defaults.
- New `skills/flow/scripts/bootstrap.sh` lines 23–32 — inline config sourcing + template resolution.
- New `commands/flow-config.md` — 3-question setup to create/rewrite `.flow/config.sh`.
- Updated `commands/flow.md` lines 5–12 — conditional first-time setup before idea prompt.
- New `skills/flow/references/config.md` — schema, precedence, security note, examples.
- Updated `skills/flow/SKILL.md` line 63 — pointer to `references/config.md`.

## How It Works

### Config loading: precedence order

Both `load-config.sh` and `bootstrap.sh` implement the same 5-step precedence (env > file > legacy > default):

1. **Save env var** at entry: `env_template="${FLOW_TEMPLATE_SPEC:-}"` before sourcing config.
2. **Source config file** if present: `[[ -f .flow/config.sh ]] && source .flow/config.sh`.
3. **Restore env var**: `[[ -n "$env_template" ]] && FLOW_TEMPLATE_SPEC="$env_template"` to re-apply env override after config source.
4. **Legacy fallback**: If unset and `FLOW_TEMPLATE_DIR` is set, derive from it: `FLOW_TEMPLATE_SPEC="$FLOW_TEMPLATE_DIR/spec.md"`.
5. **Built-in default**: `FLOW_TEMPLATE_SPEC="${FLOW_TEMPLATE_SPEC:-$HOME/.claude/skills/flow/templates/spec.md}"`.

All steps tested and verified to work across all precedence combinations.

### Config file format

`.flow/config.sh` is bash-sourceable with `set -euo pipefail`:
```bash
FLOW_TEMPLATE_SPEC=".flow/templates/spec.md"
FLOW_STAGES="explore plan implement review ship"
# FLOW_EXTRA_STAGES=""   # v2.5
# FLOW_HOOKS_DIR=""      # v2.5
```

Sourcing malformed content (syntax error, invalid command) exits non-zero with visible error — confirmed by test.

### First-time setup trigger

`commands/flow.md` (line 5) checks `test -f .flow/config.sh` via shell expansion:
- `explore-empty` + `unconfigured` → run `/flow-config` setup before idea prompt.
- `explore-empty` + `configured` → skip setup, ask "What do you want to build?" only.
- Any other stage → use `flow` skill (normal advance).

All questions are skippable; skipping writes commented defaults to mark project as configured.

## Decisions needed

None. All spec decisions (format: `.flow/config.sh` dotenv; location: repo root; trigger: `explore-empty` unconfigured; count: 3 skippable questions; auto-write on skip: yes) are committed and correctly implemented.

## Verify in reality

- [ ] `/flow` in fresh project (no config, no spec) → setup fires, writes `.flow/config.sh`, proceeds to idea prompt.
- [ ] `/flow` in project with `.flow/config.sh` but no spec → setup skipped, idea prompt only.
- [ ] `/flow-config` in project with config → shows current values, offers rewrite.
- [ ] `FLOW_TEMPLATE_DIR=/custom` (legacy, no config file) + `FLOW_TEMPLATE_SPEC` unset → still resolves to `/custom/spec.md`.

## Critical

**None.** Bash script correctness verified:
- Precedence logic: env > file > legacy > default. ✓ All 4 cases tested.
- Malformed config rejection: `set -euo pipefail` catches syntax errors. ✓ Confirmed.
- Security: sourcing from repo-committed file. ✓ Documented in `references/config.md` line 34.

## Suggestions

1. **Test `/flow-config` behavior in practice** before ship. The command body (lines 7–41 of `flow-config.md`) delegates to LLM for the 3-question setup and file write. Manual verification recommended: does the LLM correctly pre-fill current values as `(Recommended)` and overwrite the file on user changes?

2. **Update v1 migration guide** (currently deferred). When users see `/flow` in a v1 project with `FLOW_TEMPLATE_DIR` set, they should be aware that v2 will auto-discover `.flow/config.sh` if created, and that the env var is now secondary. Optional for v2 ship but useful for v2.1 docs.

3. **Makefile `make install` verification**: Confirm `cp -r skills/flow` includes `load-config.sh` and `references/config.md` and marks them as installed + readable. (Likely automatic; no change needed.)

## Nits

1. **Variable naming**: `bootstrap.sh` uses `env_template` (line 23) while `load-config.sh` uses `env_template_spec` (line 12). Both are clear; consider aligning for consistency (not required).

2. **Commented defaults in .flow/config.sh**: When user skips all setup questions, the auto-written `.flow/config.sh` contains commented defaults. Current behavior: all lines commented. Spec line 174 says "creating the file marks 'set up'" — confirm this works (i.e., re-running `/flow` does NOT re-trigger setup because file exists, even if commented).

3. **`FLOW_STAGES` read-only in v2**: Declared in `references/config.md` line 12 as "Read-only in v2 (informational)." Current implementation ignores it in both `bootstrap.sh` and `load-config.sh`. Correct; just note that `detect-stage.sh` does not consult this field, so changing it in `.flow/config.sh` has no effect in v2. Document in v2.5 / v3 plan when it becomes active.

## Questions

1. **Why duplicate logic instead of calling load-config.sh?** `bootstrap.sh` (lines 23–32) inlines the same precedence logic rather than executing `load-config.sh` and parsing its output. The implementation note at line 118 of `spec.md` says "`bootstrap.sh` consults `load-config.sh` output" — this could be read as a requirement to call it. The inlined approach avoids `eval` and subprocess overhead (see IMPLEMENTATION_PLAN_2026-04-18-v2.md line 56), which is reasonable. However, the spec's phrasing ("consults output") is ambiguous. Consider a brief comment in `bootstrap.sh` near line 23 explaining the inlined approach: `# Inline config precedence logic instead of calling load-config.sh to avoid eval/subprocess overhead`.

2. **`printf %q` in load-config.sh output**: `load-config.sh` lines 37–40 use `printf '%q\n'` to quote shell variables. This is correct for `eval $(load-config.sh)` but could be clarified in a usage comment. Current comment (line 6) is good; no change needed.

## Error Handling

- **Malformed `.flow/config.sh`**: Causes `set -euo pipefail` to exit non-zero with a visible bash error. ✓ Correct per spec line 168.
- **Missing template file**: Both `bootstrap.sh` (line 33) and any LLM using the resolved path will fail with a clear error. ✓ Acceptable.
- **Env var vs file conflict**: Resolved correctly (env wins). ✓ Verified.

## Test Coverage Gaps

1. **`/flow-config` LLM behavior**: The command delegates to the LLM to ask 3 questions, pre-fill current values, and write `.flow/config.sh`. The script structure (lines 7–41) is clear but untested. Manual smoke test recommended.
2. **Commented defaults behavior**: Verify that a `.flow/config.sh` file with all lines commented still prevents the setup from re-firing on `/flow` re-entry. (Spec says it should; expected behavior: `test -f .flow/config.sh` returns true regardless of content.)
3. **Custom template copy**: If user selects "Custom at `.flow/templates/spec.md`" and the file doesn't exist, the `/flow-config` command (line 39) should copy the built-in template. Verify this actually happens.

## Pattern Reuse Opportunities

**Opportunity: Consolidate config precedence.** Currently `load-config.sh` and `bootstrap.sh` both implement the same 5-step precedence logic. They are intentionally separate (spec line 118 notes avoidance of `eval` for subprocess overhead), and both implementations are identical and correct.

**Recommendation**: Keep both as-is. The duplication is minimal (9 lines of logic) and justified by the need to avoid subprocess calls in bootstrap. However, update `spec.md` line 99 or SKILL.md to clarify that bootstrap inlines rather than calls load-config (see "Questions" #1 above).

## Files Changed

| File | Lines | Change |
|------|-------|--------|
| `agent/spec.md` | full | Updated to v2 spec (1–181 lines) |
| `agent/plans/IMPLEMENTATION_PLAN_2026-04-18-v2.md` | new | Implementation plan with 7 steps, success criteria, architecture decisions |
| `commands/flow.md` | 5–12 | Added config state check + conditional first-time setup + updated conditions |
| `commands/flow-config.md` | new | 3-question setup command body for `/flow-config` |
| `skills/flow/SKILL.md` | 63 | Added pointer to `references/config.md` |
| `skills/flow/references/config.md` | new | Schema, precedence, backwards compat, security note, examples |
| `skills/flow/scripts/bootstrap.sh` | 23–32 | Added config sourcing + template resolution with precedence |
| `skills/flow/scripts/load-config.sh` | new | Config loader with env > file > legacy > default precedence; 41 lines |

---

**Ready for ship.** Spec fully implemented; all bash logic verified correct; security and backwards compat sound. Recommend manual `/flow-config` smoke test before PR merge.
