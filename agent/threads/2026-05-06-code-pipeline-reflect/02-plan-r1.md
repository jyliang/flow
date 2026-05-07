<!-- branch: code-pipeline-reflect · date: 2026-05-06 · author: Jason Liang · pr: -->

# Plan: code-pipeline-reflect · plan → implement

> **What:** Ship a single PR bumping `code-pipeline` to `0.3.0` that aligns the spec template with `explore.md`, fills three stage-doc gaps, adds a Reference Resolver review specialist, and cleans up two stale references.
> **Why:** Friction has accumulated since the install-path unification (`4987ec9`); the cell's templates and stage docs lag behind conventions threads actually use, and one specialist class of review finding (reference rot) keeps surfacing.

## Approach

Six testable units, ordered by ascending blast radius, all under `cells/code-pipeline/**`. Each step is a single-file or near-single-file edit verified via `make lint-docs` plus a grep-based structural check (no unit tests; `FLOW_TEST_CMD=""` for this repo). Bump `cell.yaml` version once at the end.

| Decision | Conclusion |
|---|---|
| Sequencing | Mechanical fixes first (Step 1) → template (Step 2) → discipline gap (Step 3) → stage-doc additions (Steps 4–5) → version bump + final lint (Step 6). Each step lands a separate commit; the commits ship together as one PR. |
| Test surface | `make lint-docs` (existing) is the only automated gate. Each step adds a step-local grep assertion to catch regressions the linter doesn't see. |
| Reference Resolver implementation | Adds a row to the specialist table in `review.md` Step 3 with target patterns documented inline (regex hints, file globs). No new script in this thread — the specialist runs as a subagent like the others. |
| `## Disciplines applied` checklist | Lives in `plan-template.md`'s Approach section as an optional sub-block; review does not enforce. |
| Section name in spec template | Keep `## Decisions` (matches `explore.md`); document the `(resolved)` / `(open)` annotation pattern in a comment, not via a rename. |
| Discipline references | `disciplines/tdd.md` gains a `## When FLOW_TEST_CMD is empty` section; `plan.md` Step 2 gains one cross-ref line. |

## Steps

### Step 1: Mechanical reference + template cleanups

- [ ] Tests: `grep -n "SKILL.md" cells/code-pipeline/stages/review/findings-template.md` returns nothing; `grep -nE "^##\\s+Disciplines applied" cells/code-pipeline/stages/plan/plan-template.md` returns one match.
- [ ] Code: Edit `cells/code-pipeline/stages/review/findings-template.md:63` — replace `ship/SKILL.md Step 5` with `stages/ship/ship.md Step 5`.
- [ ] Code: Edit `cells/code-pipeline/stages/plan/plan-template.md` — add `## Disciplines applied` (optional) sub-block after `## Approach`, listing `tdd`, `commits`, `parallel` each with a `[applied | skipped | n/a — reason]` slot. Mark soft per spec.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] All checks green, no regressions.

### Step 2: Spec template alignment with `explore.md`

- [ ] Tests: `grep -cE "^\\[One-sentence lede" cells/code-pipeline/templates/spec.md` returns ≥6 (one per section); `grep -nE "^## Revisions" cells/code-pipeline/templates/spec.md` returns one match in a comment block (optional slot).
- [ ] Code: Edit `cells/code-pipeline/templates/spec.md` to add `[One-sentence lede — ...]` placeholders under `## Scope`, `## Decisions`, `## Design`, `## Constraints`, `## Verification`, `## Open` matching the section descriptions in `cells/code-pipeline/stages/explore/explore.md` § *How to produce the spec*.
- [ ] Code: Add an HTML-comment-fenced optional `## Revisions` block at the bottom of the template, with a one-line usage note ("only on `-rN+1`; explain what changed since `-rN-1`").
- [ ] Code: Inline comment near `## Decisions` documenting the `(resolved)` / `(open)` annotation convention used by 7 of 11 historical threads.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] Diff scan: side-by-side `templates/spec.md` vs `stages/explore/explore.md` template block — every section present in both; section names identical.

### Step 3: `disciplines/tdd.md` empty-FLOW_TEST_CMD branch + `plan.md` cross-ref

- [ ] Tests: `grep -nE "FLOW_TEST_CMD" cells/code-pipeline/disciplines/tdd.md` returns ≥2 matches in a `## When FLOW_TEST_CMD is empty` heading and body; `grep -nE "FLOW_TEST_CMD|disciplines/tdd.md" cells/code-pipeline/stages/plan/plan.md` returns ≥1 match in Step 2.
- [ ] Code: Edit `cells/code-pipeline/disciplines/tdd.md` — add `## When FLOW_TEST_CMD is empty` section describing: write smoke-test descriptions instead of unit tests; verify via grep / structural checks; record the chosen verification in the plan's Steps. Source the language from `2026-04-21-reflect-verify-and-test-cmd/01-spec-r1.md` (already canonicalized there).
- [ ] Code: Edit `cells/code-pipeline/stages/plan/plan.md` Step 2 ("Design the approach") — add a one-line bullet referencing `disciplines/tdd.md` for the empty-FLOW_TEST_CMD branch.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] Smoke check: re-read the four shipped plans (`auto-bump-marketplace-version`, `prefer-askuserquestion`, `flow-v1-adopt`, `flow-v2-config`) — confirm the new `tdd.md` section captures their inline caveat without contradiction.

