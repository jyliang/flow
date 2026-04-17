# Findings Document Template

```markdown
# Review: <PR "#<number> - <title>" or "Local changes on <branch>">

**PR**: <PR URL — omit for local mode>
**Author**: <author or current git user>
**Branch**: <branch> -> <base>
**Review round**: <N> (or omit if round 1)
**Date reviewed**: <today>

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
```
