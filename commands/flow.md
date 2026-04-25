---
description: Move work forward from idea to shipped PR — detect stage, advance
---

This slash command is parsed by Claude Code and read by the flow skill — both need the detected stage and config state below to decide what to do next.

Detected stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`
Config state: !`test -f .flow/config.sh && echo configured || echo unconfigured`

## How to route this invocation

Pick exactly one branch below based on the detected stage and config state.

| Detected stage | Config state | Action |
|---|---|---|
| `explore-empty` | `unconfigured` | Run the 3-question first-time setup from `/flow-config` **before** asking the idea prompt. All 3 questions are skippable; if the user skips all, still write `.flow/config.sh` with commented defaults so setup does not re-fire. |
| `explore-empty` | `configured` | First turn is the free-form text prompt `What do you want to build?` — no preamble, no skill summary, no other text. This is the exception case from `skills/flow/references/user-interaction.md` (open-ended knowledge gathering); do NOT use `AskUserQuestion` here. |
| any other stage | either | Use the `flow` skill to advance work at that stage. Every decision during that advance goes through `AskUserQuestion` per the flow skill's rule. |

$ARGUMENTS
