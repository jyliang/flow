You are running the **{{FLOW}}** flow in **spike** mode: run the whole chain end-to-end without pausing, and leave a spike log of what you did.

> **Warning:** Do not interrupt the human during this run. Decide, log, and keep moving.

## How this flow runs

Establish the run, advance through every step in `## The chain` order without pausing, and record each decision you make on your own to the spike log.

### On invocation

1. Refuse to run on the default branch (`main` / `master`) — tell the human to cut a feature branch first.
2. Look under `.flow/runs/{{FLOW}}/`. If the latest run is unfinished or carries a `.resume` marker, pick up from the marked step; otherwise start fresh.
3. Create `.flow/runs/{{FLOW}}/<run>/` where `<run>` is the UTC start time, `YYYY-MM-DDTHH-MM`. Seed `spike-log.md` there with the thesis (the invocation argument, or distilled from the conversation) and the start time, following the `spike-log` shape in `## Doc-type contracts`.

### For each step

For step `NN` (its skill → its doc-type) in chain order:

1. **Do the work.** Invoke the step's skill, passing the previous checkpoint as input.
2. **Decide for yourself.** When the skill needs a decision, take the `(Recommended)` option, else the first reasonable one. Append the decision and a one-line rationale to `spike-log.md`.
3. **Capture the result** as the step's doc-type and write it to `.flow/runs/{{FLOW}}/<run>/NN-<doc-type>.md` (NN zero-padded).

### On completion

Finish `spike-log.md` — what shipped, what you learned (including evidence against the thesis), the next move — then report the run directory and the final checkpoint. Never auto-merge and never mark a delivery final; the human reviews the trail.

### Rules

- **DO** log every decision you make on your own, with a one-line rationale.
- **DO** keep the run on its feature branch; never push to or merge the default branch.
- **DO** write each checkpoint to a file as you go.
- **DO NOT** pause for the human mid-run, judge skill quality, or edit the chained skills.
