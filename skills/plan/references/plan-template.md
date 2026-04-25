# Implementation Plan Template

The plan stage fills this scaffold to produce the plan document the implement stage reads next. Copy the code block below into the workstream file and fill the placeholders.

Save as `./agent/workstreams/<YYYY-MM-DD>-<branch>/02-plan-r<N>.md` (typically `02-plan-r1.md` for a new plan; use the next `-rN` for revisions and include a `## Revisions` section).

```markdown
<!-- branch: [branch] · date: [YYYY-MM-DD] · author: [git user] · pr: -->

# Plan: [branch] · plan → implement

> **What:** [one sentence — what ships when this plan is executed]  
> **Why:** [one sentence — the spec problem this plan addresses]

## Approach

[One-sentence lede. High-level design: patterns to follow, order of changes, architectural decisions with rationale collapsed to one-liners ("chose X over Y because Z").]

## Steps

### Step 1: [First Testable Unit]

- [ ] Tests: Write tests covering [specific scenarios]
- [ ] Code: [Specific action with file locations]
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] All tests green, no regressions

### Step 2: [Next Testable Unit]

- [ ] Tests: Write tests covering [specific scenarios]
- [ ] Code: [Specific action with file locations]
- [ ] Test run: `[PASTE TEST SUMMARY HERE]`
- [ ] All tests green, no regressions

[Continue with additional steps…]

## Constraints

[One-sentence lede. Hard rules and guardrails — inherited from the spec plus any plan-specific limits.]

## Verification

[One-sentence lede. What must be confirmed when implementation is complete.]

- [ ] All implementation steps completed
- [ ] All tests passing
- [ ] Follows existing codebase patterns

## Open

[One-sentence lede. Questions for the implement stage or the human.]

- [unresolved question]
```

> **Note:** Fresh-agent checkpoint — if picking up mid-implementation, find the last `[PASTE TEST SUMMARY HERE]` to know where to continue.
