# flow v3 — folder outline (draft for iteration)

Three zones. Each owns a different lifetime.

```text
1. flow-runtime repo (this repo, slimmed to the kernel)
2. ~/.flow/                      personal state — cells as git repos, active-cell pointer
3. ~/.claude/                    Claude Code discovery root — symlinks into (2)
```

## 1. flow-runtime repo (the kernel)

What ships when someone installs flow. No stage skills — those come from cells.

```text
flow-runtime/
├── Makefile                      # USER-FACING. All cell mgmt verbs (see § Make targets).
├── README.md                     # How install works + the empty-shell concept.
├── .claude-plugin/               # plugin manifest (kept).
├── commands/                     # slash commands that talk to the kernel only
│   ├── flow.md
│   ├── flow-config.md
│   ├── flow-adopt.md
│   ├── flow-reflect.md
│   ├── flow-spike.md
│   └── flow-cell.md              # NEW. Thin wrapper over `make cell-*`.
├── skills/
│   ├── flow/                     # kernel: stage detection, boundary protocol,
│   │   ├── SKILL.md              #   AskUserQuestion contract, thread
│   │   ├── references/           #   convention, glossary, doc protocol.
│   │   │   ├── protocol.md       # KERNEL — the document schema. Every cell uses it.
│   │   │   ├── boundaries.md     # KERNEL — the 4-beat boundary handling.
│   │   │   ├── stage-detection.md# KERNEL — but now data-driven on cell manifest.
│   │   │   ├── user-interaction.md
│   │   │   ├── glossary.md
│   │   │   └── reflection.md
│   │   └── scripts/
│   │       ├── detect-stage.sh   # walks the active cell's manifest, no hardcoded names.
│   │       ├── load-config.sh
│   │       └── threads-summary.sh
│   ├── flow-config/              # owns .flow/config.sh in *target projects* (still useful)
│   ├── flow-adopt/
│   ├── flow-reflect/
│   ├── flow-spike/
│   ├── teach/                    # kernel: writes/edits skills *inside the active cell*.
│   └── docs-style/               # kernel: house style for any markdown.
├── cells/                        # BUNDLED STARTERS shipped with the kernel.
│   └── code-pipeline/            # The current 5-stage pipeline, now a starter template.
│       ├── cell.yaml             # manifest (see below)
│       ├── README.md
│       ├── skills/               # explore, plan, implement, review, ship, tdd, commits, parallel
│       └── templates/            # spec.md, etc.
├── scripts/                      # cell-mgmt internals called by Makefile
│   ├── cell-init.sh              # copy starter → ~/.flow/cells/<name>/, git init
│   ├── cell-link.sh              # symlink cell/skills/* → ~/.claude/skills/
│   ├── cell-unlink.sh
│   ├── cell-use.sh               # switch active cell
│   ├── cell-status.sh
│   ├── cell-branch.sh            # cut a branch in cell repo for an edit
│   └── cell-pr.sh                # open PR (gh if remote, else stage + remind)
└── tools/
    └── Cell.mk                   # imported by every cell's own Makefile (see zone 2)
```

**Why this shape**

- Kernel is content-free. It defines *how* a pipeline runs (detection, doc protocol, boundaries) but never *which* stages exist.
- `cells/code-pipeline/` is a starter, not the live pipeline. `make cell-init code-pipeline` clones it out into the user's own personal git repo (zone 2). The bundled copy never gets edited.
- `teach` continues to exist but it now writes into the *active cell*, not into the runtime repo. Same with reflect.

## 2. `~/.flow/` (personal state)

User's territory. Each cell is its own git repo (local-only at first; user wires up a remote when they want one).

```text
~/.flow/
├── cells/
│   ├── code-pipeline/            # the user's personal copy of the code-pipeline starter
│   │   ├── .git/                 # local-only initially; `make cell-link-remote <url>` adds origin
│   │   ├── cell.yaml             # the cell's identity (see below)
│   │   ├── Makefile              # imports ../../tools/Cell.mk for status/pr/branch
│   │   ├── skills/               # explore, plan, implement, review, ship, tdd, commits, parallel
│   │   └── templates/
│   └── <future-cell-name>/       # additional cells the user creates (e.g. writing-pipeline)
├── active-cell                   # symlink → cells/<name>/   — the one currently in use
├── tools/
│   └── Cell.mk                   # shared make targets every cell inherits
└── state/
    ├── cell-history.log          # which cell was active when, for /reflect
    └── last-sync.json            # per-cell: last commit SHA observed (for stale-check warnings)
```

**cell.yaml** (the manifest that data-drives stage detection)

```yaml
name: code-pipeline
version: 0.1.0
description: Idea → spec → plan → implement → review → PR
stages:
  - name: explore
    skill: explore
    output: 01-spec
    next: plan
  - name: plan
    skill: plan
    input: 01-spec
    output: 02-plan
    next: implement
  - name: implement
    skill: implement
    input: 02-plan
    output: branch         # special: detection looks at git diff, not a file
    next: review
  - name: review
    skill: review
    input: branch
    output: 03-review
    next: ship
  - name: ship
    skill: ship
    input: 03-review
    output: pr             # special: detection looks for an open PR
ship_target: github-pr     # plug-point — other cells could use slack-post / notion-page / blog-publish
templates_dir: templates
doc_protocol: kernel       # "kernel" = use flow-runtime's protocol.md. "custom" = use this cell's.
```

