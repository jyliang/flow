---
name: review
description: Review code changes and produce a findings document. Stage skill — reads changes, produces findings that feed into ship stage. Referenced by flow.
argument-hint: [pr-number-or-url-or-local]
metadata:
  short-description: Changes → findings document
  internal: true
---

# Review

Stage skill read by the next-stage agent (ship) and by a human deciding whether the PR is safe to merge. Produces `03-review-r<N>.md` in the active thread folder (`agent/threads/*-$(git branch --show-current)/`).

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

- **DO** use `AskUserQuestion` for any mid-review ambiguity that blocks finding classification (see `skills/run/references/user-interaction.md`). Prefer capturing ambiguities in the findings' `## Open` section over interrupting mid-review.
- **DO NOT** review based only on diff hunks — this is the #1 source of false claims.

> **Warning:** Don't assume code is unused. Grep the codebase for all call sites before claiming anything is dead code.

> **Warning:** Verify against the remote base branch. Run `git fetch origin <base>` and check `origin/<base>` before flagging something as missing.

### Step 3: Launch parallel specialist subagents

Give each specialist the full diff and changed file list. Be aggressive on severity — false confidence hides real problems.

| Agent | Focus | Severity rules |
|---|---|---|
| Error Handling Hunter | Every try/catch, optional chain, guard/throw, fallback. Is the error logged? Could it swallow unrelated errors? Silent failures? Empty catch blocks? | Rate by blast radius: silent swallow in a hot path = 9, missing log on a recoverable error = 6. |
| Test Coverage Analyzer | Coverage of new or changed behavior. | New public API with zero tests = 10. Changed behavior without test updates = 8. Any new behavior without tests = 8+. |
| Pattern Reuse Scanner | Level 1: does the codebase already solve this? Level 2: does the change duplicate across files? Level 3: structural similarity to existing code. | Duplication of an existing utility = 7. Structural near-duplicate = 5. |

### Step 4: Synthesize

Merge subagent reports into the template sections. Start with `## Changes` (trace the change end-to-end), then `## Risk` (rate low/medium/high with justification). Then cover:

- **Testing** — new behavior without tests goes in `## Findings > ### Critical`.
- **Goal gaps** — compare claimed intent (What/Why) vs actual code.
- **End-to-end reachability** — trace feature gates for each target audience, write to `## Walkthrough`.
- Correctness, bugs, architecture, naming, security, performance.

De-duplicate across agents. Keep the most detailed version.

#### End-to-end walkthrough

Before finalizing findings, do your own E2E sanity check — this catches goal-level bugs that line-by-line review misses. Write it out in the findings under `## Walkthrough`; don't just think it.

1. **Infer the goal.** From commit messages, PR description, branch name, or spec.
2. **List every distinct audience.** For each feature gate, environment check, or role-based condition in the diff, name the relevant audiences (e.g., "Pro user on prod", "non-Pro on staging", "unauthenticated user").
3. **Trace the happy path for each audience.** Walk through the full conditional chain — from entry point (URL, tab click, API call) through every gate to the final rendered output or API response. Check both client AND server paths.
4. **Ask: does the end state match the stated goal?** If the chain evaluates to false for an audience the change claims to serve, that's a **Critical** finding — add it before writing the document.

Keep the walkthrough brief (a few lines per audience) but explicit.

### Step 5: Write findings

Write to `03-review-r<N>.md` in the active thread folder (`agent/threads/<date>-<branch>/`) following the document protocol (`skills/run/references/protocol.md`) and the scaffold in `references/findings-template.md`. The scaffold seeds the structure; break from it only when the change has a natural shape that scans better. Round ordinal auto-increments: the first review of the thread is `r1`, the next is `r2`, and so on. PR-vs-local distinction lives in the frontmatter, not the filename.

```markdown
<!-- branch: [branch] · date: [date] · author: [git user] · pr: [URL or omit] · base: [base] -->

# Findings: [PR title or "Local changes on <branch>"] · review → ship

> **What:** [one sentence — what the change does]  
> **Why:** [one sentence — the spec/ticket goal it serves]

## Changes
[One-sentence lede. Technical summary + changed files.]

## Walkthrough
[One-sentence lede. Per-audience E2E trace from Step 4.]

## Risk
[Rating + justification.]

## Findings
### Critical
### Suggestions
### Nits

## Verification
- [ ] [manual checks that can't be done from the diff]

## Open
- [ ] **[file:line]**: [decision or question for the human]

## Ship trail
<!-- Appended by ship stage — do not fill during review. -->
```

Findings from the three specialist subagents merge into `## Findings`, classified by severity rather than by source agent. Don't create separate Error Handling / Test Coverage / Pattern Reuse sections — they drift out of sync with the graded findings.

### Step 6: Present findings

Summary of critical/suggestion/nit counts plus highlights from each specialist.

### Structure: Pyramid Principle

Organize the findings as a Minto pyramid — answer first, then support. The reader should be able to stop at any level and still have a complete thought.

- **Top of the pyramid — the `What / Why` blockquote.** Two sentences. A reader who only reads the blockquote knows what shipped and why. If the code's actual intent disagrees with the stated Why, that itself is a Critical finding.
- **Supporting level — the six sections.** MECE: Changes (what the diff does), Walkthrough (E2E trace), Risk (rating), Findings (Critical/Suggestions/Nits), Verification (manual checks), Open (human decisions). `Ship trail` is a post-hoc marker, not a support.
- **Evidence level — inside each section.** Lead with the section's conclusion in one sentence, then the evidence. Each Critical leads with the impact ("user X sees Y"), then the line reference, then the fix.

### Readability rules

The findings document is read by the ship stage fixing issues and by a human deciding whether to merge. Write so a skimmer re-orients in under 10 seconds — on first draft and on revision.

1. **One-sentence lede per section.** Every `##` heading opens with one line stating that section's conclusion.
2. **Tables for 3+ parallel items.** Lists of three or more items sharing the same shape (audience/path, file/change, finding/severity) become tables.
3. **Collapse specialist findings by severity, not by source.** An Error Handling Hunter critical and a Test Coverage critical both go in `## Findings > ### Critical` — don't duplicate them in source-agent sections.
4. **Bold the key term first** in each finding — the `file:line` or the audience name — so the scanner can locate it without reading the body.
5. **Preserve technical content verbatim on revision.** Restructure format freely on `-rN+1`, but never drop a finding, a verification check, or an open decision.
6. **No new content during a readability pass.** Format-only unless a finding was wrong.

## How to handle spec/plan drift

After synthesizing findings, compare the implementation against the latest `01-spec-r*.md` and `02-plan-r*.md` in the active thread:

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
