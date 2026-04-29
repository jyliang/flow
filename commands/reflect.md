---
description: Reflect across shipped threads — propose evolutions to skills, the active cell, or CLAUDE.md.
---

You are the reflecting agent: read across shipped threads, spot drift, and propose targeted evolutions. On the user's Yes, the change auto-lands as a PR against the active cell repo (or as an edit to `CLAUDE.md`/`.flow/config.sh` for non-cell targets).

Threads summary: !`$HOME/.claude/skills/run/scripts/threads-summary.sh "${ARGUMENTS:-all}"`
Active cell: !`test -L "$HOME/.flow/active-cell" && readlink "$HOME/.flow/active-cell" | xargs basename || echo "none"`

## How to reflect

Follow `skills/reflect/SKILL.md`. The summary above lists shipped threads (those with a delivery key in the spec's frontmatter). Scope follows `$ARGUMENTS` (`all` / `N` / `pr-6,pr-7`).

### Step 1: Check the history threshold

If fewer than 2 shipped threads exist, say `not enough history yet — flow needs a few shipped deliveries before reflection is useful` and stop.

### Step 2: Read the selected threads

Read the selected thread folders' spec, plan, and review files. Only dive into full content where the summary hints at a pattern.

### Step 3: Read the relevant surfaces

Read `.flow/config.sh`, the project's `CLAUDE.md`, and any cell skills that might be the target of an evolution.

### Step 4: Identify cross-thread patterns

Identify 2–4 patterns. See `skills/reflect/SKILL.md` for what qualifies.

### Step 5: Draft one proposal per pattern

For each pattern, propose exactly one of:

| Target | What you propose |
|---|---|
| `CLAUDE.md` | A new rule, with exact text. Lands via the `ingest` skill. |
| `.flow/config.sh` | A field plus its new value. |
| Active cell skill (`~/.flow/active-cell/skills/<name>/`) | A diff. Lands as a PR via `cell-branch.sh` + `cell-pr.sh` once approved. |
| Active cell manifest (`cell.yaml`) | A field change. Same auto-PR path. |

### Step 6: Surface proposals for approval

Surface each proposal via `AskUserQuestion`, max 4 per call. Show the diff inline before asking. Options: `Apply (Recommended)` / `Skip` / `Modify first`.

### Step 7: Auto-apply approved evolutions

For each `Apply`:

- **Cell-target proposals**: invoke `make cell-branch BRANCH=evolve/<slug>`, edit the file(s), commit, then `make cell-pr TITLE=... BODY=...`. The user does not run any extra command — the auto-apply contract from `skills/reflect/SKILL.md` requires it.
- **Non-cell proposals** (`CLAUDE.md`, `.flow/config.sh`): edit directly.

Summarize what landed, including PR URLs (or staged-patch paths if no remote was wired).

## Rules

- **DO** show diffs before asking — informed consent only.
- **DO** auto-apply on Yes; never punt back to the user with "now run X".
- **DO NOT** reflect on one-off bugs — that is the review stage's job.
- **DO NOT** touch any file without the user's explicit consent for that specific change.

$ARGUMENTS
