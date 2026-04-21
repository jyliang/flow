---
description: Reflect on recent flow history — propose CLAUDE.md, config, or skill tweaks.
---

Workstreams summary: !`$HOME/.claude/skills/flow/scripts/workstreams-summary.sh "${ARGUMENTS:-all}"`

Reflect on the flow system's own drift. Read the workstreams summary above (shipped workstreams only — those with a `pr:` field in the spec). Scope follows `$ARGUMENTS` (see `flow/references/reflection.md` axis (b) for the format — `all` / `N` / `pr-6,pr-7`).

If fewer than 2 shipped workstreams exist, say "not enough history yet — flow needs a few shipped PRs before reflection is useful" and stop.

Otherwise:

1. Read the selected workstream dirs' spec + plan + review files (only dive into full content for dirs where the summary hints at a pattern).
2. Also read `.flow/config.sh` and the current project's `CLAUDE.md`.
3. Identify 2-4 cross-workstream patterns (see `flow/references/reflection.md` for what qualifies).
4. For each pattern, propose exactly one of:
   - Update to `CLAUDE.md` (new convention, with exact text).
   - Edit to `.flow/config.sh` (field + new value).
   - Tweak to a stage skill file (show proposed diff, don't apply unless approved).
5. Surface each proposal via `AskUserQuestion`, max 4 per call. Options for each: `Apply (Recommended)` / `Skip` / `Modify first`.
6. Apply approved changes. Summarize what changed.

Do NOT:
- Reflect on one-off bugs — that's the review stage's job.
- Touch `CLAUDE.md`, `.flow/config.sh`, or skill files without the user's explicit consent for that specific change.

$ARGUMENTS
