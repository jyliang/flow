# Document boundaries

## Auto-advance vs pause

**Pause** when:
- The document has unresolved decisions
- The stage involves scope or architectural choices (explore, plan)
- The review found critical issues

**Auto-advance** when:
- No decisions needed
- The human explicitly said to go end-to-end
- The stage is mechanical (implement with a clear plan)

## Revisions

When a later stage discovers that an earlier document is wrong:

1. Update the earlier document with a **Revisions** entry (see `protocol.md`)
2. The revision captures what changed, why, and what's impacted
3. Continue from the current stage — don't restart the pipeline

When the human edits a document directly, the next agent should notice, add a revision entry attributing it to the human, and propagate changes downstream.

Revisions are a feature, not a bug. They're the communication trail that explains why the implementation differs from the original spec.

## Review-finding triage (review → ship)

### Auto-fix (do without asking)
Findings that are: mechanical, small (5 lines or fewer), safe, local to one file.

### Ask the human
Findings that involve: multiple valid approaches, architectural decisions, behavior changes, trade-offs, or uncertainty.

### Hard rules
- Test coverage gaps rated 8+ are ALWAYS surfaced. Never silently skipped.
- Think independently — if a finding looks wrong, skip it. If you spot something missed, add it.
- Human time is sacred. Fix trivial things. Only ask about what genuinely needs judgment.

## Interaction rule

* **DO** use `AskUserQuestion` for every user-facing decision (see `user-interaction.md`)
* **DO NOT** print free-form Y/n prompts or list choices in prose and wait for a typed answer
