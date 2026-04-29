# Review: Local changes on document-name (r2 — archive removal)

**PR**: https://github.com/jyliang/flow/pull/11
**Author**: Jason Liang
**Branch**: document-name → main
**Review round**: 2 (post archive-removal rework)
**Date reviewed**: 2026-04-21

## Status
review → ship

## Summary

Second review round, scoped to the archive-removal delta on top of r1's findings. Human feedback: the separate `agent/archive/` directory was overkill given that workstream folders are already date-prefixed. r3 plan dropped the archive entirely; all 6 historical folders moved back into `agent/workstreams/`; `archive-summary.sh` renamed to `workstreams-summary.sh` and now filters by `pr:` presence.

## How It Works (delta)

`agent/workstreams/` now holds all workstreams, shipped or in-flight. A shipped workstream is identified by a `pr: <N>` value in its `01-spec-r*.md` header comment, written by ship Step 7.5. `workstreams-summary.sh` walks the directory, skips any folder whose spec has no `pr:` value, and emits one line per shipped workstream. Everything downstream (`/flow-reflect`, `reflection.md`, the protocol's document-locations paragraph) now references `agent/workstreams/` directly; `agent/archive/` doesn't exist as a path anywhere.

## Complexity & Risk

**Low**. Six `git mv` moves + one script rename + ~6 doc edits. `detect-stage.sh` and `bootstrap.sh` needed no change (they only ever looked at `agent/workstreams/`). `workstreams-summary.sh` shares the same output format as the old `archive-summary.sh`, so `/flow-reflect`'s prompt needs no downstream adjustment.

## Decisions needed
- [x] None.

## Verify in reality
- [x] `ls agent/` → only `workstreams`. No `archive/` directory. ✓
- [x] `ls agent/workstreams/` → 7 folders: 6 historical + current `2026-04-21-document-name/`. ✓
- [x] `grep -RIn 'agent/archive\|archive-summary' skills/ commands/ README.md Makefile` → no matches. ✓
- [x] `bash skills/flow/scripts/workstreams-summary.sh` → 6 lines (pr-1, pr-2, pr-6, pr-7, pr-8, pr-11). pr-4 is skipped because its historical folder still has no spec (never written in the original PR). ✓
- [x] `bash skills/flow/scripts/detect-stage.sh` → `done` (PR #11 open). ✓
- [x] `ls skills/flow/scripts/` → no `archive-summary.sh`; `workstreams-summary.sh` present. ✓

## Findings

### Critical
None.

### Suggestions
None. This round is a clean simplification — fewer concepts, fewer locations, same capability.

### Nits

1. **pr-4 still has no `01-spec-r*.md`** (`agent/workstreams/2026-04-17-flow-skill-refactor/`). Not a regression from this PR (the original archive also had no spec for pr-4), but it means the folder shows only `03-review-r1.md`. `workstreams-summary.sh` silently skips it. Could be addressed in a future cleanup PR by reconstructing a minimal spec from the review — but it's historical and low-value.

### Questions
None.

## Error Handling

No new code paths. The `pr:` filter in `workstreams-summary.sh` uses `grep -oE 'pr: *[0-9]+'`; folders without a `pr:` value produce an empty `pr` variable and are skipped by `[[ -n "$pr" ]] || continue` — safe on empty specs too.

## Test Coverage Gaps

No change from r1. Manual smoke tests only.

## Pattern Reuse Opportunities

None new. The duplication between `workstreams-summary.sh`'s latest-spec selection and `detect-stage.sh`'s `latest()` helper persists (r1 suggestion 1 was already addressed by switching to `tail -1`). Consolidating into a single sourced helper remains a future option.

## Files Changed (r2 delta from r1)

| File | Change |
|---|---|
| `agent/archive/*/*` | removed (contents moved to `agent/workstreams/`) |
| `agent/archive/` | removed (empty dir) |
| `skills/flow/scripts/archive-summary.sh` | renamed to `workstreams-summary.sh` |
| `skills/flow/scripts/workstreams-summary.sh` | walks `agent/workstreams/`, filters by `pr:` |
| `skills/flow/SKILL.md` | stages table + scripts section (rename, archive dropped) |
| `skills/flow/references/protocol.md` | document-locations paragraph |
| `skills/flow/references/reflection.md` | input scope + "not enough history" wording |
| `skills/ship/SKILL.md` | Step 7.5 drops archive-move note |
| `README.md` | stages table |
| `commands/flow-adopt.md` | example path |
| `commands/flow-reflect.md` | script invocation + "archive dirs" → "workstream dirs" |
| `agent/workstreams/2026-04-21-document-name/01-spec-r2.md` | new — Revisions entry explaining the drop |
| `agent/workstreams/2026-04-21-document-name/02-plan-r3.md` | new — archive-removal rework plan |
| `agent/workstreams/2026-04-21-document-name/03-review-r2.md` | this document |
