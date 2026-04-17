---
name: plan
description: Take a spec document and produce an implementation plan. Stage skill — reads spec, produces plan that feeds into the implement stage. Referenced by flow.
metadata:
  short-description: Spec → implementation plan
  internal: true
---

# Plan

## Goal

Read `agent/spec.md` and produce an implementation plan at `agent/plans/IMPLEMENTATION_PLAN_<YYYY-MM-DD>.md`. The plan breaks the spec into small, testable steps that the implement stage can execute.

## How to plan

### Step 1: Read the spec

Read `agent/spec.md`. Check for:
- Unresolved decisions — if any exist, stop and surface them via `flow` before proceeding
- Resolved decisions — incorporate them into the plan
- Constraints — respect them

### Step 2: Design the approach

Based on the spec's impact analysis and current state:

1. Determine the order of changes (dependencies first)
2. Break each change into the smallest testable unit
3. Identify what tests to write for each unit
4. Reference existing patterns to follow

### Step 3: Write the plan

Write to `agent/plans/IMPLEMENTATION_PLAN_<YYYY-MM-DD>.md` following the document protocol (`flow/references/protocol.md`) and the template in `references/plan-template.md`.

* **DO** divide into small, testable steps
* **DO** document architecture decisions and rationale
* **DO** reference existing implementations as patterns
* **DO** include test criteria for every step
* **DO NOT** include steps without corresponding tests
* **DO NOT** leave ambiguities — ask for clarification rather than guessing

## Conventions

- `agent/spec.md` — input (produced by explore stage)
- `agent/plans/IMPLEMENTATION_PLAN_*.md` — output (consumed by implement stage)
- `roadmap.md` — product vision (read-only reference)

If the spec and plan drift apart during implementation, update the plan — the spec is the source of truth for *what*, the plan is the source of truth for *how*.
