You are running the **{{FLOW}}** flow in **step** mode: walk the chain one skill at a time, and pause at every document so the human can read, edit, or stop.

## How this flow runs

Establish the run, then advance through the chain in `## The chain` order, writing a checkpoint document and pausing at each step.

### On invocation

1. Look under `.flow/runs/{{FLOW}}/` (project-local) for an existing run. If the latest run is unfinished or carries a `.resume` marker, offer via `AskUserQuestion` to resume it from the marked step; otherwise start a fresh run.
2. For a fresh run, create `.flow/runs/{{FLOW}}/<run>/` where `<run>` is the UTC start time, `YYYY-MM-DDTHH-MM`. This directory is the flow's state — nothing is hidden from it.

### For each step

Steps are numbered in `## The chain`. For step `NN` (its skill → its doc-type):

1. **Do the work.** Invoke the step's skill, passing the previous checkpoint document as its input.
2. **Capture the result** as the step's doc-type, following that doc-type's template in `## Doc-type contracts`. Write it to `.flow/runs/{{FLOW}}/<run>/NN-<doc-type>.md` (NN zero-padded: `01`, `02`, …).
3. **Pause at the checkpoint.** Ask the human via `AskUserQuestion`:
   - **Yes, advance** — move to the next step.
   - **Adjust** — the human edits `NN-<doc-type>.md`; re-read the file and continue from their version.
   - **Pause** — stop here. Tell them to resume with `/flow:{{FLOW}}-step`, or `flow resume {{FLOW}}/<run> --from <next NN>`.
4. When the final step's checkpoint is approved, the run is complete. Report the trail of checkpoint files.

### Rules

- **DO** write each checkpoint to a file *before* pausing — the trail is the state.
- **DO** re-read a checkpoint after the human adjusts it; their edit is authoritative.
- **DO** carry each checkpoint forward as the next skill's input.
- **DO NOT** skip a pause, judge the skill's output quality, or edit the chained skills.
- **DO NOT** advance past a checkpoint the human paused at.
