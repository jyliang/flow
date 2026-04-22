---
description: Configure or reconfigure this project's .flow/config.sh — template, stages, hooks.
---

Configure this project's flow settings. Write or rewrite `.flow/config.sh` at the repo root.

Current config: !`test -f .flow/config.sh && cat .flow/config.sh || echo "(no .flow/config.sh yet)"`

Ask the user these 4 questions via `AskUserQuestion`. For each, if a value is already set in the current config, present it as the `(Recommended)` option. All questions skippable — skip = keep current value (or commented default if no current value).

1. **Spec template**: "Which spec template should this project use?"
   - Header: "Template"
   - Built-in default (`$HOME/.claude/skills/flow/templates/spec.md`)
   - Custom at `.flow/templates/spec.md` (copy built-in, let user edit later)
   - Custom at a different path (user provides)

2. **Test command**: "What command should ship run to exercise this project's tests?"
   - Header: "Test cmd"
   - None — this project relies on manual verification (Recommended for docs-only / shell-script repos)
   - `make test`
   - `npm test`
   - Custom (user provides; any shell command — e.g. `pytest`, `go test ./...`, `bash scripts/run-tests.sh`)

3. **Extra stages** (informational in v2, acted on in v2.5+): "Declare extra stages for this project?"
   - Header: "Extra stages"
   - No (Recommended)
   - Yes — user lists stage names

4. **Hooks dir** (informational in v2): "Declare a hooks directory for this project?"
   - Header: "Hooks"
   - No (Recommended)
   - Yes — user provides path (typically `.flow/hooks`)

After collecting answers, write `.flow/config.sh` with this shape:

```sh
# .flow/config.sh — Flow per-project config
# Managed by /flow-config. Edit carefully; this file is sourced by bash.

FLOW_TEMPLATE_SPEC="<user's answer or default>"
FLOW_STAGES="explore plan implement review ship"
FLOW_TEST_CMD="<user's answer, empty string if 'None'>"
# FLOW_EXTRA_STAGES="<user's answer>"   # v2.5
# FLOW_HOOKS_DIR="<user's answer>"      # v2.5
```

If the user chose "Custom at `.flow/templates/spec.md`" and that file doesn't exist, copy the built-in template there as a starting point. Also create `.flow/templates/` if needed.

Confirm completion with a one-line summary: what was written and where.

$ARGUMENTS
