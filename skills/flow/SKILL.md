---
name: flow
description: Single entry point for the development workflow. Detects current stage, advances work, and handles human interaction at document boundaries. Use when the user says "flow", describes what they want to build, or wants to continue where they left off.
metadata:
  short-description: Single entry point — idea to PR
---

# Flow

## Goal

Move work forward from idea to shipped PR. Detect the current stage, run the right transition, present the document for human review, and advance.

## How it works

Work moves through stages. Between each stage is a **document** that serves two purposes:
1. The human reads and edits it (decisions, corrections, scope changes)
2. The next stage reads it as input

See `references/protocol.md` for the document protocol every stage follows.

## Stages

```
Idea → [explore] → Spec → [plan] → Plan → [implement] → Changes → [review] → Findings → [ship] → PR
```

| Stage | Input | Output document | Path |
|-------|-------|----------------|------|
| explore | Idea / description | Spec | `agent/spec.md` |
| plan | Spec | Implementation plan | `agent/plans/IMPLEMENTATION_PLAN_*.md` |
| implement | Plan | Code changes | git branch |
| review | Changes | Findings | `agent/reviews/*` |
| ship | Findings | PR | GitHub PR |

## How to detect current stage

Read the workspace state to determine where we are:

1. No `agent/spec.md` → **start at explore**
2. `agent/spec.md` exists, no plan → **start at plan**
3. Plan exists with incomplete steps → **start at implement**
4. All plan steps complete or unreviewed changes on branch → **start at review**
5. Findings exist with unresolved items → **start at ship**
6. PR exists and marked ready → **done**

If the user provides explicit intent ("review this PR", "ship it"), skip detection and go directly to that stage.

### When documents are missing or stale

Don't assume. Ask.

- Spec exists but references files that don't exist → the codebase changed since the spec was written. Tell the user: "The spec references [X] which no longer exists. Want to re-explore, or update the spec manually?"
- Plan exists but spec doesn't → someone deleted or never created the spec. The plan may still be valid. Ask: "There's a plan but no spec. Continue implementing from the plan, or start fresh?"
- Findings exist but the code has changed since the review → tell the user: "Code changed since the last review. Re-review, or ship as-is?"
- Multiple plan files exist → use the most recent. Note the others exist.

The goal is never to silently proceed with stale input. Surface the gap, offer a clear choice, move on.

## Proportional ceremony

Every task goes through the same stages, but document depth scales with complexity.

A small bug fix:
- Spec: 3 lines ("The bug is X, the fix is Y, affects file Z")
- Plan: skip (the spec IS the plan for a one-step fix)
- Implement: make the change
- Review: quick check
- Ship: push

A complex feature:
- Spec: full analysis with decisions, impact, constraints
- Plan: multi-step with test criteria for each
- Implement: disciplined loop with checkpoints
- Review: parallel specialist subagents
- Ship: multiple review rounds

The system doesn't decide what's "small enough to skip." It adapts the depth of each document to the complexity of the task. Even a one-line fix might surface a decision ("this fixes it here, but the same bug exists in 3 other places — fix all or just this one?") or a verification need ("this affects payment flow — test a real transaction").

## How to handle document boundaries

At each stage boundary:

1. Show a brief summary of what was done
2. If there are **decisions needed**, present them using `AskUserQuestion` with concrete options
3. If there are items to **verify**, list them clearly
4. Ask: advance to the next stage, or pause here?

### Auto-advance vs pause

**Pause** when:
- The document has unresolved decisions
- The stage involves scope or architectural choices (explore, plan)
- The review found critical issues

**Auto-advance** when:
- No decisions needed
- The human explicitly said to go end-to-end
- The stage is mechanical (implement with a clear plan)

## How to handle revisions

When a later stage discovers that an earlier document is wrong:

1. Update the earlier document with a **Revisions** entry (see `references/protocol.md`)
2. The revision captures what changed, why, and what's impacted
3. Continue from the current stage — don't restart the pipeline

When the human edits a document directly, the next agent should notice, add a revision entry attributing it to the human, and propagate changes downstream.

Revisions are a feature, not a bug. They're the communication trail that explains why the implementation differs from the original spec.

## How to handle review findings

When transitioning from review → ship:

### Auto-fix (do without asking)
Findings that are: mechanical, small (5 lines or fewer), safe, local to one file.

### Ask the human
Findings that involve: multiple valid approaches, architectural decisions, behavior changes, trade-offs, or uncertainty.

### Hard rules
- Test coverage gaps rated 8+ are ALWAYS surfaced. Never silently skipped.
- Think independently — if a finding looks wrong, skip it. If you spot something missed, add it.
- Human time is sacred. Fix trivial things. Only ask about what genuinely needs judgment.

## Related skills

Stage implementations:
- `explore/SKILL.md` — idea → spec
- `plan/SKILL.md` — spec → implementation plan
- `implement/SKILL.md` — plan → code changes
- `review/SKILL.md` — changes → findings
- `ship/SKILL.md` — findings → fix → PR

Internal (auto-triggered):
- `tdd/SKILL.md` — test-first discipline
- `commits/SKILL.md` — atomic commit discipline
- `parallel/SKILL.md` — subagent patterns

Meta:
- `teach/SKILL.md` — create skills or capture rules
