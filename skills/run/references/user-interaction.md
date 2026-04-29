# User Interaction

Every flow stage agent (and internal skills that talk to the user, like `tdd` and `teach`) reads this doc — it is the canonical rule for how flow interacts with the human.

## The rule

**Use `AskUserQuestion` for any user-facing decision or choice.** Reserve free-form prose for status updates, progress narration, and summaries.

Every stage (`explore`, `plan`, `implement`, `review`, `ship`) — and internal skills that talk to the user (`tdd`, `teach`) — follows this rule.

## When to use and when to skip

Two buckets: decisions go through the tool, narration and open-ended prompts don't.

### Use `AskUserQuestion` for

- **Document-boundary decisions** — advance to the next stage, pause, or revise.
- **Unresolved spec/plan/findings decisions** — any item under `## Decisions needed` that blocks progress.
- **Mid-stage clarifications** — ambiguous requirements, unknown scope, discovered edge cases that require human judgment.
- **Review-finding triage** — anything that qualifies as "Ask the human" per `skills/ship/SKILL.md` (multiple valid approaches, architectural decisions, behavior changes, trade-offs, uncertainty).
- **Stale-document scenarios** — spec references missing files, plan without spec, findings out of date vs code.
- **Teach-skill scope and capture** — "system-wide vs project", "is this rule right?", "confirm outline before writing".

### Do NOT use `AskUserQuestion` for

- **Status updates** — "Exploring 4 files in parallel" is narration, not a question.
- **End-of-turn summaries** — what changed and what's next. Just state it.
- **Irreversible-action confirmations** — `git push --force`, destructive operations. The Claude Code permission layer handles these; duplicating the confirmation in `AskUserQuestion` is noise.
- **Purely informational output** — findings, summaries, diffs. Write these as prose or documents.
- **Open-ended knowledge gathering** — "Give me a concrete example", "Share reference material", "Describe your use case". The tool requires 2–4 discrete options per question; there's no natural option set for open-ended answers. Use free-form prompts instead.
- **Spike mode** — the `spike` skill overrides `AskUserQuestion` with a decision policy (pick `(Recommended)`, else first option; log to the thread's `spike-log.md`). Stage skills remain unchanged; spike intercepts at the orchestration layer. See `skills/spike/SKILL.md`.

## Tool contract

The `AskUserQuestion` tool has fixed shape — violate these limits and the call fails.

| Field | Constraint |
|---|---|
| Options per question | 2–4. No more, no fewer. |
| Questions per call | 1–4. Batch related questions into a single call rather than chaining calls. |
| "Other" | Auto-provided by the tool. Do not add it manually as an option. |
| Recommendation | If you have a preferred option, make it the first one and append `(Recommended)` to the label. |
| `multiSelect` | Default `false`. Use `true` only when choices are genuinely not mutually exclusive. |
| `header` | ≤ 12 chars, acts as a chip/tag (e.g. `Scope`, `Strength`, `Approach`). |

## Call-shape template

```text
AskUserQuestion({
  questions: [{
    question: "Full question text ending with '?'",
    header: "Short tag",
    multiSelect: false,
    options: [
      { label: "Preferred choice (Recommended)", description: "What this option does and its trade-offs" },
      { label: "Alternative", description: "What this option does and its trade-offs" }
    ]
  }]
})
```

## Batch related questions

When a stage has multiple related decisions, prefer **one `AskUserQuestion` call with multiple questions** over multiple calls. Four focused questions in one round is much better than four serialized prompts.

Group questions when they share context (same finding, same file, same architectural theme). Split into separate calls when answering one question changes what the next question should be.

## Anti-patterns

- **DO NOT** print a "Y/n?" prompt in prose and wait for the user to type — use `AskUserQuestion` with explicit options.
- **DO NOT** list choices in free-form markdown and ask "which do you prefer?" — convert to `AskUserQuestion` options.
- **DO NOT** use `AskUserQuestion` for rhetorical framing or to narrate your plan. If there's no real choice, don't ask.
- **DO NOT** overload one question with 5+ options. Split into multiple questions or pre-narrow the choice.
