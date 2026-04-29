# Plan: Drop the archive directory (r3)

## Status
plan → implement → review

## What was done
- Scoped the archive-removal rework: 6 folder moves, 1 script rename, ~6 doc edits.
- Designed as a single commit pair on top of the existing PR #11.

## Revisions

- **review → plan** 2026-04-21: New plan superseding r1/r2.
  **Why**: Human asked to drop `agent/archive/` from the convention. r1/r2 assumed the archive was the terminal state for shipped workstreams; r3 removes it.
  **Impact**: r1 and r2 are frozen as history. All new work in r3.

## Decisions needed
- [x] None — scope is clear, all paths and filenames decided.

## Verify in reality
- [x] `agent/archive/` does not exist after this plan runs.
- [x] All 6 historical workstreams appear under `agent/workstreams/` with `01-spec-r1.md`, `02-plan-r1.md`, `03-review-r1.md` (or subset, per each PR's original contents).
- [x] `skills/flow/scripts/workstreams-summary.sh` exists; `archive-summary.sh` does not.
- [x] `grep -RIn 'agent/archive' skills/ commands/ README.md` returns zero (no lingering references).
- [x] `bash skills/flow/scripts/detect-stage.sh` still returns `done` (open PR).

## Implementation Steps

### Step 1: Move archive folders into workstreams/
- [x] Tests: `ls agent/archive/` returns empty and is removed; `ls agent/workstreams/` shows 7 folders (6 historical + current).
- [x] Code: for each `agent/archive/<date>-<slug>/`, `git mv` into `agent/workstreams/<date>-<slug>/`. Then `rmdir agent/archive/`.
- [x] Test run: manual ls check.
- [x] Migration complete.

### Step 2: Rename archive-summary.sh → workstreams-summary.sh and rewrite
- [x] Tests: `bash skills/flow/scripts/workstreams-summary.sh` prints 5 lines (pr-1, pr-2, pr-6, pr-7, pr-8), skipping pr-4 (no spec) and the current workstream (no `pr:` yet — wait, this PR's spec HAS `pr: 11`, so it will show up too; adjust expectations accordingly).
- [x] Code: `git mv skills/flow/scripts/archive-summary.sh skills/flow/scripts/workstreams-summary.sh`. Update the script:
  - Walk `agent/workstreams/*/` instead of `agent/archive/*/`.
  - Filter: only print folders whose `01-spec-r*.md` has a `pr: <N>` in the header comment (non-blank value).
  - Output format unchanged: `pr-<N>\t<date>\t<title>`.
- [x] Test run: output compared against expected.
- [x] Script renamed and working.

### Step 3: Update every doc that mentions archive
- [x] Tests: `grep -RIn 'agent/archive' skills/ commands/ README.md` returns zero live references.
- [x] Code:
  - `skills/flow/SKILL.md` — stages table, scripts section (rename reference).
  - `skills/flow/references/protocol.md` — document-locations paragraph.
  - `skills/flow/references/reflection.md` — `/flow-reflect` input description.
  - `skills/ship/SKILL.md` — Step 7.5 drops the archive-move paragraph.
  - `commands/flow-adopt.md` — example path reference.
  - `README.md` — stages table.
- [x] Test run: grep clean.
- [x] All references updated.

### Step 4: Write spec r2 and plan r3; end with review r2
- [x] Tests: `ls agent/workstreams/2026-04-21-document-name/` shows `01-spec-r1.md`, `01-spec-r2.md`, `02-plan-r1.md`, `02-plan-r2.md`, `02-plan-r3.md`, `03-review-r1.md`, `03-review-r2.md`.
- [x] Code: spec r2 (Revisions entry + updated sections), plan r3 (this file), review r2 (new round findings).
- [x] Test run: file list matches.
- [x] Docs revised.

### Step 5: Commit, push, verify PR
- [x] Tests: `bash skills/flow/scripts/detect-stage.sh` → `done` (PR open). PR shows updated commits.
- [x] Code: `git add -A && git commit` with a clear message; `git push`.
- [x] Test run: pushed successfully.
- [x] PR updated.

## Architecture Decisions
- **No separate archive directory**: dates already provide chronology; `pr:` frontmatter flags shipped. A second location doesn't add information.
- **Rename script instead of keeping old name**: muscle memory matters less than having the name reflect what the script actually does. Users who `make install` get the new name automatically.
- **Keep all prior revisions (r1 + r2 of spec, r1 + r2 + r3 of plan, r1 + r2 of review) rather than squashing**: the point of the revision model is to preserve the trail. Squashing here would defeat the convention we're shipping.

## Success Criteria
- [x] `agent/archive/` removed.
- [x] All 6 historical workstreams present in `agent/workstreams/` with their docs.
- [x] `workstreams-summary.sh` works; `archive-summary.sh` removed.
- [x] Zero `agent/archive` references in live docs.
- [x] PR #11 updated; detect-stage returns `done`.
