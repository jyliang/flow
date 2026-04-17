# Plan: Prefer AskUserQuestion for user interactions in every flow stage

## Status
plan → implement

## What was done
- Designed 5-step implementation approach
- Identified existing `AskUserQuestion` mentions in flow/SKILL.md:85, ship/SKILL.md:21 and :56 as voice/phrasing patterns to match
- Estimated scope: small — documentation-only changes across 8 SKILL.md files + 1 new reference file

## Decisions needed
(None — all 4 spec decisions resolved.)

## Verify in reality
- [ ] After all edits, `grep -rn "AskUserQuestion" skills/` lists the new reference + every stage skill.
- [ ] `grep -rn "ask for clarification\|Tell the user:\|ask one clarifying" skills/` returns no remaining free-form prompts (or only ones explicitly cross-referenced to the new rule).
- [ ] Run `/flow:flow` on a throwaway task and confirm each stage surfaces decisions via `AskUserQuestion`.

## Testing caveat

This is a documentation-only skill repository — there is no test suite to run. "Test" for each step means: re-read the edited file, grep for expected/unexpected strings, and spot-check that cross-refs resolve. The "Test run" field in each step below captures that verification.

## Implementation Steps

### Step 1: Create `flow/references/user-interaction.md`

- [ ] Tests (pre): Confirm file does not yet exist (`ls skills/flow/references/`).
- [ ] Code: Create `skills/flow/references/user-interaction.md` with:
  - **Rule** (strong wording): "Use `AskUserQuestion` for any user-facing decision or choice. Reserve free-form prose for status updates, progress narration, and summaries."
  - **When to use** section — decision points, disambiguation mid-stage, boundary advance/pause, finding triage.
  - **When NOT to use** section — status narration, end-of-turn summaries, irreversible-action confirmations (handled by the CLI permission layer).
  - **Tool contract** — 2–4 options per question, 1–4 questions per call, "Other" is auto-provided (don't add manually), put `(Recommended)` on the first option when you have a preference.
  - **Call-shape template** showing a minimal example `AskUserQuestion` call with `question`, `header`, `options`, `multiSelect`.
- [ ] Test run: `cat skills/flow/references/user-interaction.md` and grep for `AskUserQuestion`, `(Recommended)`, and the rule text. Confirm length stays short (< 120 lines).
- [ ] All checks green, no regressions (no other files touched yet).

### Step 2: Rewrite `skills/flow/SKILL.md`

- [ ] Tests (pre): Confirm current lines `:53–55` quote `Tell the user: "..."` / `Ask: "..."` and line `:87` says `Ask: advance to the next stage, or pause here?`.
- [ ] Code:
  1. Strengthen line `:85` to explicitly cite the new reference: change `present them using AskUserQuestion with concrete options` → `present them using AskUserQuestion with concrete options (see references/user-interaction.md)`.
  2. Rewrite the three stale-document bullets (`:53–55`) so each shows a concrete `AskUserQuestion`-shaped pattern:
     - Spec references missing files → `AskUserQuestion` with two options: "Re-explore" / "Update the spec manually".
     - Plan without spec → options: "Continue from plan" / "Start fresh with explore".
     - Findings stale vs code → options: "Re-review" / "Ship as-is".
  3. Rewrite line `:87` boundary prompt to call out an `AskUserQuestion` with two options: "Advance to [next stage]" / "Pause here".
  4. Add one DO bullet at the top of the "document boundaries" section: `DO use AskUserQuestion for every user-facing decision (see references/user-interaction.md)`.
- [ ] Test run: re-read `skills/flow/SKILL.md`; grep for `Tell the user:` (should return 0 matches) and `AskUserQuestion` (should appear at least 5 times).
- [ ] All checks green, no regressions.

### Step 3: Update the 4 remaining stage skills (explore, plan, implement, review)

Note: ship/SKILL.md already has proper `AskUserQuestion` guidance. It gets a cross-ref update in Step 5's sweep (same sweep that verifies teach/tdd).

- [ ] Tests (pre): grep current lines confirm "ask for clarification" phrasing at `plan:42`, `implement:37`; explore and review have no user-interaction guidance.
- [ ] Code — run edits in parallel subagents, one per skill:
  - `skills/explore/SKILL.md` — add a DO bullet under "How to explore": "DO use `AskUserQuestion` for any mid-explore clarification that requires a user decision (see flow/references/user-interaction.md)."
  - `skills/plan/SKILL.md` — replace `:42` "ask for clarification rather than guessing" with "use `AskUserQuestion` rather than guessing (see flow/references/user-interaction.md)". Same change at `:20` phrasing ("stop and surface them via flow") — strengthen to mention `AskUserQuestion` is how flow surfaces.
  - `skills/implement/SKILL.md` — replace `:37` "ask for clarification rather than guessing requirements" with "use `AskUserQuestion` rather than guessing (see flow/references/user-interaction.md)".
  - `skills/review/SKILL.md` — add a DO bullet in "How to review": "DO use `AskUserQuestion` for mid-review ambiguities that block finding classification (see flow/references/user-interaction.md)." Note: review's primary interaction is writing findings, not asking — this only applies to true blockers.
- [ ] Test run: grep each file for `AskUserQuestion` — should appear at least once per file. Grep for `ask for clarification` — should return 0 matches in these files.
- [ ] All checks green, no regressions.

### Step 4: Update internal/meta skills (tdd, teach) + verify ship consistency

- [ ] Tests (pre): grep tdd/SKILL.md:30 and teach/SKILL.md:34, :36, :63, :80 for existing free-form "ask" phrasings. Confirm ship/SKILL.md:21, :56 still name `AskUserQuestion`.
- [ ] Code — parallel subagents:
  - `skills/tdd/SKILL.md` — replace `:30` "ask for clarification if unsure" with "use `AskUserQuestion` if unsure (see flow/references/user-interaction.md)".
  - `skills/teach/SKILL.md` — rewrite 4 spots:
    - `:34` "Ask scope only if ambiguous: 'System-wide or this project only?'" → show as an `AskUserQuestion` with two options ("System-wide (`~/.claude/`)" / "This project only (`.claude/`)").
    - `:36` "ask one clarifying question max" → "use `AskUserQuestion` for the one clarifying question, max".
    - `:63` "Ask the user for: ..." (concrete examples, anti-patterns, reference material) → batch as a multi-question `AskUserQuestion` call (max 4 questions).
    - `:80` "DO ask the user to review before writing the skill file" → "DO use `AskUserQuestion` to confirm the outline before writing the skill file".
    - Add a top-level cross-ref: "All user interactions in this skill follow flow/references/user-interaction.md."
  - `skills/ship/SKILL.md` — no rewrite needed; just add the cross-ref at `:56` so all skills point to the same reference. Change `Present via AskUserQuestion with concrete options, batched 1-4 per call.` to `Present via AskUserQuestion with concrete options, batched 1-4 per call (see flow/references/user-interaction.md).`
- [ ] Test run: grep all 3 files for `AskUserQuestion` + `flow/references/user-interaction.md`. Grep teach/SKILL.md for `Ask scope only if ambiguous` — should return 0.
- [ ] All checks green, no regressions.

### Step 5: Final sweep + verification

- [ ] Tests (pre): none.
- [ ] Code:
  - Run `grep -rn "Tell the user:\|ask for clarification\|ask one clarifying" skills/` — every remaining hit (if any) should be inside a deliberate reference/example context, not a directive.
  - Run `grep -rn "AskUserQuestion" skills/` — should appear in: flow/SKILL.md, flow/references/user-interaction.md (new), explore/SKILL.md, plan/SKILL.md, implement/SKILL.md, review/SKILL.md, ship/SKILL.md, tdd/SKILL.md, teach/SKILL.md (9 files total).
  - Skim each edited file's diff for tone consistency — "use AskUserQuestion" phrasing matches across files.
  - Verify no SKILL.md exceeds 300 lines (per teach guideline).
- [ ] Test run: log the grep results in the step; confirm counts.
- [ ] All checks green, no regressions.

## Architecture Decisions

- **Central reference, not per-skill duplication**: chosen to avoid drift when the rule evolves. Each skill cross-refs `flow/references/user-interaction.md` with one line. (Spec decision 2.)
- **Strong wording**: the default is `AskUserQuestion`; free-form prompts are the exception, not the other way around. (Spec decision 3.)
- **Rewrite free-form prompts inline**: the existing quoted prompts at `flow/SKILL.md:53–55` and `:87` become concrete `AskUserQuestion` shapes so new agents have a copy-paste-ready pattern. (Spec decision 4.)
- **Scope includes tdd + teach**: not stage skills, but they interact with the user. Excluding them would leave inconsistent behavior where, e.g., `teach` asks via prose while `plan` asks via `AskUserQuestion`. (Spec decision 1.)
- **ship/SKILL.md gets a cross-ref but no rewrite**: it's already the model for how to do this right. Cross-ref keeps documentation DRY.
- **commits and parallel skills untouched**: they have no user-interaction guidance. No change needed.

## Success Criteria
- [x] All 5 implementation steps completed
- [x] `flow/references/user-interaction.md` exists and is referenced from 8 SKILL.md files
- [x] No free-form "Tell the user: ..." / "ask for clarification" directives remain unqualified
- [x] Follows existing codebase patterns (matches ship/SKILL.md voice for `AskUserQuestion` guidance)
- [x] No sensitive data exposed
- [x] Each changed SKILL.md still under 300 lines

## Revisions

- **implement → plan** 2026-04-17: Scope expanded to include `skills/teach/references/capture.md`.
  **Why**: During Step 4, discovered the capture.md reference had the same "Ask the user to review before writing the skill file" phrasing that was being rewritten in teach/SKILL.md. Editing it kept teach's guidance internally consistent.
  **Impact**: One additional file edited. No downstream re-work needed.

- **ship → plan** 2026-04-17: Review found one real bug and several consistency gaps.
  **Why**: Review (`agent/reviews/local-main-r1.md`) identified that the plan's Step 4 teach rewrite misused `AskUserQuestion` for open-ended knowledge gathering, contradicting the reference's own anti-patterns. Also inline shapes omitted the required `header` field, and the teach banner created stylistic asymmetry.
  **Impact**: Ship-stage fixes applied: reverted the gather-knowledge bullet to prose, added an "Open-ended knowledge gathering" entry to `user-interaction.md` When-NOT-to-use, added `header` fields to all inline shapes, removed teach's top-level banner, polished two nits, reordered review/SKILL.md bullet placement.
