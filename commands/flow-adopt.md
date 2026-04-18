---
description: Adopt the current conversation into a flow — distill into agent/spec.md and advance.
---

You are being invoked mid-conversation. Adopt the current conversation into a flow:

1. Read back through the conversation in your context window.
2. Extract: the idea, decisions already made, open questions, constraints.
3. Determine a branch name:
   - If `$ARGUMENTS` contains a branch-name-like token (lowercase kebab-case), use it.
   - Otherwise, propose one from the conversation topic and confirm via `AskUserQuestion` before proceeding.
4. Run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch-name>` via the Bash tool.
   - If the script exits non-zero with "spec already exists", surface recovery via `AskUserQuestion`: overwrite (remove the file, re-run) / adopt into existing (edit in place) / pick a different branch name.
5. Populate `agent/spec.md` with the distilled content. Match the repo's spec style — see `agent/archive/*/spec.md` for examples.
6. Surface any unresolved decisions from the conversation via `AskUserQuestion`.
7. Ask about advancing to the plan stage.

$ARGUMENTS
