---
name: review
description: Review code changes and produce a findings document. Stage skill — reads changes, produces findings that feed into ship stage. Referenced by flow.
argument-hint: [pr-number-or-url-or-local]
metadata:
  short-description: Changes → findings document
  internal: true
---

# Review

Stage skill read by the next-stage agent (ship) and by a human deciding whether the PR is safe to merge. Produces `03-review-r<N>.md` in the active workstream folder (`agent/workstreams/*-$(git branch --show-current)/`).

## Goal

Review code changes and produce findings that follow the document protocol so the human can resolve decisions and the ship stage can apply fixes.

**Input**: `$ARGUMENTS` — a PR number, PR URL, or empty/`local` for local changes.

## How to review

A six-step pipeline: fetch, read, launch specialists, synthesize, walk through end-to-end, write.

### Step 1: Fetch the changes

**PR mode:**
```bash
gh pr view <number> --json title,body,author,baseRefName,headRefName
gh pr diff <number>
gh pr diff <number> --name-only
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

**Local mode:**
```bash
git diff main...HEAD
git diff
git diff --cached
```

### Step 2: Read full source files

For every changed file, read the full file — not just the diff hunks. Use parallel subagents. Also read related files: protocol definitions, parent modules, test files, `CLAUDE.md`.

#### Rules

- **DO** use `AskUserQuestion` for any mid-review ambiguity that blocks finding classification (see `skills/flow/references/user-interaction.md`). Prefer capturing ambiguities in the findings' `## Decisions needed` over interrupting mid-review.
- **DO NOT** review based only on diff hunks — this is the #1 source of false claims.

> **Warning:** Don't assume code is unused. Grep the codebase for all call sites before claiming anything is dead code.

> **Warning:** Verify against the remote base branch. Run `git fetch origin <base>` and check `origin/<base>` before flagging something as missing.

### Step 3: Launch parallel specialist subagents

Give each specialist the full diff and changed file list.

| Agent | Focus | Threshold |
|---|---|---|
| Error Handling Hunter | Every try/catch, optional chain, guard/throw, fallback. Is the error logged? Could it swallow unrelated errors? Silent failures? Empty catch blocks? | — |
| Test Coverage Analyzer | Be aggressive. | New public API with zero tests = 10. Changed behavior without test updates = 8. Any new behavior without tests = 8+. |
| Pattern Reuse Scanner | Level 1: does the codebase already solve this? Level 2: does the change duplicate across files? Level 3: structural similarity to existing code? | Be aggressive. |

### Step 4: Synthesize

Merge subagent reports. Write **How It Works** first — trace the change end-to-end. Then **Complexity & Risk**. Then cover:

- **Testing** — new behavior without tests goes in Critical.
- **Goal gaps** — compare claimed intent vs actual code.
- **End-to-end reachability** — trace feature gates for each target audience.
- Correctness, bugs, architecture, naming, security, performance.

De-duplicate across agents. Keep the most detailed version.

#### End-to-end walkthrough

Before finalizing findings, do your own E2E sanity check — this catches goal-level bugs that line-by-line review misses. Write it out in the findings (under **How It Works** or as its own section); don't just think it.

1. **Infer the goal.** From commit messages, PR description, branch name, or spec.
2. **List every distinct audience.** For each feature gate, environment check, or role-based condition in the diff, name the relevant audiences (e.g., "Pro user on prod", "non-Pro on staging", "unauthenticated user").
3. **Trace the happy path for each audience.** Walk through the full conditional chain — from entry point (URL, tab click, API call) through every gate to the final rendered output or API response. Check both client AND server paths.
4. **Ask: does the end state match the stated goal?** If the chain evaluates to false for an audience the change claims to serve, that's a **Critical** finding — add it before writing the document.

Keep the walkthrough brief (a few lines per audience) but explicit.

### Step 5: Write findings

Write to `03-review-r<N>.md` in the active workstream folder (`agent/workstreams/<date>-<branch>/`). Round ordinal auto-increments: the first review of the workstream is `r1`, the next is `r2`, and so on. PR-vs-local distinction lives inside the document (see template), not the filename.

Follow the document protocol (`skills/flow/references/protocol.md`):

```markdown
# Findings: [PR title or branch description]

## Status
review → ship

## What was done
- Reviewed [N] files, launched 3 specialist subagents
- Found [N] critical, [N] suggestions, [N] nits

## Decisions needed
- [ ] **[file:line]**: [Issue requiring human judgment — describe options]
- [ ] **[file:line]**: [Design decision — describe trade-offs]

## Verify in reality
- [ ] Test [specific scenario] manually
- [ ] Confirm [behavior] in [environment]

## Critical
[Issues that must be fixed]

## Suggestions
[Improvements, not blocking]

## Nits
[Minor observations]

## Questions
[Things that need clarification]

## Error Handling
[From specialist agent]

## Test Coverage Gaps
[From specialist agent]

## Pattern Reuse Opportunities
[From specialist agent]

## Files Changed
[List with brief notes]
```

### Step 6: Present findings

Summary of critical/suggestion/nit/question counts plus highlights from each specialist.

## How to handle spec/plan drift

After synthesizing findings, compare the implementation against the latest `01-spec-r*.md` and `02-plan-r*.md` in the active workstream:

- If the code does something the spec doesn't describe → flag as a goal gap in findings AND write a spec revision (`01-spec-rN+1.md`) with a Revisions entry noting the drift.
- If the code skips a plan step or does it differently → write a plan revision (`02-plan-rN+1.md`) with a Revisions entry.

This keeps the documents in sync with reality, and the revision trail explains why.

## How to post comments (PR mode)

When asked, use the GitHub reviews API. See `references/github-review-api.md`.

### Rules

- **DO** post as a single review with `"event": "COMMENT"`.
- **DO NOT** approve or request-changes.
- **DO NOT** delete posted comments.

## Related skills

- `skills/parallel/SKILL.md` — parallelizing file reads and subagents.
