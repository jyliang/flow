---
name: spike
description: Spike-mode orchestration. Runs the full flow pipeline unattended and opens a draft PR for human review. Used via /flow-spike, not directly. Referenced by flow.
metadata:
  short-description: Unattended spike → draft PR
  internal: true
---

# Spike

Run the full flow pipeline (`explore` → `plan` → `implement` → LLM-review → draft PR) unattended, so a human can kick off a thesis-validation spike and come back to something testable.

This skill has two readers: the **spike-mode agent** orchestrating the run (primary), and the **human reviewer** picking up the resulting draft PR. The single human touchpoint is the draft PR; the pipeline itself is LLM-only.

## Vocabulary

Two "reviews" exist in the flow system; this skill keeps them distinct.

| Name | Where it runs | Scope |
|---|---|---|
| LLM review | Inside this pipeline, once | Clear-eyes re-evaluation. Can trigger one self-fix pass. Bounded. |
| Human review | On the draft PR after the pipeline completes | Final approval. Outside the pipeline. Unbounded. |

> **Warning:** Anywhere this skill says bare "review", it's ambiguous and should be rewritten. Always qualify as LLM review or human review.

## When to use

Spike orchestrates `/flow-spike` runs. Invokable at **any conviction point**:

- From a clean workspace with a thesis argument.
- Mid-conversation with no arguments (the LLM distills a thesis from context).
- Mid-workstream, letting the rest run unattended.

### Rules

- **DO** use spike for thesis-validation work where you want to come back to something testable.
- **DO NOT** use spike for work that requires judgment calls the user wants to make themselves — use regular `/flow`.

## How to determine entry mode

Spike supports three entry modes but produces one artifact: a draft PR with the human-review package.

| Mode | Trigger | Entry action |
|---|---|---|
| Cold | Clean workspace, `$ARGUMENTS` = thesis | Create branch via `spike-branch.sh`, run `bootstrap.sh`, populate `01-spec-r1.md` from the thesis and conversation (if any), continue. |
| Warm-fresh | Feature branch without a workstream folder for this branch | Synthesize a one-sentence thesis from the conversation context (or use `$ARGUMENTS` if provided). Create branch + workstream, populate `01-spec-r1.md` by distilling the conversation — the human's exploration already happened; spike formalizes it. |
| Resume | Branch already has a workstream folder | Do NOT create a new workstream. Read the current state via `detect-stage.sh`; decision policy applies to every subsequent `AskUserQuestion`. Prior human answers already recorded in the spec/plan stay intact. |

### How to detect

1. Check the branch — refuse if it's `main` (or the repo's default). Spike must run on a feature branch.
2. Run `$HOME/.claude/skills/flow/scripts/detect-stage.sh`.
3. If the detected stage is `explore-empty` and no workstream folder exists for the current branch → **cold** (if `$ARGUMENTS` present) or **warm-fresh** (no args).
4. Otherwise → **resume**. Pick up from the detected stage.

All three modes end identically: a draft PR with the 7-section human-review package plus `spike-log.md` listing every auto-decision.

## How to seed the audit log

The first entry in `spike-log.md` records how spike entered. Template:

```text
### [<ISO-8601>] entry: <mode>
- **Context**: <mode-specific — key points absorbed, existing workstream state, etc.>
- **Thesis (synthesized)**: <LLM's one-sentence read>   <!-- warm-fresh / resume only; cold uses $ARGUMENTS verbatim -->
- **Starting stage**: <plan | implement | review | ship>
```

This is the only pre-seeded entry. Everything else appends as decisions are made.

## Workstream layout

Every spike run produces one workstream folder at `agent/workstreams/<YYYY-MM-DD>-<branch>/`:

| File | Produced by |
|---|---|
| `01-spec-r1.md` | `bootstrap.sh` materializes from the configured template; spike populates. |
| `02-plan-r1.md` | Plan stage. |
| `03-review-r1.md` | LLM-review stage. |
| `spike-log.md` | Audit log, append-only; every auto-decision lands here. |

The folder is 1:1 with the branch (one workstream per branch). No separate archive — after merge the folder stays put. Human review reads the workstream folder in addition to the draft PR body.

## Decision policy (replaces AskUserQuestion in spike mode)

Everywhere the stage skills (`explore`, `plan`, `implement`, `review`, `ship`) would call `AskUserQuestion`, apply this policy instead:

1. Pick the option labeled `(Recommended)`.
2. If no option has `(Recommended)`, pick the first option.
3. Append an entry to the workstream's `spike-log.md` using the template at `skills/spike/templates/spike-log.md`:
   - stage, short decision label, context, full options set, chosen label, 1-sentence rationale.
4. Continue without pausing. Do NOT narrate the decision to the user mid-pipeline.

> **Note:** Resume-mode caveat — decisions already recorded by the human in the spec or plan (under `## Decisions needed` as `[x]` or with explicit prose) stand. The decision policy only applies to decisions spike encounters from its entry point forward. Don't retroactively override prior human judgment.

## How to run the pipeline, stage by stage

### Step 1: Explore

Only runs in **cold** and **warm-fresh** entry modes. Skipped in **resume** mode because the spec already exists.

