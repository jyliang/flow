# Per-project flow config

Project maintainers and the flow stage skills both read this doc — maintainers to tune `.flow/config.sh`, agents to know which variables they can consult at runtime.

Each project may have a `.flow/config.sh` at the repo root. It is bash-sourceable — set `KEY=VALUE` lines, comments with `#`. Scripts source the file directly; malformed content fails loudly via `set -euo pipefail`.

Precedence for every field: **environment variable > `.flow/config.sh` > built-in default**. This lets a team share a repo-level config while individuals override via shell env.

## Schema

Every configurable knob is listed below; unlisted `FLOW_*` variables are not consulted.

| Variable | Default | Purpose |
|---|---|---|
| `FLOW_TEMPLATE_SPEC` | `$HOME/.claude/skills/flow/templates/spec.md` | Path to the spec template used by `bootstrap.sh`. |
| `FLOW_STAGES` | `explore plan implement review ship` | Declared stage order. Read-only in v2 (informational). |
| `FLOW_TEST_CMD` | `""` | Shell command ship runs in Steps 2 and 11 (before fixes + after push). Empty means no automated tests; ship notes "no test command configured" and continues. Example: `make test`, `npm test`, `bash scripts/run-tests.sh`. |
| `FLOW_EXTRA_STAGES` | `""` | Reserved for v2.5 (custom stage insertion). The LLM surfaces if set, but `detect-stage.sh` ignores it in v2. |
| `FLOW_HOOKS_DIR` | `""` | Reserved for v2.5 (pre/post-stage hooks). Declared-only in v2. |

> **Note:** If a new `FLOW_*` field needs to be consulted by `bootstrap.sh` (before `.flow/config.sh` can be trusted to exist), it must also be added to `bootstrap.sh`'s inlined precedence block. Fields only consumed later in the pipeline (like `FLOW_TEST_CMD`) live in `load-config.sh` alone.

## Handle backwards compatibility

`FLOW_TEMPLATE_DIR` (v1 env var) is still honored: if `FLOW_TEMPLATE_SPEC` is unset, scripts derive `FLOW_TEMPLATE_SPEC="$FLOW_TEMPLATE_DIR/spec.md"`. Planned deprecation in v3.

## Example `.flow/config.sh`

A starter file written by `/flow-config`; edit values as needed.

```sh
# .flow/config.sh — Flow per-project config
# Managed by /flow-config. Edit carefully; this file is sourced by bash.

FLOW_TEMPLATE_SPEC=".flow/templates/spec.md"
FLOW_STAGES="explore plan implement review ship"
FLOW_TEST_CMD=""                        # e.g. "make test" or "npm test"
# FLOW_EXTRA_STAGES="security-review"  # v2.5
# FLOW_HOOKS_DIR=".flow/hooks"          # v2.5
```

## Security

The config file is executable code, not data — treat it that way.

> **Warning:** `.flow/config.sh` is sourced as bash. Anything in it runs with the current user's permissions. Code review is the gate. Never source a `.flow/config.sh` from an untrusted repo.

## Run first-time setup

On `/flow` in an empty workspace with no `.flow/config.sh`, the LLM runs a 3-question scripted setup via `AskUserQuestion` and writes the file. All questions are skippable; skipping writes commented defaults (marks the project as set up, prevents the setup from re-firing). Re-run explicitly any time with `/flow-config`.
