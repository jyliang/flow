---
name: findings
purpose: report what a review surfaced — issues, risks, what passed
audience: human deciding whether to ship · the skill that acts on the review
shape: changes / walkthrough / risk / findings / verification / open
lifecycle: append-only within a run; a revision supersedes the prior findings
format: markdown
maturity: stable
---

# findings

The verdict of a review — read by a human deciding whether to ship and by whatever step acts on the result.

Findings separate what the change *does* from what's *wrong with it*. Trace the change end to end (the walkthrough catches goal-level bugs a line-by-line read misses), rate the risk honestly, then sort issues by severity — not by who found them.

## Template

~~~markdown
# Findings: <subject>

> **What:** <one sentence — what the change does>
> **Why:** <one sentence — the goal it serves>

## Changes

<One-sentence lede. Components touched, data flow, key implementation choices.>

### Files

- <path> — <what changed>

## Walkthrough

<One-sentence lede. End-to-end trace per audience — does the end state match the goal?>

- **<audience>:** <entry → step → output>

## Risk

<low / medium / high. Justify: files changed, hot paths, revert difficulty, regression likelihood.>

## Findings

### Critical

<Must be fixed before shipping.>

### Suggestions

<Better, but not blocking.>

### Nits

<Minor style, naming, formatting.>

## Verification

<One-sentence lede. Checks that can't be made from the diff alone — live commands, UI behavior.>

- [ ] <thing to check>

## Open

<One-sentence lede. Decisions the human must make before shipping.>

- [ ] **<file:line>**: <decision requiring human judgment>
~~~

## Example

> **What:** Reviews the `/standup` command and its git reader.
> **Why:** Confirm the digest is correct before shipping.
>
> **Risk** — low. Two new files, no shared state, trivial to revert.
>
> **Critical** — `git log` with no commits in-window returns empty; the command prints a bare header. Add an "no activity" fallback.
>
> **Open** — Should an empty day post nothing, or post "no activity"? Needs a call.

## Rules

- **DO** read full source, not just diff hunks, before flagging anything.
- **DO** classify by severity (Critical / Suggestion / Nit), never by which check raised it.
- **DO** put anything needing a human decision under Open with a `file:line` anchor.
- **DO NOT** rate risk "low" without naming what makes it low.
- **DO NOT** auto-approve or auto-reject — findings inform a decision, they don't make it.
