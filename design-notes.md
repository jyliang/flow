# flow v3 — folder outline (draft for iteration)

Three zones. Each owns a different lifetime.

```text
1. flow-runtime repo (this repo, slimmed to the kernel)
2. ~/.flow/                      personal state — packs as git repos, active-pack pointer
3. ~/.claude/                    Claude Code discovery root — symlinks into (2)
```

## 1. flow-runtime repo (the kernel)

What ships when someone installs flow. No stage skills — those come from packs.

```text
flow-runtime/
├── Makefile                      # USER-FACING. All pack mgmt verbs (see § Make targets).
├── README.md                     # How install works + the empty-shell concept.
├── .claude-plugin/               # plugin manifest (kept).
├── commands/                     # slash commands that talk to the kernel only
│   ├── flow.md
│   ├── flow-config.md
│   ├── flow-adopt.md
│   ├── flow-reflect.md
│   ├── flow-spike.md
│   └── flow-pack.md              # NEW. Thin wrapper over `make pack-*`.
├── skills/
│   ├── flow/                     # kernel: stage detection, boundary protocol,
│   │   ├── SKILL.md              #   AskUserQuestion contract, workstream
│   │   ├── references/           #   convention, glossary, doc protocol.
│   │   │   ├── protocol.md       # KERNEL — the document schema. Every pack uses it.
│   │   │   ├── boundaries.md     # KERNEL — the 4-beat boundary handling.
│   │   │   ├── stage-detection.md# KERNEL — but now data-driven on pack manifest.
│   │   │   ├── user-interaction.md
│   │   │   ├── glossary.md
│   │   │   └── reflection.md
│   │   └── scripts/
│   │       ├── detect-stage.sh   # walks the active pack's manifest, no hardcoded names.
│   │       ├── load-config.sh
│   │       └── workstreams-summary.sh
│   ├── flow-config/              # owns .flow/config.sh in *target projects* (still useful)
│   ├── flow-adopt/
│   ├── flow-reflect/
│   ├── flow-spike/
│   ├── teach/                    # kernel: writes/edits skills *inside the active pack*.
│   └── docs-style/               # kernel: house style for any markdown.
├── packs/                        # BUNDLED STARTERS shipped with the kernel.
│   └── code-pipeline/            # The current 5-stage pipeline, now a starter template.
│       ├── pack.yaml             # manifest (see below)
│       ├── README.md
│       ├── skills/               # explore, plan, implement, review, ship, tdd, commits, parallel
│       └── templates/            # spec.md, etc.
├── scripts/                      # pack-mgmt internals called by Makefile
│   ├── pack-init.sh              # copy starter → ~/.flow/packs/<name>/, git init
│   ├── pack-link.sh              # symlink pack/skills/* → ~/.claude/skills/
│   ├── pack-unlink.sh
│   ├── pack-use.sh               # switch active pack
│   ├── pack-status.sh
│   ├── pack-branch.sh            # cut a branch in pack repo for an edit
│   └── pack-pr.sh                # open PR (gh if remote, else stage + remind)
└── tools/
    └── Pack.mk                   # imported by every pack's own Makefile (see zone 2)
```

**Why this shape**

- Kernel is content-free. It defines *how* a pipeline runs (detection, doc protocol, boundaries) but never *which* stages exist.
- `packs/code-pipeline/` is a starter, not the live pipeline. `make pack-init code-pipeline` clones it out into the user's own personal git repo (zone 2). The bundled copy never gets edited.
- `teach` continues to exist but it now writes into the *active pack*, not into the runtime repo. Same with reflect.

## 2. `~/.flow/` (personal state)

User's territory. Each pack is its own git repo (local-only at first; user wires up a remote when they want one).

```text
~/.flow/
├── packs/
│   ├── code-pipeline/            # the user's personal copy of the code-pipeline starter
│   │   ├── .git/                 # local-only initially; `make pack-link-remote <url>` adds origin
│   │   ├── pack.yaml             # the pack's identity (see below)
│   │   ├── Makefile              # imports ../../tools/Pack.mk for status/pr/branch
│   │   ├── skills/               # explore, plan, implement, review, ship, tdd, commits, parallel
│   │   └── templates/
│   └── <future-pack-name>/       # additional packs the user creates (e.g. writing-pipeline)
├── active-pack                   # symlink → packs/<name>/   — the one currently in use
├── tools/
│   └── Pack.mk                   # shared make targets every pack inherits
└── state/
    ├── pack-history.log          # which pack was active when, for /flow-reflect
    └── last-sync.json            # per-pack: last commit SHA observed (for stale-check warnings)
```

