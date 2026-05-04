---
name: run
description: Flow kernel — orchestrate a cell execution. Detects the current stage, runs the right transition, presents the resulting handoff for human review, and advances. Used when the user says "flow", describes what they want to build, or wants to continue where they left off.
metadata:
  short-description: Flow kernel — orchestrate a cell run
---

# Run

Kernel primitive: take a cell manifest and walk a thread from idea to delivery, with the human in the loop at every boundary.

A **thread** is one piece of work — 1:1 with a git branch, a folder under `agent/threads/<YYYY-MM-DD>-<branch>/`. Each stage emits a **handoff** (a markdown document) that the human inspects and the next stage's agent consumes.

Two readers care about every handoff: a human reviewing and editing, and the next stage's agent reading. See `references/protocol.md` for the handoff format, `references/style.md` for house markdown style, `references/glossary.md` for canonical terms.

> **Note:** Every user-facing decision goes through `AskUserQuestion`. Free-form prose is for status updates, narration, and summaries only. See `references/user-interaction.md`.

## The pipeline

The active cell defines its own stages via `cell.yaml`. The `code-pipeline` starter defines:

```text
Idea → [explore] → Spec → [plan] → Plan → [implement] → Changes → [review] → Findings → [ship] → PR
```

Each stage reads the previous stage's handoff, performs its work, and writes the next one. Stage names, file prefixes, and delivery target all come from the active cell — `run` itself knows none of them.

| Stage | Input | Output | Path |
|---|---|---|---|
| explore | Idea | Spec | `agent/threads/<date>-<branch>/01-spec-r<N>.md` |
| plan | Spec | Plan | `agent/threads/<date>-<branch>/02-plan-r<N>.md` |
| implement | Plan | Changes | git branch |
| review | Changes | Findings | `agent/threads/<date>-<branch>/03-review-r<N>.md` |
| ship | Findings | Delivery | recorded as `pr: <N>` (or other delivery key) in the spec frontmatter |

Every handoff follows `<NN>-<stage>-r<N>.md`. Revisions create a new file; the previous `-rN` stays frozen and the new file's `## Revisions` section explains what changed. "Current" means the highest-`N` file for that stage.

Handoff depth scales with task complexity. A one-line fix produces a 3-line spec and skips most ceremony; a complex feature produces full analysis at every stage.

## Revision vs. evolution

Two scales of change, both first-class:

- **Revision** — a re-thought handoff inside one thread. `01-spec-r2.md` says we changed our mind during this work. Captured in the new file's `## Revisions` section.
- **Evolution** — a matured skill at the cell level. A PR against the active cell repo, opened by `reflect`. The skill itself improves across threads.

## How to detect the current stage

The active thread is `agent/threads/*-$(git branch --show-current)/`. Walk the active cell's `stages[]` in order and stop at the first stage whose output is missing:

1. No `01-spec-r*.md` → first stage (e.g., **explore**).
2. Latest stage handoff exists, next stage's output missing → next stage.
3. All stage handoffs exist and a delivery key (e.g., `pr:`) is set → **done**.

When multiple conditions match, pick the **furthest-downstream** stage.

### Rules

- **DO** skip detection and go directly to the stage the user named when they gave explicit intent (e.g. "review this PR", "ship it").
- **DO** use `AskUserQuestion` when a handoff is missing, stale, or ambiguous. See `references/stage-detection.md`.
- **DO NOT** silently proceed with stale input.

## How to handle a stage boundary

Every boundary follows the same four beats:

1. Show a brief summary of what the stage did.
2. Surface any **decisions needed** via `AskUserQuestion`.
3. List any **verify** items clearly.
4. Ask about advancing via `AskUserQuestion`.

The advance question always uses this shape:

```text
Question: "Advance to the [next-stage] stage?"
Header:   Advance?
Options:  Yes, advance (Recommended) / Pause here / Adjust [this stage's handoff] first
```

See `references/boundaries.md` for auto-advance vs. pause rules, revision handling, and review-finding triage. See `references/user-interaction.md` for the `AskUserQuestion` contract. See `references/protocol.md` for the handoff format.

## Scripts

Shell helpers live under `skills/run/scripts/`. They avoid spending LLM tokens on mechanical work.

| Script | What it does |
|---|---|
| `detect-stage.sh` | Mirrors the stage detection above. Reads the active cell's manifest. **SKILL.md is authoritative if the bash drifts.** |
| `bootstrap.sh <branch>` | Creates the branch and materializes the initial spec at `agent/threads/<today>-<branch>/01-spec-r1.md` from the active cell's template. |
| `load-config.sh` | Sources `.flow/config.sh` (if present) and prints normalized flow env vars. See `references/config.md`. |
| `threads-summary.sh [scope]` | One-line summary per shipped thread (those with a delivery key in spec frontmatter). Used by `reflect` for cross-thread pattern scans. |
| `spike-branch.sh <thesis>` | Slugifies a thesis to `spike-<slug>`. Used by `/flow:spike` for unattended runs. |

## Related skills

- **Kernel primitives**: `ingest` (turn input into a skill), `reflect` (propose evolutions after a thread).
- **Cell stage skills**: live in the active cell at `~/.flow/active-cell/skills/`. Installed as a `<cell-name>:*` plugin by `make cell-use`.
- **Spike mode**: `<cell-name>:spike` (cell-provided) — runs a thread end-to-end unattended.
