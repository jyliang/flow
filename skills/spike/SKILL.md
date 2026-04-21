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

- User invoked `/flow-spike` — this skill orchestrates the run. Invokable at **any conviction point**: from a clean workspace with a thesis argument, mid-conversation with no arguments (LLM distills a thesis), or mid-workstream to let the rest run unattended.
- Do NOT use spike for work that requires judgment calls the user wants to make themselves — use regular `/flow`.

## Conversation absorption (three entry modes, one behavior)

| Mode | Trigger | Entry action |
|---|---|---|
| **Cold** | Clean workspace, `$ARGUMENTS` = thesis | Create branch via `spike-branch.sh`, run `bootstrap.sh`, populate `01-spec-r1.md` from the thesis and conversation (if any), continue. |
| **Warm-fresh** | Feature branch without a workstream folder for this branch | Synthesize a one-sentence thesis from the conversation context (or use `$ARGUMENTS` if provided). Create branch + workstream, but populate `01-spec-r1.md` by distilling the conversation — the human's exploration already happened; spike just formalizes it. |
| **Resume** | Branch already has a workstream folder | Do NOT create a new workstream. Read the current state via `detect-stage.sh`; decision policy applies to every subsequent AUQ. Prior human answers already recorded in spec/plan stay intact. |

Detection:
1. Check branch — refuse if it's `main` (or the repo's default). Spike must run on a feature branch.
2. Run `$HOME/.claude/skills/flow/scripts/detect-stage.sh`.
3. If the detected stage is `explore-empty` and no workstream folder exists for the current branch → **cold** (if `$ARGUMENTS` present) or **warm-fresh** (no args).
4. Otherwise → **resume**. Pick up from the detected stage.

All three modes end identically: draft PR with the 7-section human-review package, `spike-log.md` listing every auto-decision.

## Seeding the audit log

The first entry in `spike-log.md` records how spike entered. Template:

```
### [<ISO-8601>] entry: <mode>
- **Context**: <mode-specific — key points absorbed, existing workstream state, etc.>
- **Thesis (synthesized)**: <LLM's one-sentence read>   <!-- warm-fresh / resume only; cold uses $ARGUMENTS verbatim -->
- **Starting stage**: <plan | implement | review | ship>
```

This is the only pre-seeded entry. Everything else gets appended as decisions are made.

## Workstream layout

Every spike run produces one workstream folder at `agent/workstreams/<YYYY-MM-DD>-<branch>/`:
- `01-spec-r1.md` — materialized by `bootstrap.sh` from the configured template; spike populates.
- `02-plan-r1.md` — written by the plan stage.
- `03-review-r1.md` — written by the LLM-review stage.
- `spike-log.md` — audit log, append-only; every auto-decision lands here.

The folder is 1:1 with the branch (the new workstream-folder convention). No separate archive location; after merge the folder stays put. Human review reads the workstream folder in addition to the draft PR body.

## Decision policy (replaces AskUserQuestion in spike mode)

Everywhere the stage skills (explore, plan, implement, review, ship) would call `AskUserQuestion`, apply this policy instead:

1. Pick the option labeled `(Recommended)`.
2. If no option has `(Recommended)`, pick the first option.
3. Append an entry to the workstream's `spike-log.md` using the template at `skills/spike/templates/spike-log.md`:
   - stage, short decision label, context, full options set, chosen label, 1-sentence rationale.
4. Continue without pausing. Do NOT narrate the decision to the user mid-pipeline.

**Resume-mode caveat**: decisions already recorded by the human in the spec/plan (under `## Decisions needed` as `[x]` or with explicit prose) stand. The decision policy only applies to decisions spike encounters from its entry point forward. Don't retroactively override prior human judgment.

## Stage-by-stage guidance

### Explore

Only runs in **cold** and **warm-fresh** entry modes. Skipped in **resume** mode (the spec already exists).

- Determine the thesis: `$ARGUMENTS` wins if non-empty; otherwise LLM distills a one-sentence thesis from the conversation context.
- Compute a branch name via `$HOME/.claude/skills/flow/scripts/spike-branch.sh "<thesis>"` — produces `spike-<slug>`. If already on a feature branch in warm-fresh mode, keep the current branch name; don't switch.
- Run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch>` — creates the branch (if not already on it) and the workstream folder, materializes `01-spec-r1.md` from the configured template.
- Materialize `spike-log.md` in the workstream folder from `skills/spike/templates/spike-log.md`, substituting `{{BRANCH}}`, `{{THESIS}}`, `{{STARTED}}` (ISO 8601). Add the seeding entry described in "Seeding the audit log" above.
- Run the normal explore skill to populate the spec. In **warm-fresh** mode, distill the conversation context directly into the spec body (the human's exploration is the source material). All "Decisions needed" auto-resolve via the decision policy.

### Plan

- Run the normal plan skill. Produce `02-plan-r1.md` in the workstream folder.
- Hard step-count ceiling: **≤ 20 substeps**. If the plan would exceed 20, either compress (fewer, larger steps) or scope down the spec.

### Implement

- Run the normal implement skill. Commit atomically per step.
- Commit the workstream's `spike-log.md` along with each step's implementation commit so the decision timeline shows up in `git log`.
- If tests fail mid-step: fix once. If still failing, invoke the abort protocol.

### LLM review

- Single round. Use the normal `review` skill; output `03-review-r1.md` in the workstream folder.
- Classify findings. Auto-fix mechanical + critical in **one pass**. Do NOT re-run LLM review after fixing — loop cap = 1.
- Residual findings (not fixed) are flagged for human review.
- **Adversarial read — required**. Before writing the "What the spike shows" section, the LLM-review subagent must answer these four questions internally:
  1. What's the strongest fact I found that *supports* the thesis?
  2. What's the strongest fact I found that *contradicts* the thesis?
  3. What tests did I run that would have falsified the thesis, and did they?
  4. What would a skeptical reviewer push back on?
- **Quiz** — after the adversarial read, produce 3–5 thesis-oriented diagnostic questions for the human reviewer. Grounded in actual evidence, not hypothetical. See `skills/spike/templates/pr-body.md` for examples.

### Ship

- **Draft PR only**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `skills/spike/templates/pr-body.md` (all 7 sections filled).
- Never `gh pr ready`. Never `gh pr merge`. Those are human-review decisions.
- Per ship Step 7.5 of the normal ship flow, record the PR number into the spec's frontmatter comment: `<!-- branch: <branch> · date: <date> · author: <author> · pr: <N> -->`. The workstream folder stays put; no archive move.
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
- `bootstrap.sh` refuses because the workstream folder already exists (same-day same-thesis collision). Re-run with a modified thesis is a human call; autopilot aborts rather than picking an arbitrary new slug.

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
- **Clean workstream** — `bootstrap.sh` refuses if the workstream folder already exists; treat this as abort, not an auto-retry.
- **Audit log commits** — never rewrite the workstream's `spike-log.md` history; append only.

## Related skills

- `flow/SKILL.md` — the skill spike bypasses `AskUserQuestion` for.
- `flow/references/user-interaction.md` — documents the spike exception to the AUQ default.
- `review/SKILL.md` — the single LLM-review round consumes this skill's contract.
- `ship/SKILL.md` — spike-ship is a constrained version (draft, no reflection; still records `pr:` per Step 7.5).
