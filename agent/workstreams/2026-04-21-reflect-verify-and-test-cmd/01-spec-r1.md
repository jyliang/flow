<!-- branch: reflect-verify-and-test-cmd · date: 2026-04-21 · author: Jason Liang · pr: -->

# Spec: reflect-verify-and-test-cmd

## Status
explore → plan

## What was done
- `/flow-reflect` scanned 6 shipped workstreams and surfaced 3 cross-workstream patterns.
- User approved one proposal (findings-template refresh) and reshaped the other two (verify-items and test-strategy) into a unified design question: per-project customization of how a change gets confirmed.
- User picked Shape A: in-review verify items flow into the PR body as GitHub-checkable items; ship test command becomes a config field (`FLOW_TEST_CMD`) each project owns.
- Mid-session, user flagged that reflection should *itself* funnel through `/flow` instead of applying changes ad-hoc. This workstream is the dogfood: spike-mode packages the session's edits as a proper workstream + draft PR.

## Decisions needed
- [x] Shape for verify-items + test-strategy coupling → **Shape A**: ship Step 5 copies review's "Verify in reality" items into PR body under `## Post-merge verify`; `FLOW_TEST_CMD` config field with empty default; `/flow-config` grows a 4th question.
- [x] Findings template refresh → apply `Status`, `Decisions needed`, `Verify in reality`, `Ship Summary` sections to `skills/review/references/findings-template.md`.
- [x] How `/flow-reflect` itself should behave next time → **Shape 1** (identified in later discussion): reflection generates ideas, which are funneled into the flow pipeline rather than applied ad-hoc. **Not implemented in this workstream** — deferred to a follow-up. This workstream retroactively wraps the ad-hoc session as a proper spike to demonstrate the pattern.
- [x] Package the ad-hoc session edits → use `/flow-spike` to wrap them in a draft PR (this workstream).

## Verify in reality
- [ ] Run `bash $HOME/.claude/skills/flow/scripts/load-config.sh` in a fresh clone after `make install` — confirm the output includes `FLOW_TEST_CMD=''`.
- [ ] Run `/flow-config` in a repo that has no `.flow/config.sh` — confirm 4 questions appear, including the new "Test command" prompt with `None` / `make test` / `npm test` / Custom options.
- [ ] Run `/flow` through to ship on a docs-only change (like this one) — confirm Step 1.5 emits "no test command configured for this project — skipping" and Step 8 skips similarly.
- [ ] Ship any change with a populated `Verify in reality` section — confirm the PR body includes a `## Post-merge verify` block with each item as an unchecked `- [ ]`.
- [ ] On a subsequent ship round, confirm the PR body patch preserves already-ticked checkboxes rather than rewriting them.
- [ ] Review a future PR using the refreshed `findings-template.md` — confirm the new sections (`Status`, `Decisions needed`, `Verify in reality`, `Ship Summary`) are present and flow naturally from the reviewer's pen.

## Spec details

### Problem
Two linked drifts surfaced in reflection across 6 shipped workstreams:

1. **Verify-in-reality items are orphaned.** 6/6 review docs include unchecked post-merge verify items; none of them get followed up on after merge. The review doc is a grave.
2. **`skills/ship/SKILL.md` Steps 1.5 and 8 say "run the project's test suite" without knowing what that means for a given project.** For this repo (shell + markdown), there is no test suite, and 4 reviews independently raised "should we add bats?" and dismissed it each time. The discussion re-opens on every ship.

A third, purely-documentary drift: `skills/review/references/findings-template.md` predates the sections every actual review uses (`Status`, `Decisions needed`, `Verify in reality`, `Ship Summary`).

### Scope
Three changes, tightly scoped to the flow skill + its stage skills. No behavioral change to any other project.

1. **Findings template refresh** — add the four sections to `skills/review/references/findings-template.md`.
2. **`FLOW_TEST_CMD` config field** — declare in `skills/flow/references/config.md`, export from `skills/flow/scripts/load-config.sh`, add a question to `commands/flow-config.md`. Ship Steps 1.5 + 8 read the var and skip-with-a-note when empty.
3. **PR-body verify propagation** — `skills/ship/SKILL.md` Step 5 copies the review's `Verify in reality` items into the PR body as `## Post-merge verify`. On update, patch via `gh api` preserving already-ticked boxes.

Out of scope (deferred):
- Reshaping `/flow-reflect` itself to generate ideas that funnel into `/flow` (Shape 1 from the later discussion).
- Per-project verify templates (`FLOW_VERIFY_TEMPLATE` — Shape B from the earlier discussion).
- Unified `.flow/verify/` dir (Shape C).

### Design
**Per-project test command.** `FLOW_TEST_CMD` joins `FLOW_TEMPLATE_SPEC`, `FLOW_STAGES`, `FLOW_EXTRA_STAGES`, `FLOW_HOOKS_DIR` as a declared config field. Precedence remains env > file > default. Default is empty string, which ship interprets as "no automated tests configured — skip with a note." Projects that have tests set it to `make test`, `npm test`, `pytest`, or any shell command. `/flow-config` prompts with `None` as first option so docs-only / shell-script repos get the right answer with a single keystroke.

**Verify-items → PR body.** The source-of-truth stays in the review doc (durable, in-repo, versioned). The PR body is a live checklist-shaped *copy*. GitHub renders `- [ ]` as clickable checkboxes, so the human reviewer (or author, post-merge) can tick off items without editing files. On subsequent ship rounds, ship patches the PR body via `gh api ... -X PATCH -f body=...` and is careful to preserve user-ticked boxes — diff the old body against the new verify items; append new ones, leave existing ones (ticked or not) alone.

**Findings template.** Purely additive: insert `## Status`, `## Decisions needed`, `## Verify in reality` before `## Findings`, and `## Ship Summary` at the bottom.

### Constraints
- No new skills, no new scripts. All changes are to files that already exist.
- Backwards compatible: projects with no `.flow/config.sh` or with `.flow/config.sh` that doesn't set `FLOW_TEST_CMD` get the same empty-default behavior. Existing review docs aren't rewritten.
- Security: `FLOW_TEST_CMD` is shell-sourced like every other var in `.flow/config.sh`; the existing security note in `references/config.md` already covers this ("treat the file as executable code").

### Open questions
None as of this round. All decisions resolved; see the `Decisions needed` section above.
