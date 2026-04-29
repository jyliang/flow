<!-- branch: document-name · date: 2026-04-21 · author: Jason Liang · pr: 11 -->

# Spec: Document naming convention — workstream folders

## Status
explore → plan

## What was done
- Inventoried the current convention: singleton `agent/spec.md`, `agent/plans/IMPLEMENTATION_PLAN_<date>.md`, `agent/reviews/{pr-<N>,local-<branch>}-r<N>.md`, `agent/archive/pr-<N>/`.
- Identified pain points with the user: (1) singleton spec blocks parallel exploration, (2) stage-based grouping doesn't match how humans track workstreams, (3) same-day plan collisions handled ad-hoc via `-v2`/`-v3`, (4) review filenames have no date, (5) archive already groups by workstream — active work should too.
- Resolved all naming decisions via AskUserQuestion (see Decisions below).

## Decisions needed (resolved)
- [x] **Workstream folders, not stage folders**: `agent/workstreams/<date>-<slug>/` contains spec + plan + review together. Matches how humans think (one context per task) and how the archive already works.
- [x] **Folder name**: `<YYYY-MM-DD>-<branch-slug>/`. Date sorts chronologically; slug = git branch name.
- [x] **File names inside folder**: `01-spec-rN.md`, `02-plan-rN.md`, `03-review-rN.md`. Numeric stage prefix makes order obvious; `-rN` tracks revisions.
- [x] **Revision model**: any revision to any doc creates a new `-rN+1` file. Previous `-rN` is frozen. The new file's `## Revisions` section explains what changed.
- [x] **Active-workstream detection**: 1:1 branch ↔ workstream. `detect-stage.sh` reads `git branch --show-current` → globs `agent/workstreams/*-<branch>/`.
- [x] **Archive shape**: `agent/archive/<YYYY-MM-DD>-<branch-slug>/` — same shape as active. Just `mv` on merge.
- [x] **PR number**: stored in `01-spec-rN.md` YAML frontmatter as `pr: <N>`, written at archive time.

## Verify in reality
- [ ] After migration, `ls agent/workstreams/` shows one folder per in-flight branch; archive shows one folder per merged PR.
- [ ] `bash skills/flow/scripts/detect-stage.sh` on a branch with a workstream folder returns the right stage.
- [ ] `bash skills/flow/scripts/bootstrap.sh <new-branch>` creates `agent/workstreams/<date>-<new-branch>/01-spec-r1.md` from the template.
- [ ] `bash skills/flow/scripts/archive-summary.sh` walks the migrated archive without errors.
- [ ] Migrated archive entries still let `/flow-reflect` find patterns across past PRs.

## Spec details

### Problem

Two concrete problems with the current layout:

1. **Singleton spec blocks parallel context.** `agent/spec.md` is overwritten each explore run. Drafting a second idea while the first is mid-flow is impossible without manual file juggling.
2. **Stage-based grouping scatters one workstream across three folders.** Spec, plan, and review for the same task live in `agent/spec.md`, `agent/plans/…`, `agent/reviews/…`. "What am I working on?" requires a join. The archive already solves this (`agent/archive/pr-N/` bundles spec + plan + review) — active work should have the same shape.

Secondary issues:
- Same-day plan collisions produce ad-hoc `-v2`/`-v3` suffixes not specified anywhere.
- Review filenames (`pr-<N>-r<N>.md`, `local-<branch>-r<N>.md`) carry no date.
- The `-v<N>` plan suffix and `-r<N>` review suffix serve the same purpose (revisions) with different shapes.

### Scope

**In:**
- New active layout: `agent/workstreams/<date>-<slug>/{01-spec-rN,02-plan-rN,03-review-rN}.md`.
- New archive layout: `agent/archive/<date>-<slug>/` (same shape).
- Update every skill doc, template, and script that references the old paths: `skills/{explore,plan,implement,review,ship,flow}/**`.
- Update `skills/flow/references/{protocol,reflection,config,stage-detection,boundaries,user-interaction}.md` wherever paths appear.
- Migrate existing files: `agent/spec.md` (none currently — archived above), any remaining `agent/plans/*`, `agent/reviews/*`, and all of `agent/archive/pr-*/` → new layout.
- Write a `pr:` frontmatter line into each migrated spec using the PR number derived from the old `pr-<N>/` folder name, mapped via `gh pr view`.
- Update `README.md` if it references old paths.

**Out (this PR):**
- Changes to the CLAUDE.md file's global rules.
- Any stage-skill behavior change beyond path references (explore still produces a spec; plan still reads it; etc.).
- Support for multiple workstreams on the same branch (1:1 rule stays).
- Renaming git branches or PRs retroactively.
- New tooling on top of the layout (e.g., a `flow status` command) — tracked as a future enhancement.

### Design

#### Active layout

```
agent/
  workstreams/
    2026-04-21-document-name/
      01-spec-r1.md
      02-plan-r1.md
      03-review-r1.md
    2026-04-25-some-other-branch/
      01-spec-r1.md
```

#### Revision model

A revision to any document creates a new file with `rN+1`. The prior file is left untouched (frozen history). The new file's standard `## Revisions` section (already part of the protocol) explains what changed, why, and the downstream impact.

```
02-plan-r1.md          (initial plan)
02-plan-r2.md          (revision 1 — Revisions section explains delta from r1)
02-plan-r3.md          (revision 2 — Revisions section explains delta from r2)
```

"Current" = highest-N file for that stage prefix. Scripts and skills always read the latest.

