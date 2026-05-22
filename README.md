# Flow

A pipeline-builder for AI work. You assemble a chain of skills; every step leaves behind **a document a human can actually read** — and resume from.

Git was for code. Flow is for the docs your agents leave behind.

A flow is a chain of **(skill, doc-type)** pairs. The skill does the work; the doc-type is the document it hands to the next step. Every document is a checkpoint you can read, edit, and resume from. Flow ships the construction kit and a catalog of doc-types — not one fixed pipeline. You build your own.

> Companion reads: [the Conviction Doc](docs/founding.html) and [the Manual](docs/manual.html).

## Install

Flow is a shell CLI (`bin/flow`) plus a doc-type catalog. It never invokes an LLM — only the skills it generates do.

```bash
git clone https://github.com/jyliang/flow && cd flow
make install      # registers the flow plugin + puts the `flow` CLI on PATH
```

`make install` does two things: registers this repo as the `flow@flow` Claude Code plugin (so generated flows appear under `/flow:`), and symlinks `bin/flow` into the first writable bin dir on your `PATH` (preferring `~/.local/bin`). Verify with `make doctor`.

Each flow you build compiles into two command files in the plugin's `commands/` dir, so Claude Code surfaces them as `/flow:<name>-spike` and `/flow:<name>-step`.

### Where Flow finds your skills

When you build a flow, Flow discovers chainable skills from two places — global first, then project-local:

```text
~/.claude/skills/      # global — shared across every project
./.claude/skills/      # project-local — checked into the repo
```

A skill is any directory containing a `SKILL.md`. Cross-tool discovery (Cursor, Cline, and friends) is deferred — Flow reads Claude skills today.

## Core concepts

Six words run everything.

| Term | Meaning |
|---|---|
| **flow** | A linear chain of steps you assemble and run. No branches mid-flow — fork by starting a new run from a checkpoint. |
| **step** | One **(skill, doc-type)** pair. The skill produces; the doc-type captures. |
| **skill** | An external capability — a Claude Code skill. Flow orchestrates skills; it never edits or rates them. |
| **doc-type** | A template plus frontmatter describing a kind of document — markdown or HTML. Purely descriptive, nothing to execute. |
| **checkpoint** | The document a step emits. Every checkpoint is a resume point — that's the whole mechanic. |
| **spike / step** | The two ways to run a flow. Trust vs. review. The only toggle. |

## Build a flow

There's no config file to hand-write. `flow new` is an interactive wizard, and the two skills it generates are the only artifacts.

```bash
flow new
```

1. **Name the flow** — short, kebab-case: `build-feature`, `triage-bug`, `write-rfc`.
2. **Pick skills, in order** — Flow lists what it found; choose them in run order. Linear only.
3. **Bind a doc-type to each** — for every skill, choose the document it leaves behind, from the catalog. You decide the pairing; Flow never infers it.

It compiles the chain into two plugin commands:

```text
/flow:build-feature-spike   # run end-to-end
/flow:build-feature-step    # pause at every document
```

The generated commands carry a "do not edit" header and a machine-readable copy of the chain. To change a flow, run `flow edit <name>` — it recovers the chain and regenerates both commands. Don't hand-edit the output.

You can also build non-interactively:

```bash
flow new --name build-feature \
  --step explore::spec --step plan::plan --step review::findings --yes
```

## Run it — spike & step

The same flow, two temperaments. Invoke the generated command in Claude Code:

```text
/flow:build-feature-spike    # run it all at once
/flow:build-feature-step     # walk it doc by doc
```

- **Spike** runs end-to-end, never pauses, and writes a spike log of what it did. Reach for it when you trust the flow and want a draft fast.
- **Step** pauses at every checkpoint with **Yes / Adjust / Pause** — edit the document, advance, or stop and resume later. Reach for it when the work needs your judgment in the loop.

## Checkpoints & resuming

Every run writes a numbered trail of documents under the project's `.flow/runs/`. The trail *is* the state — nothing is hidden, nothing is binary.

```text
.flow/runs/build-feature/
  2026-05-20T14-30/
    01-spec.md
    02-plan.md
    03-findings.md          ← edit me, then resume
```

Open any file, change it, then pick up where you left off — or rewind:

```bash
flow resume build-feature/2026-05-20T14-30 --from 03
```

To explore an alternative, edit a checkpoint and resume from it — that's a fork. No branch syntax, no DAG: a new run captures the new path while the original trail stays intact.

## The doc-type catalog

Flow ships a bootstrap set of doc-types — the documents a senior engineer or PM already recognizes. See [`doc-types/`](doc-types/).

| Doc-type | Purpose |
|---|---|
| `spec` | Intent before planning — the *what* and *why*, never the how. |
| `plan` | The ordered, checkable steps that turn a spec into work. |
| `findings` | What a review surfaced — issues, risks, what passed. |
| `decision-record` | Why we chose X over Y, captured at the moment of choosing. |
| `spike-log` | What was tried and learned on an end-to-end run. |
| `change-summary` | What shipped — ready to drop into a PR description. |

## Authoring doc-types

A doc-type is just a file: frontmatter declaring what the document is for, then a template body. No DSL, no execution semantics.

```markdown
---
name: spec
purpose: capture intent before planning — what + why, not how
audience: human reviewer, downstream plan skill
shape: scope / decisions / design / constraints / verification / open
lifecycle: append-only; supersedes prior specs
format: markdown            # or html for human-facing, visually-rich docs
maturity: stable
---
[template body in a single ~~~markdown fence, then a worked example]
```

Drop a new `<name>.md` (or `.html`) into `doc-types/`; it joins the catalog the next time you run `flow new`. The CLI extracts the `## Template` block verbatim and inlines the doc-type's contract into the skills it generates. See [`doc-types/README.md`](doc-types/README.md) for the field reference.

## Command reference

| Command | What it does |
|---|---|
| `flow new` | Interactive wizard: name the flow, pick skills in order, bind a doc-type to each. Generates the spike + step skills. |
| `flow list` | Show every flow you've defined (`--doc-types` lists the catalog instead). |
| `flow edit <name>` | Recover the chain and regenerate both skills. |
| `flow rm <name>` | Delete a flow and its generated skills. |
| `flow resume <run> --from <NN>` | Mark a run to resume from checkpoint `NN`. Edit the doc first to fork. |
| `/flow:<name>-spike` | Run the flow end-to-end, no pauses. Emits a spike log. |
| `/flow:<name>-step` | Run the flow pausing at every doc for review, edit, or abort. |

## Layout

```text
flow/
├── bin/flow              # the CLI — assembles flows, generates commands
├── commands/             # generated flow commands land here (the /flow: namespace)
├── doc-types/            # the catalog (one file per doc-type) + README
├── templates/            # protocol-spike.md, protocol-step.md (embedded into commands)
├── scripts/              # install.sh, doctor.sh
├── docs/                 # founding.html (conviction doc), manual.html
└── Makefile              # install · uninstall · doctor · list · lint-docs
```

Generated commands live in the plugin's `commands/` dir as `<name>-spike.md` / `<name>-step.md` (git-ignored — they're yours, not the product). Run checkpoints live in each project's `.flow/runs/`.

## Philosophy

Every step a document. Every document a resume point. Flow doesn't host the model, judge the output, or improve your skills — those belong to you and your agents. Flow's one job is knowing what kind of document belongs between skill A and skill B, and making every handoff a human-readable artifact instead of opaque agent state.
