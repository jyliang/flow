---
description: Reflect on recent flow history — propose CLAUDE.md, config, or skill tweaks.
---

You are the reflecting agent: read across shipped workstreams, spot drift in the flow system itself, and propose targeted tweaks for the human to approve.

Workstreams summary: !`$HOME/.claude/skills/flow/scripts/workstreams-summary.sh "${ARGUMENTS:-all}"`

## How to reflect

Read the workstreams summary above (shipped workstreams only — those with a `pr:` field in the spec). Scope follows `$ARGUMENTS` (see `skills/flow/references/reflection.md` axis (b) for the format — `all` / `N` / `pr-6,pr-7`).

### Step 1: Check the history threshold

If fewer than 2 shipped workstreams exist, say `not enough history yet — flow needs a few shipped PRs before reflection is useful` and stop.

### Step 2: Read the selected workstreams

Read the selected workstream dirs' spec, plan, and review files. Only dive into full content for dirs where the summary hints at a pattern.

### Step 3: Read the config surfaces

Read `.flow/config.sh` and the current project's `CLAUDE.md`.

### Step 4: Identify cross-workstream patterns

Identify 2–4 cross-workstream patterns. See `skills/flow/references/reflection.md` for what qualifies.

### Step 5: Draft one proposal per pattern

For each pattern, propose exactly one of:

| Target | What you propose |
|---|---|
| `CLAUDE.md` | A new convention, with exact text. |
| `.flow/config.sh` | A field plus its new value. |
| A stage skill file | A proposed diff — do not apply unless approved. |

### Step 6: Surface proposals for approval

Surface each proposal via `AskUserQuestion`, max 4 per call. Options for each: `Apply (Recommended)` / `Skip` / `Modify first`.

### Step 7: Apply and summarize

Apply approved changes. Summarize what changed.

## Rules

- **DO NOT** reflect on one-off bugs — that is the review stage's job.
- **DO NOT** touch `CLAUDE.md`, `.flow/config.sh`, or skill files without the user's explicit consent for that specific change.

$ARGUMENTS
