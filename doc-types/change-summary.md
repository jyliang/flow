---
name: change-summary
purpose: describe what shipped — ready to drop into a PR description
audience: a reviewer approving the change · the future reader of the merge
shape: what / why / changes / how-to-verify / risk
lifecycle: written once at the end of a run; edit until merged
format: markdown
maturity: stable
---

# change-summary

The closing checkpoint — read by whoever reviews and merges the work, and by anyone reading the history later.

A change summary is a PR description that earns its merge: what shipped and why, the changes at a glance, how to confirm it works, and an honest risk read. Written so a reviewer can approve without spelunking the diff.

## Template

~~~markdown
# <title — what shipped, one line>

> **What:** <one sentence — what this change does>
> **Why:** <one sentence — the goal it serves>

## Changes

<One-sentence lede. The change at a glance.>

- <path or area> — <what changed>

## How to verify

<One-sentence lede. The shortest path for a reviewer to see it working.>

```bash
<command(s) a reviewer can run>
```

## Risk

<low / medium / high — and the one thing most likely to bite.>

## Notes

<Anything a reviewer should know: follow-ups deferred, decisions made, what's intentionally out of scope.>
~~~

## Example

> **What:** Adds a `/standup` command that turns the day's git activity into a Slack digest.
> **Why:** Engineers retype their status every morning from data already in `git log`.
>
> **Changes** — `commands/standup.md` (the command), `scripts/git-digest.sh` (the reader). Merge commits are deduped.
>
> **How to verify** — `/standup` on a repo with commits today; confirm the digest matches `git log --since=midnight`.
>
> **Risk** — low; two additive files, no shared state.

## Rules

- **DO** write so a reviewer can approve from the summary alone.
- **DO** give a real, runnable verification command.
- **DO** name the single biggest risk, even when the overall risk is low.
- **DO NOT** paste the diff — summarize the changes, link the files.
- **DO NOT** hide deferred work; list it under Notes.
