<!-- branch: code-pipeline-reflect · date: 2026-05-06 · author: Jason Liang · pr: · base: main -->

# Findings: code-pipeline-reflect (local) · review → ship

> **What:** Six commits that bump the `code-pipeline` cell to `0.3.0` — spec template alignment, two new explore sub-sections, a `disciplines/tdd.md` empty-`FLOW_TEST_CMD` branch, a Reference Resolver review specialist, and one stale-ref fix.
> **Why:** Aligns the cell's templates and stage docs with conventions threads have already adopted; codifies a recurring class of review finding (reference rot) as its own specialist.

## Changes

Net +224 / −2 across 10 files; doc/template only — no code paths, no behavior gates other than `make lint-docs`. Six logical commits, one per plan step.

| File | Step | Edit |
|---|---|---|
| `cells/code-pipeline/stages/review/findings-template.md` | 1 | `ship/SKILL.md Step 5` → `stages/ship/ship.md Step 5` (post-rename drift). |
| `cells/code-pipeline/stages/plan/plan-template.md` | 1 | New optional `## Disciplines applied` block listing `tdd`, `commits`, `parallel`. |
| `cells/code-pipeline/templates/spec.md` | 2 | `[One-sentence lede ...]` placeholders for all 6 sections; HTML-commented `## Revisions` slot. |
| `cells/code-pipeline/disciplines/tdd.md` | 3 | New `## When FLOW_TEST_CMD is empty` section with smoke-check substitution. |
| `cells/code-pipeline/stages/plan/plan.md` | 3 | Bullet 5 in Step 2 cross-referencing the new tdd section. |
| `cells/code-pipeline/stages/explore/explore.md` | 4 | Two new `###` sub-sections: warm-fresh entry and small-change escape hatch. |
| `cells/code-pipeline/stages/review/review.md` | 5 | Reference Resolver row in the Step 3 specialist table. |
| `cells/code-pipeline/cell.yaml` | 6 | `version: 0.2.0` → `0.3.0`. |

