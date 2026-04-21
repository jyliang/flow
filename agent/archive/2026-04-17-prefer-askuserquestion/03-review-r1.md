# Findings: Prefer AskUserQuestion for user interactions in every flow stage

## Status
review → ship

## What was done
- Reviewed 10 files: 1 new (`flow/references/user-interaction.md`), 9 modified skills + 1 modified reference.
- Adapted the 3-specialist pattern for doc-only review: consistency/pattern reuse done inline (no code to hunt error handling or test coverage in).
- E2E walkthrough traced 4 agent audiences (flow boundary, plan, teach gather, reference lookup).
- Found **1 critical**, **3 suggestions**, **2 nits**.

## How It Works

1. `flow/references/user-interaction.md` (new) is the canonical source: the rule ("use `AskUserQuestion` for any user-facing decision"), when-to/when-not-to, tool contract (2–4 options per question, 1–4 questions per call, auto-provided "Other", `(Recommended)` label for preferred options), a call-shape template, and anti-patterns.
2. `flow/SKILL.md` rewrites 3 stale-document scenarios (`:53–55`) and the boundary advance prompt (`:87/current :93`) as concrete `AskUserQuestion` shapes (bold heading → Question → Options). Adds a DO bullet citing the reference.
3. Each of explore, plan, implement, review, ship, tdd, teach SKILL.md + teach/references/capture.md adds a cross-reference at the point where user-interaction previously was hand-waved ("ask for clarification"). Ship already used `AskUserQuestion`; it just gets the cross-ref.
4. Path conventions: inside `flow/SKILL.md`, the reference is addressed as `references/user-interaction.md` (local); from other skills, `flow/references/user-interaction.md` (relative to `skills/` root — matches existing `tdd/SKILL.md` and `parallel/SKILL.md` cross-refs).

## Complexity & Risk

Low. Documentation-only changes, 36 insertions / 19 deletions across 9 files + 1 new 63-line reference. Biggest risk is instruction-drift: SKILL.md files now tell agents to call `AskUserQuestion` in contexts where the tool's option-based contract doesn't fit (see Critical finding below). No runtime risk — none of these files are loaded programmatically.

## End-to-end walkthrough

| Audience | Entry | Gate/path | End state matches goal? |
|---|---|---|---|
| Agent at `flow` boundary | `/flow:flow` → detects stage, reaches boundary | reads `flow/SKILL.md` boundary section | ✅ sees concrete AskUserQuestion shape + cross-ref |
| Agent in plan stage hits ambiguity | reads `plan/SKILL.md:20, :42` | told to use AskUserQuestion + cross-ref | ✅ |
| Agent in teach "Gather knowledge" | reads `teach/SKILL.md:66` | told to batch concrete-examples / anti-patterns / reference-material via AskUserQuestion | ❌ **These are open-ended prompts, not decisions between 2–4 options.** See Critical below. |
| Agent looking up rule | reads `flow/references/user-interaction.md` | rule + contract + template | ✅ |

## Critical

### 1. `teach/SKILL.md` "Gather knowledge" misuses `AskUserQuestion` for open-ended input
**File:line**: `skills/teach/SKILL.md:65-68`

The change rewrites:
```
Ask the user for:
- Concrete examples of the workflow or API
- Common mistakes or anti-patterns
- Reference material (docs, interfaces, schemas)
```
as:
```
Collect the following from the user via AskUserQuestion (batch 2–4 questions in one call; ...):
- Concrete examples of the workflow or API
- Common mistakes or anti-patterns
- Reference material (docs, interfaces, schemas)
```

Problem: `AskUserQuestion` requires **2–4 discrete options per question**. "Give me concrete examples of the workflow" has no natural set of options — the user's answer is free-form text. Forcing this through `AskUserQuestion` either (a) produces nonsense options like "I have an example / Skip", or (b) relies entirely on the "Other" free-text fallback, which defeats the tool's purpose.

This also **contradicts** the new `user-interaction.md` reference (which the teach skill cross-refs), specifically its anti-pattern:
> **DON'T** use `AskUserQuestion` for rhetorical framing or to narrate your plan. If there's no real choice, don't ask.

And its When-NOT-to-use rule:
> **Purely informational output** — findings, summaries, diffs. Write these as prose or documents.

**Fix options:**
- **(A) Revert this bullet only** — keep "Ask the user for:" as a prose prompt. Leave other teach/ changes intact. (Simplest, matches reference.)
- **(B) Split the teach "gather" step**: use free-form prompt for open-ended knowledge (examples, references), use `AskUserQuestion` only for discrete decisions (scope, does-this-cover-an-existing-skill).
- **(C) Expand the reference** to explicitly list "gathering open-ended knowledge" as a When-NOT-to-use case, then revert this bullet.

Recommend (B), which is the most honest rule and also updates `user-interaction.md` to be clearer about the boundary.

## Suggestions

### 2. Review-stage DO bullet sits awkwardly below CRITICAL bullets
**File:line**: `skills/review/SKILL.md:42`

The new DO bullet was appended after three `CRITICAL:` bullets. A reader parsing the list might read the CRITICAL ones as a mini-section and miss the trailing DO. Minor — consider moving the new DO before the CRITICAL bullets, or into the `## How to review` DO/DON'T block at the top of the file.

### 3. Inline `AskUserQuestion` shapes omit `header` field
**File:line**: `skills/flow/SKILL.md:51-61, :93-95`; `skills/teach/SKILL.md:36-38`

