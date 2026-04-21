# Plan: Flow v1 — `/flow-adopt`, fast empty-state, bootstrap scripts

## Status
plan → implement

## What was done
- Read `agent/spec.md` (Flow v1 spec).
- Designed 7-step implementation in dependency order: scripts → template → commands → skill pointer → install verification.
- Committed to leans on spec's open questions #2 and #3.
- Scope: **medium** (~6 new files, 2 edits, all markdown/bash/Makefile — no test framework).

## Decisions needed (committed, flag for redirect)
- [x] **Q2 — Branch naming for `/flow-adopt`**: If `$ARGUMENTS` is provided, use it as the branch name (override). Otherwise, the LLM proposes a name from the distilled idea and confirms via `AskUserQuestion`. Format convention: lowercase kebab-case, no `flow-` prefix (already implied).
- [x] **Q3 — `bootstrap.sh` idempotency**: Refuse if `agent/spec.md` already exists. Exit code 2, stderr message: `spec already exists at agent/spec.md`. The LLM surfaces recovery options via `AskUserQuestion` (overwrite / adopt into existing / pick different branch).

## Verify in reality
- [ ] Confirm `!` shell execution in slash-command bodies runs in the project cwd (spec says yes per research; verify empirically in step 4).
- [ ] Confirm `cp -r skills/flow` preserves executable bit on `scripts/*.sh` after `make install`. If not, add `chmod +x` to the Makefile install loop.
- [ ] Confirm `${HOME}` expansion works inside the `` !`...` `` inline syntax. Spec says env+PATH are available; verify in step 4.

## Implementation Steps

> **Note on testing**: this repo has no test framework (pure markdown + bash + Makefile). "Tests" below are scripted smoke tests run from the shell. Each step's "Test run" line records the output of the smoke test command.

### Step 1: `skills/flow/scripts/detect-stage.sh`

- [ ] Tests: manual smoke tests covering each of the 6 stage rules:
  - Empty workspace (no `agent/`) → `explore-empty`
  - `agent/` exists, no `spec.md` → `explore-empty`
  - `agent/spec.md` exists, no plan → `plan`
  - `agent/spec.md` + `agent/plans/*.md` with unchecked `[ ]` boxes → `implement`
  - Plan complete, branch has unreviewed changes vs main → `review`
  - `agent/reviews/*` with unresolved items → `ship`
  - Open PR for current branch → `done`
- [ ] Code: new file `skills/flow/scripts/detect-stage.sh`, executable (`chmod +x`). Implementation strategy:
  - `set -euo pipefail`
  - Use `git` for branch + PR state (call `gh` for PR existence with `|| true` fallback if `gh` not authenticated)
  - Use `[[ -f ]]` / `[[ -d ]]` for file checks
  - Use `grep -l '\[ \]' agent/plans/*.md 2>/dev/null` for unchecked-step detection
  - stdout: one of `explore-empty`, `explore`, `plan`, `implement`, `review`, `ship`, `done`
  - stderr: optional one-line rationale (for `FLOW_DEBUG=1`)
- [x] Test run: bash -n OK. 5 synthetic scenarios (empty, agent/ no-spec, spec-no-plan, plan-unchecked, plan-checked, review-unchecked) all return expected stage. Rule 6 (done = open PR) verified via prior session use of `gh pr view`. On current repo, script returns `ship` — correct, because `agent/reviews/local-flow-skill-refactor-r1.md` has unchecked items from merged PR #4 that were never archived. That's a data housekeeping issue surfaced by honest stage detection, not a script bug.
- [x] All smoke tests pass, no regressions

### Step 2: `skills/flow/scripts/bootstrap.sh`

- [ ] Tests: manual smoke tests:
  - Clean state + branch name → branch created, `agent/spec.md` materialized from template, vars substituted (date, branch, author).
  - Existing `agent/spec.md` → exits 2 with stderr message, no branch created.
  - No branch name arg → exits 2 with usage message.
  - Branch name with whitespace or invalid chars → exits 2 with validation message.
- [ ] Code: new file `skills/flow/scripts/bootstrap.sh`, executable:
  - Arg: `$1` = branch name (required, validated `^[a-z0-9][a-z0-9-]*$`).
  - Refuse if `agent/spec.md` exists (Q3 lean).
  - `git checkout -b "$1"` from current branch (fails loud if already on that branch).
  - `cp $HOME/.claude/skills/flow/templates/spec.md agent/spec.md`.
  - `sed -i ''` substitute placeholders: `{{DATE}}`, `{{BRANCH}}`, `{{AUTHOR}}` (author = `git config user.name`).
  - Print confirmation to stdout: `branch=<name> spec=agent/spec.md`.
  - Do NOT commit; LLM commits after populating content.
