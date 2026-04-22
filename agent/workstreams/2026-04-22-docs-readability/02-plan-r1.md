<!-- branch: docs-readability · date: 2026-04-22 · author: Jason Liang · pr: -->

# Plan: docs-readability

## Status
plan → implement

## What was done
- Designed a 6-phase, 12-step plan that applies the 10 readability principles from the spec across all 32 source MD files, plus a new `skills/docs-style/SKILL.md`.
- Ordered phases by risk: style guide first (greenfield, no regression surface), then low-risk files to shake out conventions, SKILL.md files, templates last (highest structural risk), README last for full-treatment polish.
- Grouped commits by file-risk profile so each commit is independently reviewable.
- Identified the verification strategy for a docs-only repo: cross-reference grep + end-to-end `/flow-spike` spot-check replaces conventional tests.

## Decisions needed

Resolved at plan → implement boundary (user answered via `AskUserQuestion`):

- [x] **Lint target → Yes**: Step 12 is active. Add `make lint-docs` after phase 6b.
- [x] **Commit granularity → one per phase** (6 commits): style guide / low-risk / SKILL.md / templates / README / verification.
- [x] **Glossary → separate file at `skills/flow/references/glossary.md`**: linked from both `skills/docs-style/SKILL.md` and `flow/references/protocol.md`. Step 1 splits into 1a (style guide) and 1b (glossary).

## Verify in reality
- [ ] After phase 4 (templates) — fill a template manually or with Claude and confirm the downstream stage still produces a valid artifact (run `bash skills/flow/scripts/bootstrap.sh throwaway-branch`, check the generated `01-spec-r1.md` matches expectations, then delete the branch).
- [ ] After phase 6 — run `/flow-spike "no-op: add a code comment"` end-to-end on a throwaway branch, confirm the spike produces a draft PR without crashing, then close without merging.
- [ ] Frontmatter `description:` lines on all 12 `SKILL.md` files are byte-identical to pre-edit (skill-loader matches on these).
- [ ] Every cross-doc file path reference still resolves (a post-edit grep+path-exists check).

## Implementation Steps

### Step 1a: Create `skills/docs-style/SKILL.md` ✅

The canonical reference for every subsequent edit. Written first so we can link every later change back to a specific principle.

- [x] Tests: N/A (new file); verify it follows its own principles.
- [x] Code: Create `skills/docs-style/SKILL.md` with:
  - Frontmatter: `name: docs-style`, description starting "Apply when authoring or editing markdown docs in this repo", `metadata.short-description`.
  - One-sentence lede naming the two readers (human scanner, next author).
  - The 10 principles, each as a `### Principle N: <Name>` subsection with a 1-line rule + one good example + one bad example.
  - A link to `skills/flow/references/glossary.md` (built in step 1b) under a `## Glossary` section.
  - A `## DO / DO NOT` quick-reference block at the bottom.
- [x] Test run: Visual scan; compare against its own principles.
- [x] All principles present, glossary linked, no TODO markers left.

### Step 1b: Create `skills/flow/references/glossary.md` ✅

Canonical one-term-per-concept list. Referenced from `skills/docs-style/SKILL.md` and (in step 4) from `flow/references/protocol.md`.

- [x] Tests: N/A (new file).
- [x] Code: Create `skills/flow/references/glossary.md` with:
  - Short header and lede naming the purpose (one-term-per-concept; enforce on every edit).
  - A table: `Term | Use | Don't use | Why`. Rows for at minimum: spec, plan, findings, workstream folder, stage, skill, rule, revision, pipeline, draft PR, boundary.
- [x] Test run: Visual scan — 13 entries populated, table renders.
- [x] Glossary populated with ≥10 entries; linked from `skills/docs-style/SKILL.md`.

### Step 2: Build the cross-reference inventory

Read-only step. Produces an in-conversation inventory of every file path and every section-heading reference across the corpus so we don't accidentally break a link.

- [ ] Tests: N/A (inventory step).
- [ ] Code: Grep across all in-scope MD files for:
  - Backticked file paths: ``` `skills/...` ```, ``` `references/...` ```, etc.
  - Section-by-name references: "see the `## Quick capture` section", "per `How revisions work`", etc.
  - `$ARGUMENTS` and bash heredocs in `commands/*.md` (restructuring these is especially risky).
- [ ] Test run: Compile the output into a checklist block in this plan file under a new `## Cross-ref inventory` appendix, or hold it in conversation — final choice made at implement time.
- [ ] Every file path found is confirmed to exist; every section-name reference maps to a live heading.

### Step 3: Phase 2a — low-risk files

First batch applying the full principles to real files. Proves the workflow.

Files (8 total): `commands/flow.md`, `commands/flow-adopt.md`, `commands/flow-config.md`, `commands/flow-reflect.md`, `commands/flow-spike.md`, `skills/teach/references/capture.md`, `skills/teach/references/guidelines.md`, `skills/teach/references/template.md`.

