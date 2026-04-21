---
name: ship
description: Fix review findings and ship a PR. Stage skill — reads findings, applies fixes, pushes a reviewed PR. Referenced by flow.
metadata:
  short-description: Findings → fix → PR
  internal: true
---

# Ship

## Goal

Read the findings document, fix what can be fixed, ask about the rest, and push a clean PR.

## How to ship

### Step 1: Read findings

Read the latest `03-review-r*.md` in the active workstream (`agent/workstreams/*-$(git branch --show-current)/`). Check for:
- Resolved decisions (human already edited the document) — apply them
- Unresolved decisions — present to human via `AskUserQuestion` (see `flow/references/user-interaction.md`)

### Step 1.5: Run the tests

Before applying any fixes, run the project's test suite (via a subagent). If tests fail:
1. Add each failure as an 8+ severity finding — include test name, file, error message.
2. Mechanical fixes (e.g., updating a mock for a newly imported function) qualify for auto-fix in Step 2.
3. If a failure suggests a real bug in the changes, surface it to the user, not as an auto-fix.

If all tests pass, note it and move on.

### Step 2: Classify and fix findings

#### Auto-fix (do without asking)

A finding qualifies when **ALL** are true:
- **Mechanical** — exactly one obvious, correct way to do it
- **Small** — 5 lines or fewer per file
- **Safe** — no risk of changing behavior or breaking tests
- **Local** — contained within a single file or tightly coupled pair

Examples: formatting nits, obvious bugs, missing error logging where pattern is established, replacing lines with an existing utility call.

Launch parallel subagents to apply auto-fixes. List what was fixed (one line each).

#### Ask the human

A finding requires asking when **ANY** are true:
- Multiple valid approaches and the choice matters
- Architectural decisions
- Could change behavior intentionally
- Large scope (many files, significant refactoring)
- Trade-offs involved
- Not confident the fix is correct

Present via `AskUserQuestion` with concrete options, batched 1-4 per call (see `flow/references/user-interaction.md`). Give file:line, what the issue is, why it matters, and concrete options (not just "fix or skip" — describe what each option does). If you have a recommendation, make it the first option with "(Recommended)" label.

**Group related findings.** If 3 findings are all about the same architectural concern, present them as one question — don't spam the user with repetitive prompts.

* **Test coverage gaps rated 8+ are ALWAYS surfaced.** Never silently skipped.
* **When in doubt, ask.** False confidence is worse than asking too many questions.
* **Human time is sacred.** Fix trivial things. Only ask about what genuinely needs judgment.

### Step 3: Apply user decisions

For items the user chose to fix, launch subagents. Skip declined items.

If any fixes were applied in Step 2 or Step 3, re-run the test suite to verify nothing broke. Report the result.

### Step 3.5: Fix summary

Before committing, present a structured summary so the human can see what happened:

```
## Ship Summary

📄 Findings: <relative path to the findings document>

**Auto-fixed**: X items
- <one-line description per item>

**User-approved fixes**: X items
- <one-line description per item>

**Skipped**: X items
- <one-line description per item>

**Remaining for next round**: X items (if any)
```

### Step 4: Commit and push

```bash
git add <specific-files>
git commit -m "Address review findings"
git push
```

Follow `commits/SKILL.md` for commit practices.

### Step 5: Create or update PR

Check if a PR already exists:
```bash
gh pr view --json number,url 2>/dev/null
```

If no PR exists, create a draft:
```bash
git push -u origin HEAD
gh pr create --draft --title "<title>" --body "$(cat <<'EOF'
## Summary
<bullet points>

## Test plan
- [ ] <verification steps>
EOF
)"
```

### Step 6: Self-review loop

Re-run `review/SKILL.md` on the PR. If new issues found, repeat steps 2-5.

* **DO** re-review after every round of fixes
* **DO NOT** loop more than 3 times — present remaining issues to the user and stop

### Step 7: Mark ready

```bash
gh pr ready <pr-number>
```

Present the final PR URL.

### Step 7.5: Record the PR number in spec frontmatter

Write the PR number into the latest `01-spec-r*.md` header comment:

```
<!-- branch: <branch> · date: <date> · author: <author> · pr: <N> -->
```

If the line already has `pr:` with a value, leave it. The folder stays at `agent/workstreams/<date>-<branch>/` after merge — the `pr:` field marks "shipped", and `workstreams-summary.sh` uses it as the filter. There is no separate archive location.

### Step 8: Re-run tests

Run the project's test suite to verify nothing broke. Report the result.

### Step 9: Reflection scan (silent when empty)

Before returning control, scan this session's conversation for facts stated ≥ 2 times that aren't already in `CLAUDE.md`. See `flow/references/reflection.md` for qualifying observations and the 3-candidate cap.

If there are candidates, surface each via `AskUserQuestion` (at most 3). If there are none, say nothing — reflection is silent when empty.

## Related skills

- `review/SKILL.md` — produces the findings this stage consumes
- `commits/SKILL.md` — commit practices (auto-triggers)
- `flow/references/reflection.md` — the "twice is a pattern" rule used in Step 9