`detect-stage.sh` reads `cell.yaml` from `~/.flow/active-cell/` and walks `stages[]`. The current 6-rule ladder becomes a generic loop: for each stage, does its `output` exist for the current branch's thread? Stop at the first missing one.

## 3. `~/.claude/` (Claude Code discovery)

Pure symlinks. Two layers — kernel skills are real installs, cell skills are symlinks into zone 2.

```text
~/.claude/
├── skills/
│   ├── flow/             ← real install from flow-runtime repo
│   ├── flow-config/      ← real
│   ├── flow-adopt/       ← real
│   ├── flow-reflect/     ← real
│   ├── flow-spike/       ← real
│   ├── teach/            ← real
│   ├── docs-style/       ← real
│   ├── explore     →  ~/.flow/active-cell/skills/explore       (symlink)
│   ├── plan        →  ~/.flow/active-cell/skills/plan          (symlink)
│   ├── implement   →  ~/.flow/active-cell/skills/implement     (symlink)
│   ├── review      →  ~/.flow/active-cell/skills/review        (symlink)
│   ├── ship        →  ~/.flow/active-cell/skills/ship          (symlink)
│   ├── tdd         →  ~/.flow/active-cell/skills/tdd           (symlink)
│   ├── commits     →  ~/.flow/active-cell/skills/commits       (symlink)
│   └── parallel    →  ~/.flow/active-cell/skills/parallel      (symlink)
└── commands/
    └── flow*.md          ← real
```

Switching cells is one `cell-use.sh` call: unlink the old cell's symlinks, walk the new cell's `skills/` directory and link each into `~/.claude/skills/<name>`.

## Make targets (user-facing)

```text
make                        # help
make install                # install kernel into ~/.claude/ (one-time after clone)
make doctor                 # sanity: kernel installed? active-cell set? symlinks resolve? git OK?

# Cell lifecycle
make cell-list              # all cells in ~/.flow/cells/, marks the active one
make cell-init STARTER=code-pipeline  NAME=my-code
                            # copies starter from flow-runtime/cells/ into ~/.flow/cells/<NAME>/,
                            # runs `git init`, makes initial commit on `main`
make cell-new NAME=writing-pipeline
                            # empty cell scaffold (just cell.yaml + skills/ + templates/)
make cell-use NAME=my-code  # switch active cell — re-symlink ~/.claude/skills/
make cell-rm NAME=…         # delete cell (confirms first; preserves git history)

# Per-cell git operations (operate on the active cell by default; CELL= overrides)
make cell-status            # git status of active cell
make cell-link-remote URL=… # adds `origin` to the active cell's git
make cell-pull / cell-push
make cell-branch NAME=…     # create branch for an edit (used by teach/reflect)
make cell-pr                # open PR via gh if remote configured; else `git format-patch` + reminder
```

Two non-obvious ones:

- **cell-pr**: enforces the never-commit-to-main rule. teach and reflect always edit on a branch via `cell-branch`; when work is done, `cell-pr` opens a PR. With no remote, it stages the patch and tells the user how to apply once they wire up `origin`.
- **doctor**: the missing-state recovery tool. Catches "active-cell symlink is dangling," "cell repo is dirty mid-PR," "kernel skill drift," etc.

## Where flow-runtime gets its hands dirty

| Action | Who triggers | What happens |
|---|---|---|
| `/flow` boundary completes | flow kernel | reads active cell's manifest, dispatches to next stage's skill via symlinked path |
| `teach` writes a new skill | user invocation | `cell-branch` cuts a branch in active cell, writes file, prompts to commit, then `cell-pr` |
| `/reflect` proposes change | user invocation | same: branch in active cell, edit, PR |
| `make cell-use foo` | user via make | unlink old cell symlinks, link new ones, update `~/.flow/active-cell` |

Everything that mutates skills goes through `cell-branch` → edit → `cell-pr`. There is no path that commits directly to a cell's `main`.

## Open questions for the next iteration

1. **Branch in target project vs. branch in cell** — the user is in project `myapp/` running `/flow`. teach edits a skill, which creates a branch in `~/.flow/cells/code-pipeline/`. That's a *different* git repo than the project. Is the mental model clear, or do we need a UI signal (e.g. `cell-pr` always prints "this PR is in your code-pipeline repo, not myapp")?
2. **Multiple cells active at once** — explicitly out of scope for v3? Or do we want `make cell-stack` to layer two cells (e.g. code-pipeline + a `security-review-stage` cell)? My read: out of scope. Confirm.
3. **`cell.yaml` ownership** — is the manifest part of the kernel's contract (kernel reads it, stage skills don't care) or do stage skills also read it (e.g. ship reading `ship_target`)? Clean answer: kernel-only; ship is just whatever skill the manifest names.
4. **Empty-shell first run** — `/flow` with no active cell: what does it do? Three options: (a) refuse and print `make cell-init`, (b) auto-init `code-pipeline` as the personal cell on first run, (c) AskUserQuestion which starter to init from. (b) is the lowest-friction; (c) is the most discoverable.
5. **Doc protocol pluggability** — `cell.yaml` has `doc_protocol: kernel | custom`. Is that worth shipping in v3, or YAGNI until someone has a real need to deviate from the kernel protocol?
6. **Where the bundled starter lives** — inside `flow-runtime/cells/code-pipeline/` (one repo, simpler) or in its own GitHub repo (`jyliang/flow-cell-code`, more honest about it being "just another cell")? I lean toward the former for v3 since you said no community contribution yet.

