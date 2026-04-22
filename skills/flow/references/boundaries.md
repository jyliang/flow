# Document boundaries

The stage-skill agent (and the human reviewing its work) reads this doc to decide whether to auto-advance, pause, or revise at a stage transition.

## Choose auto-advance vs pause

A boundary either hands control back to the human or flows straight into the next stage.

| Outcome | Conditions |
|---|---|
| Pause | Unresolved decisions in the current doc; the stage involves scope or architectural choices (explore, plan); the review found critical issues. |
| Auto-advance | No decisions needed; the human explicitly asked for end-to-end; the stage is mechanical (implement with a clear plan). |

## Handle revisions

When a later stage discovers an earlier document is wrong, revise the earlier doc rather than silently diverging.

1. Update the earlier document with a `## Revisions` entry (see `skills/flow/references/protocol.md`).
2. Capture what changed, why, and what downstream work is impacted.
3. Continue from the current stage — don't restart the pipeline.

If the human edits a document directly, the next agent should notice, add a revision entry attributing it to the human, and propagate changes downstream.

> **Note:** Revisions are a feature, not a bug — they are the communication trail that explains why the implementation differs from the original spec.

## Triage review findings at the review → ship boundary

Ship decides per-finding whether to fix silently, ask the human, or surface unconditionally.

| Finding shape | Action |
|---|---|
| Mechanical, small (5 lines or fewer), safe, local to one file | Auto-fix without asking. |
| Multiple valid approaches, architectural decisions, behavior changes, trade-offs, uncertainty | Ask the human via `AskUserQuestion`. |
| Test coverage gap rated 8+ | Always surface — never silently skipped. |

### Rules

- **DO** think independently — if a finding looks wrong, skip it; if you spot something missed, add it.
- **DO** respect human time — fix trivial things; only ask about what genuinely needs judgment.
- **DO** use `AskUserQuestion` for every user-facing decision (see `skills/flow/references/user-interaction.md`).
- **DO NOT** print free-form Y/n prompts or list choices in prose and wait for a typed answer.
- **DO NOT** silently skip a coverage gap rated 8+.