### Step 4: `explore.md` warm-fresh entry + small-change escape hatch

- [ ] Tests: `grep -nE "^### (Warm-fresh|Conversation-derived|Small-change|Review-only)" cells/code-pipeline/stages/explore/explore.md` returns ≥2 matches (one per new sub-section).
- [ ] Code: Edit `cells/code-pipeline/stages/explore/explore.md` — add `### Warm-fresh / conversation-derived specs` (≤6 lines) explaining the `flow:here` path: spec is seeded from conversation history, not codebase study; still apply the pre-spec analysis (similarity, impact, dependencies). Mirror the structure of `stages/spike/spike.md:38` so the two stay coherent.
- [ ] Code: Add `### Small-change escape hatch` (≤6 lines) — when a change is mechanical or housekeeping (e.g. `2026-04-17-flow-skill-refactor/`), it is permitted to skip explore + plan and produce only a review/findings doc. Author records the reason in the PR body.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] Structural check: `wc -l cells/code-pipeline/stages/explore/explore.md` — increase ≤30 lines from baseline.

### Step 5: Review stage Reference Resolver specialist

- [ ] Tests: `grep -nE "Reference Resolver" cells/code-pipeline/stages/review/review.md` returns ≥1 match in Step 3's specialist table.
- [ ] Code: Edit `cells/code-pipeline/stages/review/review.md` Step 3 — add a row to the parallel-specialists table: `Reference Resolver` specialist that grep-validates `Step \d`, `Step \d\.\d`, backticked section names (e.g. `` `"Conversation absorption"` ``), and relative file paths inside `cells/code-pipeline/stages/**` and the changed files. Provide a one-line job description and 3-4 example regex patterns.
- [ ] Code: Add a one-sentence note that command-linting (`commands/*.md`) is *not* in this specialist's scope — sibling thread.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] Dry-run trace: read the new `review.md` end-to-end as if running the review stage on a small change; confirm the new specialist's instructions are concrete enough to dispatch as a subagent prompt without further clarification.

### Step 6: Version bump + final lint pass

- [ ] Tests: `grep -nE "^version: 0\\.3\\.0" cells/code-pipeline/cell.yaml` returns one match.
- [ ] Code: Edit `cells/code-pipeline/cell.yaml` — bump `version: 0.2.0` → `0.3.0`.
- [ ] Test run: `make lint-docs` → `[PASTE TEST SUMMARY HERE]`
- [ ] End-to-end check: run `bash $HOME/.flow/runtime/kernel/run/scripts/detect-stage.sh` from this branch's root — confirms stage detection still works (sanity, no behavior change expected).
- [ ] All implementation steps completed; all greps from Steps 1–5 still match; `make lint-docs` clean.

## Constraints

Hard rules and guardrails for implementation.

- **DO NOT** modify install scripts, marketplace registration, or kernel-level docs (`runtime/kernel/run/**`) — explicitly out of scope per spec.
- **DO NOT** rewrite or restructure historical thread artifacts under `agent/threads/*` — they are frozen.
- **DO** preserve every existing rule and section verbatim in stage docs; this PR adds and re-aligns, never prunes.
- **DO** keep each step's diff reviewable in one sitting — if a step grows past ~50 lines net change, split.
- **DO** commit each step independently with a message linking it to the spec/plan section (per `disciplines/commits.md`).
- **`FLOW_TEST_CMD=""`** for this repo — every step's verification uses `make lint-docs` plus a step-local grep assertion. No unit tests are written.
- **One PR for all six steps** — atomicity of the `0.3.0` version bump.

## Verification

What must hold when implementation completes.

- [ ] All 6 steps' grep assertions pass.
- [ ] `make lint-docs` passes on the final commit.
- [ ] `cells/code-pipeline/cell.yaml` shows `version: 0.3.0`.
- [ ] `templates/spec.md` matches the structure described in `stages/explore/explore.md` lines 33-60 (section names + lede placeholders).
- [ ] `disciplines/tdd.md` has a `## When FLOW_TEST_CMD is empty` section; `plan.md` Step 2 references it.
- [ ] `explore.md` covers warm-fresh and small-change escape hatch in ≤30 added lines total.
- [ ] `review.md` Step 3 lists Reference Resolver as a specialist with concrete patterns.
- [ ] `findings-template.md` no longer references `ship/SKILL.md`.
- [ ] Visual diff: side-by-side comparison of the new spec template vs. an existing shipped spec (e.g. `agent/threads/2026-04-22-docs-readability/01-spec-r1.md`) — section structure matches.
- [ ] `bash $HOME/.flow/runtime/kernel/run/scripts/detect-stage.sh` runs cleanly from this branch.
- [ ] PR body documents the `0.2.0 → 0.3.0` reasoning and links each commit to a step.

## Open

No open questions for implement — all decisions are resolved in `01-spec-r1.md` `## Decisions`. Sibling-thread items are queued in the spec's `## Open`.
