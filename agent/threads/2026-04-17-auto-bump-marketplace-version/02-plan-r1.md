# Plan: Auto-bump marketplace.json version on every merge

## Status
plan → implement

## What was done
- Designed 3-step implementation approach
- Identified the spec's prior-art YAML sketch as the starting pattern; adapted it for loop-protection and for `GITHUB_TOKEN` use
- Estimated scope: small — 2 files total (one edit, one new)

## Decisions needed
(None — all 5 spec decisions resolved: commit-count semver, post-merge CI, single channel, every-merge scope, one-time 0.1.1 bump.)

## Verify in reality
- [ ] After merging this PR, confirm the `Bump marketplace version` workflow run succeeds in Actions and produces a follow-up bot commit on `main` with version `0.1.<N>` where N = commit count after merge.
- [ ] Confirm the bot commit does NOT re-trigger the workflow (paths-ignore working as intended).
- [ ] On a throwaway client, run `/plugin install flow@flow` against the pre-fix state (or reset), then after this PR merges run `/plugin update flow` and confirm it pulls the HEAD commit of `main`.
- [ ] If branch protection on `main` is configured to require PR review, confirm `GITHUB_TOKEN` is allowed to push directly. If not, swap to a PAT stored as a repo secret (`RELEASE_PAT`).

## Testing caveat

This repo has no test suite. "Test" for each step means: run the exact shell command the workflow will run, against the current working tree, and confirm the resulting JSON is valid and contains the expected version. YAML validity is checked by eyeball + `yq` if available.

## Implementation Steps

### Step 1: One-time bump `.claude-plugin/marketplace.json` → `0.1.1`

Unsticks clients that installed from `8fecd36` or `98df12d` (both on `0.1.0`) so they immediately pull `c3cabee` + this PR on `/plugin update`.

- [x] Tests (pre): `jq '.metadata.version' .claude-plugin/marketplace.json` returned `"0.1.0"`.
- [x] Code: changed `metadata.version` from `"0.1.0"` to `"0.1.1"` in `.claude-plugin/marketplace.json`. No other edits.
- [x] Test run: `jq '.metadata.version'` returns `"0.1.1"`; `jq -e .` exits 0 (valid JSON); `git diff` shows only the `version` line changed.
- [x] All checks green, no regressions.

### Step 2: Create `.github/workflows/bump-marketplace-version.yml`

Post-merge workflow that computes `0.1.<commit_count>`, edits `marketplace.json`, and pushes the bump commit back to `main`.

- [x] Tests (pre): `.github/` did not exist; created `.github/workflows/`.
- [x] Code: created `.github/workflows/bump-marketplace-version.yml` with:
  - `on: push: branches: [main]` + `paths-ignore: ['.claude-plugin/marketplace.json']` (loop protection)
  - `permissions: contents: write`
  - One job `bump` on `ubuntu-latest` with 4 named steps: Checkout, Compute new version, Update marketplace.json, Commit and push.
- [x] Test run:
  - `python3 -c "import yaml; yaml.safe_load(open(...))"` → `YAML valid`, `jobs: ['bump']`, steps: `['Checkout', 'Compute new version', 'Update marketplace.json', 'Commit and push']`.
  - Structural parity with the spec sketch plus the declarative `paths-ignore` loop-protection.
- [x] All checks green, no regressions.

### Step 3: Local dry-run of the bump logic

Run the exact shell the workflow will run, against the current working tree, to catch `jq` / path / quoting bugs before CI.

- [x] Tests (pre): Step 1 applied (`.metadata.version == "0.1.1"`), Step 2 file present.
- [x] Code: No file changes. Ran the workflow's jq command against a scratch copy of `marketplace.json`.
- [x] Test run:
  - `count = 5` (current `git rev-list --count HEAD`).
  - `jq '.metadata.version' /tmp/mp.json` → `"0.1.5"` — matches `0.1.<count>`.
  - `diff` shows only `"version": "0.1.1"` → `"version": "0.1.5"` (no reformatting, no other keys mutated).
  - `jq -e . /tmp/mp.json` exit 0 (valid JSON).
  - Scratch file cleaned up.
- [x] All checks green, no regressions.

## Architecture Decisions

- **Loop protection via `paths-ignore`, not `[skip ci]` alone**: `paths-ignore: ['.claude-plugin/marketplace.json']` at the workflow level is declarative and robust — the workflow simply never fires on commits that only touch the bumped file. `[skip ci]` in the commit message is included as defense-in-depth but is not load-bearing.
- **Count on `HEAD`, not on `main` branch name**: `git rev-list --count HEAD` works in the checked-out state regardless of how the ref is named in the runner environment. Post-merge `HEAD == main` so the values are equivalent today.
- **`GITHUB_TOKEN` over PAT**: avoid the PAT-management burden. If branch protection later requires PR review on `main`, the Verify step will catch it and we'll swap to a PAT then — not speculatively now.
- **No `CONTRIBUTING.md` note** (spec marked optional): the workflow name is self-documenting. If hand-edits to `metadata.version` become a problem, add a note then.
- **Commit-count includes bot commits**: after each PR, the version advances by ~2 (merge + bump). Still monotonic; acceptable trade-off for zero author effort.
- **Single workflow, single job**: no script extraction (`scripts/bump-marketplace-version.sh`) — the logic is ~10 lines, extracting adds indirection without reducing duplication.

## Success Criteria
- [ ] All 3 implementation steps completed
- [ ] `.claude-plugin/marketplace.json` at `0.1.1`
- [ ] `.github/workflows/bump-marketplace-version.yml` present and valid YAML
- [ ] Dry-run produces expected `0.1.<count>` with no other mutations
- [ ] Follows existing codebase patterns (matches the spec's prior-art sketch with loop-protection additions)
- [ ] No sensitive data exposed
