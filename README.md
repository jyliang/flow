# Flow

A learning runtime for Claude Code. Three primitives — `ingest`, `run`, `reflect` — turn any pipeline of skills into something a human can inspect and that gets better the more you use it.

Flow ships empty. You install a **cell** (a git repo of skills defining one pipeline) and start running it. As you ship work, `reflect` proposes edits to your cell via PR. The cell is yours to evolve.

## Onboarding

### 1. Install

**End users — marketplace install (recommended):**

```bash
claude plugin marketplace add jyliang/flow
claude plugin install flow@flow
```

Slash commands appear under the `/flow:` namespace (`/flow:flow`, `/flow:teach`, etc.). The kernel itself ships **no Claude Code skills** — its three primitives (`run`, `ingest`, `reflect`) are docs at `kernel/<name>/<name>.md` that the slash commands `Read` on demand. This keeps the picker clean and routes every invocation through a `/flow:*` entry.

**Local development:** clone this repo and run `make install`. Hooks into the `flow` marketplace registration with the install location pointed at the live repo, then registers + enables the `flow@flow` plugin so edits flow through without re-installing. Same `/flow:` namespace as the marketplace install.

Verify either install with: `make doctor`.

### 2. First `/flow:flow`

In any project:

```text
/flow:flow
```

Flow has no cell installed, so it offers to set up the starter (`code-pipeline`: explore → plan → implement → review → ship). Pick **Yes**.

That installs a git repo at `~/.flow/cells/code-pipeline/` and registers it as the `code-pipeline@flow` plugin. Stage docs live under `stages/<name>/<name>.md` inside the cell — they are not surfaced as skills; the kernel reads them on demand when `/flow:flow` runs. `/flow:flow` is ready.

### 3. Start a thread

Tell flow what you want to build. It cuts a branch, opens a thread folder, and walks you through it stage by stage.

```text
/flow:flow add a /standup command that summarizes my git activity
```

You'll see the first handoff (a spec) and a Yes / Adjust / Pause prompt. Edit the spec, or move on.

### 4. Through the stages

Each stage emits a handoff document — spec, plan, findings — readable and editable. At every boundary flow asks:

- **Yes, advance** — go to the next stage.
- **Adjust** — edit the handoff first.
- **Pause** — stop here; resume with `/flow:flow` later.

### 5. Ship

The last stage opens a PR. Flow records the PR number in the thread's spec and exits.

Review the PR like any other PR.

### 6. Evolve a skill

After you ship something:

```text
/flow:reflect
```

Flow scans the thread for patterns — repeated suggestions you accepted, things you pushed back on twice — and proposes edits to the skills that ran. You see the diffs and pick which to accept. Flow opens a PR against your cell repo with the accepted edits.

This is how the cell matures. Over time, explore learns your codebase quirks, plan learns your style, review learns what you actually care about.

### 7. Wire your cell to a remote

The cell repo is local until you give it a home:

```bash
make cell-link-remote URL=git@github.com:you/your-cell.git
```

Once linked, evolutions push on PR merge. Pull from any machine and have the same matured cell.

## The model

Three layers:

| Layer | What it is |
|---|---|
| **Kernel** | Three primitives that don't change: `ingest` (turn input into a skill), `run` (orchestrate a cell execution with the human in the loop at every boundary), `reflect` (propose evolutions after a thread). They live as docs at `kernel/<name>/<name>.md` and are Read by the `/flow:*` commands — not surfaced as Claude Code skills. |
| **Cell** | A git repo containing the stage docs for one pipeline. The starter cell `code-pipeline` ships with the kernel; `/flow` first-run installs it as a personal git repo at `~/.flow/cells/code-pipeline/`. |
| **Thread** | One piece of work, 1:1 with a git branch. Each stage emits a handoff document that the human inspects and the next stage consumes. |

## Vocabulary

| Term | Meaning |
|---|---|
| **Cell** | A git repo of skills that defines one pipeline (e.g. code → PR, idea → blog post). |
| **Stage** | One step in a pipeline (e.g. explore, plan, implement). |
| **Thread** | One piece of work. 1:1 with a git branch and a folder under `agent/threads/<date>-<branch>/`. |
| **Handoff** | The markdown document a stage emits. Two readers: the human and the next stage's agent. |
| **Boundary** | The moment between stages. Always passes through the human via `AskUserQuestion`. |
| **Revision** | A re-thought handoff inside one thread (`-r2`, `-r3`). |
| **Evolution** | A matured skill at the cell level (a PR against your cell repo). |
| **Delivery** | What the pipeline produces (PR, blog post, slack message). |

## Slash commands

All commands are namespaced under the `flow` plugin.

| Command | Reads | What it does |
|---|---|---|
| `/flow:flow` | `kernel/run/run.md` | Start or continue a thread. |
| `/flow:teach` | `kernel/ingest/ingest.md` | Decompose input (a conversation, doc, codebase walk) into a new or updated skill. |
| `/flow:reflect` | `kernel/reflect/reflect.md` | After threads ship, propose cell evolutions. |
| `/flow:spike` | `kernel/run/run.md` + cell's spike doc | Run a thread end-to-end unattended; opens a draft PR. |
| `/flow:here` | `kernel/run/run.md` (with seed) | Distill the current conversation into a thread spec. |
| `/flow:cell` | — | Cell management (list, switch, init, link remote, open PR). |

