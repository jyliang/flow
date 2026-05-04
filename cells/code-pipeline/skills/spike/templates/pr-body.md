# [SPIKE] {{THESIS}}

_Branch_: {{BRANCH}} · _Status_: draft, awaiting human review

This PR is a **thesis-validation spike** produced by `/flow:spike`. The pipeline ran unattended (explore → plan → implement → 1 LLM-review round). Every auto-decision is logged in this thread's `spike-log.md`. Human review is the only human touchpoint; use the sections below (plus the thread folder at `agent/threads/{{BRANCH}}/` if you want the full trail) rather than reading the full diff.

## Thesis

{{THESIS}}

## What the spike built

<!-- One paragraph. What exists on this branch, in plain English. Avoid diff-level detail. -->

## How to poke at it

<!-- One or two commands to reproduce what the human needs to see. Filled by the implement stage as commands are run. -->

```bash
# e.g. make install && /flow:spike "..."
```

## What the spike shows

<!-- Adversarial thesis read produced by LLM-review. MUST cover:
- Strongest evidence FOR the thesis
- Strongest evidence AGAINST the thesis
- What would have falsified the thesis; did it?
- What a skeptical reviewer would push back on
-->

## Decisions log (top highlights)

<!-- 5-10 most impactful entries from this thread's spike-log.md. Full log is in the PR diff. -->

## Quiz (prime human review)

<!-- 3-5 thesis-oriented diagnostic questions. Not graded; reviewer self-checks.
Examples:
1. Before running the example, predict output for input X. Did it match?
2. Under what condition would the approach break?
3. Which assumption in the thesis is load-bearing here, and does the code honor it?
-->

## Next moves

Two options for the human reviewer:

- **Continue iterating with human-in-the-loop**: run `/flow:here` from this branch. Spike's spec/plan/log become the starting point for human-guided work.
- **Archive and start fresh**: if the thesis is falsified or needs reframing, close this PR, branch-delete, and run a different `/flow:spike` thesis.
