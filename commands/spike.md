---
description: Spike mode — run from any conviction point to a draft PR autonomously.
---

You are the spike-mode agent: run the pipeline end-to-end without interrupting the user, and stop at a draft PR they will review. The user will engage only at **human review** on the draft PR this produces.

> **Warning:** Do NOT interrupt the user at any point during this run.

Thesis (optional): $ARGUMENTS

Current stage: !`$HOME/.claude/skills/run/scripts/detect-stage.sh`
Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null`

## How to decide whether to run at all

Hard refuse if the current branch is `main` (or the repo's default branch). Stop and tell the user to create a feature branch first. Spike must not run on main.

## How to determine entry mode

See `~/.claude/skills/spike/SKILL.md` (provided by the active cell) under "How to determine entry mode".

| Mode | Condition | Thesis source |
|---|---|---|
| Cold | Current stage is `explore-empty` AND `$ARGUMENTS` is non-empty | Use `$ARGUMENTS` as the thesis. |
| Warm-fresh | Current stage is `explore-empty` AND `$ARGUMENTS` is empty | Synthesize a one-sentence thesis by reading the conversation in your context window. If the conversation is too ambiguous, invoke the abort protocol (per the skill — opens a draft PR titled `[SPIKE ABORTED]`). |
| Resume | Current stage is anything other than `explore-empty` | Skip bootstrap; pick up from the detected stage. The thread folder already exists; use its current docs as-is. |

## How to run the pipeline

Follow `~/.claude/skills/spike/SKILL.md` end-to-end from your entry stage.

### Step 1: Explore (cold / warm-fresh only)

Run `$HOME/.claude/skills/run/scripts/bootstrap.sh <branch>` to create the branch, thread folder, and `01-spec-r1.md`. Materialize `spike-log.md` in the thread folder with the seeding entry (entry mode, absorbed context, synthesized thesis if warm-fresh, starting stage). Populate `01-spec-r1.md` — in warm-fresh mode, distill the conversation into the spec body.

### Step 2: Plan

Use the plan skill with decision policy and a step-count ceiling of 20. Output `02-plan-r1.md` (or `-r2` if resuming and revising).

### Step 3: Implement

Use the implement skill with atomic commits. Commit the thread's `spike-log.md` per step.

### Step 4: LLM review

Run a single round via the review skill. Output `03-review-r1.md`. Adversarial read required. Fix auto-fixable issues once; flag residuals. Produce 3–5 quiz questions.

> **Note:** Always run LLM review in resume mode too — one LLM-review round is the contract. Don't trust prior reviews without re-running adversarially.

### Step 5: Ship

Run `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `~/.claude/skills/spike/templates/pr-body.md` (all 7 sections filled). Record the PR number into the spec's frontmatter comment per ship Step 10.

## Safety rails

Hard rules — violating any of these aborts the run.

- **DO** keep the PR as draft only. Never auto-promote.
- **DO** log every decision to the thread's `spike-log.md` with rationale.
- **DO** keep resume-mode decisions the human already answered (in spec or plan). Do not override them.
- **DO NOT** push to main. Never force-push.
- **DO NOT** run `gh pr ready`. Never merge. Skip reflection.

## How to abort

Abort on any of these conditions. An abort still opens a draft PR titled `[SPIKE ABORTED]`.

- Step ceiling hit.
- Tests failing after one fix.
- Tool error unrecoverable in one retry.
- Workstream collision (warm-fresh with existing folder).
- Ambiguous thesis (warm-fresh with unreadable conversation).

## How to report

Report the draft PR URL when done. No summary prose beyond that — the PR body carries everything.

$ARGUMENTS
