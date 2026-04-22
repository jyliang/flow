---
description: Configure or reconfigure this project's .flow/config.sh — template, stages, hooks.
---

You are the configuring agent: ask the four questions below and write `.flow/config.sh` at the repo root. The written file is sourced by bash at runtime.

Current config: !`test -f .flow/config.sh && cat .flow/config.sh || echo "(no .flow/config.sh yet)"`

## How to ask the questions

Ask each question via `AskUserQuestion`. For each, if a value is already set in the current config, present it as the `(Recommended)` option. All questions are skippable — skip means keep the current value (or a commented default if no current value exists).

### Step 1: Spec template

- Question: `Which spec template should this project use?`
- Header: `Template`
- Options:
  - Built-in default (`$HOME/.claude/skills/flow/templates/spec.md`)
  - Custom at `.flow/templates/spec.md` (copy built-in, let user edit later)
  - Custom at a different path (user provides)

### Step 2: Test command

- Question: `What command should ship run to exercise this project's tests?`
- Header: `Test cmd`
- Options:
  - None — this project relies on manual verification (Recommended for docs-only / shell-script repos)
  - `make test`
  - `npm test`
  - Custom (user provides any shell command — e.g. `pytest`, `go test ./...`, `bash scripts/run-tests.sh`)

### Step 3: Extra stages

Informational in v2, acted on in v2.5+.

- Question: `Declare extra stages for this project?`
- Header: `Extra stages`
- Options:
  - No (Recommended)
  - Yes — user lists stage names

### Step 4: Hooks dir

Informational in v2.

- Question: `Declare a hooks directory for this project?`
- Header: `Hooks`
- Options:
  - No (Recommended)
  - Yes — user provides path (typically `.flow/hooks`)

## How to write the config file

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

### Rules

- **DO** copy the built-in template to `.flow/templates/spec.md` if the user chose that option and the file does not exist yet. Create `.flow/templates/` if needed.
- **DO** confirm completion with a one-line summary: what was written and where.
- **DO NOT** drop unanswered questions silently — keep their commented defaults in the file so the setup does not re-fire.

$ARGUMENTS
