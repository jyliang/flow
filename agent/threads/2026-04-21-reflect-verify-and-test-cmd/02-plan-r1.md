# Plan: reflect-verify-and-test-cmd

## Status
plan → implement

## Source spec
`agent/workstreams/2026-04-21-reflect-verify-and-test-cmd/01-spec-r1.md`

## Architecture decisions
- **Verify-items source-of-truth stays in the review doc.** The PR body is a copy, not a rewrite target. This keeps the historical workstream immutable and lets GitHub's checkbox UI be the live state.
- **`FLOW_TEST_CMD` default is empty string, not unset.** `load-config.sh` always emits a value (via `printf '%q'`), so downstream consumers can branch on `[[ -n "$FLOW_TEST_CMD" ]]` without worrying about set-vs-unset. Matches the existing pattern for `FLOW_EXTRA_STAGES` and `FLOW_HOOKS_DIR`.
- **No separate `FLOW_VERIFY_TEMPLATE` in this round.** Shape B was considered and set aside — Shape A solves the acute pain (verify items going nowhere) without introducing a new template file. Revisit if projects report re-typing the same verify items across reviews.
- **No bats / pytest harness for flow's own scripts.** The reflection surfaced this question four times; each answer was "manual smoke tests are sufficient." Leaving the status quo in place is intentional. `FLOW_TEST_CMD` lets individual consumer projects set their own command without flow forcing a choice.
- **Bootstrap.sh is not extended to handle "branch already exists".** The gap surfaced during this spike's scaffolding step (see spike-log entry on 2026-04-21T17:33:00-04:00). Worth documenting but not worth a feature here — warm-fresh spike runs from an existing branch are rare.

## Steps

- [x] **1. Refresh `skills/review/references/findings-template.md`** — insert `## Status`, `## Decisions needed`, `## Verify in reality` after `## Complexity & Risk`; append `## Ship Summary` at the end. Match the prose conventions used in the last 6 review docs.
- [x] **2. Add `FLOW_TEST_CMD` row to `skills/flow/references/config.md`'s schema table.** Document the empty-default behavior ("empty = no automated tests; ship notes 'no test command configured' and continues"). Include an example `.flow/config.sh` block showing the field.
- [x] **3. Wire `FLOW_TEST_CMD` through `skills/flow/scripts/load-config.sh`.** Capture the env var at entry, restore after sourcing `.flow/config.sh`, default to empty string, emit via `printf '%q\n'`. Follow the existing pattern for `FLOW_STAGES`.
- [x] **4. Grow `/flow-config` to 4 questions.** Update `commands/flow-config.md`: change "3 questions" → "4 questions", insert a "Test command" question as #2 (between Template and Extra stages), update the written `.flow/config.sh` shape to include `FLOW_TEST_CMD`.
- [x] **5. Update `skills/ship/SKILL.md` Step 1.5** to `eval "$(…/load-config.sh)"` and branch on `FLOW_TEST_CMD`. Empty → note "no test command configured for this project — skipping". Non-empty → run via subagent and surface failures as 8+ findings.
- [x] **6. Update `skills/ship/SKILL.md` Step 8** to re-run `FLOW_TEST_CMD` if set, skip otherwise.
- [x] **7. Update `skills/ship/SKILL.md` Step 5** to copy the review's unchecked "Verify in reality" items into a `## Post-merge verify` block in the PR body. For new PRs: include in the `gh pr create --body` HEREDOC. For existing PRs: patch via `gh api repos/<owner>/<repo>/pulls/<num> -X PATCH -f body="…"` preserving already-ticked checkboxes. Document both paths in the step body.
- [x] **8. Smoke-test `load-config.sh`** — run the script, verify `FLOW_TEST_CMD=''` appears in the output alongside the other vars.
- [x] **9. Bootstrap the workstream** — branch off `main`, scaffold `agent/workstreams/2026-04-21-reflect-verify-and-test-cmd/`, materialize `01-spec-r1.md` and `spike-log.md` with warm-fresh seeding entry.
- [x] **10. Commit scaffolding + implementation** — separate commits per architectural boundary so `git log` tells the story.
- [x] **11. LLM-review round** — adversarial read via the review skill, produce `03-review-r1.md` with findings + 3–5 quiz questions.
- [x] **12. Draft PR** — `gh pr create --draft --title "[SPIKE] Reflect: verify-items → PR body + FLOW_TEST_CMD config"` with body from `skills/spike/templates/pr-body.md`.
- [x] **13. Record PR number** in the spec's frontmatter comment per ship Step 7.5.

## Success criteria
- `bash skills/flow/scripts/load-config.sh` outputs `FLOW_TEST_CMD=''` (and four other vars).
- `skills/ship/SKILL.md` no longer says "run the project's test suite" without config — both Step 1.5 and Step 8 branch on `FLOW_TEST_CMD`.
- `skills/ship/SKILL.md` Step 5 explicitly instructs propagation of the review's `Verify in reality` items into the PR body.
- `commands/flow-config.md` asks 4 questions including "Test command".
- `skills/review/references/findings-template.md` contains the 4 new sections.
- Draft PR is open with `[SPIKE]` prefix; PR body has all 7 sections from `skills/spike/templates/pr-body.md`.

## Risks
- **Scope creep back into "reshape /flow-reflect itself"**: mitigated by the explicit "Out of scope" in the spec and the spike-log entry explaining the deferral.
- **PR-body patch logic is subtle.** Ship needs to preserve user-ticked checkboxes on subsequent rounds. For the first PR this is a non-issue (no prior state). Revisit on the next ship that touches a re-opened PR.

## Revisions
None. First revision.
