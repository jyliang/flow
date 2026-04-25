# Stage detection edge cases

The flow-dispatch agent reads this doc when `detect-stage.sh` returns an ambiguous workspace state. When in doubt, don't silently proceed — surface the gap via `AskUserQuestion`, let the user choose, move on.

## Handle a stale spec (spec references missing files)

The codebase changed since the spec was written.

- **Question**: `"The spec references [X] which no longer exists. How do you want to proceed?"`
- **Header**: `Stale spec`
- **Options**: `Re-explore` / `Update the spec manually` / `Proceed anyway`

## Handle a plan without a spec

Someone deleted or never created the spec. The plan may still be valid.

- **Question**: `"There's a plan but no spec. How do you want to proceed?"`
- **Header**: `Missing spec`
- **Options**: `Continue from the plan` / `Start fresh with explore`

## Handle a stale review (code changed since review)

The findings may no longer match the current code.

- **Question**: `"Code changed since the last review. How do you want to proceed?"`
- **Header**: `Stale review`
- **Options**: `Re-review` / `Ship as-is`

## Handle multiple plan files

Use the most recent. Note the others exist. No question needed unless the user asks.