- [ ] Tests: After edits, grep each file for untagged ```` ``` ```` fences; grep for raw (non-backticked) file paths; confirm every `## heading` is referenced from the same place it was before (or update the reference in the referring doc).
- [ ] Code: Apply principles 1-10 file by file. For `commands/*.md`, preserve every embedded bash block and every `$ARGUMENTS` reference byte-identically; only reformat prose and headings around them.
- [ ] Test run: Manually read each post-edit file top to bottom; it should scan cleanly in under 30 seconds per file.
- [ ] All 8 files edited, no broken cross-refs.

### Step 4: Phase 2b — `skills/flow/references/*.md`

Medium-risk: these are loaded on demand by SKILL.md files. Structural changes cascade only if the referring SKILL.md uses section-name references.

Files (6 total): `boundaries.md`, `config.md`, `protocol.md`, `reflection.md`, `stage-detection.md`, `user-interaction.md`.

- [ ] Tests: For each referring SKILL.md (e.g., `flow/SKILL.md` references `references/user-interaction.md`), verify every `## heading` mentioned in the referrer still exists in the reference file.
- [ ] Code: Apply principles 1-10. Pay special attention to `protocol.md` — it's the document-protocol spec, so its own structure is load-bearing for downstream agents.
- [ ] Test run: Grep `skills/**/SKILL.md` for each reference file's known section names; all must still resolve.
- [ ] All 6 files edited, no broken referrer links.

### Step 5: Phase 3a — `skills/flow/SKILL.md`

Single-file step. This is the entry-point skill; we edit it alone so it becomes the canonical example of what a post-edit SKILL.md looks like.

