# Flow

A learning runtime for Claude Code. Three primitives — `ingest`, `run`, `reflect` — turn any pipeline of skills into something a human can inspect and that gets better the more you use it.

Flow ships empty. You install a **pack** (a git repo of skills defining one pipeline) and start running it. As you ship work, `reflect` proposes edits to your pack via PR. The pack is yours to evolve.

## Onboarding

### 1. Install

Clone this repo, then:

```bash
make install
```

Installs into `~/.claude/` and `~/.flow/`.

Verify: `make doctor`.

### 2. First `/flow`

In any project:

```text
/flow
```

Flow has no skills installed, so it offers to set up the starter (`code-pipeline`: explore → plan → implement → review → ship). Pick **Yes**.

That installs a git repo at `~/.flow/packs/code-pipeline/` and links its skills into Claude Code. `/flow` is ready.

### 3. Start a thread

Tell flow what you want to build. It cuts a branch, opens a thread folder, and walks you through it stage by stage.

```text
/flow add a /standup command that summarizes my git activity
```

You'll see the first handoff (a spec) and a Yes / Adjust / Pause prompt. Edit the spec, or move on.

### 4. Through the stages

Each stage emits a handoff document — spec, plan, findings — readable and editable. At every boundary flow asks:

- **Yes, advance** — go to the next stage.
- **Adjust** — edit the handoff first.
- **Pause** — stop here; resume with `/flow` later.

### 5. Ship

The last stage opens a PR. Flow records the PR number in the thread's spec and exits.

Review the PR like any other PR.

### 6. Evolve a skill

After you ship something:

```text
/reflect
```

Flow scans the thread for patterns — repeated suggestions you accepted, things you pushed back on twice — and proposes edits to the skills that ran. You see the diffs and pick which to accept. Flow opens a PR against your pack repo with the accepted edits.

This is how the pack matures. Over time, explore learns your codebase quirks, plan learns your style, review learns what you actually care about.

### 7. Wire your pack to a remote

The pack repo is local until you give it a home:

```bash
make pack-link-remote URL=git@github.com:you/your-pack.git
```

Once linked, evolutions push on PR merge. Pull from any machine and have the same matured pack.

## The model

Three layers:

| Layer | What it is |
|---|---|
| **Kernel** | Three skills that don't change: `ingest` (turn input into a skill), `run` (orchestrate a pack execution with the human in the loop at every boundary), `reflect` (propose evolutions after a thread). |
| **Pack** | A git repo containing the stage skills for one pipeline. The starter pack `code-pipeline` ships with the kernel; `/flow` first-run installs it as a personal git repo at `~/.flow/packs/code-pipeline/`. |
| **Thread** | One piece of work, 1:1 with a git branch. Each stage emits a handoff document that the human inspects and the next stage consumes. |

## Vocabulary

| Term | Meaning |
|---|---|
| **Pack** | A git repo of skills that defines one pipeline (e.g. code → PR, idea → blog post). |
| **Stage** | One step in a pipeline (e.g. explore, plan, implement). |
| **Thread** | One piece of work. 1:1 with a git branch and a folder under `agent/threads/<date>-<branch>/`. |
| **Handoff** | The markdown document a stage emits. Two readers: the human and the next stage's agent. |
| **Boundary** | The moment between stages. Always passes through the human via `AskUserQuestion`. |
| **Revision** | A re-thought handoff inside one thread (`-r2`, `-r3`). |
| **Evolution** | A matured skill at the pack level (a PR against your pack repo). |
| **Delivery** | What the pipeline produces (PR, blog post, slack message). |

## Slash commands

| Command | Calls | What it does |
|---|---|---|
| `/flow` | `run` | Start or continue a thread. |
| `/teach` | `ingest` | Decompose input (a conversation, doc, codebase walk) into a new or updated skill. |
| `/reflect` | `reflect` | After threads ship, propose pack evolutions. |
| `/spike` | `run` (autonomous) | Run a thread end-to-end unattended; opens a draft PR. |
| `/adopt` | `run` (with seed) | Distill the current conversation into a thread spec. |
| `/pack` | — | Pack management (list, switch, init, link remote, open PR). |

