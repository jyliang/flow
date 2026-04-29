---
description: Distill the current conversation into a new thread — populate the spec and advance.
---

You are the seed-mode agent: read the live conversation, distill it into a new thread, and hand off at the spec boundary.

## /flow-here vs /teach — pick the right one

| Command | Output | Lifetime | Lands in |
|---|---|---|---|
| `/flow-here` (here) | A **thread** (one piece of work) | Time-bound; ends when shipped | Current project (`agent/threads/<date>-<branch>/`) |
| `/teach` | A **skill** (or CLAUDE.md rule) | Long-lived; reused across threads | Active cell repo (via branch + PR) |

If the user said "let's build this" / "ship this" / "kick this off as a thread" → `/flow-here`.
If the user said "remember this" / "create a skill" → `/teach`.

## How to seed the thread

Walk these steps in order. Each step produces input for the next.

### Step 1: Read the conversation

Read back through the conversation in your context window.

### Step 2: Extract the seed material

Extract the idea, decisions already made, open questions, and constraints.

### Step 3: Determine a branch name

- If `$ARGUMENTS` contains a branch-name-like token (lowercase kebab-case), use it.
- Otherwise, propose one from the conversation topic and confirm via `AskUserQuestion` before proceeding.

### Step 4: Bootstrap the thread

Run `$HOME/.claude/skills/run/scripts/bootstrap.sh <branch-name>` via the Bash tool. This creates `agent/threads/<today>-<branch>/01-spec-r1.md`.

If the script exits non-zero with `thread already exists`, surface recovery via `AskUserQuestion` with these options:

| Option | Effect |
|---|---|
| Overwrite | Remove the folder, re-run bootstrap. |
| Seed into existing | Edit `01-spec-r1.md` in place, or add a `-r2` revision. |
| Pick a different branch name | Restart from Step 3. |

### Step 5: Populate the spec

Populate the new `01-spec-r1.md` with the distilled content. Match the repo's spec style — see other shipped threads under `agent/threads/*/01-spec-r*.md` for examples.

### Step 6: Surface unresolved decisions

Surface any unresolved decisions from the conversation via `AskUserQuestion`.

### Step 7: Ask about advancing

Use `AskUserQuestion` with:

- Question: `Advance to the plan stage?`
- Header: `Advance?`
- Options: `Yes, advance (Recommended)` / `Pause here` / `Adjust spec first`

$ARGUMENTS
