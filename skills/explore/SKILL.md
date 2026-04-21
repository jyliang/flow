---
name: explore
description: Explore a codebase and produce a spec document. Stage skill — produces the spec that feeds into the plan stage. Referenced by flow.
metadata:
  short-description: Idea → spec document
  internal: true
---

# Explore

## Goal

Take an idea or feature description and produce a spec document at `agent/workstreams/<YYYY-MM-DD>-<branch>/01-spec-r<N>.md` (typically `01-spec-r1.md` for a new workstream). The spec captures what exists, what needs to change, and what decisions the human should make before planning begins.

Before writing, check for an existing workstream folder for this branch (`agent/workstreams/*-$(git branch --show-current)/`). If none exists, `bootstrap.sh` creates one; otherwise, write a revision (`-rN+1`) with a `## Revisions` section explaining what changed.

## How to explore

Use parallel subagents to understand the codebase:

1. Study source code — find all files relevant to the feature
2. Search for existing implementations before creating new ones
3. Read `CLAUDE.md`, project-level reference specs, and `roadmap.md` if they exist
4. Research technical concepts via web search if needed

* **DO** search for existing implementations before assuming they don't exist
* **DO** use parallel subagents for all exploration (see `parallel/SKILL.md`)
* **DO** use `AskUserQuestion` for any mid-explore clarification that requires a user decision (see `flow/references/user-interaction.md`). Prefer capturing ambiguities under `## Decisions needed` in the spec over interrupting mid-explore.
* **DO NOT** assume features aren't implemented — study the code first

## How to produce the spec

After exploration, write the spec at `agent/workstreams/<YYYY-MM-DD>-<branch>/01-spec-r<N>.md` following the document protocol (`flow/references/protocol.md`):

```markdown
# Spec: [Feature Name]

## Status
explore → plan

## What was done
- Explored [N] files across [areas]
- Found existing implementations of [X]
- Identified [N] files that will need changes

## Decisions needed
- [ ] **Reuse vs replace**: [existing module] does something similar — extend it or build new?
- [ ] **Scope**: The ticket mentions X but the code also affects Y — include Y?
- [ ] **Edge case**: What should happen when [discovered edge case]?

## Verify in reality
- [ ] Confirm [assumption about current behavior] by testing in [environment]

## Spec details

### Current state
[What exists today — relevant files, patterns, data flow]

### Proposed change
[What needs to happen — high level, not implementation details]

### Impact analysis
- **Files to change**: [list with one-line reasons]
- **Files to create**: [list]
- **Dependencies**: [what this relies on, what relies on this]
- **Similar modules**: [existing patterns to follow or avoid duplicating]

### Constraints
[Anything discovered during exploration that constrains the approach]
```

### Pre-spec analysis

Before writing the spec, perform:

1. **Similarity check** — identify modules that look similar but differ
2. **Impact analysis** — list all files that will be affected
3. **Dependencies** — what does this rely on? what relies on this?

## Conventions

- `agent/workstreams/<date>-<branch>/01-spec-r<N>.md` — the spec document. A new workstream starts at `r1`; a revision creates `r2`, `r3`, ... with the prior file frozen and a `## Revisions` section explaining the delta.
- `roadmap.md` — product vision (read-only reference)

* **DO NOT** include implementation details — that's the plan stage's job