## Make targets

| Target | Purpose |
|---|---|
| `make install` | Install kernel as the `flow@flow` plugin (under the `flow` marketplace pointed at this repo), provision `~/.flow/`. Dev mode. |
| `make doctor` | Sanity check the install. |
| `make list` | Show kernel docs + slash commands. |
| `make cell-init STARTER=code-pipeline NAME=<name>` | Clone a starter into `~/.flow/cells/<name>/`. |
| `make cell-new NAME=<name>` | Empty cell scaffold. |
| `make cell-list` | Show installed cells, mark the active one. |
| `make cell-use NAME=<name>` | Switch active cell (re-registers as `<name>@flow` plugin). |
| `make cell-status` | Git status of the active cell. |
| `make cell-link-remote URL=...` | Add origin to the active cell. |
| `make cell-branch BRANCH=...` | Cut an evolution branch in the active cell. |
| `make cell-pr TITLE=... BODY=...` | Open a PR for current cell edits. |
| `make cell-pull` / `make cell-push` | Sync the cell with its remote. |
| `make lint-docs` | Markdown style lint across runtime + cells. |

## Philosophy

Two principles, not negotiable:

**Inspectable.** Every artifact is markdown a human can read. Every boundary is `AskUserQuestion`. Nothing happens silently.

**Evolvable.** Skills aren't fixed. Cells aren't fixed. The system improves through use, and the mechanism for that improvement is first-class — same git/PR workflow you use for code.

Three biological analogies for how the kernel primitives work:

- **`ingest` = digestion.** Raw input is broken into reusable nutrients (skills) and the residue is dropped. The system stores the extracted parts, not the meal.
- **`run` = foraging.** A trained repertoire is executed in a real environment, with online feedback (the human at each boundary).
- **`reflect` = affinity maturation.** After exposure, the underlying instructions are edited to produce better-bound variants. The next run uses the matured cell.

## Layout

```text
flow-runtime/
├── Makefile                          # User-facing CLI for kernel + cells
├── README.md                         # This file
├── .claude-plugin/plugin.json        # Plugin manifest — name: flow
├── commands/                         # Kernel slash commands (auto-namespaced as /flow:*)
│   ├── flow.md                       # /flow:flow → run
│   ├── teach.md                      # /flow:teach → ingest
│   ├── reflect.md                    # /flow:reflect → reflect
│   ├── spike.md                      # /flow:spike → autonomous run
│   ├── here.md                       # /flow:here → seed a thread from conversation
│   └── cell.md                       # /flow:cell → cell management
├── kernel/                           # Kernel docs — read by /flow:* commands; NOT skills
│   ├── run/run.md
│   ├── ingest/ingest.md
│   └── reflect/reflect.md
├── cells/                            # Bundled starter cells
│   └── code-pipeline/
│       ├── cell.yaml                 # Manifest
│       ├── stages/<name>/<name>.md   # Stage docs (internal — read by kernel)
│       ├── disciplines/<name>.md     # Cross-cutting docs (internal)
│       └── templates/                # Cell-specific templates
├── scripts/                          # Cell-mgmt internals (called by Makefile)
└── tools/Cell.mk                     # Imported by each cell's own Makefile
```

After `make install`:

```text
~/.flow/
├── cells/<name>/                     # Each cell as its own git repo (and plugin)
├── active-cell -> cells/<active>/    # Symlink
├── runtime-path                      # Where this runtime lives
├── tools/Cell.mk                     # Copy of the runtime's Cell.mk
└── state/                            # Patches, history, telemetry

~/.claude/plugins/installed_plugins.json
   ├── flow@flow              → /path/to/this/repo            (kernel)
   └── <cell-name>@flow       → ~/.flow/cells/<cell-name>     (active cell)

~/.claude/plugins/marketplaces/flow -> /path/to/this/repo     # symlink, dev mode
~/.claude/settings.json
   └── enabledPlugins: { flow@flow: true, <cell>@flow: true }  # written by make install
```

Only the `/flow:*` slash commands appear in the picker. Kernel primitives (`kernel/<name>/<name>.md`) and cell stage/discipline docs deliberately live outside `skills/` so they don't show up — the slash commands `Read` them on demand. End-user marketplace installs produce the same layout — `make install` is dev-mode only.

## Reflection

After a few shipped threads, `/flow:reflect` scans them for patterns worth acting on — "same suggestion appeared across three reviews", "decision repeatedly deferred" — and proposes concrete edits. Every proposal goes through `AskUserQuestion`; on Yes, the change auto-lands as a PR against the active cell repo. Nothing lands silently.

Separately, the ship stage fires a **"twice is a pattern"** scan at the end of every PR: if the LLM stated the same non-obvious fact about the project twice this session without it being in `CLAUDE.md`, you'll get a prompt to persist. See `kernel/reflect/reflect.md`.
