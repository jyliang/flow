# code-pipeline

The starter cell. Idea → spec → plan → implement → review → PR.

## Stages

| Stage | Doc | Handoff |
|---|---|---|
| explore | `stages/explore/explore.md` | `01-spec-r<N>.md` |
| plan | `stages/plan/plan.md` | `02-plan-r<N>.md` |
| implement | `stages/implement/implement.md` | git branch |
| review | `stages/review/review.md` | `03-review-r<N>.md` |
| ship | `stages/ship/ship.md` | GitHub PR (recorded as `pr:` in spec frontmatter) |

Stage docs are **not** Claude Code skills — the kernel `Read`s them on demand when `/flow:flow` runs, driven by `cell.yaml`'s `path:` field. This keeps stages out of the picker so they only run via `/flow:*` commands and cannot be auto-invoked out of context.

`stages/spike/spike.md` is the spike-mode variant, driven by `/flow:spike` and read by it directly.

## Delivery

`github-pr` — the ship stage opens a draft PR and records the PR number in the spec frontmatter.

## Disciplines

Cross-cutting docs at `disciplines/<name>.md`. Stage docs reference them; the kernel doesn't trigger them itself.

- `disciplines/tdd.md` — test-driven discipline during implement.
- `disciplines/commits.md` — atomic commits during implement and ship.
- `disciplines/parallel.md` — parallel-subagent guidelines during explore and review.

## Lifecycle

This cell is your personal git repo. After `make cell-init STARTER=code-pipeline`, it lives at `~/.flow/cells/code-pipeline/` with a fresh `git init` and no remote.

- **Revisions** to handoffs (inside threads) happen in your project repos, never here.
- **Evolutions** to the docs here happen via `/flow:reflect` — branch + commit + PR opened by `cell-pr`.

Wire to a remote when you want sync across machines:

```bash
make cell-link-remote URL=git@github.com:you/your-cell.git
```
