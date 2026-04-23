<!-- branch: docs-readability · date: 2026-04-22 · author: Jason Liang · pr: -->

# Findings: docs-readability (local changes, 7 commits)

## Status
review → ship

## What was done
- Reviewed 34 changed files (+1,517 / -627) across 7 commits on `docs-readability` vs `origin/main`.
- Launched 3 specialist subagents in parallel:
  - **Principle auditor**: verified the 10 principles from `skills/docs-style/SKILL.md` were applied.
  - **Load-bearing verifier**: checked frontmatter, heading names, template scaffolds, cross-refs, bash invocations, `$ARGUMENTS`.
  - **Consistency auditor**: scanned for glossary drift, cross-doc narrative issues, internal inconsistencies in the new `docs-style` skill.
- Ran my own E2E walkthrough across 5 audiences (GitHub browser, plugin installer, `/flow` on empty workspace, `/flow-spike` run, `make lint-docs`).
- Counts: **7 critical**, **16 suggestions**, **7 nits**, **1 question**.

## Decisions needed

- [ ] **Principle 2 vs `## Goal` reality.** The docs-style principle says "verb-first heading names", but 8 stage/internal SKILL.md files use a shared `## Goal` section as a structural label. Options:
  - **(a) Amend the principle** to whitelist structural labels (`## Goal`, `## Schema`, `## Security`, `## Conventions`). The style guide becomes honest about its own corpus. (Recommended — smaller diff, less churn, keeps consistent cross-file shape.)
  - **(b) Rewrite all 8 headings** to verb-first (e.g., `## Goal` → `## What this skill does`). Consistency with the stated rule; bigger diff.
  - **(c) Fold each `## Goal` section into the opening lede and delete the heading.** Shortest result; strongest adherence; highest editorial risk.