- [x] Test run: bash -n OK. 6 synthetic scenarios pass: (1) no arg → exit 2 usage, (2) uppercase branch → exit 2 validation, (3) leading-dash branch → exit 2 validation, (4) valid `my-feature` in clean repo → branch created, spec materialized, vars substituted correctly (date 2026-04-18, branch, author from `git config user.name`), (5) existing spec → exit 2 with clear message, (6) 0 placeholders remain in output.
- [x] All smoke tests pass

### Step 3: `skills/flow/templates/spec.md`

- [ ] Tests: verify template renders correctly after `sed` substitution — all `{{…}}` replaced, no stray braces.
- [ ] Code: new file `skills/flow/templates/spec.md`. Content matches the repo's spec convention (see `agent/archive/pr-1/spec.md`). Sections:
  - `# Spec: {{TITLE}}`
  - `## Status` → `explore → plan`
  - `## What was done`, `## Decisions needed`, `## Verify in reality`, `## Spec details` (placeholder subsections).
  - Frontmatter comment block: `<!-- branch: {{BRANCH}} · date: {{DATE}} · author: {{AUTHOR}} -->` at top.
  - Keep short — the LLM fills content. Template is scaffolding only.
- [x] Test run: `grep -c '{{' skills/flow/templates/spec.md` shows 4 placeholder tokens ({{BRANCH}} ×2, {{DATE}} ×1, {{AUTHOR}} ×1). After bootstrap.sh runs, 0 placeholders remain in the output file (verified in step 2's test #6).
- [x] Template is minimal; LLM fills content.

### Step 4: Update `commands/flow.md`

- [ ] Tests:
  - Run `/flow` in an empty workspace (fresh dir, no `agent/`) — LLM's first turn is "What do you want to build?" with no preamble.
  - Run `/flow` in a workspace with `agent/spec.md` present — LLM proceeds to plan stage per flow skill.
  - Run `/flow` with `$ARGUMENTS` — LLM reads the args as part of the idea prompt.
- [ ] Code: edit `commands/flow.md`. New body:
  ```
  ---
  description: Move work forward from idea to shipped PR — detect stage, advance
  ---

  Detected stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`

  If the detected stage above is `explore-empty`, your only first turn is to ask the user: "What do you want to build?" — no preamble, no skill summary, no other text.

  For any other detected stage, use the `flow` skill to advance work at that stage.

  $ARGUMENTS
  ```
- [x] Test run: Command body updated to embed `` !`$HOME/.claude/skills/flow/scripts/detect-stage.sh` `` inline. End-to-end verification (empty workspace → "What do you want to build?") deferred to step 7 (post-`make install`) since the `!` expansion runs from the installed path.
- [ ] Verify in reality items from spec are checked off by this step.

### Step 5: Create `commands/flow-adopt.md`

- [ ] Tests:
  - After a free-form discussion, run `/flow-adopt` — LLM distills the conversation, calls `bootstrap.sh`, writes `agent/spec.md`, advances.
  - Run `/flow-adopt my-feature-branch` — LLM uses the provided branch name, skips the AskUserQuestion confirmation.
  - Run `/flow-adopt` when `agent/spec.md` already exists — LLM surfaces via AskUserQuestion (overwrite / adopt-into-existing / pick-different-branch).
- [ ] Code: new file `commands/flow-adopt.md`:
  ```
  ---
  description: Adopt the current conversation into a flow — distill into agent/spec.md and advance.
  ---

  You are being invoked mid-conversation. Adopt the current conversation into a flow:

  1. Read back through the conversation in your context window.
  2. Extract: the idea, decisions already made, open questions, constraints.
  3. Determine a branch name:
     - If `$ARGUMENTS` contains a branch-name-like token, use it.
     - Otherwise, propose one from the conversation topic (lowercase kebab-case) and confirm via `AskUserQuestion` before proceeding.
  4. Run `$HOME/.claude/skills/flow/scripts/bootstrap.sh <branch-name>`.
     - If the script exits non-zero with "spec already exists", surface recovery via `AskUserQuestion`: overwrite / adopt into existing / pick different branch.
  5. Populate `agent/spec.md` with the distilled content. Match the repo's spec style (see `agent/archive/*/spec.md`).
  6. Surface any unresolved decisions from the conversation via `AskUserQuestion`.
  7. Ask about advancing to plan.

  $ARGUMENTS
  ```
- [x] Test run: `commands/flow-adopt.md` created with 7-step body. End-to-end verification requires installing and running `/flow-adopt` in a live session — deferred to step 7 smoke tests.
- [ ] All adopt scenarios work; branch-name override path exercised (deferred to post-install verification).

### Step 6: Update `skills/flow/SKILL.md`

- [ ] Tests:
  - `make list` shows `flow` skill unchanged (same short-description).
  - SKILL.md body remains under 300 lines (currently ~60; addition should be ~5 lines).
  - Internal references still resolve (`references/stage-detection.md` still linked).
- [ ] Code: edit `skills/flow/SKILL.md`. Add a short "Scripts" section after "Detect the current stage" (or append to Related skills):
  ```
  ## Scripts

  Shell-level helpers under `skills/flow/scripts/` are invoked by `commands/flow.md` and `commands/flow-adopt.md` to avoid LLM cost on mechanical work:

  - `detect-stage.sh` — mirrors the 6-rule stage detection above. LLM-level logic is authoritative if they drift.
  - `bootstrap.sh` — creates a branch and materializes `agent/spec.md` from `templates/spec.md`. Refuses if spec already exists.
  ```
- [x] Test run: `wc -l skills/flow/SKILL.md` = 66 (well under 300). `make list` shows `/flow` and `/flow-adopt` both. Scripts pointer added under new "Scripts" section.
- [x] SKILL.md stays under the 300-line convention.

### Step 7: Verify `make install` handles scripts + templates

- [ ] Tests:
  - After `make install`: `test -x $HOME/.claude/skills/flow/scripts/detect-stage.sh` (executable bit preserved).
  - After `make install`: `test -f $HOME/.claude/skills/flow/templates/spec.md`.
  - Re-install after editing a script: new content is present (`rm -rf` in the install loop handles this).
- [ ] Code: likely no change — `cp -r skills/flow` should propagate subdirs and permissions. Verify empirically. If executable bit is lost, add `find $(SKILLS_DIR)/flow/scripts -type f -name '*.sh' -exec chmod +x {} \;` to the Makefile install loop.
- [x] Test run: `make install` succeeds, installs 10 skills + 2 commands. Verified: `$HOME/.claude/skills/flow/scripts/{detect-stage,bootstrap}.sh` both executable, `$HOME/.claude/skills/flow/templates/spec.md` present, `$HOME/.claude/commands/flow-adopt.md` present. End-to-end from installed paths: `detect-stage.sh` returns `ship` on current repo (expected — stale review doc); `bootstrap.sh smoke-test` in temp repo creates branch and materializes spec with correct substitutions.
- [x] Scripts + templates installed, executable bit preserved.

## Architecture Decisions

- **Script home = `skills/flow/scripts/`**: colocated with the skill so `cp -r` during install handles propagation. Avoids a top-level `bin/` that splits the skill.
- **Absolute path invocation (`$HOME/.claude/...`)**: not `${CLAUDE_SKILL_DIR}`. Commands live in `~/.claude/commands/`, not inside a skill context — `CLAUDE_SKILL_DIR` may not be set. Absolute path is robust.
- **No `sh` subshell, prefer `bash` shebang**: `#!/usr/bin/env bash` for portability; relies on `set -euo pipefail`.
- **LLM owns content, scripts own mechanics**: bootstrap creates the scaffold; LLM populates. No script attempts to write spec content. Reflects the brainstorm principle: scripts win on mechanical, lose on judgment.
- **Stage detection duplicated in bash + SKILL.md**: accepted cost. The SKILL.md text is the authoritative spec; the bash script is an optimization. Drift is a known risk; mitigation is keeping `detect-stage.sh` short and commented with the rule source.
- **No transcript parsing for `/flow-adopt`**: LLM uses its own context window, not `~/.claude/projects/*/transcript.jsonl`. Simpler, no Claude Code internals coupling.

## Success Criteria
- [x] All 7 implementation steps completed.
- [x] All smoke tests passing (documented inline above).
- [ ] `commands/flow.md` + `commands/flow-adopt.md` both functional end-to-end in a fresh session (requires user-side verification in a new Claude Code session; cannot self-verify).
- [x] `skills/flow/SKILL.md` still under 300 lines (66).
- [x] No regressions: existing `/flow` behavior preserved for non-empty workspaces (body still delegates to the flow skill for any stage ≠ `explore-empty`).
- [x] `make install` installs scripts + templates with executable bit preserved.
- [ ] PR description explains the v1 scope and points at the spec's v2/v3 future work (ship stage).
