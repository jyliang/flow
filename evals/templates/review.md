# Review: {{run_id}}

- task: `{{task}}`
- reviewer: `{{reviewer}}`
- reviewed_at: {{reviewed_at}}

> Read the run artifacts alongside this review:
>
> - manifest: `evals/runs/{{task}}/{{run_id}}/manifest.json`
> - thread docs: `evals/runs/{{task}}/{{run_id}}/thread/*.md`
> - final diff: `evals/runs/{{task}}/{{run_id}}/diff.patch`

---

## Overall impression

(gut take — write freely. one paragraph or ten, your choice)

## What went well

(what should flow keep doing? cite specifics — quote the doc, point at the diff)

## What went poorly

(what should flow change? same — be specific)

## Per-stage notes

### Spec / explore

(what did the explore stage produce? was the spec usable? did it capture intent?)

### Plan

(was the plan grounded in the actual codebase? did it reference real files? right level of detail?)

### Implementation / final diff

(read `diff.patch`. is the code good? right size? scope-disciplined? any over-engineering?)

### Review (the stage)

(if a review stage ran — did it catch anything real, or rubber-stamp?)

## Document quality

### Human readability

How easy were the docs for a human to read? Quote awkward passages. Was the structure helpful or noise?

### Machine clarity

Did each stage's output give the next stage what it needed? Look for places where the next stage had to re-derive context, re-ask questions, or guess. That's where the upstream document failed its second reader.

## Code quality

Was the final diff good? Right things changed, right size, right amount of test coverage / comments / abstraction? Specific quotes from the diff are more useful than general impressions.

## Patterns flow should learn

**This is the highest-value section.** What should the next iteration of the kernel or cell do differently based on what you saw? Concrete proposals — *"plan stage should grep for existing patterns before proposing new abstractions," "spec stage should require an explicit acceptance criteria block."* The reflect step will read these.

## Comparison to other runs

If you've reviewed prior runs of this task (or similar tasks), what changed here? Better, worse, same — and why?

## Optional numeric scores (1-5)

Fill in what's useful, leave the rest blank. These supplement the prose, they don't replace it.

- doc_readability:
- doc_machine_clarity:
- code_quality:
- cost_satisfaction:
- speed_satisfaction:
- overall:
