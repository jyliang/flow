---
description: Spike-mode flow. Runs explore → plan → implement → 1 LLM-review round → draft PR autonomously.
---

You are in SPIKE mode. Do NOT interrupt the user at any point during this run. The user will engage only at **human review** on the draft PR this produces.

Thesis: $ARGUMENTS

If `$ARGUMENTS` is empty, tell the user "spike needs a thesis — invoke as `/flow-spike \"<thesis>\"`" and stop. Do not start the pipeline without a thesis.

Branch name: !`$HOME/.claude/skills/flow/scripts/spike-branch.sh "$ARGUMENTS" 2>/dev/null || echo "spike-missing-thesis"`

Follow `skills/spike/SKILL.md` end-to-end:

1. **Explore**: create the branch (above), materialize `agent/spec.md` from the configured template, materialize `agent/spike-log.md` from the spike template with `{{BRANCH}}` / `{{THESIS}}` / `{{STARTED}}` substituted. Run the explore skill with the decision policy intercepting `AskUserQuestion`.
2. **Plan**: plan skill, decision policy, step-count ceiling 20.
3. **Implement**: implement skill, atomic commits, also commit `agent/spike-log.md` per step.
4. **LLM review**: single round. Adversarial read required. Fix auto-fixable once; flag residuals. Produce 3–5 quiz questions.
5. **Ship**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `skills/spike/templates/pr-body.md` (all 7 sections filled). Never `gh pr ready`. Never merge. Skip reflection.

Safety rails (HARD):
- Draft PR only. Never auto-promote.
- Never push to main. Never force-push.
- Every decision logged to `agent/spike-log.md` with rationale.
- If blocked (step cap, failing tests after one fix, tool error), invoke abort protocol per the skill — still opens a draft PR, titled `[SPIKE ABORTED]`.

Report the draft PR URL when done (success or aborted). No summary prose beyond that — the PR body carries everything.

$ARGUMENTS
