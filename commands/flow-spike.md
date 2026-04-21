---
description: Spike mode — run from any conviction point to a draft PR autonomously.
---

You are in SPIKE mode. Do NOT interrupt the user at any point during this run. The user will engage only at **human review** on the draft PR this produces.

Thesis (optional): $ARGUMENTS

Current stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`
Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null`

Hard refuse: if the current branch is `main` (or the repo's default branch), stop and tell the user to create a feature branch first. Spike must not run on main.

Determine entry mode (see `skills/spike/SKILL.md` "Conversation absorption"):

- **Cold** — current stage is `explore-empty` AND `$ARGUMENTS` is non-empty. Use `$ARGUMENTS` as the thesis.
- **Warm-fresh** — current stage is `explore-empty` AND `$ARGUMENTS` is empty. Synthesize a one-sentence thesis by reading the conversation in your context window. If the conversation is too ambiguous to synthesize a thesis, invoke the abort protocol (per the skill — opens a draft PR titled `[SPIKE ABORTED]`).
- **Resume** — current stage is anything other than `explore-empty`. Skip bootstrap; pick up from the detected stage. The workstream folder already exists; use its current docs as-is.

Follow `skills/spike/SKILL.md` end-to-end from your entry stage:

1. **Explore** (cold / warm-fresh only): run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch>` to create the branch + workstream + `01-spec-r1.md`. Materialize `spike-log.md` in the workstream folder with the seeding entry (entry mode, absorbed context, synthesized thesis if warm-fresh, starting stage). Populate `01-spec-r1.md` — in warm-fresh mode, distill the conversation into the spec body.
2. **Plan**: plan skill, decision policy, step-count ceiling 20. Output `02-plan-r1.md` (or `-r2` if resuming and revising).
3. **Implement**: implement skill, atomic commits; commit the workstream's `spike-log.md` per step.
4. **LLM review**: single round via the review skill; output `03-review-r1.md`. Adversarial read required. Fix auto-fixable once; flag residuals. Produce 3–5 quiz questions. **Always run in resume mode too** — one LLM-review round is the contract; don't trust prior reviews without re-running adversarially.
5. **Ship**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `skills/spike/templates/pr-body.md` (all 7 sections filled). Record PR number into the spec's frontmatter comment per ship Step 7.5. Never `gh pr ready`. Never merge. Skip reflection.

Safety rails (HARD):
- Draft PR only. Never auto-promote.
- Never push to main. Never force-push.
- Every decision logged to the workstream's `spike-log.md` with rationale.
- Resume-mode decisions the human already answered (in spec/plan) stay — don't override.
- Aborts on: step ceiling hit, tests failing after one fix, tool error unrecoverable in one retry, workstream collision (warm-fresh with existing folder), ambiguous thesis (warm-fresh with unreadable conversation). Abort still opens a draft PR titled `[SPIKE ABORTED]`.

Report the draft PR URL when done. No summary prose beyond that — the PR body carries everything.

$ARGUMENTS
