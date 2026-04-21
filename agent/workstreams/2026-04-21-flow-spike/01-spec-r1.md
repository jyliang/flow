<!-- branch: flow-spike · date: 2026-04-21 · author: Jason Liang · pr: -->

# Spec: `/flow-spike` — thesis-validation spike mode

## Status
explore → plan

## What was done
- Brainstormed spike shape across three turns (2026-04-21). Converged on "spike tool for thesis validation" framing, not "production PR generator."
- Pipeline confirmed: explore → plan → implement → **1 LLM-review round** → draft PR.
- Terminology pinned (user correction, 2026-04-21): **LLM review** is the "clear eyes" re-evaluation performed by the `review` skill inside the pipeline; it can trigger one self-fix pass. **Human review** is what happens on the draft PR after the pipeline completes — final approval, outside the pipeline. Spike spec uses "LLM review" and "human review" explicitly; bare "review" is avoided.
- Committed to a set of safety rails and audit-log conventions (see Design).
- Scope confirmed: one chunky PR is fine. Spike does NOT split scope; if follow-up work emerges, it lands in the "Next moves" section of the PR body for the human to decide.

## Decisions needed (committed, flag for redirect)
- [x] **LLM-review depth**: single LLM-review round. No re-review loop even if critical findings surface — fix once, ship with residuals flagged. Human review on the draft PR is the backstop.
- [x] **Audit log location**: `agent/spike-log.md`, committed as part of the PR. Human can audit every auto-decision from the PR diff during human review.
- [x] **Recommended-option fallback**: when an `AskUserQuestion` decision has no explicit `(Recommended)`, spike picks the first option and logs the fallback reasoning.
- [x] **Reflection skipped in spike**: the v3 "twice is a pattern" + `/flow-reflect` aren't useful on a throwaway spike; skipped to keep runtime bounded.
- [x] **Runtime ceiling**: no wall-clock timeout. Step-count ceiling in the implement stage (≤ 20 substeps per run); LLM self-aborts if it blows past.
- [x] **Terminology** (user-specified 2026-04-21): use "LLM review" and "human review" explicitly everywhere in spike artifacts (spec, plan, skill body, PR template). Bare "review" is ambiguous and avoided.

## Verify in reality
- [ ] Run `/flow-spike "validate that X approach is faster than Y"` in a sample project. Confirm: pipeline runs end-to-end without user interrupts, draft PR opens, PR body contains all 7 review-package sections, `agent/spike-log.md` lists every auto-decision.
- [ ] Confirm "What the spike shows" section is honestly adversarial (actively looks for thesis-contradicting evidence), not rubber-stamp.
- [ ] Confirm draft status sticks: PR is not `ready`, no auto-merge.
- [ ] Run two spike commands in parallel from different terminals; confirm branches + agent dirs don't collide.

## Spec details

### Problem

The v1–v3 flow pipeline is tuned for human-in-the-loop work: every stage boundary has an `AskUserQuestion`, the ship stage opens a real PR with auto-merge. This makes flow slow for **spikes** — experiments where the goal is to validate a thesis ("will approach X actually feel faster to users?", "can the parser handle Y edge case at all?") and come back with something to poke at.

Spike addresses that gap:
- Run unattended: kick off one or many spikes, walk away, come back to draft PRs.
- Thesis-centric: the draft PR body is organized around "does this support or refute the thesis?", not around "is this mergeable?".
- Human-light: no mid-pipeline prompts; the human's only touchpoint is **human review** of the draft PR after the pipeline completes.
- Throwaway-friendly: the PR may never merge — it's a scratchpad that either gets picked up via `/flow-adopt` for real work, or archived.

### Scope

**In:**
- New command `commands/flow-spike.md` — mode verb that drives the pipeline end-to-end.
- New skill `skills/spike/SKILL.md` — encapsulates the decision policy, audit log, and review package shape.
- New script `skills/flow/scripts/spike-branch.sh` — generates a unique branch name (`spike-<slug>-<date>`) from the thesis string.
- Review-package template: `skills/spike/templates/pr-body.md` — the 7-section draft PR body.
- Audit-log convention: `agent/spike-log.md` (committed) + template at `skills/spike/templates/spike-log.md`.

