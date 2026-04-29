<!-- branch: document-name · date: 2026-04-21 · author: Jason Liang · pr: 11 -->

# Spec: Document naming convention — workstream folders

## Status
explore → plan → implement → review (r2)

## What was done
- See `01-spec-r1.md` for the original scope (inventory, decisions, migration plan).
- This revision drops the separate `agent/archive/` directory. Merged workstreams stay in `agent/workstreams/`; the `pr:` frontmatter field marks "shipped".

## Revisions

- **review → spec** 2026-04-21: Dropped the `agent/archive/` directory from the convention.
  **Why**: Human noted the archive was overkill now that every workstream folder is date-prefixed. Dates already sort chronologically. The `pr:` frontmatter in the spec already marks whether a workstream shipped, so a separate location isn't buying additional information. Simpler mental model: workstream folder = one task's full context, for its full lifetime.
  **Impact**: `agent/archive/` removed entirely. All 6 historical archive folders moved back into `agent/workstreams/`. Ship no longer mentions archiving (just writes `pr:`). `archive-summary.sh` renamed to `workstreams-summary.sh` and filters by `pr:` presence. Updated every referring doc (flow/SKILL, protocol, reflection, ship, README, commands/flow-adopt).

## Decisions needed (resolved)
- [x] **Workstream folders, not stage folders**: `agent/workstreams/<date>-<slug>/` contains spec + plan + review together.
- [x] **Folder name**: `<YYYY-MM-DD>-<branch-slug>/`. Date sorts chronologically; slug = git branch name.
- [x] **File names inside folder**: `01-spec-rN.md`, `02-plan-rN.md`, `03-review-rN.md`.
- [x] **Revision model**: any revision to any doc creates a new `-rN+1` file; previous `-rN` frozen; `## Revisions` explains the delta.
- [x] **Active-workstream detection**: 1:1 branch ↔ workstream. `detect-stage.sh` globs `agent/workstreams/*-<branch>/`.
- [x] **No separate archive** (new in r2): merged workstreams stay in `agent/workstreams/`. Shipped state = presence of `pr: <N>` in the spec's frontmatter comment.
- [x] **PR number**: stored in `01-spec-rN.md` frontmatter comment as `pr: <N>`, written by ship.

## Verify in reality
- [x] `agent/archive/` no longer exists after migration.
- [x] `ls agent/workstreams/` shows the current in-flight workstream plus every historical one.
- [x] `bash skills/flow/scripts/workstreams-summary.sh` lists all workstreams with a `pr:` value; skips those without (active or never-shipped).
- [x] `bash skills/flow/scripts/detect-stage.sh` on this branch returns `ship` / `done` as expected.

## Spec details

### Problem (unchanged from r1, summarized)
- Singleton `agent/spec.md` blocks parallel context.
- Stage-based folders scatter one task across three locations.
- Same-day plan collisions handled ad-hoc.

### Scope (as revised)

**In:**
- Active AND archived layout: `agent/workstreams/<YYYY-MM-DD>-<branch>/{01-spec-rN,02-plan-rN,03-review-rN}.md`. One location, one shape.
- "Shipped" marker: `pr: <N>` in the spec's header comment. Ship writes it at PR-ready time.
- `workstreams-summary.sh` (renamed from `archive-summary.sh`): walks `agent/workstreams/*/`, emits one line per folder with a `pr:` value.
- All skill docs, templates, scripts, command bodies, and README updated for the no-archive layout.

**Out:**
- `agent/archive/` as a directory. Removed in migration.
- Automatic moves on merge. Nothing to move.

### Design

#### Layout

```
agent/
  workstreams/
    2026-04-17-prefer-askuserquestion/    (merged — pr: 1 in spec)
    2026-04-17-auto-bump-marketplace-version/   (merged — pr: 2)
    2026-04-17-flow-skill-refactor/       (merged — pr: 4)
    2026-04-18-flow-v1-adopt/             (merged — pr: 6)
    2026-04-18-flow-v2-config/            (merged — pr: 7)
    2026-04-18-flow-v3-reflection/        (merged — pr: 8)
    2026-04-21-document-name/             (current — pr: 11)
```

#### Filtering for "shipped"

`grep -l 'pr: *[0-9]' agent/workstreams/*/01-spec-r*.md` returns the shipped ones. `workstreams-summary.sh` uses this filter internally; humans can run it ad-hoc.

#### Script changes (from r1's design)

- `detect-stage.sh`: unchanged — still globs `agent/workstreams/*-<branch>/`.
- `bootstrap.sh`: unchanged.
- `archive-summary.sh` → `workstreams-summary.sh`: walks `agent/workstreams/*/` instead of `agent/archive/*/`. Filters to folders whose `01-spec-r*.md` has a `pr: <N>` in the header comment.
- `load-config.sh`: unchanged.

#### Migration delta from r1

r1 migrated `agent/archive/pr-<N>/` → `agent/archive/<date>-<slug>/`. r2 continues that: `agent/archive/<date>-<slug>/` → `agent/workstreams/<date>-<slug>/`. One `git mv` per historical workstream + remove the empty `agent/archive/` directory.

### Constraints

- Single PR (#11) for the full end state. The intermediate archive layout (from r1's commits earlier in this PR) is not a state anyone else will see.
- Git history preserved via `git mv`.

### Impact analysis

Files modified in this revision:
- `skills/flow/SKILL.md` — scripts section, document-locations
- `skills/flow/references/protocol.md` — no archive mention
- `skills/flow/references/reflection.md` — `/flow-reflect` reads workstreams, not archive
- `skills/ship/SKILL.md` — Step 7.5 drops archive-move note
- `skills/flow/scripts/archive-summary.sh` → rename + rewrite as `workstreams-summary.sh`
- `README.md` — archive wording
- `commands/flow-adopt.md` — archive example path → workstreams path

Files moved:
- `agent/archive/<date>-<slug>/` → `agent/workstreams/<date>-<slug>/` (6 folders)
- Removed: empty `agent/archive/` directory

### Open questions

None.
