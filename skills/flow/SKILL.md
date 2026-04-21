---
name: flow
description: Single entry point for the development workflow. Detects current stage, advances work, and handles human interaction at document boundaries. Use when the user says "flow", describes what they want to build, or wants to continue where they left off.
metadata:
  short-description: Single entry point — idea to PR
---

# Flow

Move work forward from idea to shipped PR. Detect the current stage, run the right transition, present the document for human review, and advance.

Each document serves two readers: the human reviews and edits it, the next stage consumes it as input.

**Every user-facing decision goes through `AskUserQuestion`.** Free-form prose is for status updates, narration, and summaries only. When in doubt, `AskUserQuestion`. See `references/user-interaction.md` for the rule and its exceptions (open-ended text prompts, irreversible-action confirms).

## Pipeline

```
Idea → [explore] → Spec → [plan] → Plan → [implement] → Changes → [review] → Findings → [ship] → PR
```

| Stage | Input | Output | Path |
|-------|-------|--------|------|
| explore | Idea | Spec | `agent/workstreams/<date>-<branch>/01-spec-r<N>.md` |
| plan | Spec | Plan | `agent/workstreams/<date>-<branch>/02-plan-r<N>.md` |
| implement | Plan | Changes | git branch |
| review | Changes | Findings | `agent/workstreams/<date>-<branch>/03-review-r<N>.md` |
| ship | Findings | PR | GitHub PR (workstream folder moves to `agent/archive/` on merge) |

Every document within a workstream follows `<NN>-<stage>-r<N>.md`: stage-order prefix (`01`/`02`/`03`), stage name, and a revision suffix (`-r1`, `-r2`, …). Revisions create a new file — the previous `-rN` is frozen; the new file's `## Revisions` section explains what changed. "Current" means the highest-`N` file for that stage.

Document depth scales with task complexity. A one-line fix produces a 3-line spec and skips most ceremony; a complex feature produces full analysis at every stage. Structure is constant, depth is proportional.

## Detect the current stage

The active workstream is `agent/workstreams/*-$(git branch --show-current)/` (1:1 branch↔workstream). Within it:

1. No `01-spec-r*.md` → **explore**
2. Latest spec exists, no `02-plan-r*.md` → **plan**
3. Latest plan has unchecked steps → **implement**
4. Latest plan complete or unreviewed changes on branch → **review**
5. Latest `03-review-r*.md` has unchecked items → **ship**
6. PR exists and ready → **done**

When multiple conditions are true (e.g., open PR and a stale findings doc), the detection picks the **furthest-downstream** stage: done > ship > review > implement > plan > explore.

If the user gives explicit intent ("review this PR", "ship it"), skip detection and go directly to that stage.

If a document is missing, stale, or ambiguous, see `references/stage-detection.md` for the exact `AskUserQuestion` to raise. Never silently proceed with stale input.

## At a stage boundary

1. Show a brief summary of what was done.
2. Surface any **decisions needed** via `AskUserQuestion`.
3. List any **verify** items clearly.
4. Ask about advancing via `AskUserQuestion`:
   - Question: `"Advance to the [next-stage] stage?"`
   - Header: `Advance?`
   - Options: `Yes, advance (Recommended)` / `Pause here` / `Adjust [this stage's document] first`

See `references/boundaries.md` for auto-advance vs pause rules, revision handling, and review-finding triage. See `references/user-interaction.md` for the `AskUserQuestion` contract. See `references/protocol.md` for the document format.

## Scripts

Shell helpers under `skills/flow/scripts/` avoid LLM cost on mechanical work. Called from slash-command bodies and (when needed) directly via the Bash tool.

- `detect-stage.sh` — mirrors the 6-rule stage detection above. Prints one of `explore-empty` / `plan` / `implement` / `review` / `ship` / `done`. SKILL.md is authoritative if the bash drifts.
- `bootstrap.sh <branch>` — creates the branch and materializes the initial spec at `agent/workstreams/<today>-<branch>/01-spec-r1.md` from the configured template. Refuses if the workstream folder already exists. Consults `.flow/config.sh` for `FLOW_TEMPLATE_SPEC`; env var overrides file.
- `load-config.sh` — sources `.flow/config.sh` (if present) and prints normalized flow env vars. Precedence: env > file > defaults. See `references/config.md` for the schema.
- `archive-summary.sh [scope]` — one-line summary per archived workstream. Used by `/flow-reflect` for cross-archive pattern scans. Scope: `all` (default), `N` (last N), or `pr-X,pr-Y` (matches the `pr:` number from spec frontmatter).

## Related skills

Stages: `explore`, `plan`, `implement`, `review`, `ship`.
Internal (auto-triggered): `tdd`, `commits`, `parallel`.
Meta: `teach` — create skills or capture rules. Reflection — see `references/reflection.md` for the "twice is a pattern" rule; triggered at ship-stage and via `/flow-reflect`.
