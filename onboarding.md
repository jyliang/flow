# Flow onboarding

## 1. Install

Clone this repo, then:

```bash
make install
```

Installs into `~/.claude/` and `~/.flow/`.

Verify: `make doctor`.

## 2. First `/flow`

In any project:

```
/flow
```

Flow has no skills installed, so it offers to set up the starter (`code-pipeline`: explore → plan → implement → review → ship). Pick **Yes**.

That installs a git repo at `~/.flow/cells/code-pipeline/` and links its skills into Claude Code. `/flow` is ready.

## 3. Start a thread

Tell flow what you want to build. It cuts a branch, opens a thread folder, and walks you through it stage by stage.

```
/flow add a /standup command that summarizes my git activity
```

You'll see the first handoff (a spec) and a Yes / Adjust / Pause prompt. Edit the spec, or move on.

## 4. Through the stages

Each stage emits a handoff document — spec, plan, findings — readable and editable. At every boundary flow asks:

- **Yes, advance** — go to the next stage
- **Adjust** — edit the handoff first
- **Pause** — stop here; resume with `/flow` later

## 5. Ship

The last stage opens a PR. Flow records the PR number in the thread's spec and exits.

Review the PR like any other PR.

## 6. Evolve a skill

After you ship something:

```
/reflect
```

Flow scans the thread for patterns — repeated suggestions you accepted, things you pushed back on twice — and proposes edits to the skills that ran. You see the diffs and pick which to accept. Flow opens a PR against your cell repo with the accepted edits.

This is how the cell matures. Over time, explore learns your codebase quirks, plan learns your style, review learns what you actually care about.

## 7. Wire your cell to a remote

The cell repo is local until you give it a home:

```bash
make cell-link-remote URL=git@github.com:you/your-cell.git
```

Once linked, evolutions push on PR merge. Pull from any machine and have the same matured cell.
