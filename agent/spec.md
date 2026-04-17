# Spec: Prefer AskUserQuestion for user interactions in every flow stage

## Status
explore → plan

## What was done
- Explored all 10 skill SKILL.md files and 6 reference docs under `skills/`
- Grepped for every user-interaction phrase (`Ask`, `Tell the user`, `ask for clarification`, `surface...`, `present...`)
- Identified 2 skills that already reference `AskUserQuestion` and 6 that don't but should
- Mapped out every file and line that needs updating

## Decisions needed (all resolved)
- [x] **Scope**: All stage + internal skills — flow, explore, plan, implement, review, ship, tdd, teach.
- [x] **Structure**: Central reference + cross-links. Create a new `flow/references/user-interaction.md` with the canonical rule. Each skill gets a one-line cross-reference.
- [x] **Strength**: Strong — `AskUserQuestion` is the default for any user-facing decision. Free-form prose is reserved for status updates and summaries.
- [x] **Rewrite free-form prompts**: Rewrite `flow/SKILL.md:53–55` and `:87` as concrete `AskUserQuestion` call shapes (question + options).

## Verify in reality
- [ ] After updating, run `/flow:flow` on a sample task and confirm each stage surfaces decisions via `AskUserQuestion` rather than free-form prompts.
- [ ] Confirm the final spec matches how `AskUserQuestion` actually behaves (2–4 options, free-text "Other" is auto-provided) — we don't want guidance that contradicts the tool's contract.

## Spec details

### Current state

The flow skill system already has partial adoption of `AskUserQuestion`:

| File | Line | Current state |
|---|---|---|
| `skills/flow/SKILL.md` | 85 | ✅ "present them using `AskUserQuestion` with concrete options" |
| `skills/ship/SKILL.md` | 21 | ✅ "present to human via `AskUserQuestion`" |
| `skills/ship/SKILL.md` | 56 | ✅ "Present via `AskUserQuestion` with concrete options, batched 1-4 per call..." |

But other skills either use free-form prose or give vague "ask for clarification" guidance without naming the tool:

| File | Line | Gap |
|---|---|---|
| `skills/flow/SKILL.md` | 53–55 | Quoted free-form prompts for stale-document scenarios (no `AskUserQuestion`) |
| `skills/flow/SKILL.md` | 87 | "Ask: advance to the next stage, or pause here?" (free-form) |
| `skills/explore/SKILL.md` | — | No guidance for mid-explore clarifications |
| `skills/plan/SKILL.md` | 42 | "ask for clarification rather than guessing" (vague) |
| `skills/implement/SKILL.md` | 37 | "ask for clarification rather than guessing requirements" (vague) |
| `skills/review/SKILL.md` | — | No guidance for mid-review ambiguities |
| `skills/tdd/SKILL.md` | 30 | "ask for clarification if unsure" (vague) |
| `skills/teach/SKILL.md` | 34, 36, 63, 80 | Multiple free-form "ask" instructions |

Pattern: the word "ask" appears but the **mechanism** (`AskUserQuestion` tool) is named inconsistently.

### Proposed change

Make `AskUserQuestion` the default mechanism for every user-facing question that the agent asks during a flow stage. Specifically:

1. **Add a canonical rule** — one sentence + short rationale, either centralized (Decision B option A) or repeated per stage (Decision B option B).
2. **Rewrite every "ask for clarification" / "Tell the user" / "Ask:" spot** so it either invokes `AskUserQuestion` directly or cross-references the canonical rule.
3. **Keep the existing three `AskUserQuestion` mentions** and make them consistent (same phrasing, same level of prescriptiveness).
4. **Do not require** `AskUserQuestion` for:
   - Status updates / progress narration
   - Summaries after a stage completes
   - Irreversible operations where a free-form confirmation is clearer (these belong to the CLI's permission layer anyway)

### Impact analysis

**Files to change** (each gets at minimum one edit):
- `skills/flow/SKILL.md` — rewrite `:53–55` stale-document prompts and `:87` boundary prompt; add/strengthen canonical guidance near `:85`
- `skills/explore/SKILL.md` — add a DO/DON'T line for mid-explore clarifications
- `skills/plan/SKILL.md` — update `:42` to name `AskUserQuestion`
- `skills/implement/SKILL.md` — update `:37` to name `AskUserQuestion`
- `skills/review/SKILL.md` — add a DO/DON'T line for mid-review clarifications
- `skills/ship/SKILL.md` — already good; verify consistency of language only
- `skills/tdd/SKILL.md` — update `:30` if in-scope (see decision 1)
- `skills/teach/SKILL.md` — update `:34`, `:36`, `:63`, `:80` if in-scope (see decision 1)
- Possibly `skills/flow/references/protocol.md` — if Decision B chooses option A, add a new section here
- Possibly `skills/flow/references/user-interaction.md` — new file if Decision B chooses option A

**Files to create**: at most 1 (`flow/references/user-interaction.md`), depending on Decision B.

**Dependencies**:
- Relies on the `AskUserQuestion` tool being available in the harness when any flow stage runs. This is a safe assumption — it's a standard Claude Code tool, not plugin-gated.
- No code depends on these SKILL.md files programmatically — only Claude reads them. Changes are low-risk.

**Similar modules**:
- `flow/SKILL.md:85` and `ship/SKILL.md:21,56` are the existing patterns to follow — they already name the tool and describe option shape ("concrete options", "1-4 per call", "first option with '(Recommended)' label"). New additions should match this voice.

### Constraints

- `AskUserQuestion` supports 2–4 options per question and 1–4 questions per call. Guidance must not ask stages to batch more than that.
- "Other" is auto-provided by the tool — guidance should not instruct stages to add it manually.
- The existing proportional-ceremony principle (flow/SKILL.md:60–78) means not every "discovery" needs a user question — small, mechanical choices should still auto-advance. The rule is "prefer `AskUserQuestion` **when asking**", not "ask more often".
- SKILL.md body < 300 lines (per `teach/SKILL.md:73`) — additions should be tight, ideally one DO/DON'T bullet per skill rather than a new section.
