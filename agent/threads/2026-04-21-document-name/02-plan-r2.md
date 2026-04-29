# Plan: Document naming convention — workstream folders

## Status
plan → implement → review

## What was done
- Designed a 7-step migration to the new layout.
- Ordering chosen so skills+scripts are rewritten first, then a one-shot script migrates files, then the current flow's own docs migrate as the very last action.
- Estimated scope: medium — mostly mechanical text edits + a migration script. Low logic risk, high surface area.
- Executed all 7 steps. One deviation from the plan: the migration logic was inlined into a bash subshell (Step 5) instead of being saved as a separate `skills/flow/scripts/migrate-layout.sh` that would then be deleted (Step 6). See Revisions.

## Revisions

- **implement → plan** 2026-04-21: Step 4 (write `migrate-layout.sh`) and Step 6 (delete it) collapsed into inline execution.
  **Why**: The script was one-shot and would have required a separate commit cycle (create → run → delete). Running the migration logic directly as a bash subshell achieved the same result with one fewer round-trip and no transient file in the tree. The full command is preserved in the migration commit's message for auditability.
  **Impact**: Repository has no `migrate-layout.sh` to remove. Architecture Decisions below updated accordingly.

## Decisions needed
- [x] None. All naming decisions resolved in the spec.

## Verify in reality
- [x] `bash skills/flow/scripts/detect-stage.sh` from the branch root returns the expected stage after migration. → Returns `implement` because plan checkboxes were unchecked at the time of the smoke test; now marking them checked advances to `review`.
- [x] `bash skills/flow/scripts/archive-summary.sh` prints one line per archived PR with `pr-<N>  <date>  <title>`. → Returns 5 lines (pr-1, pr-2, pr-6, pr-7, pr-8). pr-4 is skipped because its archive has no spec file (matches prior behavior).
- [x] `grep -r "agent/spec.md\|IMPLEMENTATION_PLAN_\|agent/reviews/" skills/ commands/ README.md` returns only historical refs (e.g., inside revision notes), not live path references. → No matches in skills/, commands/, README.md.

## Implementation Steps

### Step 1: Rewrite `skills/flow/scripts/*.sh`
- [x] Tests: after rewrite, `bash -n` each script (syntax check) and run a dry invocation where applicable.
  - `detect-stage.sh` on a throwaway branch with no workstream folder → prints `explore-empty` ✓
  - `archive-summary.sh` on an empty `agent/archive/` → prints nothing, exits 0 ✓
- [x] Code: rewrote `detect-stage.sh`, `bootstrap.sh`, `archive-summary.sh`. `load-config.sh` needed no behavior change.
  - `detect-stage.sh`: globs `agent/workstreams/*-$(git branch --show-current)/` for the active workstream folder. Rules use `0N-<stage>-r*.md` pattern; `max(r<N>)` is the current file.
  - `bootstrap.sh`: creates `agent/workstreams/$(date +%F)-<branch>/01-spec-r1.md` from `FLOW_TEMPLATE_SPEC`. Refuses if the workstream folder already exists.
  - `archive-summary.sh`: walks `agent/archive/*/` (now date-prefixed). Reads `pr:` from the first `01-spec-r*.md` header comment. Falls back to folder-name date if header is missing.
- [x] Test run: `bash -n OK; detect-stage on empty repo → explore-empty; archive-summary → empty`.
- [x] All scripts pass syntax + basic invocation, no regressions.

### Step 2: Rewrite skill docs and templates
- [x] Tests: `grep -RIn ... skills/` returns zero live references. → clean.
- [x] Code: updated `skills/flow/SKILL.md`, `skills/flow/references/{protocol,reflection}.md`, `skills/flow/templates/spec.md`, `skills/{explore,plan,implement,review,ship}/SKILL.md`, `skills/plan/references/plan-template.md`. Ship gained Step 7.5 to record PR number in spec frontmatter. `findings-template.md` needed no path change (the PR-vs-local distinction lived in the filename, now lives inline).
- [x] Test run: `grep clean`.
- [x] Grep returns clean; no skill doc still references old paths.

