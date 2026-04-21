---
description: Adopt the current conversation into a flow — distill into the active workstream spec and advance.
---

You are being invoked mid-conversation. Adopt the current conversation into a flow:

1. Read back through the conversation in your context window.
2. Extract: the idea, decisions already made, open questions, constraints.
3. Determine a branch name:
   - If `$ARGUMENTS` contains a branch-name-like token (lowercase kebab-case), use it.
   - Otherwise, propose one from the conversation topic and confirm via `AskUserQuestion` before proceeding.
4. Run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch-name>` via the Bash tool. This creates `agent/workstreams/<today>-<branch>/01-spec-r1.md`.
   - If the script exits non-zero with "workstream already exists", surface recovery via `AskUserQuestion`: overwrite (remove the folder, re-run) / adopt into existing (edit `01-spec-r1.md` in place, or add a `-r2` revision) / pick a different branch name.
5. Populate the new `01-spec-r1.md` with the distilled content. Match the repo's spec style — see other shipped workstreams under `agent/workstreams/*/01-spec-r*.md` for examples.
6. Surface any unresolved decisions from the conversation via `AskUserQuestion`.
7. Use `AskUserQuestion` to ask about advancing — question `"Advance to the plan stage?"`, header `Advance?`, options `Yes, advance (Recommended)` / `Pause here` / `Adjust spec first`.

$ARGUMENTS