**pack.yaml** (the manifest that data-drives stage detection)

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
ship_target: github-pr     # plug-point — other packs could use slack-post / notion-page / blog-publish
templates_dir: templates
doc_protocol: kernel       # "kernel" = use flow-runtime's protocol.md. "custom" = use this pack's.
```

`detect-stage.sh` reads `pack.yaml` from `~/.flow/active-pack/` and walks `stages[]`. The current 6-rule ladder becomes a generic loop: for each stage, does its `output` exist for the current branch's workstream? Stop at the first missing one.

## 3. `~/.claude/` (Claude Code discovery)

Pure symlinks. Two layers — kernel skills are real installs, pack skills are symlinks into zone 2.

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
│   ├── explore     →  ~/.flow/active-pack/skills/explore       (symlink)
│   ├── plan        →  ~/.flow/active-pack/skills/plan          (symlink)
│   ├── implement   →  ~/.flow/active-pack/skills/implement     (symlink)
│   ├── review      →  ~/.flow/active-pack/skills/review        (symlink)
│   ├── ship        →  ~/.flow/active-pack/skills/ship          (symlink)
│   ├── tdd         →  ~/.flow/active-pack/skills/tdd           (symlink)
│   ├── commits     →  ~/.flow/active-pack/skills/commits       (symlink)
│   └── parallel    →  ~/.flow/active-pack/skills/parallel      (symlink)
└── commands/
    └── flow*.md          ← real
```

Switching packs is one `pack-use.sh` call: unlink the old pack's symlinks, walk the new pack's `skills/` directory and link each into `~/.claude/skills/<name>`.

## Make targets (user-facing)

```text
make                        # help
make install                # install kernel into ~/.claude/ (one-time after clone)
make doctor                 # sanity: kernel installed? active-pack set? symlinks resolve? git OK?

# Pack lifecycle
make pack-list              # all packs in ~/.flow/packs/, marks the active one
make pack-init STARTER=code-pipeline  NAME=my-code
                            # copies starter from flow-runtime/packs/ into ~/.flow/packs/<NAME>/,
                            # runs `git init`, makes initial commit on `main`
make pack-new NAME=writing-pipeline
                            # empty pack scaffold (just pack.yaml + skills/ + templates/)
make pack-use NAME=my-code  # switch active pack — re-symlink ~/.claude/skills/
make pack-rm NAME=…         # delete pack (confirms first; preserves git history)

# Per-pack git operations (operate on the active pack by default; PACK= overrides)
make pack-status            # git status of active pack
make pack-link-remote URL=… # adds `origin` to the active pack's git
make pack-pull / pack-push
make pack-branch NAME=…     # create branch for an edit (used by teach/reflect)
make pack-pr                # open PR via gh if remote configured; else `git format-patch` + reminder
```

Two non-obvious ones:

- **pack-pr**: enforces the never-commit-to-main rule. teach and reflect always edit on a branch via `pack-branch`; when work is done, `pack-pr` opens a PR. With no remote, it stages the patch and tells the user how to apply once they wire up `origin`.
- **doctor**: the missing-state recovery tool. Catches "active-pack symlink is dangling," "pack repo is dirty mid-PR," "kernel skill drift," etc.

## Where flow-runtime gets its hands dirty

| Action | Who triggers | What happens |
|---|---|---|
| `/flow` boundary completes | flow kernel | reads active pack's manifest, dispatches to next stage's skill via symlinked path |
| `teach` writes a new skill | user invocation | `pack-branch` cuts a branch in active pack, writes file, prompts to commit, then `pack-pr` |
| `/flow-reflect` proposes change | user invocation | same: branch in active pack, edit, PR |
| `make pack-use foo` | user via make | unlink old pack symlinks, link new ones, update `~/.flow/active-pack` |

Everything that mutates skills goes through `pack-branch` → edit → `pack-pr`. There is no path that commits directly to a pack's `main`.

## Open questions for the next iteration

1. **Branch in target project vs. branch in pack** — the user is in project `myapp/` running `/flow`. teach edits a skill, which creates a branch in `~/.flow/packs/code-pipeline/`. That's a *different* git repo than the project. Is the mental model clear, or do we need a UI signal (e.g. `pack-pr` always prints "this PR is in your code-pipeline repo, not myapp")?
2. **Multiple packs active at once** — explicitly out of scope for v3? Or do we want `make pack-stack` to layer two packs (e.g. code-pipeline + a `security-review-stage` pack)? My read: out of scope. Confirm.
3. **`pack.yaml` ownership** — is the manifest part of the kernel's contract (kernel reads it, stage skills don't care) or do stage skills also read it (e.g. ship reading `ship_target`)? Clean answer: kernel-only; ship is just whatever skill the manifest names.
4. **Empty-shell first run** — `/flow` with no active pack: what does it do? Three options: (a) refuse and print `make pack-init`, (b) auto-init `code-pipeline` as the personal pack on first run, (c) AskUserQuestion which starter to init from. (b) is the lowest-friction; (c) is the most discoverable.
5. **Doc protocol pluggability** — `pack.yaml` has `doc_protocol: kernel | custom`. Is that worth shipping in v3, or YAGNI until someone has a real need to deviate from the kernel protocol?
6. **Where the bundled starter lives** — inside `flow-runtime/packs/code-pipeline/` (one repo, simpler) or in its own GitHub repo (`jyliang/flow-pack-code`, more honest about it being "just another pack")? I lean toward the former for v3 since you said no community contribution yet.