- Determine the thesis: `$ARGUMENTS` wins if non-empty; otherwise the LLM distills a one-sentence thesis from the conversation context.
- Compute a branch name via `$HOME/.claude/skills/flow/scripts/spike-branch.sh "<thesis>"` — produces `spike-<slug>`. If already on a feature branch in warm-fresh mode, keep the current branch name; don't switch.
- Run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch>` — creates the branch (if not already on it) and the workstream folder, materializes `01-spec-r1.md` from the configured template.
- Materialize `spike-log.md` in the workstream folder from `skills/spike/templates/spike-log.md`, substituting `{{BRANCH}}`, `{{THESIS}}`, `{{STARTED}}` (ISO 8601). Add the seeding entry described in "How to seed the audit log" above.
- Run the normal `explore` skill to populate the spec. In warm-fresh mode, distill the conversation context directly into the spec body — the human's exploration is the source material. All `## Decisions needed` items auto-resolve via the decision policy.

### Step 2: Plan

- Run the normal `plan` skill. Produce `02-plan-r1.md` in the workstream folder.
- Hard step-count ceiling: **≤ 20 substeps**. If the plan would exceed 20, either compress (fewer, larger steps) or scope down the spec.

### Step 3: Implement

- Run the normal `implement` skill. Commit atomically per step.
- Commit the workstream's `spike-log.md` along with each step's implementation commit, so the decision timeline shows up in `git log`.
- If tests fail mid-step: fix once. If still failing, invoke the abort protocol.

### Step 4: LLM review (single round)

Use the normal `review` skill; output `03-review-r1.md` in the workstream folder.

- Classify findings. Auto-fix mechanical + critical findings in **one pass**. Do NOT re-run LLM review after fixing — loop cap = 1.
- Residual findings (not fixed) are flagged for human review.
- **Adversarial read — required**. Before writing the "What the spike shows" section, the LLM-review subagent must answer these four questions internally:
  1. What's the strongest fact I found that *supports* the thesis?
  2. What's the strongest fact I found that *contradicts* the thesis?
  3. What tests did I run that would have falsified the thesis, and did they?
  4. What would a skeptical reviewer push back on?
- **Quiz** — after the adversarial read, produce 3–5 thesis-oriented diagnostic questions for the human reviewer. Ground them in actual evidence, not hypotheticals. See `skills/spike/templates/pr-body.md` for examples.

### Step 5: Ship

- **Draft PR only**: `gh pr create --draft --title "[SPIKE] <thesis-first-60-chars>"` with body from `skills/spike/templates/pr-body.md` (all 7 sections filled).
- Never `gh pr ready`. Never `gh pr merge`. Those are human-review decisions.
- Record the PR number into the spec's frontmatter comment (same as normal ship): `<!-- branch: <branch> · date: <date> · author: <author> · pr: <N> -->`. The workstream folder stays put; no archive move.
- After push + PR creation, report the PR URL in plain text. Do NOT invoke reflection (`/flow-reflect`) — reflection is for longitudinal flow use, not spikes.

## Adversarial-review anti-pattern

Spike builds what it thought the thesis asked for. If LLM review then reads its own output and says "yes, this confirms the thesis" — that's worthless.

> **Warning:** The adversarial read is non-optional. If the LLM-review subagent cannot name strong evidence *against* the thesis, the "What the spike shows" section should say so explicitly: *"I could not find evidence against this thesis, which may mean the spike didn't probe hard enough. Human reviewer should challenge this."* That admission is more useful than false confidence.

## How to abort

Spike aborts when any of these hit:

- Step-count ceiling exceeded (> 20 implement substeps needed).
- Tests fail after one fix attempt.
- The thesis is fundamentally unclear or self-contradictory.
- Any tool error the LLM can't route around in one retry.
- `bootstrap.sh` refuses because the workstream folder already exists (same-day same-thesis collision). Re-running with a modified thesis is a human call; autopilot aborts rather than picking an arbitrary new slug.

On abort:

1. Commit all outstanding work on the branch.
2. Open a **draft** PR with title `[SPIKE ABORTED] <thesis-first-60-chars>`.
3. In the body: first line explains the abort reason. Skip the Quiz and Next moves sections; include What the spike built, Decisions log, and what remains.
4. Report the PR URL.

Aborting still produces a draft PR — the partial work is valuable for the human to inspect.

## Safety rails

- **DO NOT** mark a PR ready — never `gh pr ready`, never `gh pr merge`, never `--auto`.
- **DO NOT** touch main — never push to main, never rebase onto main mid-run.
- **DO NOT** force push — even if a fix pass needs rework, make a new commit.
- **DO NOT** run reflection — skip the "twice is a pattern" ship-stage scan; spike is too ephemeral.
- **DO NOT** override `bootstrap.sh` — if it refuses because the workstream folder exists, that's abort, not auto-retry.
- **DO NOT** rewrite history in `spike-log.md` — append only.

## Related skills

- `skills/flow/SKILL.md` — the skill spike bypasses `AskUserQuestion` for.
- `skills/flow/references/user-interaction.md` — documents the spike exception to the AUQ default.
- `skills/review/SKILL.md` — the single LLM-review round consumes this skill's contract.
- `skills/ship/SKILL.md` — spike-ship is a constrained version (draft, no reflection; still records `pr:`).
- `skills/docs-style/SKILL.md` — house style applied to every doc, including the spike PR body and log.
