# Spec: Auto-bump marketplace.json version on every merge

## Status
explore → plan

## What was done
- Read `.claude-plugin/marketplace.json` (single plugin entry, version `0.1.0`).
- Surveyed repo for existing automation, release tooling, and docs.
- Confirmed current state: **no `.github/`**, no workflows, no pre-commit hooks, no release tool (changesets/semantic-release/release-please), no git tags, no GitHub releases, no package manifest (`package.json`/`pyproject.toml`/`Cargo.toml`).
- Confirmed `marketplace.json` has only ever been touched twice (`8fecd36`, `98df12d`); `c3cabee` didn't touch it — this is why clients miss the update.
- Confirmed the only version string in the repo is `metadata.version` in `.claude-plugin/marketplace.json`.

## Decisions resolved

- [x] **Versioning scheme** → **A) Commit-count semver** `0.1.<commits_on_main>`. Monotonic, auto-computed, human-readable.
- [x] **Bump trigger** → **A) Post-merge CI**. Workflow on `push: main` edits `marketplace.json` and pushes back with `[skip ci]`.
- [x] **Channels** → **A) Single rolling entry**. No public install base yet; dual channels premature.
- [x] **Bump scope** → **A) Every merge to main**. Includes docs/CI-only changes; simpler and guarantees clients see HEAD.
- [x] **PR #1 aftermath** → **Yes, one-time bump** `0.1.0` → `0.1.1` in the same PR that lands the workflow, so existing installs unstick immediately.

## Verify in reality

- [ ] **Confirm `/plugin update` comparison semantics** before committing to scheme D. The ticket implies string equality (`"0.1.0" === "0.1.0"` ⇒ skip). Need to know whether Claude Code parses SemVer (so `0.1.0+sha` differs from `0.1.0`) or compares strings (so `0.1.0+sha` differs but `0.1.0+foo` vs. `0.1.0+bar` also differ — fine either way, but worth knowing). Check Claude Code plugin docs or source.
- [ ] **Confirm branch protection on `main`** allows a GitHub Actions bot to push. Repo is private (Pro required for protection API); the current git status shows local commits landing directly via PR merge. If protection requires PR review, the post-merge bump workflow needs either (a) a PAT with bypass, (b) a `[skip ci]` commit from a bot with bypass, or (c) switch to scheme 2B (pre-merge author bump).
- [ ] **Test end-to-end on a throwaway client**: after implementing, `/plugin install flow@flow`, merge a dummy PR, run `/plugin update flow` on the client and confirm the new commit arrives.

## Spec details

### Current state

- Single plugin declared in `.claude-plugin/marketplace.json` with `metadata.version = "0.1.0"`.
- No CI, no release process, no version automation.
- Installation docs (`README.md`) tell users `/plugin marketplace add jyliang/flow` then `/plugin install flow@flow`; updates happen via `/plugin update flow`.
- Commits merged to `main` via GitHub PRs (3 merge styles all enabled on repo).

### Proposed change

Add a GitHub Actions workflow that, on every merge to `main`, updates `metadata.version` in `.claude-plugin/marketplace.json` to a monotonically-increasing value, commits it back to `main`, and pushes — so `/plugin update` sees a new version every time and pulls the latest commit.

The workflow runs **before** the next developer action, so downstream clients running `/plugin update flow` always see the HEAD of `main`.

Out of scope (for this change):
- Tagged stable releases / `gh release` automation.
- Dual marketplace entries (stable + rolling).
- Semantic versioning tied to change type.

These can be layered in later if the plugin attracts a stable user base.

### Impact analysis

- **Files to change**:
  - `.claude-plugin/marketplace.json` — one-time bump (unstick existing installs); thereafter edited by CI.
- **Files to create**:
  - `.github/workflows/bump-marketplace-version.yml` — the automation.
  - Possibly a small script (`scripts/bump-marketplace-version.{sh,js}`) if the workflow logic is non-trivial — depends on chosen scheme.
- **Files to possibly create**:
  - `CONTRIBUTING.md` — one short section documenting "don't hand-edit `metadata.version`; CI does it." Optional.
- **Dependencies**:
  - Needs a token with `contents: write` on `main`. `GITHUB_TOKEN` suffices unless branch protection blocks bot pushes.
  - Relies on `jq` (pre-installed on GitHub ubuntu runners) to edit JSON without mangling formatting.
- **Similar modules**:
  - None in-repo. External prior art: `release-please`, `changesets`, but both are overkill for a single-version-string marketplace.

### Constraints

- **Workflow must not loop**: the CI-authored commit must be marked so it doesn't retrigger the same workflow (e.g. `[skip ci]`, or `if: github.actor != 'github-actions[bot]'`, or path-filter excluding `.claude-plugin/marketplace.json`).
- **Commit ordering**: the bump commit lands *after* the merge commit, so `/plugin update` returns `merge_commit + 1`. Clients will see the bump commit as HEAD; the previous user-intended change is the parent. This is fine for pulls but slightly confusing in `git log` — note for docs.
- **No breaking existing workflow**: the merge process today is "PR → squash/merge → done." The bump must not require additional human steps.
- **Must stay readable**: `/plugin marketplace list` shows the version to humans. Scheme should produce a string that isn't hostile to read (e.g. `0.1.247` is fine; `2026.04.17+c3cabee2d4f8.main.build.42` is ugly).

### Prior-art sketch (non-binding)

For the planner: a minimal scheme-A + trigger-A implementation looks like:

```yaml
# .github/workflows/bump-marketplace-version.yml
on:
  push:
    branches: [main]
    paths-ignore:
      - '.claude-plugin/marketplace.json'
jobs:
  bump:
    runs-on: ubuntu-latest
    permissions: { contents: write }
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Bump version
        run: |
          count=$(git rev-list --count main)
          jq --arg v "0.1.$count" '.metadata.version = $v' \
            .claude-plugin/marketplace.json > tmp && mv tmp .claude-plugin/marketplace.json
      - name: Commit
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add .claude-plugin/marketplace.json
          git diff --cached --quiet || git commit -m "chore: bump marketplace version [skip ci]"
          git push
```

The planner should validate this against the decisions above — this is a sketch, not a commitment.
