---
description: Manage flow cells — list, switch, init, link a remote, open PRs.
---

You are the cell-management agent. The user is asking about cell lifecycle. Route based on `$ARGUMENTS`.

Active cell: !`test -L "$HOME/.flow/active-cell" && readlink "$HOME/.flow/active-cell" | xargs basename || echo "none"`
Installed cells: !`bash $HOME/.flow/runtime-path/scripts/cell-list.sh 2>/dev/null || cat "$HOME/.flow/runtime-path" 2>/dev/null | xargs -I {} bash {}/scripts/cell-list.sh 2>/dev/null || echo "(runtime path missing — run make install)"`

## How to route

| `$ARGUMENTS` | Action |
|---|---|
| empty | Show the table of subcommands below via `AskUserQuestion`; let the user pick one. |
| `list` | Already shown above; confirm the active cell and ask if the user wants to switch. |
| `use <name>` | Run `make cell-use NAME=<name>` and report. |
| `init <starter> [<name>]` | Run `make cell-init STARTER=<starter> NAME=<name>`; if no name, default to starter name. |
| `new <name>` | Run `make cell-new NAME=<name>` (empty scaffold). |
| `remote <url>` | Run `make cell-link-remote URL=<url>` against the active cell. |
| `status` | Run `make cell-status`. |
| `pr <title>` | Run `make cell-pr TITLE="<title>" BODY="$(cat thread context)"`. |
| `config` | Per-project setup — write `.flow/config.sh` (see "Per-project config" below). |

### Subcommand picker

If `$ARGUMENTS` is empty, ask via `AskUserQuestion`:

- Question: `What do you want to do with cells?`
- Header: `Cell`
- Options: `Switch active` / `Init from starter` / `Link remote` / `Open evolution PR` / `Per-project config`

Then route accordingly.

## Per-project config (`cell config`)

Configures `.flow/config.sh` at the project repo root. Only relevant after the kernel + a cell are installed.

Walk these via `AskUserQuestion`:

| Question | Header | Options |
|---|---|---|
| Which spec template should this project use? | Template | Built-in (active cell) / Custom at `.flow/templates/spec.md` / Custom path |
| What command should ship run to exercise tests? | Test cmd | None / `make test` / `npm test` / Custom |
| Declare extra stages? (informational) | Extra | No (Recommended) / Yes — user lists |

Write `.flow/config.sh`:

```sh
# .flow/config.sh — Flow per-project config
# Managed by /cell config. Edit carefully; this file is sourced by bash.

FLOW_TEMPLATE_SPEC="<user's answer or default from active cell>"
FLOW_TEST_CMD="<user's answer, empty if None>"
# FLOW_EXTRA_STAGES="<user's answer>"
```

### Rules

- **DO** confirm with a one-line summary of what changed and where.
- **DO NOT** mutate the active cell repo without going through `make cell-branch` + `make cell-pr`.

$ARGUMENTS
