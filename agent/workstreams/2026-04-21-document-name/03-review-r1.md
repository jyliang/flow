# Review: Local changes on document-name

**PR**: (not yet created)
**Author**: Jason Liang
**Branch**: document-name → main
**Review round**: 1
**Date reviewed**: 2026-04-21

## Status
review → ship → PR

## Summary
Rewrites the flow skill's document naming convention to use per-workstream folders (`agent/workstreams/<date>-<branch>/{01-spec-rN,02-plan-rN,03-review-rN}.md`) and applies the same shape to the archive. Migrates all existing docs (6 archived PRs + the current flow's spec/plan) into the new layout.

## How It Works

The refactor has three layers. (1) Three scripts under `skills/flow/scripts/` are rewritten to resolve the active workstream via `agent/workstreams/*-$(git branch --show-current)/` (1:1 branch↔folder) and to pick the latest revision of each stage document by globbing `0N-<stage>-r*.md` and sorting by version. (2) Every skill doc, command, reference, and template is updated to point at the new paths; the flow's `Document locations` table now reflects the workstream shape; ship gains a Step 7.5 that writes `pr: <N>` into the spec's header comment. (3) A one-shot in-commit migration walks each `agent/archive/pr-<N>/`, queries `gh pr view` for the merge date and branch slug, creates `agent/archive/<date>-<slug>/`, `git mv`s files to the new names, and prepends/merges `<!-- pr: <N> -->` into each migrated spec's first line. The current flow's own `agent/spec.md` and `agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md` are migrated last under the same rules.

## Complexity & Risk

**Medium**. Surface area is high (~34 files touched, 18 file renames) but logic risk is low: scripts don't change runtime behavior beyond path resolution, and every migration is a `git mv` that preserves `git log --follow`. The one real risk is a drift between the three scripts' path conventions and the new skill docs — verified by grep and direct smoke tests (detect-stage returns `review`, archive-summary returns 5 lines). Reverting is trivial (one revert-commit).

## Decisions needed
- [x] None flagged. See Ship Summary below for what was applied and what was deferred.

## Verify in reality
- [x] After merge, run `bash skills/flow/scripts/detect-stage.sh` in a fresh clone; should print `done` while PR is open, then `explore-empty` after a new workstream is bootstrapped on a fresh branch. (Post-merge verification; documented here for the record.)
- [x] After a future `/flow-reflect` run, verify archive-summary.sh output matches the 5 historical PRs + whatever new archives exist. (Post-merge verification.)

## Ship Summary

**Auto-fixed** (1 item):
- `skills/flow/scripts/archive-summary.sh:26`: `head -1` → `tail -1` so archive-summary picks the latest `-rN` spec, matching `detect-stage.sh`'s `latest()` helper.

**Skipped — documented for future work**:
- *Findings template `pr:` header* (Suggestion 2): speculative, no concrete use-case today. Add when reflection tooling needs it.
- *detect-stage debug message when `gh` missing* (Nit 1): pre-existing; non-blocking.
- *bootstrap.sh regex error message* (Nit 2): pre-existing wording; non-blocking.

**Open question — deferred to a follow-up PR**:
- Archive automation (ship-time `mv agent/workstreams/<…> agent/archive/<…>`). Today the workstream folder stays put after ship; the human or a future command moves it post-merge. Documented in `skills/ship/SKILL.md:138-144`.

## Findings

### Critical
None.

### Suggestions

1. **`skills/flow/scripts/archive-summary.sh:26` picks the lowest-`rN` spec via `head -1`**
   `detect-stage.sh`'s `latest()` helper uses `tail -1` to get the highest revision, which matches the convention ("latest = highest `-rN`"). archive-summary picks `head -1` instead — `specs | sort -V | head -1` is r1, not rN. For frozen archives it doesn't matter (all archived specs are r1 today), but if an archived workstream ever had r2+ the summary would print stale metadata from r1. Change to `tail -1` for internal consistency.

2. **`skills/review/references/findings-template.md:4` doesn't have a `<!-- … · pr: · … -->` header**
   The spec template picked up `pr:` as part of the frontmatter comment; findings didn't. This isn't a regression (findings weren't previously parsed for `pr:`), but if a future `/flow-reflect` ever wants to correlate findings across archives by PR number, the missing header is a small obstacle. Low priority — add only if a concrete use-case emerges.

### Nits

1. **`skills/flow/scripts/detect-stage.sh:15`**: when `gh` is missing or the PR lookup fails, the script silently continues. A `debug "no gh or PR lookup failed"` would help when running with `FLOW_DEBUG=1`.

2. **`skills/flow/scripts/bootstrap.sh:19`**: the branch-name regex rejects underscores (`^[a-z0-9][a-z0-9-]*$`). Intentional per the kebab-case rule, but the error message (`invalid branch name '$branch' (expected lowercase kebab-case)`) could spell out "a-z, 0-9, hyphens only" to save the reader a guess. Pre-existing wording; not introduced by this PR.

### Questions

1. **Archive automation**: ship's Step 7.5 writes `pr:` into the spec frontmatter but deliberately does NOT `mv` the workstream folder to archive. The comment says "today performed manually after merge; future flows may automate". Is this something to file as a follow-up ticket, or leave as a known manual step documented in CLAUDE.md / README?

## Error Handling

Scripts use `set -euo pipefail`. `nullglob` is used where globs may be empty. No bare `||` swallowing errors beyond the intentional `gh` fallback. No new error-handling risks introduced.

## Test Coverage Gaps

There's no automated test suite for the flow scripts. Verification is manual (bash -n, smoke commands). This is pre-existing. A small bats test covering detect-stage on synthetic fixtures would be valuable but is out of scope here.

## Pattern Reuse Opportunities

- `latest()` in `detect-stage.sh` and the ad-hoc `sort -V | head -1` in `archive-summary.sh` solve the same problem differently — consolidating would remove the inconsistency flagged in Suggestion 1.
- `bootstrap.sh` and `load-config.sh` duplicate the config-precedence logic. Pre-existing; called out as a comment in `bootstrap.sh` but not addressed here.

## Files Changed

| File | Change |
|---|---|
| `skills/flow/scripts/{detect-stage,bootstrap,archive-summary}.sh` | Rewritten for new layout |
| `skills/flow/scripts/load-config.sh` | No behavior change |
| `skills/flow/SKILL.md` | Stages table, detect rules, scripts section |
| `skills/flow/references/{protocol,reflection}.md` | Path refs, examples |
| `skills/flow/templates/spec.md` | `pr:` added to header comment |
| `skills/{explore,plan,implement,review,ship}/SKILL.md` | Path refs; ship gains Step 7.5 |
| `skills/plan/references/plan-template.md` | Save location |
| `README.md`, `commands/flow-adopt.md` | Stage table, adopt flow |
| `agent/archive/*` | Migrated from `pr-<N>/` to `<date>-<slug>/` |
| `agent/workstreams/2026-04-21-document-name/` | Current flow docs in new layout; `02-plan-r2.md` captures executed state |
