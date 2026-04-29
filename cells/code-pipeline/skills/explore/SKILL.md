---
name: explore
description: Explore a codebase and produce a spec document. Stage skill — produces the spec that feeds into the plan stage. Referenced by flow.
metadata:
  short-description: Idea → spec document
  internal: true
---

# Explore

Stage skill read by the next-stage agent (plan) and by a human scanning the spec before approving it. Turns an idea into a spec at `agent/threads/<YYYY-MM-DD>-<branch>/01-spec-r<N>.md`.

## Goal

Capture what exists, what needs to change, and what decisions the human must make before planning can start.

Before writing, check for an existing thread folder for this branch (`agent/threads/*-$(git branch --show-current)/`). If none exists, `bootstrap.sh` creates one; otherwise, write a revision (`-rN+1`) with a `## Revisions` section explaining what changed.

## How to explore

Use parallel subagents to understand the codebase before writing anything.

1. Study source code — find every file relevant to the feature.
2. Search for existing implementations before creating new ones.
3. Read `CLAUDE.md`, project-level reference specs, and `roadmap.md` if they exist.
4. Research technical concepts via web search if needed.

### Rules

- **DO** search for existing implementations before assuming they don't exist.
- **DO** use parallel subagents for all exploration (see `skills/parallel/SKILL.md`).
- **DO** use `AskUserQuestion` for any mid-explore clarification that requires a user decision (see `skills/run/references/user-interaction.md`). Prefer capturing ambiguities under `## Open questions` in the spec over interrupting mid-explore.
- **DO NOT** assume features aren't implemented — study the code first.

## How to produce the spec

Write the spec at `agent/threads/<YYYY-MM-DD>-<branch>/01-spec-r<N>.md` following the document protocol (`skills/run/references/protocol.md`). The scaffold at `cells/code-pipeline/templates/spec.md` seeds the structure; break from it only when the work has a natural shape that scans better.

`bootstrap.sh` substitutes `{{BRANCH}}`, `{{DATE}}`, and `{{AUTHOR}}` but leaves `{{STATUS}}`, `{{WHAT}}`, and `{{WHY}}` raw — you fill those in. On first draft, `{{STATUS}}` is `explore → plan`; `{{WHAT}}` is one sentence on what the spec delivers; `{{WHY}}` is one sentence on the problem it solves or value it creates.

```markdown
# Spec: [branch] · explore → plan

> **What:** [one sentence — what this spec delivers]  
> **Why:** [one sentence — the problem it solves or value it creates]

## Scope
[One-sentence lede. What's in, what's out. Table for file lists with risk tier.]

## Decisions
[One-sentence lede. Questions resolved during explore — conclusions only, not deliberation.]

## Design
[One-sentence lede. High-level approach and the shape of the solution.]

## Constraints
[One-sentence lede. Hard rules, guardrails, forbidden changes.]

## Verification
[One-sentence lede. What must be confirmed after the change ships.]

- [ ] [thing to check]

## Open
[One-sentence lede — or go straight to the list if there's only one item.]

- [unresolved question to escalate to plan stage]
```

### Pre-spec analysis

Run three checks before writing — they drive the Design section:

1. **Similarity check** — identify modules that look similar but differ.
2. **Impact analysis** — list all files that will be affected.
3. **Dependencies** — what this relies on; what relies on this.

### Structure: Pyramid Principle

Organize the spec as a Minto pyramid — answer first, then support. The reader should be able to stop at any level and still have a complete thought.

- **Top of the pyramid — the `What / Why` blockquote.** Two sentences. A reader who only reads the blockquote should know what ships and why it matters. This is the governing thought; every section below supports it.
- **Supporting level — the six sections.** MECE: Scope (boundaries), Decisions (resolved questions), Design (approach), Constraints (guardrails), Verification (proof the change works), Open (unresolved questions). Don't overlap; don't leave gaps; don't add a seventh unless the work genuinely needs one.
- **Evidence level — inside each section.** Lead with the section's conclusion in one sentence, then the evidence (tables, bullets, examples). A skimmer reading only the first line of each section should get the full argument.

### Readability rules

The spec is read by a human approving the plan and by the next-stage agent, often mid-context-switch. Write so a skimmer re-orients in under 10 seconds — on first draft and on revision.

1. **One-sentence lede per section.** Every `##` heading opens with one line stating that section's conclusion. Ledes are the pyramid's middle layer — reading only them should give the full argument.
2. **Tables for 3+ parallel items.** Lists of three or more items sharing the same shape (question/answer, file/risk, problem/example) become tables.
3. **Collapse resolved decisions into conclusions.** Record the answer, not the deliberation. A question answered mid-explore becomes a one-line conclusion, not a `[x]`-prefixed checkbox.
4. **Bold the key term first** in each rule, principle, or DO/DON'T bullet — the scanner sees the term before the explanation.
5. **Preserve technical content verbatim on revision.** Restructure format freely on `-rN+1`, but never drop a constraint, checklist item, or file-scope row.
6. **No new content during a readability pass.** Restructuring is format-only unless the spec is wrong.

## Conventions

Where things live and how they're named:

- `agent/threads/<date>-<branch>/01-spec-r<N>.md` — the spec. A new thread starts at `r1`; revisions create `r2`, `r3`, … with the prior file frozen and a `## Revisions` section explaining the delta.
- `roadmap.md` — product vision (read-only reference).

### Rules

- **DO NOT** include implementation details — that's the plan stage's job.
