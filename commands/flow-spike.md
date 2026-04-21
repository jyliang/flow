---
description: Spike-mode flow. Runs explore → plan → implement → 1 LLM-review round → draft PR autonomously.
---

You are in SPIKE mode. Do NOT interrupt the user at any point during this run. The user will engage only at **human review** on the draft PR this produces.

Thesis: $ARGUMENTS

If `$ARGUMENTS` is empty, tell the user "spike needs a thesis — invoke as `/flow-spike \"<thesis>\"`" and stop. Do not start the pipeline without a thesis.

Branch name: !`$HOME/.claude/skills/flow/scripts/spike-branch.sh "$ARGUMENTS" 2>/dev/null || echo "spike-missing-thesis"`

Follow `skills/spike/SKILL.md` end-to-end:

1. **Explore**: run `bootstrap.sh` with the branch name above — it creates the branch and materializes `agent/workstreams/<today>-<branch>/01-spec-r1.md` from the configured template. Then materialize a `spike-log.md` in that same workstream folder from `skills/spike/templates/spike-log.md`, substituting `{{BRANCH}}` / `{{THESIS}}` / `{{STARTED}}`. Run the explore skill with the decision policy intercepting `AskUserQuestion`.
2. **Plan**: plan skill, decision policy, step-count ceiling 20. Output to `02-plan-r1.md` in the workstream folder.
3. **Implement**: implement skill, atomic commits; commit the workstream's `spike-log.md` per step.
4. **LLM review**: single round via the review skill; output to `03-review-r1.md`. Adversarial read required. Fix auto-fixable once; flag residuals. Produce 3–5 quiz questions.
5. **Ship**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `skills/spike/templates/pr-body.md` (all 7 sections filled). Record PR number into the spec's frontmatter comment per ship Step 7.5. Never `gh pr ready`. Never merge. Skip reflection.

Safety rails (HARD):
- Draft PR only. Never auto-promote.
- Never push to main. Never force-push.
- Every decision logged to the workstream's `spike-log.md` with rationale.
- If blocked (step cap, failing tests after one fix, tool error, workstream collision), invoke abort protocol per the skill — still opens a draft PR, titled `[SPIKE ABORTED]`.

Report the draft PR URL when done (success or aborted). No summary prose beyond that — the PR body carries everything.

$ARGUMENTS
