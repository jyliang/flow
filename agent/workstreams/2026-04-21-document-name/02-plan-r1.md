# Plan: Document naming convention — workstream folders

## Status
plan → implement

## What was done
- Designed a 7-step migration to the new layout.
- Ordering chosen so skills+scripts are rewritten first, then a one-shot script migrates files, then the current flow's own docs migrate as the very last action.
- Estimated scope: medium — mostly mechanical text edits + a migration script. Low logic risk, high surface area.

## Decisions needed
- [ ] None. All naming decisions resolved in the spec.

## Verify in reality
- [ ] `bash skills/flow/scripts/detect-stage.sh` from the branch root returns the expected stage after migration.
- [ ] `bash skills/flow/scripts/archive-summary.sh` prints one line per archived PR with `pr-<N>  <date>  <title>`.
- [ ] `grep -r "agent/spec.md\|IMPLEMENTATION_PLAN_\|agent/reviews/" skills/ commands/ README.md` returns only historical refs (e.g., inside revision notes), not live path references.

## Implementation Steps

### Step 1: Rewrite `skills/flow/scripts/*.sh`
- [ ] Tests: after rewrite, `bash -n` each script (syntax check) and run a dry invocation where applicable.
  - `detect-stage.sh` on a throwaway branch with no workstream folder → prints `explore-empty`
  - `archive-summary.sh` on an empty `agent/archive/` → prints nothing, exits 0
- [ ] Code: rewrite `detect-stage.sh`, `bootstrap.sh`, `archive-summary.sh`, `load-config.sh` to use `agent/workstreams/<date>-<slug>/` and `agent/archive/<date>-<slug>/` (see spec §Design/Script changes).
  - `detect-stage.sh`: glob `agent/workstreams/*-$(git branch --show-current)/` for the active workstream folder. Rules: spec/plan/review file presence using new `0N-<stage>-r*.md` pattern. `max(r<N>)` is the current file.
  - `bootstrap.sh`: create `agent/workstreams/$(date +%F)-<branch>/01-spec-r1.md` from `FLOW_TEMPLATE_SPEC`. Refuse if folder exists. Update message printed at end.
  - `archive-summary.sh`: walk `agent/archive/*/` (now date-prefixed). Read `pr:` from the first `01-spec-r*.md` frontmatter. Print `pr-<N>  <date>  <title>`; fall back to folder date if no `pr:` frontmatter.
  - `load-config.sh`: only path reference in comments — update docstring, leave behavior intact.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] All scripts pass syntax + basic invocation, no regressions.

### Step 2: Rewrite skill docs and templates
- [ ] Tests: `grep -RIn "agent/spec\.md\|IMPLEMENTATION_PLAN_\|agent/plans/\|agent/reviews/\|pr-[0-9]\+/" skills/` returns zero live references after this step (historical mentions inside quoted examples are OK if clearly marked "legacy").
- [ ] Code:
  - `skills/flow/SKILL.md` — stages table, detect-stage rules, Scripts section.
  - `skills/flow/references/protocol.md` — document-locations table, example paths in "How revisions work".
  - `skills/flow/references/reflection.md` — `/flow-reflect` archive scanning path.
  - `skills/flow/references/config.md`, `stage-detection.md`, `boundaries.md` — path refs only.
  - `skills/flow/templates/spec.md` — add `pr:` frontmatter line (blank until archive).
  - `skills/explore/SKILL.md` — output path → `agent/workstreams/<date>-<branch>/01-spec-r<N>.md`; describe `-rN` revision rule.
  - `skills/plan/SKILL.md` + `skills/plan/references/plan-template.md` — input path (latest `01-spec-r*.md`), output path (`02-plan-r<N>.md`). Template file-save instruction updated.
  - `skills/review/SKILL.md` + `skills/review/references/findings-template.md` — output path (`03-review-r<N>.md`). Drop `pr-<N>-r<N>.md` / `local-<branch>-r<N>.md` distinction.
  - `skills/implement/SKILL.md` — input path (latest `02-plan-r*.md`).
  - `skills/ship/SKILL.md` — add step: before archiving, write `pr: <N>` into the frontmatter of the latest `01-spec-r*.md`. Then `mv` workstream folder → archive.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] Grep returns clean; no skill doc still references old paths.

### Step 3: Update other repo-level path references
- [ ] Tests: `grep -RIn "agent/spec\.md\|IMPLEMENTATION_PLAN_\|agent/plans/\|agent/reviews/\|pr-[0-9]\+/" commands/ README.md .github/ Makefile 2>/dev/null` returns zero live references.
- [ ] Code:
  - `commands/flow.md`, `commands/flow-adopt.md`, `commands/flow-config.md`, `commands/flow-reflect.md` — any path refs.
  - `README.md` — any naming convention mention.
  - `.github/`, `Makefile` — unlikely but check.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] All repo docs point at new layout.

