---
name: plan
description: Take a spec document and produce an implementation plan. Stage skill — reads spec, produces plan that feeds into the implement stage. Referenced by flow.
metadata:
  short-description: Spec → implementation plan
  internal: true
---

# Plan

Stage skill read by the next-stage agent (implement) and by a human scanning before implementation starts. Reads the latest spec and produces `02-plan-r<N>.md` in the same thread folder.

## Goal

Break the spec into small, testable steps that the implement stage can execute without further clarification.

## How to plan

A three-step loop: read the spec, design the approach, write the plan.

### Step 1: Read the spec

Read the latest `01-spec-r*.md` in the active thread folder (highest `-rN` = current). Check for:

- Unresolved decisions — if any exist, stop and surface them to the user via `AskUserQuestion` (see `skills/run/references/user-interaction.md`) before proceeding.
- Resolved decisions — incorporate them into the plan.
- Constraints — respect them.

### Step 2: Design the approach

Based on the spec's impact analysis and current state:

1. Determine the order of changes (dependencies first).
2. Break each change into the smallest testable unit.
3. Identify what tests to write for each unit.
4. Reference existing patterns to follow.

### Step 3: Write the plan

Write to `02-plan-r<N>.md` in the active thread folder following the document protocol (`skills/run/references/protocol.md`) and the scaffold in `references/plan-template.md`. The scaffold seeds the structure; break from it only when the work has a natural shape that scans better. A new thread starts at `r1`; a revision creates `r2`, `r3`, … with a `## Revisions` section explaining the delta.

### Structure: Pyramid Principle

Organize the plan as a Minto pyramid — answer first, then support. The reader should be able to stop at any level and still have a complete thought.

- **Top of the pyramid — the `What / Why` blockquote.** Two sentences carried over from the spec. A reader who only reads the blockquote should know what ships when this plan is executed and why.
- **Supporting level — the five sections.** MECE: Approach (the design), Steps (ordered work), Constraints (guardrails), Verification (done-when), Open (unresolved). Don't overlap; don't leave gaps; don't add a sixth unless the work genuinely needs it.
- **Evidence level — inside each section.** Lead with the section's conclusion in one sentence, then the detail. For Steps, each step's title is its thesis and the checklist is the evidence.

### Readability rules

The plan is read by the implement stage and by a human checking scope before coding starts. Write so a skimmer re-orients in under 10 seconds — on first draft and on revision.

1. **One-sentence lede per section.** Every `##` heading opens with one line stating that section's conclusion.
2. **Tables for 3+ parallel items.** Lists of three or more items sharing the same shape become tables.
3. **Collapse decisions into conclusions with inline rationale.** Don't preserve the deliberation — record the chosen approach as "X (over Y) because Z" in one line, not a paragraph.
4. **Bold the key term first** in each rule or DO/DON'T bullet.
5. **Preserve technical content verbatim on revision.** Restructure freely on `-rN+1`, but never drop a step's test criteria or a `[PASTE TEST SUMMARY HERE]` marker.
6. **No new content during a readability pass.** Format-only unless the plan is wrong.

### Rules

- **DO** divide into small, testable steps.
- **DO** reference existing implementations as patterns.
- **DO** include test criteria for every step.
- **DO** collapse architecture decisions into one-liner conclusions in the Approach section — rationale inline, not as its own paragraph.
- **DO NOT** include steps without corresponding tests.
- **DO NOT** leave ambiguities — use `AskUserQuestion` rather than guessing (see `skills/run/references/user-interaction.md`).

## Conventions

Where inputs and outputs live:

- `agent/threads/<date>-<branch>/01-spec-r*.md` — input (produced by explore; latest `-rN` is current).
- `agent/threads/<date>-<branch>/02-plan-r*.md` — output (consumed by implement).
- `roadmap.md` — product vision (read-only reference).

> **Note:** If the spec and plan drift apart during implementation, update the plan. The spec is the source of truth for *what*; the plan is the source of truth for *how*.