Plus `agent/threads/2026-05-06-code-pipeline-reflect/01-spec-r1.md` and `02-plan-r1.md` (this thread's artifacts).

## Walkthrough

Doc-only change with no audience-gated runtime behavior; the per-audience trace below covers the two readers the new docs are written for.

| Audience | Path | End state |
|---|---|---|
| Fresh agent in explore stage | reads `explore.md` → hits new sub-sections → sees warm-fresh + escape hatch | Knows that `/flow:here` seeds spec from conversation; knows mechanical changes may skip explore+plan. **Gap:** "trivial" and "if in doubt, write the spec" are not decision rules — see Suggestion S5. |
| Fresh agent in plan stage with `FLOW_TEST_CMD=""` | reads `plan.md` Step 2 bullet 5 → follows pointer to `disciplines/tdd.md` → reads "When FLOW_TEST_CMD is empty" section | Knows to substitute smoke checks. **Gap:** doesn't know what to write on the plan's per-step `Tests:` line — see S6. |
| Fresh agent in review stage on a doc PR | reads `review.md` Step 3 → dispatches Reference Resolver | Specialist runs against changed stage docs. **Gap:** Reference Resolver's own example list contains a non-existent skill `kernel:run` — see S1 (caught by dogfooding the specialist on its own row). |
| Reviewer comparing tdd.md to ship.md | reads `disciplines/tdd.md:59` (smoke-check substitution) and `stages/ship/ship.md:28` (legacy "skip" text) | Two docs describe the same condition with different verbs ("substitute" vs "skip") — see S3. |

## Risk

**Low.** Doc-only PR; no code paths; `make lint-docs` clean; all 11 plan-defined verification gates pass at HEAD `c9c1e64`. The new content is additive; no existing rule was edited or removed. Highest concern is rule-clarity drift in the new content (Suggestions S5–S8), which can be addressed in this thread or deferred to a follow-up.

## Findings

### Critical

None.

### Suggestions

**S1 — `cells/code-pipeline/stages/review/review.md:54` · severity 6 · Reference Resolver self-dogfood**
The new specialist's example list cites `kernel:run` as a current skill. `kernel/run/run.md:3` explicitly states it is "not surfaced as a Claude Code skill." The specialist that teaches "verify they are current" uses an example that is itself not current. **Fix:** replace `kernel:run` with `flow:flow` (or another genuinely current skill), or drop the second example entirely.

**S2 — `agent/threads/2026-05-06-code-pipeline-reflect/01-spec-r1.md:41` and `02-plan-r1.md:34` · severity 7 · stale line refs after intra-thread edits**
Both cite `explore.md:33-60` as the lede block's location. Step 4 added two sub-sections to `explore.md` before line 33; the lede block now lives at `:41-68`. The references resolve to *real* lines but the wrong content — the exact failure mode the new Reference Resolver is meant to flag. **Fix:** update both citations to `explore.md:41-68`, or cite by section heading (`stages/explore/explore.md` § *How to produce the spec*) which is robust to line drift.

**S3 — `disciplines/tdd.md:59` ↔ `stages/ship/ship.md:28` · severity 5 · split-brain on empty `FLOW_TEST_CMD`**
`tdd.md` says substitute smoke checks; `ship.md` line 28 says "no test command configured for this project — skipping." Two docs, two verbs, same condition. A reader hitting `ship.md` first concludes *skip*; hitting `tdd.md` first they conclude *substitute*. **Fix:** add a one-line back-reference from `ship.md:28` ("If empty, follow `disciplines/tdd.md` § When FLOW_TEST_CMD is empty for smoke-check substitution") so the docs converge.

**S4 — `stages/review/review.md:54` · severity 5 · Reference Resolver row breaks the specialist-table shape**
The other 3 specialist rows have a Focus cell of 1–3 sentences; this one is 6+ sentences crammed with regex patterns, scope rules, exclusions, and output format. The cell's own readability rule (`review.md:133`) mandates "Tables for 3+ parallel items" share shape. **Fix:** move scope, output format, and command-exclusion out of the table cell into a "How the Reference Resolver runs" sub-section under Step 3; keep only a one-sentence Focus and the severity rules in the row.

**S5 — `stages/explore/explore.md:31-33` · severity 7 · "small-change escape hatch" lacks a decision rule**
"`...may legitimately skip explore + plan...`" + "`If in doubt, write the spec.`" leaves "trivial" undefined and provides no test for "in doubt." A fresh agent on a 200-line refactor can't tell which side they're on. **Fix:** convert to DO/DON'T with concrete predicates ("DO skip if: no production-code change AND no behavior change AND single-file diff") and name *who* approves the skip (the human, in the PR body). Also note the entry-point doc the author lands in when both explore and plan are skipped.

**S6 — `stages/plan/plan.md:29` · severity 6 · bullet 5 says read but not write**
The new bullet tells the planner to follow `disciplines/tdd.md` for the empty-`FLOW_TEST_CMD` branch but doesn't say what artifact to produce. **Fix:** "...and record `Tests: smoke check — <grep|diff|lint command>` on each step's `Tests:` line."

**S7 — `stages/plan/plan-template.md:21` · severity 6 · `Disciplines applied` lacks examples**
"`[Optional. Omit for trivial threads.`" leaves "trivial" and the `applied / skipped — <reason> / n/a — <reason>` distinctions undefined. **Fix:** add one example each: `applied`, `skipped — single-file rename`, `n/a — no test framework`.

**S8 — `disciplines/tdd.md` new section · severity 6 · "`make lint-docs` (or analogue)" undefined**
"or analogue" is hand-wavy for a fresh agent in a non-flow repo. **Fix:** "`make lint-docs` if defined; otherwise the project's documented lint command from `CLAUDE.md`; otherwise skip and note the absence in the plan."

### Nits

| File:line | Issue | Severity | Fix |
|---|---|---|---|
| `stages/explore/explore.md:29` | `spike.md:38` line ref is brittle — same anti-pattern as S2. | 3 | Cite by section heading. |
| `stages/explore/explore.md:24` (pre-existing, in changed file) | `## Open questions` vs template's `## Open`. | 3 | Change to `## Open`. |
| `templates/spec.md:24` | Empty `- [ ]` checkbox under `## Verification` — agents will commit it as-is. | 5 | `- [ ] [thing to check]` matching `explore.md` example. |
| `templates/spec.md:30-33` | HTML-commented `## Revisions` may be missed on `-r2`. | 5 | Add to `explore.md` Conventions: "On `-rN` where N>1, uncomment the `## Revisions` block." |
| `stages/review/review.md:54` | Reference Resolver has no documented "clean" output. | 5 | Specify: emit `Reference Resolver: clean` if no findings, so the synthesizer confirms the specialist ran. |
| `stages/explore/explore.md` ordering | New sub-sections placed between Rules and "How to produce" — existing pattern puts Rules at the end of a "How to" block. | 3 | Move new sub-sections before `### Rules`, or after "How to produce the spec". |
| `disciplines/tdd.md:59` (style) | Section uses `## When <condition>` + bullets, while sibling sections use `## How to <verb>` + Steps + `#### Rules`. | 3 | Restructure to match sibling shape, or accept the divergence as intentional for a conditional-branch section. |

## Verification

Manual checks the diff alone can't prove.

- [ ] `bash $HOME/.flow/runtime/kernel/run/scripts/detect-stage.sh` from this branch returns the expected stage (currently returns `plan` — check whether this is correct now that `02-plan-r1.md` exists and `03-review-r1.md` is being written; if not, file as a sibling thread).
- [ ] On the next thread that hits revision `-r2`, confirm the `## Revisions` HTML comment in `templates/spec.md` is uncommented (Nit re S2).
- [ ] On the next review of a stage doc edit, the new Reference Resolver actually runs as a 4th specialist (proof: visible specialist call in the boundary trace).
- [ ] If a follow-up addresses S3, both `ship.md:28` and `tdd.md:59` agree on verb ("substitute" wins).
- [ ] PR description records the `0.2.0 → 0.3.0` rationale and links commits to plan steps.

## Open

Decisions for the human at the review→ship boundary.

- **Fix in this PR vs defer?** S1 (Reference Resolver self-dogfood) and S5 (escape-hatch decision rule) are arguably blocking for the PR's quality bar; S2 is a thread-internal cleanup; S3, S4, S6–S8 are improvements but the PR ships value either way. Triage in the boundary.
- **S2 fix mechanism** — edit `01-spec-r1.md` and `02-plan-r1.md` in place (since they're this thread's own artifacts and not yet shipped), or write `-r2` revisions? In-place is lighter; `-r2` is more orthodox per the protocol.
- **S4 (table shape)** — fix now or accept divergence? The new row carries information the others omit because the new specialist is more pattern-driven; could go either way.

## Ship trail

<!-- Appended by ship stage — do not fill during review. -->