### Step 4: Write `migrate-layout.sh` (one-shot)
- [ ] Tests:
  - Dry-run mode (`DRY_RUN=1`) prints every planned `git mv` without mutating state.
  - On a disposable copy, running once produces the expected layout; running twice is a no-op (idempotent or errors cleanly).
- [ ] Code: `skills/flow/scripts/migrate-layout.sh` does:
  1. For each `agent/archive/pr-<N>/`:
     - Query `gh pr view <N> --json mergedAt,headRefName` → extract date (YYYY-MM-DD) and branch slug.
     - Create `agent/archive/<date>-<slug>/`.
     - `git mv` files in:
       - `spec.md` → `01-spec-r1.md`; append `pr: <N>` to YAML frontmatter (insert as first line or into existing frontmatter block).
       - `IMPLEMENTATION_PLAN_*.md` → `02-plan-r<K>.md` — if multiple present (e.g., `-v2`, `-v3`), sort ascending by version and assign `r1`, `r2`, `r3`.
       - Any review file (`local-*-r*.md` or `pr-<N>-r*.md`) → `03-review-r<K>.md` preserving the `-r<N>` ordinal.
  2. Remove old empty `agent/archive/pr-<N>/` directories.
  3. Print a final summary: old → new mapping.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] Script is idempotent or errors cleanly; dry-run shows correct plan.

### Step 5: Run migration on `agent/archive/` and current-flow docs
- [ ] Tests:
  - `ls agent/archive/` shows only `<date>-<slug>/` folders, no `pr-<N>/`.
  - Each new archive folder has at least `01-spec-r1.md` with a `pr:` frontmatter line.
  - `ls agent/workstreams/2026-04-21-document-name/` shows `01-spec-r1.md`, `02-plan-r1.md` (and `03-review-r1.md` after review stage).
  - `bash skills/flow/scripts/detect-stage.sh` returns a valid stage string (expected: `review` or `implement` depending on when this runs).
- [ ] Code:
  1. Run `bash skills/flow/scripts/migrate-layout.sh`.
  2. Create `agent/workstreams/2026-04-21-document-name/`.
  3. `git mv agent/spec.md agent/workstreams/2026-04-21-document-name/01-spec-r1.md`.
  4. `git mv agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md agent/workstreams/2026-04-21-document-name/02-plan-r1.md`.
  5. If review file exists, migrate it too (deferred to Step 6 if review runs after).
  6. Remove empty `agent/plans/` and `agent/reviews/` directories.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] Migration complete; directory listing matches expected layout.

### Step 6: Delete `migrate-layout.sh` and clean up
- [ ] Tests: `ls skills/flow/scripts/` no longer contains `migrate-layout.sh`. Commit message records the migration approach.
- [ ] Code: `git rm skills/flow/scripts/migrate-layout.sh`.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] Script removed; repo clean.

### Step 7: End-to-end smoke + review stage
- [ ] Tests:
  - `bash skills/flow/scripts/detect-stage.sh` returns `review` (plan complete, unreviewed changes on branch).
  - `bash skills/flow/scripts/archive-summary.sh` prints one line per migrated archive with correct PR numbers and dates.
  - `git status` is clean or has only intentional changes.
  - `grep -RIn "agent/spec\.md\|IMPLEMENTATION_PLAN_\|agent/plans/\|agent/reviews/\|pr-[0-9]\+/" skills/ commands/ README.md` returns zero live references.
- [ ] Code: none beyond verification. Advance to review stage after this step.
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] Smoke passes; ready for review.

## Architecture Decisions
- **One-shot migration script over inline git moves**: encapsulates the mapping logic (PR number → date + slug, `-v<N>` → `-r<N>`) in a reviewable place. Deleted in the same PR so it doesn't live on as dead code.
- **Rewrite scripts/skills before running migration**: the new scripts expect the new layout, but they don't fail on empty trees. Safer than migrating files first and leaving scripts broken mid-PR.
- **Current-flow docs migrate last**: `agent/spec.md` and the new `IMPLEMENTATION_PLAN_2026-04-21.md` were produced under the old convention because the old scripts were still in effect when this flow started. They migrate at Step 5 along with everything else.
- **`pr:` frontmatter written at archive time, not at bootstrap**: PR number doesn't exist until ship. Writing it earlier would require re-editing the spec, which violates the "frozen file per revision" rule. Archive is the natural write point.
- **Keep `git mv`, not rewrite+delete**: preserves `git blame` and `git log --follow` on migrated files.

## Success Criteria
- [ ] All 7 implementation steps completed
- [ ] All verification commands pass (grep returns clean; detect-stage returns valid; archive-summary prints correct output)
- [ ] `agent/archive/` fully migrated to `<date>-<slug>/` shape
- [ ] `agent/workstreams/2026-04-21-document-name/` contains the current flow's docs
- [ ] Old top-level `agent/plans/` and `agent/reviews/` directories removed
- [ ] `migrate-layout.sh` removed from the tree before PR
- [ ] No sensitive data exposed (none expected; path-only changes)
- [ ] Commit log records the migration approach (link to this plan)
