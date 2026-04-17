---
name: implement
description: Execute an implementation plan step by step. Stage skill — reads plan, produces code changes. Referenced by flow.
metadata:
  short-description: Plan → code changes
  internal: true
---

# Implement

## Goal

Read the latest `agent/plans/IMPLEMENTATION_PLAN_*.md` and execute it step by step, producing code changes on the current branch.

## How to set up

1. Study `CLAUDE.md` for project patterns and guidelines
2. Read `agent/spec.md` for the feature spec (what we're building and why)
3. Read the latest `agent/plans/IMPLEMENTATION_PLAN_*.md` for the steps to execute
4. Study the source code around the affected files

## How to run the loop

Pick the single most important incomplete step from the plan, then:

1. **Explore** — spawn parallel subagents to read all relevant files and search for existing implementations
2. **Implement** — spawn parallel subagents to write code (tests first, then implementation)
3. **Test** — run tests via a single subagent, capture and study the output
4. **Commit** — if tests pass, commit with a descriptive message and push
5. **Update plan** — mark the step complete, note any blockers or decisions
6. **Repeat** — pick the next most important step

* **DO NOT** edit files directly in the main context — delegate all edits to subagents
* **DO NOT** proceed to the next step with failing tests
* **DO** update the plan after every step so a fresh agent can pick up
* **DO** write production-ready code — no placeholders, no stubs
* **DO** ask for clarification rather than guessing requirements

## How to handle discoveries

During implementation you will discover things that contradict the spec or plan — an API that doesn't work as assumed, middleware that constrains the approach, an existing pattern that changes the design.

When this happens:

1. **Update the earlier document.** Go back to `agent/spec.md` or the plan and revise the affected section.
2. **Add a Revisions entry** to the document you changed (see `flow/references/protocol.md`):
   ```markdown
   ## Revisions
   - **implement → spec** [date]: [What changed]
     **Why**: [What you discovered during which step]
     **Impact**: [What downstream work is affected]
   ```
3. **Update the plan** if the spec revision changes the approach.
4. **Continue implementing** from the current step, not from the beginning.

* **DO NOT** silently diverge from the spec — if the code does something different from what the spec says, update the spec
* **DO** surface significant discoveries to the human via `flow` before continuing if the change is large

## Related skills

- `tdd/SKILL.md` — test-first discipline (auto-triggers)
- `commits/SKILL.md` — atomic commit discipline (auto-triggers)
- `parallel/SKILL.md` — subagent patterns (auto-triggers)
