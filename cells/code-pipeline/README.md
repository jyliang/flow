# code-pipeline

The starter cell. Idea → spec → plan → implement → review → PR.

## Stages

| Stage | Skill | Handoff |
|---|---|---|
| explore | `explore` | `01-spec-r<N>.md` |
| plan | `plan` | `02-plan-r<N>.md` |
| implement | `implement` | git branch |
| review | `review` | `03-review-r<N>.md` |
| ship | `ship` | GitHub PR (recorded as `pr:` in spec frontmatter) |

## Delivery

`github-pr` — the ship stage opens a draft PR and records the PR number in the spec frontmatter.

## Support skills

- `tdd` — test-driven discipline during implement.
- `commits` — atomic commits during implement and ship.
- `parallel` — parallel-subagent guidelines during explore and review.

## Lifecycle

This cell is your personal git repo. After `make cell-init STARTER=code-pipeline`, it lives at `~/.flow/cells/code-pipeline/` with a fresh `git init` and no remote.

- **Revisions** to handoffs (inside threads) happen in your project repos, never here.
- **Evolutions** to the skills here happen via `/reflect` — branch + commit + PR opened by `cell-pr`.

Wire to a remote when you want sync across machines:

```bash
make cell-link-remote URL=git@github.com:you/your-cell.git
```
