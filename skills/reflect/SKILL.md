---
name: reflect
description: Flow kernel — after a thread runs, scan for patterns and propose evolutions to skills, the cell manifest, or CLAUDE.md. On user approval, the change auto-lands via branch + commit + PR. Use when the user says "reflect", invokes `/flow:reflect`, or finishes shipping a thread.
metadata:
  short-description: Flow kernel — propose cell evolutions
---

# Reflect

Kernel primitive: after a thread runs, observe what happened, propose changes that would have made it run better, and (on consent) apply them as PRs against the active cell repo.

The biological analog is **affinity maturation** — after immune exposure, B-cells edit the DNA encoding their antibodies, test variants, keep the better-binding ones. Reflect edits the markdown encoding skills, the human picks variants that bound better, and the cell matures.

User-facing slash command: `/flow:reflect`.

## The auto-apply contract

The defining principle: **once the user agrees a skill should evolve, the change lands automatically**. No second human step.

For each accepted proposal, reflect:

1. Cuts a branch in the active cell repo via `scripts/cell-branch.sh`.
2. Edits the skill markdown.
3. Commits with a message that links back to the thread.
4. Opens a PR via `scripts/cell-pr.sh` — to the user's remote if linked, otherwise stages the patch and reports next steps.

The user gives one informed Yes (after seeing the diff). The plumbing handles the rest.

## Two triggers

### Trigger 1: ship-stage sweep ("twice is a pattern")

Runs as the last step of the ship stage on every thread. Catches patterns that surface during a single run.

**Rule**: if the LLM has stated the same non-obvious fact about the project at least 2 times in this thread, and that fact is not already in `CLAUDE.md`, surface it as a candidate.

| Qualifies | Does not qualify |
|---|---|
| Paths: *"migrations live in `db/migrations/*.sql`"* | Status updates: *"I'm reading the file now"* |
| Rules: *"this repo uses `make install`, not `npm install`"* | Restatements during summaries |
| Gotchas: *"`gh pr edit --body` fails — use `gh api`"* | Transient reasoning |

One `AskUserQuestion` per candidate. Cap at 3 per ship.

### Trigger 2: explicit `/flow:reflect`

User invokes `/flow:reflect [scope]` to scan across multiple shipped threads. `scope` selects which:

| Argument | Meaning |
|---|---|
| `all` (default) | Every shipped thread under `agent/threads/` (those with a delivery key set). |
| `N` | Last N shipped threads. |
| `pr-6,pr-7` | Specific subset by delivery key. |

## What to look for

| Pattern | Proposal |
|---|---|
| Same finding in 2+ review handoffs | Edit to a stage skill that should have caught it earlier. |
| Decisions repeatedly deferred | Schedule the deferred work, or capture the deferral rule. |
| Stages consistently skipped | Cell manifest change (drop or merge stages). |
| Same correction the user made twice | Skill evolution capturing the corrected behavior. |

## What NOT to look for

- One-off bugs — that's review's job.
- Formatting of archived handoffs.
- Outcomes already done.
- Reflection on reflection (cataloging past reflections).

## Surface shape

2–4 proposals max per `/flow:reflect` invocation, each via `AskUserQuestion`. Each proposal is one of:

| Proposal kind | Lands in |
|---|---|
| New rule | `CLAUDE.md` (project or user, prompt for scope) |
| Cell manifest change | `~/.flow/active-cell/cell.yaml` |
| Skill evolution | `~/.flow/active-cell/skills/<name>/SKILL.md` (or references) |

Show the proposed diff inline. The user's Yes is informed consent — pre-baked plumbing applies it.

## Rules

- **DO** show diffs before asking. The user's Yes must be informed.
- **DO** delegate `CLAUDE.md` writes to the `ingest` skill.
- **DO** cap at 3 candidates per ship-stage sweep, 4 per `/flow:reflect`.
- **DO** exit silently when nothing qualifies.
- **DO NOT** write to `CLAUDE.md`, the active cell, or any skill silently.
- **DO NOT** run reflection as a background scan — only at ship or explicit command.
- **DO NOT** reflect on reflection itself.

> **Note:** If fewer than 2 threads under `agent/threads/` have a delivery key, say "not enough history yet" and exit. Reflection needs data.

## Related skills

- `run` — the orchestrator. Calls reflect at ship-stage end.
- `ingest` — the partner primitive. Reflect proposes; ingest is what lands new skills (vs. evolutions to existing ones).