The reference's call-shape template includes `header: "Short tag"`. Inline examples only show Question + Options. New agents writing a call from scratch will match the inline example, not the template, and may forget the required `header` field. (Actually `header` is required per the `AskUserQuestion` schema.) Consider adding `header` to inline shapes or removing it from the template for consistency. Prefer adding — the schema requires it.

### 4. Top-level cross-ref in `teach/SKILL.md` is unique among skills
**File:line**: `skills/teach/SKILL.md:12`

Only teach has a banner cross-ref under the `#` heading. Other skills have inline DO bullets. Either pattern is fine in isolation, but inconsistency forces readers to check two places. Options: (a) keep as-is — teach has the most user-interaction surface so a banner is justified; (b) remove the banner and rely on inline bullets; (c) add banners everywhere. Current (a) is defensible; note the asymmetry.

## Nits

### 5. `teach/SKILL.md` "max one" phrasing is awkward
**File:line**: `skills/teach/SKILL.md:40`

> If the input is unclear, use `AskUserQuestion` for the one clarifying question (max one)

"max one" is slightly redundant after "the one". Could read "use `AskUserQuestion` for at most one clarifying question". Optional.

### 6. `flow/SKILL.md` advance-prompt example doesn't show `(Recommended)` label
**File:line**: `skills/flow/SKILL.md:94-95`

The reference says to mark a preferred option with `(Recommended)`. The inline example (`Yes, advance / Pause here / Adjust...`) doesn't demonstrate that convention. Could update to `Yes, advance (Recommended) / Pause here / Adjust...`. Optional — the reference already covers it.

## Questions

None. Spec decisions were resolved before implementation; no new ambiguity surfaced.

## Error Handling

N/A — documentation changes only.

## Test Coverage Gaps

- **"Verify in reality" step not executed**: the plan included running `/flow:flow` on a throwaway task to confirm stages actually surface decisions via `AskUserQuestion`. This has not been done. Severity: **6** (not 8+ because docs are lower-risk; agents will self-correct when they read the new guidance).

## Pattern Reuse Opportunities

- **Stale-document bullets in `flow/SKILL.md:51-61`** repeat the same shape three times (bold heading → Question → Options). Could be normalized as a sub-reference (e.g., `flow/references/stale-documents.md`) or a table, but current prose is readable at this volume. Not worth the indirection.
- **The `(see `flow/references/user-interaction.md`)` suffix** is now repeated in ~10 places. Fine as-is — paths need to be explicit — but worth noting that future rules added to the reference will require the same pattern.

## Spec/Plan Drift

### Minor expansion not captured in plan
**File**: `skills/teach/references/capture.md`

The plan's Step 4 listed teach/SKILL.md rewrites but didn't mention `teach/references/capture.md:29`, which had the same "Ask the user to review before writing the skill file" phrasing and was also updated during implementation. This is an intentional, scope-consistent extension — worth noting as a Revisions entry on the plan but not a problem.

**Recommended action**: add a Revisions entry to the plan noting this expansion. No code change.

## Files Changed

| File | Lines | Notes |
|---|---|---|
| `skills/flow/references/user-interaction.md` | +63 (new) | Canonical rule + contract + template |
| `skills/flow/SKILL.md` | +15 / -6 | 3 stale-doc prompts + boundary prompt rewritten as AskUserQuestion shapes |
| `skills/explore/SKILL.md` | +1 | DO bullet |
| `skills/plan/SKILL.md` | +2 / -2 | Two "ask for clarification" → "AskUserQuestion" |
| `skills/implement/SKILL.md` | +1 / -1 | DO bullet updated |
| `skills/review/SKILL.md` | +1 | DO bullet (see suggestion #2) |
| `skills/ship/SKILL.md` | +2 / -2 | Cross-ref added to existing AskUserQuestion mentions |
| `skills/tdd/SKILL.md` | +1 / -1 | DO NOT bullet updated |
| `skills/teach/SKILL.md` | +9 / -4 | Top-level banner + 4 inline rewrites (see Critical #1) |
| `skills/teach/references/capture.md` | +1 / -1 | Matching rewrite (see Spec/Plan drift) |

## Decisions needed (all resolved)

- [x] **Critical #1**: Split — `AskUserQuestion` for structured choices, prose for open-ended knowledge. Also update `user-interaction.md` to list "open-ended knowledge gathering" as a When-NOT-to-use case.
- [x] **Suggestion #2** (review DO bullet placement): auto-fix during ship — move the new DO bullet into the existing DO/DON'T block above the CRITICAL bullets.
- [x] **Suggestion #3**: add `header` field to inline `AskUserQuestion` shapes in `flow/SKILL.md` and `teach/SKILL.md`.
- [x] **Suggestion #4**: remove teach's top-level banner cross-ref; rely on inline bullets (consistent with other skills).
- [x] **Nits #5, #6**: fix both — rephrase "max one"; add `(Recommended)` to the advance-prompt example.
- [x] **Plan drift**: add a Revisions entry to the plan noting `teach/references/capture.md` was edited.

## Verify in reality

- [ ] Run `/flow:flow` on a throwaway task and confirm each stage surfaces decisions via `AskUserQuestion` (carried forward from plan).
- [ ] Confirm `AskUserQuestion` tool schema requires `header` (appears to — verify before Suggestion #3 is decided).