## Make targets

| Target | Purpose |
|---|---|
| `make install` | Install kernel into `~/.claude/`, provision `~/.flow/`. |
| `make doctor` | Sanity check the install. |
| `make list` | Show installed kernel skills + slash commands. |
| `make pack-init STARTER=code-pipeline NAME=<name>` | Clone a starter into `~/.flow/packs/<name>/`. |
| `make pack-new NAME=<name>` | Empty pack scaffold. |
| `make pack-list` | Show installed packs, mark the active one. |
| `make pack-use NAME=<name>` | Switch active pack (re-symlinks). |
| `make pack-status` | Git status of the active pack. |
| `make pack-link-remote URL=...` | Add origin to the active pack. |
| `make pack-branch BRANCH=...` | Cut an evolution branch in the active pack. |
| `make pack-pr TITLE=... BODY=...` | Open a PR for current pack edits. |
| `make pack-pull` / `make pack-push` | Sync the pack with its remote. |
| `make lint-docs` | Markdown style lint across runtime + packs. |

## Philosophy

Two principles, not negotiable:

**Inspectable.** Every artifact is markdown a human can read. Every boundary is `AskUserQuestion`. Nothing happens silently.

**Evolvable.** Skills aren't fixed. Packs aren't fixed. The system improves through use, and the mechanism for that improvement is first-class — same git/PR workflow you use for code.

Three biological analogies for how the kernel primitives work:

- **`ingest` = digestion.** Raw input is broken into reusable nutrients (skills) and the residue is dropped. The system stores the extracted parts, not the meal.
- **`run` = foraging.** A trained repertoire is executed in a real environment, with online feedback (the human at each boundary).
- **`reflect` = affinity maturation.** After exposure, the underlying instructions are edited to produce better-bound variants. The next run uses the matured pack.

## Layout

```text
flow-runtime/
├── Makefile                          # User-facing CLI for kernel + packs
├── README.md                         # This file
├── commands/                         # Kernel slash commands
│   ├── flow.md                       # /flow → run
│   ├── teach.md                      # /teach → ingest
│   ├── reflect.md                    # /reflect → reflect
│   ├── spike.md                      # /spike → autonomous run
│   ├── adopt.md                      # /adopt → seed a thread from conversation
│   └── pack.md                       # /pack → pack management
├── skills/                           # Kernel skills (don't change between packs)
│   ├── run/
│   ├── ingest/
│   └── reflect/
├── packs/                            # Bundled starter packs
│   └── code-pipeline/
│       ├── pack.yaml                 # Manifest
│       ├── skills/                   # Stage skills
│       └── templates/                # Pack-specific templates
├── scripts/                          # Pack-mgmt internals (called by Makefile)
└── tools/Pack.mk                     # Imported by each pack's own Makefile
```

After `make install`:

```text
~/.flow/
├── packs/<name>/                     # Each pack as its own git repo
├── active-pack -> packs/<active>/    # Symlink
├── runtime-path                      # Where this runtime lives
├── tools/Pack.mk                     # Copy of the runtime's Pack.mk
└── state/                            # Patches, history, telemetry

~/.claude/
├── skills/                           # Symlinks to kernel + active pack skills
└── commands/                         # Symlinks to kernel slash commands
```

## Install (alternatives)

Flow also ships as a `skills.sh`-compatible skill pack for non-Claude-Code agents, but the kernel/pack model is Claude Code-first. See the older v2 install instructions if you need a different agent.

## Reflection

After a few shipped threads, `/reflect` scans them for patterns worth acting on — "same suggestion appeared across three reviews", "decision repeatedly deferred" — and proposes concrete edits. Every proposal goes through `AskUserQuestion`; on Yes, the change auto-lands as a PR against the active pack repo. Nothing lands silently.

Separately, the ship stage fires a **"twice is a pattern"** scan at the end of every PR: if the LLM stated the same non-obvious fact about the project twice this session without it being in `CLAUDE.md`, you'll get a prompt to persist. See `skills/reflect/SKILL.md`.
