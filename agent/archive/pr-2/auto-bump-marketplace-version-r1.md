# Findings: Auto-bump marketplace.json version on every merge

## Status
review → ship

## What was done
- Reviewed commit `c7a08ce` on branch `auto-bump-marketplace-version` against `agent/spec.md` + `agent/plans/IMPLEMENTATION_PLAN_2026-04-17.md`
- Read all 4 changed files in full; walked the workflow end-to-end for the two audiences (CI runner + downstream `/plugin update` client)
- Found **0 critical, 2 suggestions, 2 nits**. No spec/plan drift.

## How It Works (end-to-end)

**Goal** (from commit msg + spec): every merge to `main` produces a new `metadata.version` string in `.claude-plugin/marketplace.json` so downstream `/plugin update flow` clients see something new and pull HEAD.

**Audiences:**
1. **GitHub Actions runner on `push:main`** — ubuntu-latest, `contents: write` token.
2. **A Claude Code user running `/plugin update flow`** — compares local cached version against the remote `marketplace.json`.

**Trace for audience 1** (post-merge):
1. Author's merge commit lands on `main`.
2. `push` event fires. `paths-ignore: ['.claude-plugin/marketplace.json']` passes because the merge commit changed files outside that path.
3. Job checks out main with full history (`fetch-depth: 0`) → `GITHUB_TOKEN` persisted as git credential.
4. `git rev-list --count HEAD` → integer N. Sets `new_version=0.1.N`.
5. `jq '.metadata.version = $v' > tmp && mv tmp` rewrites the file.
6. `git add`; if the version was already correct (no-op), exits cleanly. Otherwise commits `chore: bump marketplace version to 0.1.N [skip ci]` and pushes via `GITHUB_TOKEN`.
7. The bot commit ONLY touches `.claude-plugin/marketplace.json`, so `paths-ignore` prevents re-trigger. `[skip ci]` is defense-in-depth.

**Trace for audience 2**: after the bot commit lands, `/plugin update flow` sees `0.1.N` on remote vs. cached `0.1.M` (M<N) → pulls HEAD → user's commit + bot commit both arrive.

**End state matches goal for both audiences** — gated only on branch-protection policy allowing `GITHUB_TOKEN` to push to `main` (flagged in Verify).

## Decisions needed
(None — all design decisions were resolved in the spec; implementation matches.)

## Verify in reality
- [ ] After merge: confirm Actions run succeeds and bot commit with `0.1.<N>` lands on `main`.
- [ ] Confirm the bot commit does NOT re-trigger the workflow (paths-ignore working).
- [ ] If branch protection on `main` requires PR review: swap `GITHUB_TOKEN` for a PAT in `secrets.RELEASE_PAT` and adjust checkout `with: token:`.
- [ ] End-to-end: `/plugin install flow@flow` → merge a dummy PR → `/plugin update flow` pulls HEAD.

## Critical
None.

## Suggestions

### S1 — Add a `concurrency` group to prevent races on rapid merges
**File**: `.github/workflows/bump-marketplace-version.yml`

If two PRs merge within the workflow's runtime window, both workflow runs race:
- Run A checks out M_A, prepares bump from count N+1
- Run B checks out M_B (=M_A+PR_B's merge), prepares bump from count N+2
- Whichever pushes second fails with non-fast-forward; that bump is lost

For this repo's current velocity it's unlikely, but the fix is one-liner cheap insurance:
```yaml
concurrency:
  group: bump-marketplace-version
  cancel-in-progress: false
```
`cancel-in-progress: false` queues (rather than cancels) so no merge's bump gets dropped.

### S2 — Validate the JSON after `jq` before committing
**File**: `.github/workflows/bump-marketplace-version.yml:29-34`

GitHub Actions runs `run:` steps with `bash -e`, so a failed `jq` fails the step. But if some pathological input causes `jq` to exit 0 with malformed output (rare but possible, e.g. disk fill between stdout flush and exit), the `mv` still runs and the workflow commits invalid JSON.

Cheap belt-and-suspenders: add one line after the `mv`:
```bash
jq -e . .claude-plugin/marketplace.json > /dev/null
```
Fails the step loudly if the file isn't valid JSON.

## Nits

### N1 — Version count advances ~2x per PR
`git rev-list --count HEAD` includes the bot's own commits. After each merge: count +=1 (merge) +=1 (bot bump) = +2. So version strings will read `0.1.6`, `0.1.8`, `0.1.10`, … Still monotonic and readable. Plan's Architecture Decisions section already acknowledges this — no change needed.

### N2 — Workflow name could include "on merge to main" context
Currently `name: Bump marketplace version`. The Actions UI run list would be clearer as `name: Bump marketplace version on push to main`. Optional polish.

## Error Handling
- `bash -e` default on Linux runners → any step failure halts.
- `if git diff --cached --quiet; then exit 0` correctly handles the "already at target version" no-op case without committing an empty change.
- No silent catch-and-continue; all failures surface as a red workflow run. ✓

## Test Coverage Gaps
This is CI/ops code — no unit tests are realistic. The plan's Step 3 dry-run exercised the `jq` transformation against the live file. The remaining verification (token permissions, push semantics, branch-protection interaction) is necessarily post-merge and is captured in **Verify in reality** above. Rated as **test gap 3** (low, matches standard practice for single-file Actions workflows).

## Pattern Reuse Opportunities
None — this is the repo's first `.github/` directory. Workflow structure follows GitHub's standard idioms (named steps, `steps.version.outputs.*`, bot identity for commits).

## Files Changed
- `.claude-plugin/marketplace.json` (+1/-1) — one-time `0.1.0` → `0.1.1` bump. Clean.
- `.github/workflows/bump-marketplace-version.yml` (+46) — new workflow, 4 named steps. See S1/S2.
- `agent/spec.md` (+56/-88 vs HEAD) — replaces PR #1's spec at the same path. Semantically a new file; git sees as modification because the old spec wasn't first moved to archive.
- `agent/plans/IMPLEMENTATION_PLAN_2026-04-17.md` (+70/-73 vs HEAD) — same situation; new plan at the same path as PR #1's plan.