- [ ] **`skills/flow/references/boundaries.md` section renames.** The refactor renamed `## Revisions` → `## Handle revisions`, `## Auto-advance vs pause` → `## Choose auto-advance vs pause`, `## Review-finding triage (review → ship)` → `## Triage review findings at the review → ship boundary`. No runtime breakage (nothing greps these by literal name), but "`## Revisions`" is a load-bearing term in the protocol.
  - **(a) Keep the renames** (the principle-2 move was correct).
  - **(b) Restore `## Revisions`** specifically (since it's the glossary-canonical term) but keep the other two renames. (Recommended.)
  - **(c) Restore all three.**

## Verify in reality
- [ ] `bash skills/flow/scripts/bootstrap.sh docs-readability-throwaway` on a throwaway branch — confirm the generated `01-spec-r1.md` matches expectations. Template was left byte-identical so should pass.
- [ ] `/flow-spike "add temp comment"` end-to-end — confirms the full pipeline still completes after all skill edits. Close and delete the PR and branch after.
- [ ] Render `README.md` and a couple of SKILL.md files on GitHub — confirm tables, callouts, and the ASCII pipeline diagram render correctly.

## Critical

### 1. `commands/flow-spike.md:20` — broken cross-reference to renamed section

The line reads:

```markdown
See `skills/spike/SKILL.md` under "Conversation absorption".
```

That section was renamed to `## How to determine entry mode` in phase 3. The reference no longer resolves. A human (or an LLM that follows links) reading this command will hit a dead-end.

**Fix:** Change "Conversation absorption" → "How to determine entry mode" on line 20.

### 2. `commands/flow-spike.md:52` — broken cross-reference to renumbered step

The line reads:

```markdown
Record the PR number into the spec's frontmatter comment per ship Step 7.5.
```

Phase 3 renumbered `skills/ship/SKILL.md`: old Step 7.5 is now **Step 10: Record the PR number in spec frontmatter**. The literal "Step 7.5" no longer exists anywhere in the codebase.

**Fix:** Change "ship Step 7.5" → "ship Step 10" on line 52.

### 3. `skills/flow/references/config.md:17` — stale ship-step reference

Table cell reads:

```markdown
| FLOW_TEST_CMD | ... Shell command ship runs in Steps 1.5 and 8 (before fixes + after push). |
```

Phase 3 renumbered ship — Step 1.5 is now **Step 2: Run the tests** and Step 8 is now **Step 11: Re-run tests**. The "Steps 1.5 and 8" literal is stale.

**Fix:** Change "Steps 1.5 and 8" → "Steps 2 and 11" at `config.md:17`.

### 4. `skills/review/references/findings-template.md:69` — stale ship-step reference

The template contains the literal:

```markdown
See ship/SKILL.md Step 3.5.
```

There is no Step 3.5 after renumbering; that content now lives inside **Step 5: Present the fix summary** (the Ship Summary block).

**Fix:** Change "ship/SKILL.md Step 3.5" → "ship/SKILL.md Step 5" at `findings-template.md:69`.

### 5. `skills/review/SKILL.md:59-62` — specialist-subagent table has swapped columns

Phase 3 converted the loose specialist-subagent list into a table. The column assignment went wrong: the Test Coverage Analyzer's Focus column says "Be aggressive." (which was originally the mindset, not the focus), and the Pattern Reuse Scanner's Threshold column says "Be aggressive." while its Focus column holds the Level 1/2/3 content (which IS the focus, so actually correct for that row).

Current table:

```markdown
| Test Coverage Analyzer | Be aggressive. | New public API with zero tests = 10. ... |
| Pattern Reuse Scanner | Level 1: ... Level 3: ... | Be aggressive. |
```

The Focus column for Test Coverage should describe *what* to look for (coverage gaps), not the mindset. The original prose said: "Test Coverage Analyzer — **be aggressive**. New public API with zero tests = 10. ..." — "be aggressive" was a descriptor of threshold aggressiveness, not the focus area.

**Fix:** Restructure the table so each row's Focus cell describes what the agent looks for and Threshold describes the severity rule. For Test Coverage: Focus = "Coverage of new / changed behavior"; Threshold = "New public API with zero tests = 10. ..." (drop the orphan "Be aggressive." — the overall note can move to the section lede).

### 6. `skills/flow/references/reflection.md:38` — stale "cross-archive" reference

The line reads:

```markdown
looking across shipped workstreams for cross-archive patterns.
```

The `agent/archive/` directory no longer exists (was removed in a prior workstream). The rest of this doc uses "cross-workstream" correctly. This one stale reference confuses readers.

**Fix:** Change "cross-archive patterns" → "cross-workstream patterns" at `reflection.md:38`.

### 7. Findings-template title disagrees with review/SKILL.md

- `skills/review/references/findings-template.md:6` starts its scaffold with `# Review: <PR ... or branch ...>`.
- `skills/review/SKILL.md:93` (inside the Step-5 fenced example) uses `# Findings: [PR title or branch description]`.
- `skills/flow/references/glossary.md:18` canonicalizes the noun as `findings`.

Whichever gets filled first wins; past `03-review-r*.md` files are split between the two shapes. The refactor did not resolve it.

**Fix:** Pick `# Findings: <PR title or branch description>` (matches glossary). Align both `findings-template.md:6` and the embedded example in `review/SKILL.md:93`.

## Suggestions

### docs-style/SKILL.md violates some of its own principles

The style-guide skill (phase 0) falls short on the rules it defines:

- **Principle 1 (lede)**: `## DO / DO NOT quick reference` drops straight into the bullet list; `## Glossary` has no lede either.
- **Principle 2 (verb-first)**: `## The ten principles`, `## Glossary`, `## DO / DO NOT quick reference` are all noun phrases. `## Related skills` is acceptable as convention.
- **Internal inconsistency**: Principle 8 lists 3 callout types (Note, Warning, Tip); the DO / DO NOT block only names Note and Warning. Either drop Tip from principle 8 OR add it to the DO block.

**Fix:** Add ledes; rename headings; align callout list. Candidate headings: `## How to apply the ten principles`, `## Look up a term`, `## DO / DO NOT at a glance`.

### "convention" / "guideline" drift vs glossary `rule`

Glossary entry for `rule` bans "convention" and "guideline". Real drift in prose:

| File:line | Current text | Severity |
|---|---|---|
| `skills/teach/SKILL.md:14` | "For simple rules and conventions..." | Suggestion |
| `skills/teach/SKILL.md:16` | heading `### How to capture a simple rule or convention` | Suggestion |
| `skills/teach/SKILL.md:131` | "the full set of skill-authoring design guidelines..." | Suggestion |
| `skills/teach/references/guidelines.md:1,3` | `# Skill design guidelines` / "the principles below" | Suggestion (file name is load-bearing — see below) |
| `skills/flow/references/reflection.md:18` | table row "Conventions: ..." | Suggestion |
| `skills/flow/references/reflection.md:68` | "Update to CLAUDE.md (new convention)" | Suggestion |
| `commands/flow-reflect.md:35` | "A new convention, with exact text" | Suggestion |
| `skills/implement/SKILL.md:21` | "project patterns and guidelines" | Nit |

The filename `skills/teach/references/guidelines.md` is cross-referenced from `skills/teach/SKILL.md:131`. Renaming the file is safe only if the referrer is updated in the same commit. Simpler: add a glossary carve-out for "skill design guidelines" (legacy term for a specific doc) OR rename to `rules.md` with the referrer update.

### "phase" leakage vs glossary `stage`

Glossary reserves `phase` for sub-stage loops. The loose uses below blur stage/phase:

- `skills/implement/SKILL.md:28` — "six-phase loop" where four of the six items (`Explore / Implement / Test / Commit / Update plan / Repeat`) collide with stage names. Relabel as "six-step loop".
- `skills/commits/SKILL.md:41` — "Each completed phase or feature." Weaker case; `step or feature` would be cleaner.

### `## Conventions` section headings in explore and plan

- `skills/explore/SKILL.md:84` — `## Conventions`
- `skills/plan/SKILL.md:51` — `## Conventions`

Violates both glossary (use `rule`) and principle 2 (verb-first). Rename to `## Where files live` or `## How to name and locate artifacts`.

### `## Related skills` presence inconsistent across stage skills

Section present in: `implement`, `review`, `ship`, `spike`, `flow`, `teach`, `docs-style`.
Section missing in: `explore`, `plan`, `tdd`, `commits`, `parallel`.

Stage skills should either all have it or none. Add it to the 5 missing files, or remove from the 7 that have it. Recommend adding.

### Double-paragraph ledes in flow and spike SKILL.md

Principle 10 says "Every doc opens with one sentence".

- `skills/flow/SKILL.md:10-14` — one sentence, then a second paragraph at line 12, then a `> **Note:**` callout at line 14. Three blocks before the first `##`. Consider merging the second paragraph (which points at docs-style and glossary) into the lede.
- `skills/spike/SKILL.md:11-13` — two paragraphs (1 sentence + 2 sentences). Consider compressing.

### README ↔ flow/SKILL.md pipeline-table wording drift

- `README.md:106` ship row: `GitHub PR (records pr: in spec; workstream folder stays at agent/workstreams/<date>-<branch>/)`
- `skills/flow/SKILL.md:30`: `GitHub PR (records pr: <N> in the spec's frontmatter comment; workstream folder stays in place)`

Same intent, different wording. The flow/SKILL.md version is more precise. Align both — README is the user's first touchpoint.

### `commands/flow-config.md` step headings are not verb-first

Lines 13, 22, 32, 42 use `Step 1: Spec template` / `Step 2: Test command` / `Step 3: Extra stages` / `Step 4: Hooks dir`. Principle 3's example shows verb-first. Rewrite as `Step 1: Choose the spec template` etc.

### 4. `## Goal` heading pattern across 8 skills

See Decision 1. Affected files: `skills/explore/SKILL.md:13`, `skills/plan/SKILL.md:13`, `skills/implement/SKILL.md:13`, `skills/review/SKILL.md:14`, `skills/ship/SKILL.md:13`, `skills/commits/SKILL.md:13`, `skills/tdd/SKILL.md:13`, `skills/parallel/SKILL.md:13`.

### 5. `skills/teach/SKILL.md` noun-phrase cluster

- `## Quick capture` (line 12) — should be `## How to capture a one-off rule`.
- `## Full skill creation` (line 45) — should be `## How to create a new skill`.
- `## Design principles` (line 126) — should be `## How to apply the house style`.
- `### Where skills live` (line 49) — should be `### How to pick project-level vs user-level`.
- `### Quick-capture rules` (line 35) — this is a 4-step numbered list; should be `### How to run quick-capture` with explicit `### Step N` subsections (applies principle 3 spirit).

### 6. Other noun-phrase `##` headings (lower priority than #4, #5)

| File:line | Heading |
|---|---|
| `skills/flow/SKILL.md:16` | `## The pipeline` |
| `skills/flow/SKILL.md:80` | `## Scripts` |
| `skills/flow/references/protocol.md:7` | `## Sections` |
| `skills/flow/references/protocol.md:118` | `## Document locations` |
| `skills/flow/references/config.md:9` | `## Schema` |
| `skills/spike/SKILL.md:15` | `## Vocabulary` |
| `skills/spike/SKILL.md:71` | `## Workstream layout` |
| `skills/spike/SKILL.md:84` | `## Decision policy ...` |

Acceptable under either decision-1 outcome; low priority.

### 7. Bulleted lists of 3+ parallel items that should be tables (principle 6)

| File:lines | What it is |
|---|---|
| `skills/tdd/SKILL.md:62-65` | 4 parallel "Testing scope" bullets. |
| `skills/commits/SKILL.md:39-44` | 6 parallel "When to commit immediately" event bullets. |
| `skills/parallel/SKILL.md:21-25` | 5 parallel "parallelize" operation bullets. |
| `skills/parallel/SKILL.md:37-40` | 4 parallel "sequential" operation bullets. |
| `skills/spike/SKILL.md:102-106` | Step 1 Explore: 5 bullets that are actually sequential instructions. |
| `skills/spike/SKILL.md:110-137` | Steps 2-5: each uses bullets where numbered sub-steps would parse as principle-3 steps. |

### 8. Findings-template duplication

`skills/review/SKILL.md:92-133` embeds a full findings template in a fenced code block. `skills/review/references/findings-template.md` also contains a findings template. Two sources of truth; the embedded one in the SKILL.md will drift. Recommend either (a) replacing the embedded template with a pointer to the reference file, or (b) removing the standalone reference file and keeping the embedded one.

### 9. Genuine glossary drift (principle 5)

| File:line | Current | Recommended |
|---|---|---|
| `README.md:72` | "Plan steps 3-5 updated." (inside a code-block example) | "plan steps 3-5 updated" |
| `skills/flow/references/protocol.md:89` | Same "Plan steps 3-5" — copy of README. | "plan steps 3-5" |
| `skills/spike/SKILL.md:78` | Table cell: `\| \`02-plan-r1.md\` \| Plan stage. \|` | `\| plan stage. \|` |
| `skills/spike/SKILL.md:108` | `### Step 2: Plan` | `### Step 2: Run the plan stage` (also fixes principle 2) |
| `commands/flow-spike.md:36` | `### Step 2: Plan` | Same fix. |
| `commands/flow-config.md:13` | `### Step 1: Spec template` | `### Step 1: Choose the spec template` |

Acceptable glossary uses (diagram/table labels or sentence openers): `README.md:27,31,39` (diagram), `skills/flow/SKILL.md:26-30` (stage-IO table), `protocol.md:76` (sentence start), literal `# Spec:` / `# Findings:` document titles.

### 10. `plan-template.md`: `**FRESH AGENT CHECKPOINT**` literal replaced

Phase 4 converted `**FRESH AGENT CHECKPOINT**:` to `> **Note:** Fresh-agent checkpoint —`. No runtime consumer greps for this literal, so no breakage. Flagged only because any external tool or human memory of the literal "FRESH AGENT CHECKPOINT" will no longer find it.

### 11. `skills/flow/references/boundaries.md` heading renames

See Decision 2. Three headings renamed. No runtime consumer depends on them, but a human searching for the old names won't find them.

## Nits

### 12. Missing ledes on a few `##` sections (principle 1)

- `skills/commits/SKILL.md:46-50` (`## How to handle generated code`) — drops straight into an ordered list.
- `skills/tdd/SKILL.md:51-56` (`## How to handle test failures`) — drops straight into a numbered list.
- `skills/spike/SKILL.md:96-98` (`## How to run the pipeline, stage by stage`) — goes directly into `### Step 1`.
- `skills/teach/SKILL.md:45-47` (`## Full skill creation`) — lede `For workflows, patterns, or knowledge that need a proper skill.` is a fragment.

### 13. Back-to-back `> **Warning:**` callouts

`skills/review/SKILL.md:50-52` stacks two warnings consecutively. Principle 8 says "used sparingly" — each individual warning is substantive, but the sequence dilutes the signal. Consider merging into one warning or reframing one as `> **Note:**`.

### 14. Rules-block boundary

`skills/review/SKILL.md:45-52` — a `#### Rules` block is immediately followed by two `> **Warning:**` callouts that read like additional rules. Either fold the warnings into the rules block or rename them.

### 15. Inline-rule drift

`skills/ship/SKILL.md:78-82` — the sentence "Group related findings." immediately before a `#### Rules` block reads as a rule in disguise. Consider folding.

### 16. Minor: step-block bullets in spike/SKILL.md

See Suggestion 7's second row. Not breakage, just tighter principle-3 adherence.

### 17. Deferred verify items from the plan

The two post-merge verify items from `02-plan-r1.md` (throwaway bootstrap + `/flow-spike`) should land in the PR's Post-merge verify block when ship runs.

### 18. `skills/flow/references/glossary.md` unreferenced terms

Every term in the glossary should be in active use somewhere in the corpus. A quick audit would confirm no pre-emptive bloat. (Not worth blocking ship — a nice-to-have for a v2.)

## Questions

### Q1. Should `## Revisions` be glossary-canonical in prose or only as a section heading?

`flow/references/protocol.md` uses `## Revisions` as the document-protocol section. `boundaries.md` renamed its `## Revisions` to `## Handle revisions`. The glossary doesn't specify. If "revision" is the canonical term for "the -rN suffix mechanism", what's the heading style when you're teaching the reader *how to* produce one? Verb-first says `## Handle revisions`; protocol-consistency says `## Revisions`. Resolving Decision 2 answers this, but worth flagging.

## How It Works (end-to-end)

Five audiences for this refactor; I traced each.

1. **GitHub browser → README.md.** Opens with reader-stance lede ✓. Pipeline diagram renders (ASCII in `text`-tagged fence). Tables render. Install steps preserved. Internal links (`skills/flow/references/config.md`, etc.) all resolve. No external link regressions.

2. **Plugin installer (`/plugin install flow`).** The installer reads every `SKILL.md`'s frontmatter `description:` line. All 11 pre-existing lines are byte-identical vs `origin/main` (verified via `git show origin/main:...`); the new `skills/docs-style/SKILL.md` has a valid description with multiple trigger phrases. Skill loader will behave identically.

3. **Claude invoking `/flow`.** `commands/flow.md` → `skills/flow/SKILL.md`. Detected-stage bash (`!`...``) preserved, `$ARGUMENTS` preserved. Flow's stage-detection rule list matches `skills/flow/scripts/detect-stage.sh` outputs (unchanged). All `skills/flow/references/*.md` cross-refs resolve. At stage boundaries, the AUQ contract (header/question/options/multiSelect) is preserved in `user-interaction.md`.

4. **Claude invoking `/flow-spike "thesis"`.** `commands/flow-spike.md` → `skills/spike/SKILL.md` → ship. **This path has two broken references** (criticals 1 & 2). The command file's body says "See `skills/spike/SKILL.md` under 'Conversation absorption'" (that section no longer exists) and "per ship Step 7.5" (that step number no longer exists). A literal-name lookup fails. A smart-agent like Claude would probably soft-recover by finding the renamed section, but the stale references are a reliability regression.

5. **`make lint-docs`.** New target added in phase 6. Passes clean on the post-edit corpus. Handles nested fences of different marker lengths correctly (verified via `skills/teach/references/template.md` which has outer 4-backtick fences containing inner 3-backtick content).

## Complexity & Risk

- **Files touched**: 34 (out of 34 in-scope). Mostly prose; no code logic changes. Scripts untouched.
- **Commits**: 7, one per phase plus phase 0 foundation. Each is independently reviewable.
- **Blast radius**: only the LLM-runtime behavior of skills and the human-readability of docs. No user-data or production-system path.
- **Risk**: Medium. The 3 critical findings are real regressions the refactor introduced. None are subtle; all are fixable in minutes. If they ship unfixed, the spike pipeline will still work (Claude will recover from the stale references) but a literal-name reader will bounce.

## Error Handling

N/A — docs-only change. The `make lint-docs` target exits non-zero on violations, which is correct error-handling for a lint tool.

## Test Coverage Gaps

N/A — docs-only change. The substitute tests (cross-ref grep, frontmatter byte-diff, `make lint-docs`) are documented in `02-plan-r1.md`'s Success Criteria.

Gap worth noting: no automated check that section-by-name references across docs still resolve. The 3 criticals in this review (broken section-name refs in `flow-spike.md`) would've been caught by such a check. **If a v2 lint is worth pursuing**, a `grep-then-resolve` check for phrases like `under "<heading>"` or `per ship Step N` would have prevented criticals 1 and 2.

## Pattern Reuse Opportunities

- Suggestion 8: `skills/review/SKILL.md` duplicates `skills/review/references/findings-template.md`. Pick one home.
- No other duplication introduced.

## Files Changed

| File | Kind of change | Risk |
|---|---|---|
| `Makefile` | +`lint-docs` target | Low |
| `README.md` | Full docs-style pass | Low |
| `skills/docs-style/SKILL.md` | **New** | Low (greenfield) |
| `skills/flow/references/glossary.md` | **New** | Low (greenfield) |
| `commands/*.md` (5) | Docs-style pass | Low (one broken ref: flow-spike.md lines 20, 52) |
| `skills/flow/SKILL.md` | Full docs-style pass (hand-written) | Low |
| `skills/flow/references/*.md` (6) | Full docs-style pass | Low-medium (one rename of `## Revisions`) |
| `skills/{explore,plan,implement,review,ship}/SKILL.md` (5) | Full docs-style pass | Medium (ship: 12-step renumber; review: one content-bug in table) |
| `skills/{commits,tdd,parallel,teach,spike}/SKILL.md` (5) | Full docs-style pass | Low-medium (teach: noun-phrase cluster) |
| `skills/plan/references/plan-template.md` | Lede + callout for FRESH AGENT CHECKPOINT | Low (literal gone) |
| `skills/review/references/findings-template.md` | Lede added | Low |
| `skills/spike/templates/pr-body.md` | Tagged one fence `bash` | Low |
| `skills/teach/references/*.md` (3) | Full docs-style pass | Low |
| `agent/workstreams/2026-04-22-docs-readability/*.md` | Workstream docs | N/A |