**Out (deferred):**
- Retry/resume on failure (spike that stops halfway; user picks up manually via `/flow`).
- Cross-spike synthesis ("here are three spikes and what they collectively show about the thesis").
- Auto-selection of which thesis to try next based on prior spike outcomes.

### Design

#### Command entry

`commands/flow-spike.md`:
```
---
description: Spike-mode flow. Run explore → plan → implement → 1 review → draft PR autonomously.
---

You are in SPIKE mode. Do NOT interrupt the user at any point during this run.

Thesis: $ARGUMENTS  (what we're validating)

Run: `$HOME/.claude/skills/flow/scripts/spike-branch.sh "$ARGUMENTS"` to get the branch name.

Then follow skills/spike/SKILL.md end-to-end:
1. Explore (auto-decisions logged to agent/spike-log.md).
2. Plan.
3. Implement (step-count ceiling: 20 substeps).
4. LLM review — 1 round of "clear eyes" re-evaluation via the `review` skill. Fix auto-fixable findings once; flag the rest as residuals. Do NOT loop.
5. Open draft PR for human review. Body assembled from skills/spike/templates/pr-body.md.

Safety rails:
- Draft PR only. Never `gh pr ready`. Never auto-merge.
- Never push to main. Never force-push.
- Every AskUserQuestion-equivalent decision is auto-resolved per the Recommended option (or first if none), and logged to agent/spike-log.md.
- If blocked (compile error, missing tool, hard contradiction in thesis), abort: commit current state, open draft PR with "ABORTED" status, explain.
```

#### Skill: `skills/spike/SKILL.md`

Orchestrates the full pipeline. Key sections:

1. **Decision policy** — "Pick `(Recommended)` option; if no `(Recommended)`, pick the first; log choice + 1-sentence rationale + the full options set to `agent/spike-log.md`."

2. **Stage-by-stage guidance** — spike-flavored version of each stage:
   - **Explore** — writes `agent/spec.md` same as normal; no user prompts. All "Decisions needed" auto-resolve.
   - **Plan** — writes `agent/plans/IMPLEMENTATION_PLAN_*.md`. Hard step-count ceiling enforced.
   - **Implement** — runs steps. Commits atomically per step. If tests fail, fix once; if still failing, abort.
   - **LLM review** — single "clear eyes" round via the `review` skill. Classifies findings; auto-fixes mechanical + critical (one pass); residuals flagged for human review on the draft PR. Loop cap = 1; never re-reviews after fix pass.
   - **Ship** — opens a **draft** PR for human review (`gh pr create --draft`). Populates body from the template. Never marks ready.

3. **Adversarial "What the spike shows"** — the LLM-review stage is instructed to actively hunt for thesis-contradicting evidence before writing this section. Checklist:
   - What's the strongest fact I found that *supports* the thesis?
   - What's the strongest fact I found that *contradicts* the thesis?
   - What tests did I run that would have falsified the thesis, and did they?
   - What would a skeptical reviewer point out?

4. **Abort protocol** — spike detects it can't make honest progress (step-count ceiling hit, tests still failing after one fix, thesis is fundamentally unclear). It commits whatever exists, opens a draft PR titled `[SPIKE ABORTED] <thesis>`, body explains the blocker, no quiz, no "next moves."

#### Human-review package (draft PR body)

Assembled from `skills/spike/templates/pr-body.md`. This is the sole input to **human review**. Every section is authored so the reviewer can decide "keep iterating vs archive" without reading the full diff.

1. **Thesis** — `$ARGUMENTS` verbatim.
2. **What the spike built** — one paragraph, plain English.
3. **How to poke at it** — one or two commands to reproduce what the human needs to see (run the dev server, `cargo run --example X`, a REPL snippet). Filled by the implement stage as commands are run.
4. **What the spike shows** — adversarial thesis read produced by the LLM-review stage (see above).
5. **Decisions log** — summary of `agent/spike-log.md`'s most impactful decisions (top 5–10; full file in the diff).
6. **Quiz** — 3–5 thesis-oriented diagnostic questions. Not graded; they prime the human reviewer. Example: *"Before running the example, predict what the output will be for input X. Did the actual output match?"*
7. **Next moves** — two buttons in prose: "Continue with `/flow-adopt` from this branch" (iterate with human-in-loop) and "Archive and start a new flow" (let the branch die, run a different spike).