#### Archive layout

On PR merge, `mv agent/workstreams/<date>-<slug>/ agent/archive/<date>-<slug>/`. Before the move, `ship` writes `pr: <N>` into the frontmatter of the latest `01-spec-rN.md` so the PR number survives the move.

```
agent/archive/
  2026-04-21-document-name/
    01-spec-r1.md           # frontmatter: pr: 9
    02-plan-r1.md
    03-review-r1.md
```

#### Script changes

- **`detect-stage.sh`**: resolve active workstream as `agent/workstreams/*-$(git branch --show-current)/`. Detection rules stay the same, just path-adjusted:
  - No `01-spec-r*.md` → `explore-empty`
  - Spec exists, no `02-plan-r*.md` → `plan`
  - Latest plan has unchecked `- [ ]` steps → `implement`
  - Plan checked or unreviewed changes → `review`
  - Latest `03-review-r*.md` has unchecked items → `ship`
  - PR open → `done`
- **`bootstrap.sh`**: create `agent/workstreams/<today>-<branch>/01-spec-r1.md` from template. Refuse if the folder already exists for this branch.
- **`archive-summary.sh`**: walk `agent/archive/<date>-<slug>/` instead of `agent/archive/pr-*/`. Read `pr:` frontmatter from `01-spec-r*.md` to print the PR number alongside the date and title.
- **`load-config.sh`**: path reference updates only.

#### Skill doc updates (path references)

For each of `skills/{explore,plan,implement,review,ship,flow}/SKILL.md`, replace every path reference with the new convention. Also update:
- Plan template at `skills/plan/references/plan-template.md`.
- Findings template at `skills/review/references/findings-template.md`.
- Spec template at `skills/flow/templates/spec.md` — add `pr:` to the frontmatter comment line (blank until archive).
- `skills/flow/references/protocol.md` — document-locations table, examples.
- `skills/flow/references/reflection.md` — archive scanning path.

#### Migration approach

1. Create new layout and rewrite all scripts/skills **first**.
2. Write a one-shot migration script (in `skills/flow/scripts/migrate-layout.sh`, removed after migration) that:
   - For each `agent/archive/pr-<N>/`, resolves date via `gh pr view <N>` → creates `agent/archive/<YYYY-MM-DD>-<slug>/`. Slug derived from the PR branch name.
   - Renames files inside: `spec.md` → `01-spec-r1.md`; `IMPLEMENTATION_PLAN_*.md` → `02-plan-r1.md` (pick the latest `-v<N>` as the newest `r` if there are multiple, older ones become `-r1`, `-r2`); `local-*-r<N>.md` or `pr-<N>-r<N>.md` → `03-review-r<N>.md`.
   - Writes `pr: <N>` into the frontmatter of the new `01-spec-r1.md`.
3. Delete the migration script in the same PR (one-shot; record approach in commit message).

#### Why the `-r<N>` suffix from r1 (not r2 onwards)

Uniform from the start = simpler rule. "Latest file" is always `max(r<N>)` without special-casing "the one without a suffix". Small extra ceremony on day one; pays off as soon as any revision happens.

### Constraints

- **No behavior change beyond paths.** Stages produce the same documents with the same content. Only filenames and folders move.
- **Git history preserved.** Use `git mv` so blame/log works. The migration script uses `git mv` internally.
- **Bootstrapping order.** The flow scripts running this PR are the same ones being rewritten. Approach: write the spec to the OLD location (done — `agent/spec.md`), let plan/implement run under old paths, and have the implementation's final step migrate everything (including the current workstream's spec/plan/review) to the new layout. This is the ONLY run under the old layout.
- **Atomic PR.** All skill/script updates and the file migration land in a single PR. Downstream users should not see a half-migrated repo.
- **README.** If `README.md` references path conventions, update it in the same PR.

### Impact analysis

Files modified (path references or content):
- `skills/explore/SKILL.md`
- `skills/plan/SKILL.md` + `skills/plan/references/plan-template.md`
- `skills/implement/SKILL.md`
- `skills/review/SKILL.md` + `skills/review/references/findings-template.md`
- `skills/ship/SKILL.md`
- `skills/flow/SKILL.md`
- `skills/flow/templates/spec.md`
- `skills/flow/references/protocol.md`
- `skills/flow/references/reflection.md`
- `skills/flow/references/config.md` (if any path refs)
- `skills/flow/references/stage-detection.md` (if any path refs)
- `skills/flow/references/boundaries.md` (if any path refs)
- `skills/flow/scripts/detect-stage.sh`
- `skills/flow/scripts/bootstrap.sh`
- `skills/flow/scripts/archive-summary.sh`
- `skills/flow/scripts/load-config.sh` (if any path refs)
- `README.md` (if any path refs)
- `commands/flow*.md` (if any path refs)

Files moved (migration):
- `agent/archive/pr-{1,2,4,6,7,8}/` → `agent/archive/<date>-<slug>/`
- `agent/plans/` (empty after archiving PR #8 docs) — remove directory
- `agent/reviews/` (empty after archiving PR #8 docs) — remove directory
- `agent/spec.md` (this very spec) → `agent/workstreams/2026-04-21-document-name/01-spec-r1.md` as the final implementation step
- Any plan/review produced during this flow, same migration

Files created:
- `agent/workstreams/2026-04-21-document-name/` (at migration time)
- `skills/flow/scripts/migrate-layout.sh` (one-shot, deleted in same PR)

### Open questions

None — all decisions resolved. Leaving this section in case review surfaces new questions.
