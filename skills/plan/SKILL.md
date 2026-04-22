---
name: plan
description: Take a spec document and produce an implementation plan. Stage skill — reads spec, produces plan that feeds into the implement stage. Referenced by flow.
metadata:
  short-description: Spec → implementation plan
  internal: true
---

# Plan

Stage skill read by the next-stage agent (implement) and by a human scanning before implementation starts. Reads the latest spec and produces `02-plan-r<N>.md` in the same workstream folder.

## Goal

Break the spec into small, testable steps that the implement stage can execute without further clarification.

## How to plan

A three-step loop: read the spec, design the approach, write the plan.

### Step 1: Read the spec

Read the latest `01-spec-r*.md` in the active workstream folder (highest `-rN` = current). Check for:

- Unresolved decisions — if any exist, stop and surface them to the user via `AskUserQuestion` (see `skills/flow/references/user-interaction.md`) before proceeding.
- Resolved decisions — incorporate them into the plan.
- Constraints — respect them.

### Step 2: Design the approach

Based on the spec's impact analysis and current state:

1. Determine the order of changes (dependencies first).
2. Break each change into the smallest testable unit.
3. Identify what tests to write for each unit.
4. Reference existing patterns to follow.

### Step 3: Write the plan

Write to `02-plan-r<N>.md` in the active workstream folder following the document protocol (`skills/flow/references/protocol.md`) and the template in `references/plan-template.md`. A new workstream starts at `r1`; a revision creates `r2`, `r3`, … with a `## Revisions` section explaining the delta.

### Rules

- **DO** divide into small, testable steps.
- **DO** document architecture decisions and rationale.
- **DO** reference existing implementations as patterns.
- **DO** include test criteria for every step.
- **DO NOT** include steps without corresponding tests.
- **DO NOT** leave ambiguities — use `AskUserQuestion` rather than guessing (see `skills/flow/references/user-interaction.md`).

## Conventions

Where inputs and outputs live:

- `agent/workstreams/<date>-<branch>/01-spec-r*.md` — input (produced by explore; latest `-rN` is current).
- `agent/workstreams/<date>-<branch>/02-plan-r*.md` — output (consumed by implement).
- `roadmap.md` — product vision (read-only reference).

> **Note:** If the spec and plan drift apart during implementation, update the plan. The spec is the source of truth for *what*; the plan is the source of truth for *how*.
