# mini-todo

**What this task evaluates:** Greenfield code-pipeline behaviour on a small, fully specified task. The prompt is intentionally tight (commands, storage, std-lib-only) so divergences in flow's output reflect the cell's behaviour, not prompt ambiguity. We're watching for:

- **Spec stage** — does it pin the JSON schema and the failure-mode behaviour (missing id, malformed file) the prompt left implicit, or does it just restate the prompt?
- **Plan stage** — does it propose a sensible single-file layout, or invent unnecessary structure (`src/`, modules, classes for a 100-line tool)?
- **Implement stage** — is the code tight (target: <150 LOC), does it handle the obvious edge cases (file doesn't exist yet, bad id), and does it stop there?
- **Review stage** — does it actually find anything, or rubber-stamp?
- **Scope discipline** — does flow stay in scope, or does it add config files, GitHub Actions, type hints when prompt didn't ask?

## Prompt

See `prompt.md`. Pass that to `/flow:flow` verbatim.

## Project location

Run flow against `~/Workspace/jyliang/mini-todo` (a fresh empty repo, scaffolded once and reused across runs — each run cuts its own branch). If that path doesn't exist, see "First-time setup" below.

## How to run a fresh run

1. Reset the project to a clean main:
   ```
   cd ~/Workspace/jyliang/mini-todo
   git checkout main && git reset --hard <initial-commit-sha>
   ```
   (Initial-commit SHA: see `notes` at the bottom of this file once it's been initialized.)
2. Open a Claude Code session in that directory and run `/flow:flow` with the prompt from `prompt.md`.
3. Walk flow through its stages, answering boundary prompts as a real user would. Note rough cost + duration if you can.
4. From the flow repo:
   ```
   make eval-record TASK=mini-todo PROJECT=~/Workspace/jyliang/mini-todo COST=<usd> DURATION=<sec>
   ```
5. Review:
   ```
   make eval-review TASK=mini-todo RUN=<run-id>
   ```

## What's a good outcome?

- Final diff is one Python file (~100–150 LOC) plus a short README.
- All four commands work; `--file` flag is honoured; missing-id is handled cleanly.
- Spec doc captures: data shape, what happens on missing/malformed file, behaviour when id doesn't exist.
- Plan doc proposes the single-file layout without inventing structure.
- No type hints, no test framework, no CI — those weren't asked for.
- Total flow run cost: under $2; duration: under 15 minutes.

## First-time setup

```
mkdir -p ~/Workspace/jyliang/mini-todo
cd ~/Workspace/jyliang/mini-todo
git init -b main
echo "# mini-todo" > README.md
git add README.md && git commit -m "init"
```

Then record that initial commit's SHA in the **Notes** section below so future runs can reset to it.

## Notes

- **Initial commit SHA** (reset target): `9f05045` (`9f050453dc9081213a1adc1baa1dcae6db7d3dbb`)
- _(running history across runs — what's improving, what's still a problem, goes here.)_