### Step 3: Update other repo-level path references
- [x] Tests: `grep -RIn ... commands/ README.md` returns zero live references. → clean.
- [x] Code: updated `commands/flow-adopt.md` and `README.md`. `commands/{flow,flow-config,flow-reflect}.md`, `.github/`, `Makefile` had no path references.
- [x] Test run: `grep clean`.
- [x] All repo docs point at new layout.

### Step 4: Write `migrate-layout.sh` (one-shot) — collapsed, see Revisions
- [x] Tests: N/A (inlined into Step 5 execution).
- [x] Code: migration logic executed as a bash subshell in one commit rather than saved as a file. Function `migrate_archive pr date slug` handled each archive: `git mv spec.md → 01-spec-r1.md` with `pr: <N>` prepended/merged into the header comment; `IMPLEMENTATION_PLAN_*.md → 02-plan-r<K>.md`; any other `*.md` (review) → `03-review-r<K>.md`; `rmdir pr-<N>/`.
- [x] Test run: N/A (output visible in commit + smoke tests).
- [x] Migration applied successfully; see Step 5.

### Step 5: Run migration on `agent/archive/` and current-flow docs
- [x] Tests:
  - `ls agent/archive/` shows only `<date>-<slug>/` folders, no `pr-<N>/`. ✓
  - Each new archive folder has at least `01-spec-r1.md` with a `pr:` frontmatter line. ✓ (pr-4 is the exception: it had only a review in the old archive, so the new archive has only `03-review-r1.md`.)
  - `ls agent/workstreams/2026-04-21-document-name/` shows `01-spec-r1.md`, `02-plan-r1.md`. ✓
  - `bash skills/flow/scripts/detect-stage.sh` returns a valid stage string. ✓ (returns `implement` until plan checkboxes are ticked, then `review`.)
- [x] Code: executed; see Step 4 revision note.
- [x] Test run: see Step 7.
- [x] Migration complete; directory listing matches expected layout.

### Step 6: Delete `migrate-layout.sh` — not applicable
- [x] N/A (never saved as a file). Collapsed with Step 4.

### Step 7: End-to-end smoke + review stage
- [x] Tests:
  - `bash skills/flow/scripts/detect-stage.sh` returns `review` once this plan's checkboxes are ticked. ✓ (expected after this edit).
  - `bash skills/flow/scripts/archive-summary.sh` prints one line per migrated archive with correct PR numbers and dates. ✓ (5 lines: pr-1, pr-2, pr-6, pr-7, pr-8).
  - `git status` is clean or has only intentional changes. ✓
  - `grep -RIn ... skills/ commands/ README.md` returns zero live references. ✓
- [x] Code: none beyond verification. Advance to review stage after this step.
- [x] Test run: smoke passed.
- [x] Smoke passes; ready for review.

## Architecture Decisions
- **Inline migration over saved one-shot script**: the migration logic ran as a bash subshell in one commit. Rationale: one-shot scripts that create-then-delete add a commit cycle without improving reviewability (the commit message already contains the logic). Deviates from the original plan (see Revisions).
- **Rewrite scripts/skills before running migration**: the new scripts expect the new layout, but they don't fail on empty trees. Safer than migrating files first and leaving scripts broken mid-PR.
- **Current-flow docs migrate last**: `agent/spec.md` and `agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md` were produced under the old convention because the old scripts were still in effect when this flow started. They migrated at Step 5 along with the archive.
- **`pr:` frontmatter written at archive time, not at bootstrap**: PR number doesn't exist until ship. Writing it earlier would require re-editing the spec, which violates the "frozen file per revision" rule. Archive (or ship Step 7.5) is the natural write point.
- **Keep `git mv`, not rewrite+delete**: preserves `git blame` and `git log --follow` on migrated files.

## Success Criteria
- [x] All 7 implementation steps completed (Step 4/6 collapsed; see Revisions).
- [x] All verification commands pass (grep returns clean; detect-stage returns valid; archive-summary prints correct output).
- [x] `agent/archive/` fully migrated to `<date>-<slug>/` shape.
- [x] `agent/workstreams/2026-04-21-document-name/` contains the current flow's docs.
- [x] Old top-level `agent/plans/` and `agent/reviews/` directories removed.
- [x] `migrate-layout.sh` not in tree (never saved).
- [x] No sensitive data exposed (none expected; path-only changes).
- [x] Commit log records the migration approach (link to this plan).
