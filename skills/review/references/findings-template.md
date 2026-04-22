# Findings Document Template

The review stage fills this scaffold to produce the findings document the ship stage reads next. Copy the code block below into the workstream file and replace the bracketed placeholders.

```markdown
# Review: <PR "#<number> - <title>" or "Local changes on <branch>">

**PR**: <PR URL — omit for local mode>
**Author**: <author or current git user>
**Branch**: <branch> -> <base>
**Review round**: <N> (or omit if round 1)
**Date reviewed**: <today>

## Status
<e.g. `review → ship` or `review → ship → PR`>

## Summary
<1-2 sentence summary of what the change does>

## How It Works
<Technical summary of the approach — how the change actually works, not just what it does.
Describe the mechanism: what components are involved, how data/control flows through them,
what triggers the behavior, and any key implementation choices.>

## Complexity & Risk
<Rate: low / medium / high. Justify with: number of files changed, whether it touches hot paths
or shared abstractions, concurrency or state management concerns, how easy it would be to
revert, and likelihood of subtle regressions.>

## Decisions needed
<Checklist of open decisions the human must resolve before ship. Mark `[x]` once resolved
inline (noting the outcome), or `[ ]` if still open. Omit the section if none.>

## Verify in reality
<Unchecked list of what needs to be confirmed post-merge (or post-ship in a live session) —
things that cannot be verified from the diff alone: live commands, UI behavior, production
config, manual smoke tests. One `- [ ]` per item. Items here are expected to flow into the
PR description so a human can check them off on GitHub.>

## Findings

### Critical
<issues that must be fixed before merge>

### Suggestions
<improvements that would be nice but aren't blocking>

### Nits
<minor style/naming/formatting observations>

### Questions
<things that are unclear and need clarification>

## Error Handling
<findings from the error handling hunter agent>

## Test Coverage Gaps
<findings from the test coverage analyzer agent>

## Pattern Reuse Opportunities
<findings from the pattern reuse scanner agent>

## Files Changed
<list of files with brief note on what changed in each>

## Ship Summary
<Added during ship, not review. Records what ship actually did with the findings:
**Auto-fixed** (X items), **User-approved fixes** (X items), **Skipped — documented for future work**,
**Open question — deferred to a follow-up PR**. See ship/SKILL.md Step 3.5.>
```
