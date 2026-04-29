# Plan: `/flow-spike` — thesis-validation spike mode

## Status
plan → implement

## What was done
- Read spec at `agent/spec.md` (spike).
- Resolved spec open questions with defensible leans (see Decisions below).
- Designed 8-step implementation: scripts → templates → orchestration skill → command → flow docs → install.
- Scope: **medium-large** — 5 new files, 2 modified, ~250 LOC bash + markdown.

## Decisions needed (committed, flag for redirect)
- [x] **Q1 — Quiz authored by LLM-review stage**. Concrete mechanism: the spike LLM-review subagent produces 3–5 questions *after* writing the adversarial "What the spike shows" section, so the questions are grounded in the actual evidence.
- [x] **Q2 — Existing `agent/spec.md` → refuse**. Spike must start from a clean branch. Reuses `bootstrap.sh`-style refuse pattern: exit 2, stderr points at the existing spec, LLM surfaces "pick a different branch name" (but since spike is unattended, this falls through to the abort protocol).
- [x] **Q3 — PR title: `[SPIKE] <thesis-trimmed-to-60-chars>`**. Filterable in `gh pr list`; makes spike provenance obvious.
- [x] **Q4 — Broader flow vocabulary deferred**. Out of scope for this PR. Tracked as future work; the spike skill internally uses "LLM review" and "human review" consistently.

## Verify in reality
- [ ] Confirm `gh pr create --draft` creates a draft PR that stays draft even after push (no silent auto-promote).
- [ ] Confirm that committing `agent/spike-log.md` alongside implementation commits surfaces the decision log cleanly in the PR file tree.
- [ ] Confirm that the 20-substep implement ceiling is enforced by LLM self-discipline (no bash-level enforcement possible for this; verify via dry-run + instruction strength).

## Implementation Steps

