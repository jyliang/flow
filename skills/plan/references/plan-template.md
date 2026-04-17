# Implementation Plan Template

Save as `./agent/plans/IMPLEMENTATION_PLAN_<YYYY-MM-DD>.md`.

```markdown
# Plan: [Feature Name]

## Status
plan → implement

## What was done
- Designed [N]-step implementation approach
- Identified [patterns/modules] to follow
- Estimated scope: [small/medium/large]

## Decisions needed
- [ ] **Approach**: [if multiple valid approaches exist]

## Verify in reality
- [ ] [Any assumptions that need manual verification before coding]

## Implementation Steps

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

[Continue with additional steps...]

## Architecture Decisions
- [Decision]: [Rationale]

## Success Criteria
- [ ] All implementation steps completed
- [ ] All tests passing
- [ ] Follows existing codebase patterns
- [ ] No sensitive data exposed
```

**FRESH AGENT CHECKPOINT**: If picking up mid-implementation, find the last `[PASTE TEST SUMMARY HERE]` to know where to continue.
