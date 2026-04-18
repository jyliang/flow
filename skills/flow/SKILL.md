---
name: flow
description: Single entry point for the development workflow. Detects current stage, advances work, and handles human interaction at document boundaries. Use when the user says "flow", describes what they want to build, or wants to continue where they left off.
metadata:
  short-description: Single entry point — idea to PR
---

# Flow

Move work forward from idea to shipped PR. Detect the current stage, run the right transition, present the document for human review, and advance.

Each document serves two readers: the human reviews and edits it, the next stage consumes it as input.

## Pipeline

```
Idea → [explore] → Spec → [plan] → Plan → [implement] → Changes → [review] → Findings → [ship] → PR
```

| Stage | Input | Output | Path |
|-------|-------|--------|------|
| explore | Idea | Spec | `agent/spec.md` |
| plan | Spec | Plan | `agent/plans/IMPLEMENTATION_PLAN_*.md` |
| implement | Plan | Changes | git branch |
| review | Changes | Findings | `agent/reviews/*` |
| ship | Findings | PR | GitHub PR |

Document depth scales with task complexity. A one-line fix produces a 3-line spec and skips most ceremony; a complex feature produces full analysis at every stage. Structure is constant, depth is proportional.

## Detect the current stage

1. No `agent/spec.md` → **explore**
2. Spec exists, no plan → **plan**
3. Plan exists with incomplete steps → **implement**
4. Plan complete or unreviewed changes on branch → **review**
5. Findings exist with unresolved items → **ship**
6. PR exists and ready → **done**

When multiple conditions are true (e.g., open PR and a stale findings doc), the detection picks the **furthest-downstream** stage: done > ship > review > implement > plan > explore.

If the user gives explicit intent ("review this PR", "ship it"), skip detection and go directly to that stage.

If a document is missing, stale, or ambiguous, see `references/stage-detection.md` for the exact `AskUserQuestion` to raise. Never silently proceed with stale input.

## At a stage boundary

1. Show a brief summary of what was done.
2. Surface any **decisions needed** via `AskUserQuestion`.
3. List any **verify** items clearly.
4. Ask about advancing via `AskUserQuestion`:
   - Question: `"Advance to the [next-stage] stage?"`
   - Header: `Advance?`
   - Options: `Yes, advance (Recommended)` / `Pause here` / `Adjust [this stage's document] first`

See `references/boundaries.md` for auto-advance vs pause rules, revision handling, and review-finding triage. See `references/user-interaction.md` for the `AskUserQuestion` contract. See `references/protocol.md` for the document format.

## Scripts

Shell helpers under `skills/flow/scripts/` avoid LLM cost on mechanical work. Called from slash-command bodies and (when needed) directly via the Bash tool.

- `detect-stage.sh` — mirrors the 6-rule stage detection above. Prints one of `explore-empty` / `plan` / `implement` / `review` / `ship` / `done`. SKILL.md is authoritative if the bash drifts.
- `bootstrap.sh <branch>` — creates the branch and materializes `agent/spec.md` from the configured template. Refuses if `agent/spec.md` already exists. Consults `.flow/config.sh` for `FLOW_TEMPLATE_SPEC`; env var overrides file.
- `load-config.sh` — sources `.flow/config.sh` (if present) and prints normalized flow env vars. Precedence: env > file > defaults. See `references/config.md` for the schema.

## Related skills

Stages: `explore`, `plan`, `implement`, `review`, `ship`.
Internal (auto-triggered): `tdd`, `commits`, `parallel`.
Meta: `teach` — create skills or capture rules.
