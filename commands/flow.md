---
description: Move work forward from idea to delivery — detect stage, advance.
---

This slash command is parsed by Claude Code and read by the `run` kernel skill — both need the detected stage and pack state below to decide what to do next.

Active pack: !`test -L "$HOME/.flow/active-pack" && readlink "$HOME/.flow/active-pack" | xargs basename || echo "none"`
Detected stage: !`$HOME/.claude/skills/run/scripts/detect-stage.sh 2>/dev/null || echo "kernel-not-installed"`
Config state: !`test -f .flow/config.sh && echo configured || echo unconfigured`

## How to route this invocation

Pick exactly one branch below based on active pack, detected stage, and config state.

| Active pack | Detected stage | Config state | Action |
|---|---|---|---|
| `none` | any | any | Offer to install the bundled `code-pipeline` starter via `AskUserQuestion` (Yes / Skip). On Yes, run `make pack-init STARTER=code-pipeline NAME=code-pipeline` and re-route. |
| set | `explore-empty` | `unconfigured` | Run the 3-question first-time setup from `/pack` **before** asking the idea prompt. All 3 questions are skippable; if the user skips all, still write `.flow/config.sh` with commented defaults so setup does not re-fire. |
| set | `explore-empty` | `configured` | First turn is the free-form text prompt `What do you want to build?` — no preamble, no skill summary. This is the exception case from `skills/run/references/user-interaction.md` (open-ended knowledge gathering); do NOT use `AskUserQuestion` here. |
| set | any other stage | either | Use the `run` skill to advance work at that stage. Every decision during that advance goes through `AskUserQuestion`. |

$ARGUMENTS
