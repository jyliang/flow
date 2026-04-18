---
description: Move work forward from idea to shipped PR — detect stage, advance
---

Detected stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`
Config state: !`test -f .flow/config.sh && echo configured || echo unconfigured`

If the detected stage is `explore-empty` AND config state is `unconfigured`, run the 3-question first-time setup from `/flow-config` BEFORE asking the idea prompt. All 3 questions are skippable — if the user skips all, still write `.flow/config.sh` with commented defaults so the setup doesn't re-fire.

If the detected stage is `explore-empty` AND config state is `configured`, your only first turn is to ask the user: "What do you want to build?" — no preamble, no skill summary, no other text.

For any other detected stage, use the `flow` skill to advance work at that stage.

$ARGUMENTS