> **Testing note**: same as prior v1/v2/v3 PRs — no test framework. Smoke tests in shell; end-to-end spike validation is inherently manual (can't self-drive the full pipeline without invoking it, which requires a live Claude Code session).

### Step 1: `skills/flow/scripts/spike-branch.sh`

- [ ] Tests:
  - Valid thesis → slug + timestamp branch name.
  - Thesis with uppercase / punctuation / whitespace → normalized to lowercase kebab-case.
  - Thesis > 40 chars → truncated cleanly.
  - Empty thesis → exit 2 with usage.
  - Two runs within a minute → different stamps (but safe because timestamp resolution is minute-level and we accept collisions are LLM's problem to retry).
- [ ] Code: new executable script per spec. Output: one line `spike-<slug>-<YYYYMMDD-HHmm>`.
- [ ] Test run: scripted smoke tests captured. ← `[PASTE TEST SUMMARY HERE]`

### Step 2: `skills/spike/templates/spike-log.md`

- [ ] Tests: docs-only; template renders cleanly (no orphan `{{...}}` after substitution).
- [ ] Code: new template with placeholders `{{BRANCH}}`, `{{THESIS}}`, `{{STARTED}}`. Header + empty `## Decisions` section that the LLM appends to during the run.
- [ ] Test run: `grep -c '{{' skills/spike/templates/spike-log.md`. ← `[PASTE TEST SUMMARY HERE]`

### Step 3: `skills/spike/templates/pr-body.md`

- [ ] Tests: docs-only. Template includes all 7 sections from the spec (Thesis, What the spike built, How to poke at it, What the spike shows, Decisions log, Quiz, Next moves).
- [ ] Code: new template. Use `{{THESIS}}`, `{{BRANCH}}` placeholders. The LLM fills the rest at ship time.
- [ ] Test run: verify all 7 section headers present: `grep -c '^## ' skills/spike/templates/pr-body.md` should be 7. ← `[PASTE TEST SUMMARY HERE]`

### Step 4: `skills/spike/SKILL.md` — orchestration skill

- [ ] Tests: `wc -l` under 250. Body covers decision policy, stage-by-stage guidance, adversarial review checklist, abort protocol.
- [ ] Code: new skill body. Sections:
  - **Goal + framing** — spike mode, thesis-validation, human-review-later.
  - **Vocabulary** — explicit "LLM review" / "human review" definitions at the top.
  - **Decision policy** — `(Recommended)` option; if none, first; log to `agent/spike-log.md`.
  - **Stage-by-stage** — concrete guidance for explore, plan, implement, LLM review, ship.
  - **Adversarial LLM-review checklist** — the four thesis-challenge questions from the spec.
  - **Abort protocol** — conditions + actions.
  - **Safety rails** — draft only, no force push, no main touches.
- [ ] Test run: `wc -l skills/spike/SKILL.md`. ← `[PASTE TEST SUMMARY HERE]`

### Step 5: `commands/flow-spike.md`

- [ ] Tests:
  - `/flow-spike "<thesis>"` invokes the spike skill.
  - No `$ARGUMENTS` → command says "need a thesis" and exits.
- [ ] Code: new command body. Minimal — mostly delegates to `skills/spike/SKILL.md`. Inline shell expansion to set up branch name: `!`$HOME/.claude/skills/flow/scripts/spike-branch.sh "$ARGUMENTS"``. LLM uses this for the branch.
- [ ] Test run: Manual post-install verification. ← `[PASTE TEST SUMMARY HERE]`

### Step 6: Update `skills/flow/SKILL.md`

- [ ] Tests: `wc -l` under 300.
- [ ] Code: add one line under Related skills mentioning spike as a "spike mode" alternative. No vocabulary changes here (Q4 is deferred).
- [ ] Test run: `wc -l skills/flow/SKILL.md && make list`. ← `[PASTE TEST SUMMARY HERE]`

### Step 7: Update `skills/flow/references/user-interaction.md`

- [ ] Tests: `wc -l` under 100.
- [ ] Code: add one "When NOT to use `AskUserQuestion`" bullet: "**Spike mode** — the `spike` skill overrides `AskUserQuestion` with a decision policy (Recommended option + audit log). See `spike/SKILL.md`."
- [ ] Test run: grep for the new bullet. ← `[PASTE TEST SUMMARY HERE]`

### Step 8: Install + end-to-end verify

- [ ] Tests:
  - `make install` succeeds; new skill dir copied; new script executable; new command present.
  - `skills/spike/` installed as a sibling of `skills/flow/`.
- [ ] Code: no Makefile change expected (`cp -r` handles new skill dir).
- [ ] Test run: `make install && test -x $HOME/.claude/skills/flow/scripts/spike-branch.sh && test -f $HOME/.claude/skills/spike/SKILL.md && test -f $HOME/.claude/commands/flow-spike.md && echo OK`. ← `[PASTE TEST SUMMARY HERE]`

## Architecture Decisions

- **Spike as a new skill, not a mode flag on existing ones**: keeps stage skills (explore, plan, implement, review, ship) free of conditional "if spike then X" logic. The spike skill orchestrates them from the outside, telling each "run your normal body, but don't prompt the user."
- **LLM-review / human-review terminology strict inside spike**: per user correction (2026-04-21). Anywhere the spec or plan says "review" bare, it's a bug — always qualified.
- **Audit log committed per implement-step**: landing each decision in git as it's made lets the human scan `git log agent/spike-log.md` during human review. Alternative (write-all-at-end) loses the chronological signal.
- **Abort = still opens a draft PR**: "ABORTED" state is visible in the PR title + body so the human can decide whether to pick up or discard. Alternative (exit silently) leaves the user confused.
- **Reuse existing stage skills unchanged**: stage skill bodies have `AskUserQuestion` calls; spike's decision policy intercepts at the LLM level ("when you'd normally call AskUserQuestion, apply the decision policy instead and log"). No changes to explore/plan/implement/review/ship themselves.

## Success Criteria
- [ ] All 8 implementation steps completed.
- [ ] `/flow-spike "<thesis>"` runs end-to-end without user interrupts.
- [ ] Draft PR opens, title starts with `[SPIKE]`, body has all 7 sections.
- [ ] `agent/spike-log.md` lists every auto-decision with rationale.
- [ ] PR stays draft; never auto-promoted.
- [ ] Two parallel spike runs don't collide on branch names or `agent/` paths (per-branch isolation by git).
- [ ] `skills/spike/SKILL.md` body under 250 lines.
- [ ] `skills/flow/SKILL.md` body under 300 lines.
