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

Read the latest `agent/reviews/*` document. Check for:
- Resolved decisions (human already edited the document) — apply them
- Unresolved decisions — present to human via `AskUserQuestion`

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

Present via `AskUserQuestion` with concrete options, batched 1-4 per call.

* **Test coverage gaps rated 8+ are ALWAYS surfaced.** Never silently skipped.
* **When in doubt, ask.** False confidence is worse than asking too many questions.
* **Human time is sacred.** Fix trivial things. Only ask about what genuinely needs judgment.

### Step 3: Apply user decisions

For items the user chose to fix, launch subagents. Skip declined items.

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

### Step 8: Re-run tests

Run the project's test suite to verify nothing broke. Report the result.

## Related skills

- `review/SKILL.md` — produces the findings this stage consumes
- `commits/SKILL.md` — commit practices (auto-triggers)
