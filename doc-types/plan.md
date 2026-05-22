---
name: plan
purpose: turn a spec into an ordered, checkable sequence of work
audience: human approving the approach · the skill that executes the work
shape: approach / steps / constraints / verification / open
lifecycle: append-only within a run; a revision supersedes the prior plan
format: markdown
maturity: stable
---

# plan

The bridge between intent and execution — read by a human sanity-checking the approach and by the skill that will carry it out.

A plan names the approach in one breath, then breaks it into steps small enough to check off. Each step is a testable unit: what to build, and how you'll know it works. A fresh agent picking up mid-run should find its place from the last unchecked box.

## Template

~~~markdown
# Plan: <subject>

> **What:** <one sentence — what ships when this plan is executed>
> **Why:** <one sentence — the spec problem this plan addresses>

## Approach

<One-sentence lede. The design in brief: patterns to follow, order of changes, key choices collapsed to one-liners ("chose X over Y because Z").>

## Steps

### Step 1: <first testable unit>

- [ ] <specific action, with file locations>
- [ ] <how you'll confirm it works>

### Step 2: <next testable unit>

- [ ] <specific action>
- [ ] <confirmation>

## Constraints

<One-sentence lede. Hard rules inherited from the spec plus any plan-specific limits.>

## Verification

<One-sentence lede. What must be confirmed when the work is complete.>

- [ ] <end-to-end check>

## Open

<One-sentence lede. Questions for the executing step or the human.>

- <unresolved question>
~~~

## Example

> **What:** Add a `/standup` command backed by a `git log` reader.
> **Why:** The spec calls for a one-call, author-scoped digest.
>
> **Approach** — One command file plus one helper that shells out to `git log --since=midnight --author`. Format in the command; keep the helper pure so it's testable.
>
> **Step 1: git reader** — Write the helper; confirm it returns commits for a known window. **Step 2: command** — Wire the helper to the slash command; confirm output renders in Slack.

## Rules

- **DO** number steps as integers; promote a half-step into a subsection of its neighbor.
- **DO** make each step a unit you can verify before moving on.
- **DO** collapse architectural choices to one-line rationales in Approach.
- **DO NOT** restate the spec's *why* as steps — link forward, don't duplicate.
- **DO NOT** leave a step whose completion you can't check.
