---
description: Move work forward from idea to delivery — detect stage, advance.
---

**Read `~/.flow/runtime/kernel/run/run.md`** — that's the orchestration contract (stage detection, handoff format, boundary beats). The dispatch table below names the entry behavior; the kernel doc carries the rest.

Active cell: !`test -L "$HOME/.flow/active-cell" && readlink "$HOME/.flow/active-cell" | xargs basename || echo "none"`
Detected stage: !`$HOME/.flow/runtime/kernel/run/scripts/detect-stage.sh 2>/dev/null || echo "kernel-not-installed"`
Config state: !`test -f .flow/config.sh && echo configured || echo unconfigured`

## How to route this invocation

Pick exactly one branch below based on active cell, detected stage, and config state.

| Active cell | Detected stage | Config state | Action |
|---|---|---|---|
| `none` | any | any | Offer to install the bundled `code-pipeline` starter via `AskUserQuestion` (Yes / Skip). On Yes, run `bash $HOME/.flow/runtime/scripts/cell-init.sh code-pipeline code-pipeline` and re-route. |
| set | `explore-empty` | `unconfigured` | Run the 3-question first-time setup from `/cell` **before** asking the idea prompt. All 3 questions are skippable; if the user skips all, still write `.flow/config.sh` with commented defaults so setup does not re-fire. |
| set | `explore-empty` | `configured` | First turn is the free-form text prompt `What do you want to build?` — no preamble, no kernel-doc summary. This is the exception case from `~/.flow/runtime/kernel/run/references/user-interaction.md` (open-ended knowledge gathering); do NOT use `AskUserQuestion` here. |
| set | any other stage | either | Follow `~/.flow/runtime/kernel/run/run.md` to advance work at that stage. Every decision during that advance goes through `AskUserQuestion`. |

$ARGUMENTS