- [ ] Tests: Frontmatter `description:` byte-identical to pre-edit. Every file path in the body still resolves.
- [ ] Code: Apply principles 1-10. Simplify the pipeline diagram; add one-sentence lede to each `##` section; consolidate the "Detect the current stage" numbered list into the existing format but with a clearer intro sentence.
- [ ] Test run: `bash skills/flow/scripts/detect-stage.sh` still prints a valid stage string on main branch (i.e., the bash hasn't drifted from the doc — it shouldn't have, since we didn't touch bash).
- [ ] File passes its own principles; no broken refs.

### Step 6: Phase 3b — stage SKILL.md files

Parallel-safe: each file is independent of the others at the SKILL.md level (they reference shared refs in `flow/references/`, already handled in step 4).

Files (5 total): `skills/explore/SKILL.md`, `skills/plan/SKILL.md`, `skills/implement/SKILL.md`, `skills/review/SKILL.md`, `skills/ship/SKILL.md`.

- [ ] Tests: Frontmatter `description:` byte-identical. Every `### Step N` renumbered cleanly (no 1.5s). `review/SKILL.md` findings-template reference still resolves.
- [ ] Code: Apply principles 1-10. **Key focus**: `ship/SKILL.md`'s 1, 1.5, 2, 3, 3.5, 4, 5, 6, 7, 7.5, 8, 9 sequence becomes 1, 2, 3, ..., 10 (absorb the half-steps into their neighbors or promote them). Consolidate DO/DON'T rules per section.
- [ ] Test run: Read each file top to bottom; steps should flow linearly. Grep for any remaining `Step N.5` — zero matches expected.
- [ ] All 5 files edited, steps cleanly numbered, rules consolidated.

### Step 7: Phase 3c — meta / internal SKILL.md files

The remaining SKILL.md files: cross-cutting rules (`commits`, `tdd`, `parallel`), the teach skill, the spike skill.

Files (5 total): `skills/commits/SKILL.md`, `skills/tdd/SKILL.md`, `skills/parallel/SKILL.md`, `skills/teach/SKILL.md`, `skills/spike/SKILL.md`.

- [ ] Tests: Frontmatter `description:` byte-identical. `teach/SKILL.md` references to `references/template.md` / `references/guidelines.md` / `references/capture.md` still resolve. `spike/SKILL.md` references to `templates/pr-body.md` and `templates/spike-log.md` still resolve.
- [ ] Code: Apply principles 1-10. In `teach/SKILL.md`, add a cross-reference to the new `skills/docs-style/SKILL.md` under "Design principles" (so `teach` naturally picks up the style guide when creating new skills).
- [ ] Test run: Read each file; confirm cross-refs resolve.
- [ ] All 5 files edited.

### Step 8: Phase 4 — templates (highest risk)

Templates are filled literally by stage skills. Changing their section structure changes what gets produced downstream. Edit conservatively: reformat around the scaffolding, don't reshape it.

Files (5 total): `skills/flow/templates/spec.md`, `skills/plan/references/plan-template.md`, `skills/review/references/findings-template.md`, `skills/spike/templates/pr-body.md`, `skills/spike/templates/spike-log.md`.

- [ ] Tests: Diff each template's section headings pre/post edit — they must be identical (only prose and formatting around them changes).
- [ ] Code: Apply principles 1, 6, 7, 9, 10 (lede, tables, tagged fences, backticked paths, reader stance). Skip principles that would alter section structure (principle 3 step-renumbering is N/A here since templates use `## Section` not steps).
- [ ] Test run: Manual fill test — on a throwaway branch, run `bash skills/flow/scripts/bootstrap.sh docs-readability-throwaway` and confirm the generated `01-spec-r1.md` has the same scaffold. Delete the throwaway branch after.
- [ ] All 5 templates edited; section scaffolds byte-identical where the stage skill depends on them.

### Step 9: Phase 5 — `README.md`

Full-treatment edit per user's decision. The README is the highest-visibility doc, so principles must shine here.

- [ ] Tests: External links (if any) still resolve. Every internal file path still exists.
- [ ] Code: Apply principles 1-10. Likely the biggest individual diff because the README is 183 lines with several sections that could use ledes. Preserve the ASCII pipeline diagram (it's good) but check its alignment.
- [ ] Test run: Render on GitHub (push the branch as draft) and scan — all tables, code fences, and the pipeline diagram must render correctly.
- [ ] README scans cleanly; structure coherent with the rest of the corpus.

### Step 10: Phase 6a — corpus-wide consistency pass

Final pass across all edited files to catch drift from the style guide introduced while batching.

- [ ] Tests:
  - Grep for untagged ```` ``` ```` fences across all in-scope MDs: zero matches expected.
  - Grep for common glossary drift (capitalized `Spec` outside a proper noun context; `Plan` when we mean `plan`): zero offending matches.
  - Grep for decimal steps (`Step \d+\.\d`): zero matches.
  - Grep for orphaned cross-refs: every backticked `skills/…` path exists.
- [ ] Code: Fix any lint failures from the greps above.
- [ ] Test run: All four greps clean.
- [ ] Consistent corpus; style-guide principles applied uniformly.

### Step 11: Phase 6b — end-to-end spike

The load-bearing real-world test: can the pipeline still complete a spike after all edits?

- [ ] Tests:
  - Run `/flow-spike "add a temp comment to README"` on a throwaway branch off main (*not* off `docs-readability`; we want to test against a clean baseline so our edits are what's under test).
  - Wait, actually: we must test the *post-edit* skills, so we run the spike from `docs-readability` — the skill code living in `~/.claude/skills/` is installed via `make install`.
  - Run `make install` first, then `/flow-spike "trivial test"` on a throwaway branch.
  - Verify the spike produces a draft PR, fills the PR body template correctly, and exits cleanly.
- [ ] Code: No code changes unless the spike reveals a regression; if it does, create a revision (`02-plan-r2.md` with a Revisions entry) describing what needs fixing.
- [ ] Test run: Spike completes; draft PR exists with expected body; no crashes.
- [ ] Close and delete the spike's draft PR and throwaway branch.

### Step 12: Phase 6c — lint target

User resolved the optional decision as "Yes, add it".

- [ ] Tests: `make lint-docs` passes on the post-edit corpus.
- [ ] Code: Add a Makefile target:
  - Grep for untagged code fences in `**/*.md` under `README.md`, `skills/`, `commands/`, excluding `agent/workstreams/**`.
  - Grep for raw (non-backticked) file-path-looking strings in prose — imperfect but catches obvious cases.
  - Exit non-zero on any match.
- [ ] Test run: `make lint-docs` is green.
- [ ] Target exists and passes.

## Architecture Decisions

- **Phase order by risk, not by importance**: style guide first (zero regression surface), templates last (highest regression surface). This is opposite the "impact first" instinct but safer for a docs-only refactor where the blast radius is skill-loader behavior.
- **Commits grouped by phase**: each commit is self-reviewable and bisectable. A bad commit affects a bounded file set.
- **No synthesized tests**: for a docs-only repo, cross-ref grep + end-to-end spike stands in for unit tests. The style guide is the implicit spec; the spike is the implicit integration test.
- **Aggressive restructure with reactive repair** (per user decision): we don't try to preserve every heading. If a rename breaks a cross-ref, step 10's grep catches it; if it breaks LLM skill-loading, step 11's spike catches it. Iterate post-merge if something subtler slips through.
- **Style guide as a skill, not a loose doc**: living at `skills/docs-style/SKILL.md` means `teach` (the skill-creation skill) can trigger it automatically when users create new skills. A loose `STYLE.md` would rely on author memory.
- **Glossary inline in the style guide** (pending user confirmation): keeps the style guide self-contained. Split into `flow/references/glossary.md` only if it grows past ~20 terms.

## Success Criteria

- [ ] `skills/docs-style/SKILL.md` exists and is internally consistent with its own principles.
- [ ] All 32 in-scope MD files pass the 4 corpus-wide greps (untagged fences, decimal steps, glossary drift, orphaned cross-refs).
- [ ] Every `SKILL.md` frontmatter `description:` line is byte-identical to pre-edit.
- [ ] `/flow-spike "trivial test"` runs end-to-end on a throwaway branch without regression.
- [ ] Each commit is independently reviewable; reviewer can bisect if regression appears.
- [ ] One PR on branch `docs-readability`, targeting `main`, passing review.
