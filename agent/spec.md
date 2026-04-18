# Spec: Flow v2 — per-project `.flow/config.sh` + scripted first-time setup

## Status
explore → plan

## What was done
- v1 (PR #6, merged) established scripts home + `/flow-adopt` + empty-state primed prompt. v1 spec deferred v2 (config) and v3 (reflection) explicitly.
- v2 scope confirmed from the 2026-04-17 brainstorm:
  - Per-project config so users can modify flow on a per-repo basis.
  - First-time conversational setup so the defaults path is frictionless.
- Committed to format/location decisions to keep the scope tight (see Decisions below).

## Decisions needed (committed, flag for redirect)
- [x] **Format**: `.flow/config.sh` as dotenv/bash (`KEY=VALUE`), bash-sourceable. Zero parsing dependencies. YAML was brainstormed but costs a parser (yq, Python) without clear v2 wins.
- [x] **Location**: always `.flow/config.sh` in the repo root. Personal overrides via environment variables (already supported by v1's `FLOW_TEMPLATE_DIR`). The brainstorm's "shared vs personal" toggle is collapsed — team-shared is the default; individuals who want overrides set env vars.
- [x] **First-time trigger**: automatic on `/flow` when `.flow/config.sh` is missing AND the workspace is empty (`explore-empty`). Not on every new project — only at the first real use. Explicit re-run via `/flow-config`.
- [x] **Question count**: 3 questions, all skippable. Smallest set that covers the real v2 value.

## Verify in reality
- [ ] Run `/flow` in a fresh project → scripted setup fires, writes `.flow/config.sh` with user's answers, then proceeds to the normal empty-state prompt.
- [ ] Run `/flow` in a project with existing `.flow/config.sh` → setup is skipped; bootstrap.sh uses the configured template path.
- [ ] Run `/flow-config` in a project that already has a config → offer to reconfigure (same 3 questions, current values pre-filled as defaults).
- [ ] Test `FLOW_TEMPLATE_DIR` env var still overrides `.flow/config.sh`'s `FLOW_TEMPLATE_SPEC` (env > file > built-in default).

## Spec details

### Problem

v1's flow is rigid: single template, no project-level overrides, no way to declare "this project wants a security-review stage after implement." v1 intentionally deferred this to keep the initial shipping surface small.

Two user pains motivate v2:
1. **Teams share a repo, want shared conventions** — e.g., everyone on team X uses the same spec template, the same pre-ship lint hook. Config must be committable.
2. **First-time setup should be frictionless** — a new user running `/flow` in a new repo should not face a blank prompt; the system should ask a short, specific set of questions with good defaults.

v2 solves (1) with `.flow/config.sh` and (2) with a 3-question setup fired on first `/flow`.

### Scope

**In:**
- `.flow/config.sh` schema (dotenv, bash-sourceable).
- `skills/flow/scripts/load-config.sh` — helper that sources `.flow/config.sh` if present, applies defaults, exports env vars for downstream scripts.
- `bootstrap.sh` consults `load-config.sh` output; uses `FLOW_TEMPLATE_SPEC` if set, else default.
- `commands/flow.md` updated: if `explore-empty` AND no `.flow/config.sh`, LLM runs scripted setup before the idea prompt.
- `commands/flow-config.md` — explicit re-configure command.
- `skills/flow/references/config.md` — documents the schema, field semantics, env var override precedence.
- `skills/flow/templates/` stays; users override by pointing `FLOW_TEMPLATE_SPEC` to a different file (usually in `.flow/templates/`).

**Out (deferred to v2.5 or v3):**
- Extra stages (custom stage insertion). Config schema will declare a placeholder field for forward-compat but the LLM ignores it in v2.
- Pre/post-stage hooks. Same — declared, not acted on.
- YAML format. Document migration path only.
- User-local (non-shared) config. Env vars handle this today.

### Design

#### The config schema

File: `.flow/config.sh` at repo root. Bash-sourceable. Example:
```sh
# .flow/config.sh — Flow per-project config
# Managed by /flow-config. Edit carefully; this file is sourced by bash.

FLOW_TEMPLATE_SPEC=".flow/templates/spec.md"
FLOW_STAGES="explore plan implement review ship"
FLOW_EXTRA_STAGES=""   # reserved for v2.5; unused in v2
FLOW_HOOKS_DIR=""      # reserved for v2.5; unused in v2
```

Fields:
- `FLOW_TEMPLATE_SPEC` — path to the spec template (relative to repo root). Overrides built-in `~/.claude/skills/flow/templates/spec.md`.
- `FLOW_STAGES` — space-separated stage list. Default = `explore plan implement review ship`. Changing this is future-work (v2.5); for v2 it's a read-only declaration.
- `FLOW_EXTRA_STAGES`, `FLOW_HOOKS_DIR` — reserved. LLM reads and surfaces them if set but doesn't act on them in v2.

#### Config loader

`skills/flow/scripts/load-config.sh` (new):
```bash
#!/usr/bin/env bash
# Load .flow/config.sh if present; export normalized env vars.
# Precedence: environment > .flow/config.sh > built-in defaults.

set -euo pipefail

if [[ -f .flow/config.sh ]]; then
  # shellcheck disable=SC1091
  source .flow/config.sh
fi

export FLOW_TEMPLATE_SPEC="${FLOW_TEMPLATE_SPEC:-$HOME/.claude/skills/flow/templates/spec.md}"
export FLOW_STAGES="${FLOW_STAGES:-explore plan implement review ship}"

# Print for debugging / command-body embedding
echo "FLOW_TEMPLATE_SPEC=$FLOW_TEMPLATE_SPEC"
echo "FLOW_STAGES=$FLOW_STAGES"
```

#### `bootstrap.sh` changes

Currently `bootstrap.sh` uses `FLOW_TEMPLATE_DIR` (override) + built-in default. v2 changes: honor `FLOW_TEMPLATE_SPEC` (a path to the file, not a dir), still fallback to built-in.

```bash
# v1
template_dir="${FLOW_TEMPLATE_DIR:-$HOME/.claude/skills/flow/templates}"
template="$template_dir/spec.md"

# v2
if [[ -f .flow/config.sh ]]; then source .flow/config.sh; fi
template="${FLOW_TEMPLATE_SPEC:-$HOME/.claude/skills/flow/templates/spec.md}"
```

Backwards-compat: keep `FLOW_TEMPLATE_DIR` working as a fallback-with-deprecation-note (users relying on v1's env var keep working for one release).

#### First-time scripted setup

Trigger: `commands/flow.md` runs `detect-stage.sh`. If stage is `explore-empty` AND `.flow/config.sh` is missing, include a primed instruction block:

```
First-time setup: this project doesn't have .flow/config.sh yet. Run the
scripted setup before asking for the idea — 3 AskUserQuestion prompts:

1. "Which spec template should this project use?"
   - Built-in default (from ~/.claude/skills/flow/)
   - Custom — copy default into .flow/templates/spec.md and edit later
2. "Declare project-specific extra stages now?"
   - No (Recommended)
   - Yes — ask what stage name (FLOW_EXTRA_STAGES, informational only in v2)
3. "Declare a hooks dir now?"
   - No (Recommended)
   - Yes — ask path (FLOW_HOOKS_DIR, informational only in v2)

Write answers to .flow/config.sh, then proceed to the idea prompt.
```

All three questions skippable (Recommended option = do nothing, fall through to defaults). In the frictionless path, user answers nothing-of-substance 3 times and lands on "What do you want to build?" within one turn.

#### `/flow-config` command

New: `commands/flow-config.md`. Body invokes the same 3-question setup, but with current `.flow/config.sh` values pre-filled as `(Recommended)` defaults. User overrides → rewrite file. User cancels → no change.

Used when: user already has a config and wants to reconfigure, or v2.5 adds new fields and the user wants to declare them.

#### `references/config.md`

New doc under `skills/flow/references/`. Content:
- The full schema with field semantics.
- The precedence rule (env > file > default).
- Migration notes for v1 users (`FLOW_TEMPLATE_DIR` still works).
- Forward-compat disclaimer (v2.5 will act on `FLOW_EXTRA_STAGES` / `FLOW_HOOKS_DIR`).

### Impact analysis

**Files to create:**
- `commands/flow-config.md`
- `skills/flow/scripts/load-config.sh`
- `skills/flow/references/config.md`
- `.flow/templates/spec.md` — only if the test case exercises the custom-template path. Not shipped to the repo; created by setup if user opts for custom.

**Files to modify:**
- `skills/flow/scripts/bootstrap.sh` — add config source + new env var name; keep legacy env var working.
- `commands/flow.md` — add first-time-setup primed block when applicable.
- `skills/flow/SKILL.md` — one-line pointer to `references/config.md`.
- `Makefile list` target — consider enumerating config state (future polish, optional).

### Constraints

- **No new binary dependencies**: bash + sed + git + gh. No yq, no Python, no jq.
- **Backwards compat**: v1 users running v2 scripts must keep working. `FLOW_TEMPLATE_DIR` is honored if set (with `FLOW_TEMPLATE_SPEC` taking precedence when both are set).
- **No silent config**: if `.flow/config.sh` exists but is malformed (bash syntax error), fail loudly rather than ignoring. `set -euo pipefail` + `source` will catch this.
- **Security**: `.flow/config.sh` is sourced. This is a trust decision — anyone who can edit the repo can inject bash. The file is committed, so code review is the gate. Document this in `references/config.md`.

### Open questions

1. **Config file name**: `.flow/config.sh` is explicit but verbose. Alternatives: `.flowrc` (shell-ish convention but less discoverable), `.flow/config` (no extension — portable but editors don't highlight). Lean: `.flow/config.sh`. Defer final.
2. **Should the first-time setup auto-write `.flow/config.sh` with defaults even if user skips all questions?** Yes — creating the file marks "this project has been set up" so the setup doesn't fire again. Content: all commented-out defaults. User knows where to look.

## References

- Brainstorm: 2026-04-17 session ("Flow v1 design" + "Flow v2/v3 followup").
- v1: `agent/archive/pr-6/{spec,IMPLEMENTATION_PLAN_2026-04-18,local-flow-v1-adopt-r1}.md`.
- `skills/flow/SKILL.md` — v1 semantics, preserved.
