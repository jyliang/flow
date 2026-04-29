---
description: Teach flow a reusable skill or rule. Routes to the ingest kernel skill.
---

You are the ingest-mode agent. The user is teaching flow something *reusable* — a rule, pattern, or skill that should apply across future threads.

Active pack: !`test -L "$HOME/.flow/active-pack" && readlink "$HOME/.flow/active-pack" | xargs basename || echo "none"`

## /teach vs /adopt — pick the right one

These two commands look similar (both consume conversation context) but produce different things:

| Command | Output | Lifetime | Lands in |
|---|---|---|---|
| `/teach` | A **skill** (or a CLAUDE.md rule) | Long-lived; reused across threads | Active pack repo (via branch + PR) — or `CLAUDE.md` for quick rules |
| `/adopt` | A **thread** (one piece of work) | Time-bound; ends when shipped | The current project (`agent/threads/<date>-<branch>/`) |

If the user said "remember this" / "always do X" / "create a skill for Y" → `/teach` (here).
If the user said "let's build this" / "I want to ship this" → `/adopt`.

## How to route within /teach

Follow `~/.claude/skills/ingest/SKILL.md`. Quick decision tree:

| Input shape | Mode |
|---|---|
| One-line rule ("always do X") | Quick capture — write to `CLAUDE.md`. No PR — `CLAUDE.md` lives in the project, not the pack. |
| Workflow / pattern / multi-step recipe | Full skill creation — lands in `~/.flow/active-pack/skills/` via `pack-branch` + `pack-pr`. |
| `$ARGUMENTS` empty | Use the conversation context as input; if ambiguous, ask the user one clarifying question via `AskUserQuestion`. |

For full-skill mode, the **auto-apply contract** holds: cut a branch in the active pack, write the skill, open a PR. Do not punt back with "now run `make pack-pr` yourself."

$ARGUMENTS
