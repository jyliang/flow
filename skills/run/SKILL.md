---
name: flow
description: Single entry point for the development workflow. Detects current stage, advances work, and handles human interaction at document boundaries. Use when the user says "flow", describes what they want to build, or wants to continue where they left off.
metadata:
  short-description: Single entry point — idea to PR
---

# Flow

Move work from idea to shipped PR. This skill detects the current stage, runs the right transition, presents the resulting document for human review, and advances.

Two readers care about every document this skill produces: a **human** reviewing and editing it, and the **next stage's agent** consuming it as input. See `skills/docs-style/SKILL.md` for the house-style applied across every doc, and `skills/flow/references/glossary.md` for canonical terms.

> **Note:** Every user-facing decision goes through `AskUserQuestion`. Free-form prose is for status updates, narration, and summaries only. When in doubt, `AskUserQuestion`. See `references/user-interaction.md` for the rule and its exceptions (open-ended text prompts, irreversible-action confirms).

## The pipeline

```text
Idea → [explore] → Spec → [plan] → Plan → [implement] → Changes → [review] → Findings → [ship] → PR
```

Each stage reads the previous stage's document, performs its work, and writes the next one.

| Stage | Input | Output | Path |
|---|---|---|---|
| explore | Idea | Spec | `agent/workstreams/<date>-<branch>/01-spec-r<N>.md` |
| plan | Spec | Plan | `agent/workstreams/<date>-<branch>/02-plan-r<N>.md` |
| implement | Plan | Changes | git branch |
| review | Changes | Findings | `agent/workstreams/<date>-<branch>/03-review-r<N>.md` |
| ship | Findings | PR | GitHub PR (records `pr: <N>` in the spec's frontmatter comment; workstream folder stays in place) |

Every document follows `<NN>-<stage>-r<N>.md`:

- `<NN>` — stage-order prefix: `01` / `02` / `03`.
- `<stage>` — stage name.
- `-r<N>` — revision suffix: `-r1`, `-r2`, ….

Revisions create a new file; the previous `-rN` stays frozen, and the new file's `## Revisions` section explains what changed. "Current" means the highest-`N` file for that stage.

Document depth scales with task complexity. A one-line fix produces a 3-line spec and skips most ceremony; a complex feature produces full analysis at every stage. Structure is constant, depth is proportional.

## How to detect the current stage

The active workstream is `agent/workstreams/*-$(git branch --show-current)/` — one workstream per branch. Walk the detection rules in order and stop at the first match:

1. No `01-spec-r*.md` → **explore**.
2. Latest spec exists, no `02-plan-r*.md` → **plan**.
3. Latest plan has unchecked steps → **implement**.
4. Latest plan complete or unreviewed changes on branch → **review**.
5. Latest `03-review-r*.md` has unchecked items → **ship**.
6. PR exists and ready → **done**.

When multiple conditions match (e.g. open PR *and* a stale findings doc), pick the **furthest-downstream** stage: `done` > `ship` > `review` > `implement` > `plan` > `explore`.

### Rules

- **DO** skip detection and go directly to the stage the user named when they gave explicit intent (e.g. "review this PR", "ship it").
- **DO** use `AskUserQuestion` when a document is missing, stale, or ambiguous. See `references/stage-detection.md` for the exact prompts.
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
Options:  Yes, advance (Recommended) / Pause here / Adjust [this stage's document] first
```

See `references/boundaries.md` for auto-advance vs. pause rules, revision handling, and review-finding triage. See `references/user-interaction.md` for the `AskUserQuestion` contract. See `references/protocol.md` for the document format.

## Scripts

Shell helpers live under `skills/flow/scripts/`. They avoid spending LLM tokens on mechanical work, and are called from slash-command bodies and (when needed) directly via the Bash tool.

| Script | What it does |
|---|---|
| `detect-stage.sh` | Mirrors the 6-rule stage detection above. Prints one of `explore-empty` / `plan` / `implement` / `review` / `ship` / `done`. **SKILL.md is authoritative if the bash drifts.** |
| `bootstrap.sh <branch>` | Creates the branch and materializes the initial spec at `agent/workstreams/<today>-<branch>/01-spec-r1.md` from the configured template. Refuses if the workstream folder already exists. Consults `.flow/config.sh` for `FLOW_TEMPLATE_SPEC`; env var overrides file. |
| `load-config.sh` | Sources `.flow/config.sh` (if present) and prints normalized flow env vars. Precedence: env > file > defaults. See `references/config.md` for the schema. |
| `workstreams-summary.sh [scope]` | One-line summary per shipped workstream (those whose spec has a `pr: <N>` in its frontmatter comment). Used by `/flow-reflect` for cross-workstream pattern scans. Scope: `all` (default), `N` (last N), or `pr-X,pr-Y`. |
| `spike-branch.sh <thesis>` | Slugifies a thesis to `spike-<slug>`. Used by `/flow-spike` to name the unattended-spike branch; `bootstrap.sh` then adds the date prefix to form the workstream folder. |

## Related skills

- **Stages**: `explore`, `plan`, `implement`, `review`, `ship`.
- **Internal (auto-triggered)**: `tdd`, `commits`, `parallel`.
- **Meta**: `teach` — create skills or capture rules. `docs-style` — the house style applied to every doc.
- **Reflection**: see `references/reflection.md` for the "twice is a pattern" rule; triggered at ship-stage and via `/flow-reflect`.
- **Spike mode**: `spike/SKILL.md` — runs the full pipeline unattended to produce a draft PR for human review. Used via `/flow-spike "<thesis>"` when you want to validate a thesis fast and come back to something testable.
