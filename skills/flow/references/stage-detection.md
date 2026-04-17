# Stage detection edge cases

When the workspace state is ambiguous, don't silently proceed. Surface the gap via `AskUserQuestion`, let the user choose, move on.

## Spec exists but references files that don't exist

The codebase changed since the spec was written.

- Question: `"The spec references [X] which no longer exists. How do you want to proceed?"`
- Header: `Stale spec`
- Options: `Re-explore` / `Update the spec manually` / `Proceed anyway`

## Plan exists but spec doesn't

Someone deleted or never created the spec. The plan may still be valid.

- Question: `"There's a plan but no spec. How do you want to proceed?"`
- Header: `Missing spec`
- Options: `Continue from the plan` / `Start fresh with explore`

## Findings exist but the code has changed since the review

- Question: `"Code changed since the last review. How do you want to proceed?"`
- Header: `Stale review`
- Options: `Re-review` / `Ship as-is`

## Multiple plan files exist

Use the most recent. Note the others exist. No question needed unless the user asks.
