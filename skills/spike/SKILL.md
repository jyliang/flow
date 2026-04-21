---
name: spike
description: Spike-mode orchestration. Runs the full flow pipeline unattended and opens a draft PR for human review. Used via /flow-spike, not directly. Referenced by flow.
metadata:
  short-description: Unattended spike → draft PR
  internal: true
---

# Spike

## Goal

Run the full flow pipeline (explore → plan → implement → LLM-review → draft PR) **unattended** so the user can kick off a thesis-validation spike and come back to something testable.

The single human touchpoint is **human review** of the draft PR. The pipeline itself is LLM-only.

## Vocabulary

Two "reviews" — keep them distinct:
- **LLM review**: the `review` skill, run once inside this pipeline. "Clear eyes" re-evaluation; can trigger one self-fix pass. Bounded.
- **Human review**: happens on the draft PR after the pipeline completes. Final approval. Outside the pipeline, unbounded.

Anywhere this skill says bare "review" — it's ambiguous and should be rewritten. Always qualify.

## When to use

- User invoked `/flow-spike "<thesis>"` — this skill orchestrates the run.
- Do NOT use spike for work that requires judgment calls the user wants to make themselves — use regular `/flow`.

## Decision policy (replaces AskUserQuestion in spike mode)

Everywhere the stage skills (explore, plan, implement, review, ship) would call `AskUserQuestion`, apply this policy instead:

1. Pick the option labeled `(Recommended)`.
2. If no option has `(Recommended)`, pick the first option.
3. Append an entry to `agent/spike-log.md` using the template at `skills/spike/templates/spike-log.md`:
   - stage, short decision label, context, full options set, chosen label, 1-sentence rationale.
4. Continue without pausing. Do NOT narrate the decision to the user mid-pipeline.

## Stage-by-stage guidance

### Explore

- Use `bootstrap.sh`-style mechanics: create branch via `spike-branch.sh`, materialize `agent/spec.md` from `skills/flow/templates/spec.md` (or the project's configured template).
- Also materialize `agent/spike-log.md` from `skills/spike/templates/spike-log.md`, substituting `{{BRANCH}}`, `{{THESIS}}`, `{{STARTED}}` (ISO 8601).
- Run the normal explore skill to populate the spec. All "Decisions needed" auto-resolve via the decision policy.

### Plan

- Run the normal plan skill. Produce `agent/plans/IMPLEMENTATION_PLAN_*.md`.
- Hard step-count ceiling: **≤ 20 substeps**. If the plan would exceed 20, either compress (fewer, larger steps) or scope down the spec.

### Implement

- Run the normal implement skill. Commit atomically per step.
- Commit `agent/spike-log.md` along with each step's implementation commit so the decision timeline shows up in `git log`.
- If tests fail mid-step: fix once. If still failing, invoke the abort protocol.

### LLM review

- Single round. Use the normal `review` skill.
- Classify findings. Auto-fix mechanical + critical in **one pass**. Do NOT re-run LLM review after fixing — loop cap = 1.
- Residual findings (not fixed) are flagged for human review.
- **Adversarial read — required**. Before writing the "What the spike shows" section, the LLM-review subagent must answer these four questions internally:
  1. What's the strongest fact I found that *supports* the thesis?
  2. What's the strongest fact I found that *contradicts* the thesis?
  3. What tests did I run that would have falsified the thesis, and did they?
  4. What would a skeptical reviewer push back on?
- **Quiz** — after the adversarial read, produce 3–5 thesis-oriented diagnostic questions for the human reviewer. Grounded in actual evidence, not hypothetical. See `skills/spike/templates/pr-body.md` for examples.

### Ship

- **Draft PR only**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>" --body "$(cat agent/pr-body.md)"`.
- Never `gh pr ready`. Never `gh pr merge`. Those are human-review decisions.
- Body populated from `skills/spike/templates/pr-body.md` with substitutions for `{{THESIS}}`, `{{BRANCH}}`, and all 7 sections filled per the checklist in that template.
- After push + PR creation, report the PR URL plain text. Do NOT invoke reflection (`/flow-reflect`) — reflection is for longitudinal flow use, not spikes.

## Adversarial-review anti-pattern

Spike builds what it thought the thesis asked for. If LLM review then reads its own output and says "yes, this confirms the thesis" — that's worthless.

**Counter**: the adversarial read is non-optional. If the LLM-review subagent cannot name strong evidence *against* the thesis, the "What the spike shows" section should say so explicitly: *"I could not find evidence against this thesis, which may mean the spike didn't probe hard enough. Human reviewer should challenge this."*

That admission is more useful than false confidence.

## Abort protocol

Spike aborts when:
- Step-count ceiling hit (> 20 implement substeps needed).
- Tests fail after one fix attempt.
- The thesis is fundamentally unclear or self-contradictory.
- Any tool error the LLM can't route around in one retry.

On abort:
1. Commit all outstanding work on the branch.
2. Open a **draft** PR with title `[SPIKE ABORTED] <thesis-first-60-chars>`.
3. Body: first line explains the abort reason. Skip Quiz and Next moves sections; include What the spike built, Decisions log, and what remains.
4. Report the PR URL.

Aborting still produces a draft PR — the partial work is valuable for the human to inspect.

## Safety rails (hard rules)

- **Draft PR only** — never `gh pr ready`, never `gh pr merge`, never `--auto`.
- **No main touches** — never push to main, never rebase onto main mid-run.
- **No force push** — even if a fix pass needs rework, make a new commit.
- **No reflection** — skip the v3 "twice is a pattern" ship-stage scan; spike is too ephemeral.
- **Clean branch** — refuse if `agent/spec.md` already exists on the starting branch. Re-invoke with a different branch name (new timestamp handles this automatically).
- **Audit log commits** — never rewrite `agent/spike-log.md` history; append only.

## Related skills

- `flow/SKILL.md` — the skill spike bypasses `AskUserQuestion` for.
- `flow/references/user-interaction.md` — documents the spike exception to the AUQ default.
- `review/SKILL.md` — the single LLM-review round consumes this skill's contract.
- `ship/SKILL.md` — spike-ship is a constrained version (draft, no reflection).
