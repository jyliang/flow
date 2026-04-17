---
name: review
description: Review code changes and produce a findings document. Stage skill — reads changes, produces findings that feed into ship stage. Referenced by flow.
argument-hint: [pr-number-or-url-or-local]
metadata:
  short-description: Changes → findings document
  internal: true
---

# Review

## Goal

Review code changes and produce a findings document at `agent/reviews/`. The findings follow the document protocol so the human can resolve decisions and the ship stage can apply fixes.

**Input**: `$ARGUMENTS` — a PR number, PR URL, or empty/`local` for local changes.

## How to review

### Step 1: Fetch the changes

**PR mode:**
```bash
gh pr view <number> --json title,body,author,baseRefName,headRefName
gh pr diff <number>
gh pr diff <number> --name-only
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

**Local mode:**
- `git diff main...HEAD` plus `git diff` and `git diff --cached`

### Step 2: Read full source files (CRITICAL)

For every changed file, read the FULL file — not just the diff hunks. Use parallel subagents.

Also read related files: protocol definitions, parent modules, test files, `CLAUDE.md`.

* **DO NOT** review based only on diff hunks — this is the #1 source of false claims
* **CRITICAL: DON'T ASSUME CODE IS UNUSED.** Grep the codebase for all call sites before claiming anything is dead code.
* **CRITICAL: VERIFY AGAINST THE REMOTE BASE BRANCH.** Run `git fetch origin <base>` and check `origin/<base>` before flagging something as missing.

### Step 3: Launch parallel specialist subagents

Give each the full diff and changed file list.

**Agent 1: Error Handling Hunter** — every try/catch, optional chain, guard/throw, fallback. Is the error logged? Could it swallow unrelated errors? Silent failures? Empty catch blocks?

**Agent 2: Test Coverage Analyzer** — be aggressive. New public API with zero tests = 10. Changed behavior without test updates = 8. Any new behavior without tests = 8+.

**Agent 3: Pattern Reuse Scanner** — be aggressive. Level 1: does the codebase already solve this? Level 2: does the change duplicate across files? Level 3: structural similarity to existing code?

### Step 4: Synthesize

Merge subagent reports. Write **How It Works** first — trace the change end-to-end. Then **Complexity & Risk**. Then:
- **Testing**: new behavior without tests goes in Critical
- **Goal gaps**: compare claimed intent vs actual code
- **End-to-end reachability**: trace feature gates for each target audience
- Correctness, bugs, architecture, naming, security, performance

De-duplicate across agents. Keep the most detailed version.

### Step 5: Write findings

Write to `agent/reviews/` using auto-incrementing ordinals:
- PR mode: `agent/reviews/pr-<number>-r<N>.md`
- Local mode: `agent/reviews/local-<branch>-r<N>.md`

Follow the document protocol (`flow/references/protocol.md`):

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

After synthesizing findings, compare the implementation against `agent/spec.md` and the plan:

- If the code does something the spec doesn't describe → flag as a goal gap in findings AND add a Revisions entry to the spec noting the drift
- If the code skips a plan step or does it differently → update the plan with a Revisions entry

This ensures the documents stay in sync with reality, and the revision trail explains why.

## Posting comments (PR mode)

When asked, use the GitHub reviews API. See `references/github-review-api.md`.
- Post as a single review with `"event": "COMMENT"`
- Never approve or request-changes
- Never delete posted comments

## Related skills

- `parallel/SKILL.md` — for parallelizing file reads and subagents
