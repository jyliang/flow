# evals

Capture flow runs, review them with rich qualitative feedback, and compare runs across kernel/cell versions. Reviews are committed to this repo so the next iteration of `/flow:reflect` (and the humans iterating on flow) can read them.

## Workflow

1. **Define a task.** A task is the prompt + the expected work — what we're evaluating flow against.
   ```
   make eval-task-new TASK=add-standup-cmd
   # edit evals/tasks/add-standup-cmd/{prompt.md,README.md}
   ```

2. **Run flow on the task.** In any project, open a Claude Code session and run `/flow:flow` with the task's prompt. Ship, pause, or abort — all are recordable.

3. **Capture the run.**
   ```
   make eval-record TASK=add-standup-cmd PROJECT=/path/to/project
   ```
   Discovers the most recent thread under `<project>/agent/threads/`, copies it, generates the diff, and writes a manifest pinned to the current kernel and cell SHAs. Optional flags: `THREAD=<dir>`, `BASE=main`, `COST=N`, `DURATION=N`.

4. **Review the run.** Long-form qualitative review in `$EDITOR`:
   ```
   make eval-review TASK=add-standup-cmd RUN=<run-id>
   ```
   Sections cover overall impression, per-stage notes, document quality (for both human and machine readers), code quality, and the highest-value section: **patterns flow should learn**. Numeric scores are optional.

5. **Compare runs:**
   ```
   make eval-compare TASK=add-standup-cmd A=<run-a> B=<run-b>
   ```
   Prints version pins, metric deltas, and lists reviews on both sides — `diff` the review files yourself to compare prose feedback.

6. **List what we have:**
   ```
   make eval-list
   ```

7. **Commit.** `evals/tasks/`, `evals/runs/`, and `evals/templates/` are all part of this repo.

## Layout

```
evals/
  tasks/<task-id>/             # task definitions (committed)
    task.json
    prompt.md
    README.md
  runs/<task-id>/<run-id>/     # captured runs (committed)
    manifest.json              # versions, project, metrics
    prompt.md                  # snapshot of the prompt at record time
    thread/                    # copied handoff docs from the run
    diff.patch                 # git diff <base>...<branch>
    reviews/<reviewer>.md      # one markdown file per reviewer
  templates/
    review.md                  # the review template
```

`run-id` format: `<utc-iso-timestamp>-<kernel-sha7>` — sortable, scannable, includes the kernel version axis.

## Why qualitative

Numeric scores are easy to game and lose nuance. The richest signal for improving flow is prose: *"the plan invented a file that doesn't exist," "the spec buried acceptance criteria in narrative," "implement re-asked questions explore had already answered."* That's what the review template invites, and that's what feeds the next iteration.
