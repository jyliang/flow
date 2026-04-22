# Per-project flow config

Each project may have a `.flow/config.sh` at the repo root. It is bash-sourceable — set `KEY=VALUE` lines, comments with `#`. Scripts source the file directly; malformed content fails loudly via `set -euo pipefail`.

Precedence for every field: **environment variable > `.flow/config.sh` > built-in default**. This lets a team share a repo-level config while letting individuals override via shell env.

## Schema

| Variable | Default | Purpose |
|---|---|---|
| `FLOW_TEMPLATE_SPEC` | `$HOME/.claude/skills/flow/templates/spec.md` | Path to the spec template used by `bootstrap.sh`. |
| `FLOW_STAGES` | `explore plan implement review ship` | Declared stage order. Read-only in v2 (informational). |
| `FLOW_TEST_CMD` | `""` | Shell command ship runs before and after applying fixes (Steps 1.5 and 8). Empty = no automated tests; ship notes "no test command configured" and continues. Example: `make test`, `npm test`, `bash scripts/tests/*.sh`. |
| `FLOW_EXTRA_STAGES` | `""` | Reserved for v2.5 (custom stage insertion). LLM surfaces if set, but `detect-stage.sh` ignores it in v2. |
| `FLOW_HOOKS_DIR` | `""` | Reserved for v2.5 (pre/post-stage hooks). Declared-only in v2. |

## Backwards compat

`FLOW_TEMPLATE_DIR` (v1 env var) is still honored: if `FLOW_TEMPLATE_SPEC` is unset, scripts derive `FLOW_TEMPLATE_SPEC="$FLOW_TEMPLATE_DIR/spec.md"`. Planned deprecation in v3.

## Example `.flow/config.sh`

```sh
# .flow/config.sh — Flow per-project config
# Managed by /flow-config. Edit carefully; this file is sourced by bash.

FLOW_TEMPLATE_SPEC=".flow/templates/spec.md"
FLOW_STAGES="explore plan implement review ship"
FLOW_TEST_CMD=""                        # e.g. "make test" or "npm test"
# FLOW_EXTRA_STAGES="security-review"  # v2.5
# FLOW_HOOKS_DIR=".flow/hooks"          # v2.5
```

## Security note

`.flow/config.sh` is sourced as bash. Anything in it runs with the current user's permissions. Treat the file as executable code — code review is the gate. Never source a `.flow/config.sh` from an untrusted repo.

## First-time setup

On `/flow` in an empty workspace with no `.flow/config.sh`, the LLM runs a 3-question scripted setup via `AskUserQuestion` and writes the file. All questions are skippable; skipping writes commented defaults (marks the project as set up, prevents the setup from re-firing). Re-run explicitly any time with `/flow-config`.