#### Audit log (`agent/spike-log.md`)

Appended to during the run. Template:
```markdown
# Spike decision log

_Branch_: <branch>
_Thesis_: <thesis>
_Started_: <timestamp>

## Decisions

### [<timestamp>] <stage>: <short decision label>
- **Context**: <what was being decided, 1 sentence>
- **Options**:
  1. <option> (Recommended) — <description>
  2. <option> — <description>
- **Chose**: <label>
- **Why**: <1-sentence rationale>
```

Appended to exactly once per auto-decision. Committed per implement-step; visible in the final diff.

#### Branch naming: `spike-branch.sh`

```bash
#!/usr/bin/env bash
# Generate a unique branch name from a thesis string.
# Output: spike-<slug>-<YYYYMMDD-HHmm>
set -euo pipefail
thesis="$1"
slug="$(printf '%s' "$thesis" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9-' '-' \
  | sed -E 's/-+/-/g; s/^-|-$//g' \
  | cut -c1-40)"
stamp="$(date +%Y%m%d-%H%M)"
printf 'spike-%s-%s\n' "$slug" "$stamp"
```

Always includes a timestamp so two runs on the same thesis don't collide.

### Impact analysis

**Files to create:**
- `commands/flow-spike.md`
- `skills/spike/SKILL.md`
- `skills/spike/templates/pr-body.md`
- `skills/spike/templates/spike-log.md`
- `skills/flow/scripts/spike-branch.sh`

**Files to modify:**
- `skills/flow/SKILL.md` — one-line pointer to the spike skill under Related skills.
- `skills/flow/references/user-interaction.md` — note the spike exception ("Spike auto-answers via decision policy; see `spike/SKILL.md`").

**Files NOT to modify**: the stage skills (explore, plan, implement, review, ship). Spike orchestrates them by referencing them; each stage still operates normally under its own rules. Spike's "don't interrupt the user" wrapper is at the orchestration layer, not inside the stages.

### Constraints

- **Draft-only**: `gh pr create --draft`. Never `--title "Ready"` or `gh pr ready`.
- **Never escape the branch**: no push to other branches, no rebase against main mid-run.
- **Bounded**: ≤ 20 implement substeps, ≤ 1 LLM-review round, ≤ 1 fix pass. Human review (on the draft PR) has no bound — that's the user's call.
- **Honest adversarial LLM review**: explicit instruction in the LLM-review stage to look for falsifying evidence. Anti-pattern to avoid: LLM building what it thought the thesis asked for, then "confirming" the thesis by looking at its own output.
- **No reflection**: `/flow-reflect` behavior is skipped inside spike to keep runtime bounded. Reflection is for longitudinal flow use, not spikes.

### Open questions

1. **Quiz question generation**: who writes them, the implement stage or the LLM-review stage? Lean: LLM-review stage, because it has the end-to-end view and can phrase questions adversarially. Defer concrete mechanism to plan.
2. **How does spike handle existing `agent/spec.md`?** Refuse like `bootstrap.sh`, or treat as a resume? Lean: refuse (spike mode assumes clean branch), force a new branch.
3. **Should the PR title be a prefix (`[SPIKE] <thesis>`) to make it filterable in lists?** Lean: yes. Easy to add; helpful for "what have my spikes done lately?"
4. **Should the broader flow vocabulary adopt LLM-review / human-review** throughout (SKILL.md, references, ship-stage guidance)? Out-of-scope for this spec, but worth a follow-up — current flow docs use bare "review" which becomes ambiguous once spike normalizes the two-review model.

## References

- Brainstorm: 2026-04-21 session.
- Prior arcs: `agent/archive/pr-6/` (v1), `pr-7/` (v2), the unarchived v3 + AUQ-defaulting shipped under PRs #8/#9.
- `skills/flow/references/user-interaction.md` — the AskUserQuestion rule spike bypasses via its decision policy.
- `skills/review/SKILL.md` — the single review round consumes this skill's output shape.
