# Flow — design notes

Working notes on how the pipeline-builder is put together. The product thesis lives in [`docs/founding.html`](docs/founding.html); the user-facing story in [`docs/manual.html`](docs/manual.html). This file is the implementer's view.

## The shape in one breath

A flow is a linear chain of **(skill, doc-type)** pairs. The `flow` CLI assembles a chain and compiles it into two plugin commands — `<name>-spike` and `<name>-step`. Those two commands are the only artifacts; there is no separate source file. Running a command writes a numbered trail of checkpoint documents you can read, edit, and resume from.

The CLI is deterministic and never calls an LLM. Only the generated commands drive skills (and thus the model).

## Three zones, three lifetimes

| Zone | Holds | Lifetime |
|---|---|---|
| **This repo (the plugin)** | `bin/flow` (CLI), `doc-types/` (catalog), `templates/` (run protocols), `commands/` (generated flows) | versioned product, except `commands/` which is git-ignored and user-owned |
| **`~/.claude/`** | the `flow@flow` plugin registration; chainable skills under `~/.claude/skills/` | per-machine |
| **project `.flow/runs/`** | checkpoint trails: `<flow>/<timestamp>/NN-<doc-type>.md` | per-run, lives with the work |

Because `bin/flow` lives inside the plugin, `$FLOW_ROOT/commands/` *is* the plugin's command directory — a generated file there surfaces as `/flow:<name>-<mode>` with no extra wiring.

## The compile step

`flow new` (interactive or `--name`/`--step`) produces each command from three inputs:

1. **The protocol** — `templates/protocol-<mode>.md`, with `{{FLOW}}` substituted. Spike runs end-to-end and keeps a spike log; step pauses at every checkpoint with Yes / Adjust / Pause.
2. **The chain** — a `## The chain` table, plus a machine-readable `<!-- FLOW-SPEC -->` block. The FLOW-SPEC is how `flow list` / `edit` recover a flow's definition from its command (there is no source file to read).
3. **The doc-type contracts** — for each bound doc-type, the frontmatter contract and the `## Template` block are inlined verbatim from `doc-types/<name>.md`, so the command is self-contained at runtime. Spike commands always inline `spike-log`.

## Key decisions

- **No source file.** The two commands are the flow. `flow edit` parses the FLOW-SPEC back out and regenerates — editing the flow, never the output.
- **`/flow:` namespace.** Generated commands are real plugin commands (`commands/<name>-<mode>.md`), matching the manual. The cost: each flow adds files to the installed plugin dir; a plugin update could clear them, and the dir must be writable.
- **Catalog inlined, not referenced.** A doc-type change after generation is invisible until you `flow edit`. That's the price of self-contained commands — and the regenerate path is one command.
- **Skill discovery.** `~/.claude/skills/` then `./.claude/skills/`, the same resolution Claude Code uses. Cross-tool discovery (Cursor, Cline) is deferred.
- **Resume is deterministic.** `flow resume` validates the run, writes a `.resume` marker, and prints the invocation; the actual resume happens when the generated command runs and honors the marker — keeping the CLI LLM-free.

## Open threads

- Marketplace installs put the plugin in a clone that `claude plugin update` may overwrite; generated commands there are not yet protected.
- `flow edit`'s interactive prefill currently shows the chain and offers a full rebuild rather than per-step editing.
- HTML doc-types are supported in the catalog (`format: html`) but none ship yet beyond the docs themselves.
