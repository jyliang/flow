# Review: reflect-verify-and-test-cmd

**PR**: (draft, to be opened by spike)
**Author**: Jason Liang
**Branch**: reflect-verify-and-test-cmd → main
**Review round**: 1 (LLM-review, spike mode)
**Date reviewed**: 2026-04-21

## Status
review → ship

## Summary

Shape A lands cleanly: `FLOW_TEST_CMD` joins the five-field config schema with `load-config.sh` emitting `FLOW_TEST_CMD=''` by default, and ship Step 5 now copies review's `Verify in reality` items into a `## Post-merge verify` block in the PR body. Findings-template refresh is additive. One real latent problem — the patch-not-rewrite behavior on re-ship is under-specified — and three suggestions around `bootstrap.sh` duplication and test-subagent handling.

## How It Works

Five files change the runtime; one file changes the review artifact shape.

1. **Config plumbing** — `skills/flow/references/config.md:13` adds a `FLOW_TEST_CMD` row (default `""`, doc says "empty = skip with a note"). `skills/flow/scripts/load-config.sh:14,26,36,43` adds the env-capture line, the env-override line, the default line, and the `printf '%q'` emission line. Precedence (env > file > default) is preserved. Smoke-tested: `bash skills/flow/scripts/load-config.sh` in this repo emits `FLOW_TEST_CMD=''` on line 3 of 5, alongside the other four vars. `commands/flow-config.md` grows from 3 to 4 questions with "Test command" inserted as question 2, and the written `.flow/config.sh` shape gains `FLOW_TEST_CMD="<user's answer, empty string if 'None'>"`.

2. **Ship consumption** — `skills/ship/SKILL.md:27-31` replaces the bare "run the project's test suite" with an `eval "$(…/load-config.sh)"` + `[[ -n "$FLOW_TEST_CMD" ]]` branch. Step 8 (line 160) mirrors the same branch. Empty → "no test command configured for this project — skipping"; non-empty → run via subagent, surface failures as 8+ findings.

3. **Verify-items propagation** — `skills/ship/SKILL.md:116` adds a pre-body step that instructs the LLM to copy unchecked `- [ ]` items from the latest review's `Verify in reality` section into a `## Post-merge verify` block. The HEREDOC for new PRs (line 125) now emits `## Post-merge verify` instead of `## Test plan`. For existing PRs, line 131 instructs a `gh api … -X PATCH -f body="…"` with prose "preserve any checkboxes the user already ticked". The review doc remains the source-of-truth; the PR body is a live copy.

4. **Findings template** — `skills/review/references/findings-template.md` gains four sections purely additively: `## Status` after the header block, `## Decisions needed` and `## Verify in reality` after `## Complexity & Risk`, and `## Ship Summary` at the bottom. This matches what the last six review docs already had (`agent/workstreams/2026-04-21-document-name/03-review-r1.md:9,24,26,30`, `2026-04-18-flow-v2-config/03-review-r1.md:3,52,56`).

Runtime behavior for existing projects: nothing changes if there's no `.flow/config.sh` or it doesn't set `FLOW_TEST_CMD` — `load-config.sh` emits empty, ship skips the test step with a visible note. For new projects, `/flow-config`'s new question #2 nudges "None" as the default so docs-only / shell-script repos get the right answer with a single keystroke.

## Adversarial read

**Strongest fact FOR the thesis**: The empty-string default is load-bearing and works correctly. Smoke test confirmed: `bash skills/flow/scripts/load-config.sh` in a repo with no `.flow/config.sh` emits exactly `FLOW_TEST_CMD=''` (verified against `/tmp/flow-test` with an empty `git init`). Downstream `[[ -n "$FLOW_TEST_CMD" ]]` is correct regardless of whether the field is set-but-empty, unset, or omitted — `printf '%q' ""` produces `''`, which eval-assigns to empty, which fails `-n`. The per-project customization that reflection surfaced four times in prior review docs now has a single declared field with no special-case behavior, backwards-compatible by construction.

**Strongest fact AGAINST the thesis**: The patch-not-rewrite behavior in Step 5 is **described but not specified**. The prose (line 131) says "Preserve any checkboxes the user already ticked on GitHub — only add new items, don't rewrite existing state." That is a behavioral contract with at least three edge cases the spec never mentions:
- What does "new item" mean when the review doc's item text drifts (e.g., r1 had "Run /flow-config" and r2 has "Run /flow-config in a repo without config")? String match? Substring? Fuzzy?
- What happens if the user manually edited the PR body between rounds — prepending their own notes, reordering sections?
- What happens on the *first* re-ship after a review where the human ticked `[x]` in the review doc? The review doc's state is `[x]`, but the code in Step 5 says to copy **unchecked** items only — so a ticked review item drops out of the PR body entirely, which may look like regression to a GitHub reviewer who was about to tick it there.

None of these are show-stoppers, but the ship-time LLM is going to have to invent a policy on the fly. The spec's own Risks section acknowledges this ("revisit on the next ship that touches a re-opened PR") but the workstream is shipping Shape A *now*, and Shape A's PR will itself be the first test case — so this ships with a known unknown.

**Checks run that would have falsified**: (a) Running `load-config.sh` in a clean git init — would have falsified the "default is empty" claim if `FLOW_TEST_CMD` had been absent from output. Did not falsify. (b) Reading the bootstrap.sh precedence block to see whether a future config field would silently drop out of bootstrap's view — found the `# Kept in sync with that script` comment confirms this is an intentional, documented-but-narrow duplication. Did not falsify the thesis (bootstrap doesn't need test cmd) but did flag latent drift — see Suggestion 1. (c) Grepping the workstream's own spec headings against the refreshed findings-template — the spec uses `## Status`, `## Decisions needed`, `## Verify in reality` which matches (dogfood check passes).

**What a skeptical reviewer would push back on**:
- "You added a feature (PR-body propagation) whose first real invocation is the PR that ships the feature. That's a dogfood, but it's also a self-test with no baseline. How will you know the propagation worked?" — see Verify-in-reality item 4 below.
- "You deferred `/flow-reflect` reshape, but that's the whole point of the session. What stops someone from forgetting the deferral?" — the spec's Out-of-scope section (01-spec-r1.md:45-48) names it and the spike-log's 17:45 entry gives the reasoning. Adequate for an LLM-searchable trail; a human could still miss it.
- "The `FLOW_STAGES` line in `load-config.sh` output is shell-quoted to `explore\ plan\ implement\ review\ ship` — is anything downstream broken by that?" — not introduced by this PR, but the test-cmd field has the same quoting contract; if a user sets `FLOW_TEST_CMD="make test"`, output is `FLOW_TEST_CMD=make\ test`, which eval-assigns correctly to `make test`. Fine.

## Complexity & Risk

**Low**. 8 files, 198 insertions, 7 deletions. Two commits (`7f554ac` scaffolds, `b394f91` implements). Revert is trivial (`git revert b394f91`); the scaffold commit is documentation-only. No new scripts, no new skills. The only behavioral change to existing runs is ship Step 1.5/8 — which now skips (with a note) instead of "running the project's test suite" for the 100% of flow projects today that have no test suite. That's strictly less surprising than the prior behavior (which had the LLM inventing a command each time).

The PR-body patch logic (Step 5 for existing PRs) is the one unresolved risk — see Adversarial read AGAINST and Suggestion 2.

## Decisions needed
- [x] Shape A is already resolved in the spec (`01-spec-r1.md:15`); no human decision needed at ship.
- [ ] **On the very first re-ship of this PR, verify that Step 5's patch-not-rewrite behavior doesn't clobber the `Post-merge verify` block.** The human reviewer should check the PR body diff between ship rounds and intervene if propagation misbehaves. This is a deliberate dogfood; record the observation in the spec's Revisions section for the follow-up workstream.

## Verify in reality

- [ ] Run `bash $HOME/.claude/skills/flow/scripts/load-config.sh` in a fresh clone after `make install` — confirm output includes `FLOW_TEST_CMD=''` on its own line, alongside the other four `FLOW_*` vars.
- [ ] Run `/flow-config` in a repo that has no `.flow/config.sh` — confirm 4 `AskUserQuestion` prompts appear, that question #2 is "Test command" with "None" as the (Recommended) first option, and that the written `.flow/config.sh` contains `FLOW_TEST_CMD=""` (not commented out).
- [ ] Run `/flow` through to ship on a docs-only change — confirm Step 1.5 surfaces "no test command configured for this project — skipping" in the transcript and Step 8 skips with the same message.
- [ ] Ship any change with a populated `Verify in reality` section — confirm the created PR body includes a `## Post-merge verify` block, each item as an unchecked `- [ ]` with text copied verbatim from the review.
- [ ] On a subsequent ship round for the same PR, tick one checkbox on GitHub first, then re-run ship. Confirm the ticked box is preserved in the patched body, and any new verify items from r2 are appended, not interleaved.
- [ ] Open a fresh review using `skills/review/references/findings-template.md` and confirm the four new sections (`Status`, `Decisions needed`, `Verify in reality`, `Ship Summary`) are in the expected positions and that the reviewer does not need to reorder them.
- [ ] Grep `skills/` and `commands/` after this PR merges for `Test plan` — confirm the old `## Test plan` PR-body header is gone from the ship HEREDOC (one match remains in the review doc, which is fine).

## Findings

### Critical

None. The thesis ships; the known gap is the patch-not-rewrite fuzziness flagged under Adversarial read, and it's explicitly tagged as a dogfood risk — not a blocker for a spike PR.

### Suggestions

1. **`bootstrap.sh` inlined precedence is a drift trap for future config fields.** `skills/flow/scripts/bootstrap.sh:23-34` has its own copy of the precedence logic with the comment `# Kept in sync with that script`. This PR does not touch `bootstrap.sh` because bootstrap doesn't need `FLOW_TEST_CMD`. Fine. But the pattern is "every new `FLOW_*` field lives in both places iff bootstrap needs it" — and there's no enforcement. A future field that both bootstrap and load-config need (e.g., `FLOW_WORKSTREAM_DIR`) will silently diverge if only one is updated. Not worth fixing here, but worth a `references/config.md` note that reads "If a new field is needed during bootstrap (before `.flow/config.sh` is writable), it must be added to `bootstrap.sh`'s inlined precedence block as well." File: `skills/flow/references/config.md:8-15`.

2. **Step 5's patch-not-rewrite contract needs a concrete algorithm.** `skills/ship/SKILL.md:131` says "preserve any checkboxes the user already ticked … only add new items, don't rewrite existing state." A future LLM executing ship on a re-opened PR has to choose: (a) diff the review's `Verify in reality` against the PR body's `## Post-merge verify` by item text, append unmatched new items, leave all existing lines alone; or (b) regenerate from the latest review and then post-patch ticked boxes back in; or (c) leave the block alone if it exists. Each has different failure modes. Recommend promoting the spec's mental model ("diff old body against new verify items; append new ones, leave existing ones (ticked or not) alone" — `01-spec-r1.md:53`) into the SKILL.md step body so the ship LLM doesn't have to re-derive it. Auto-fix candidate: copy the spec sentence verbatim into `skills/ship/SKILL.md` after line 131.

3. **Empty verify section behavior is partly covered.** `skills/ship/SKILL.md:116` says "If the review has no 'Verify in reality' items (or none remain unchecked), omit the section entirely." Good. But the HEREDOC template (line 121-128) still hard-codes the `## Post-merge verify` block. A ship LLM reading Step 5 in isolation might write the HEREDOC as-written and leave a stub `## Post-merge verify` with a dangling comment. Auto-fix candidate: rephrase the HEREDOC's `## Post-merge verify` line as a comment (`# Optionally: include a '## Post-merge verify' section …`) or add an explicit "if verify items exist" conditional in the surrounding prose.

4. **The test-cmd subagent detail disappeared from Step 1.5.** Pre-existing Step 1.5 said "run the project's test suite (via a subagent)". New Step 1.5 (`skills/ship/SKILL.md:31`) says "run it (via a subagent for long-running commands)". That qualifier — "for long-running commands" — is a new-to-this-PR hedge. A shell command like `bats tests/` is fast; `pytest tests/e2e/` is not. Leaving the subagent choice to the LLM is probably fine, but the prose could be tighter: "run it via a subagent" (unconditional) or drop the hedge and let the subagent heuristic apply. Nit-adjacent.

### Nits

1. **`commands/flow-config.md:22` says "Custom (user provides; any shell command — e.g. `pytest`, `go test ./...`, `bash scripts/tests/*.sh`)"**. The `*` inside a backtick prose block is fine; just flagging that `bash scripts/tests/*.sh` as an `FLOW_TEST_CMD` value will be glob-expanded at source-time by `.flow/config.sh`, not at run-time — so if someone literally writes `FLOW_TEST_CMD="bash scripts/tests/*.sh"` and sources the file, `FLOW_TEST_CMD` receives the space-joined expanded filenames, not the glob pattern. The example is cosmetically fine but subtly misleading. Prefer `bash scripts/run-tests.sh` as the example.

2. **Spec's Decisions-needed checklist uses `[x]` for items "resolved in this workstream"**. That's a valid reading of the template, but the findings-template's wording ("Mark `[x]` once resolved inline (noting the outcome), or `[ ]` if still open") strongly implies the checklist is for the *reviewer's ship-time* decisions, not a retrospective of what was decided upstream. Compare `agent/workstreams/2026-04-21-document-name/03-review-r1.md:24` — `[x] None flagged` is the convention. The spec is using the same section as a decision *log*. Not a bug; just a minor template-intent drift.

3. **`skills/flow/references/config.md:13`**: "Shell command ship runs **before and after** applying fixes (Steps 1.5 and 8)." Accurate. But Step 1.5 is *before* fixes, Step 8 is after — the "before and after" reads like "each fix is wrapped" on first glance. Tighter: "Shell command ship runs in Steps 1.5 and 8 (before fixes + after push)."

4. **Spike-log entry at 17:33:00 ("bootstrap path") names `bootstrap.sh` as unusable for warm-fresh mode.** Legitimate observation, but the entry lives in the spike-log only. The plan's Risks section also captures it. Suggest referencing the spike-log entry from the plan explicitly (e.g. "see spike-log 17:33 for rationale") so the reasoning trail is navigable from the plan alone. Already partly done at `02-plan-r1.md:14`, but the spike-log link is implicit.

### Questions

1. **What's the rollout story for projects that already have a `.flow/config.sh` missing `FLOW_TEST_CMD`?** `load-config.sh` handles it (empty default). But `/flow-config` is interactive — does running it on an already-configured repo rewrite the whole file, or does it detect the missing field and prompt only for that? `commands/flow-config.md:34-45` writes a fresh file each time; that means an existing config without `FLOW_TEST_CMD` will, after one `/flow-config` run, gain the field. That's fine but worth a note in `commands/flow-config.md` or `references/config.md`.

2. **Why is "Test command" question #2 rather than #4 (after the two v2.5-reserved fields)?** Arguable either way. Current ordering: Template → Test cmd → Extra stages → Hooks. The two reserved fields cluster at the end. A skeptic would argue Test cmd should go *last* among the active fields (which is currently position #2) since it's the most project-specific. Not a correctness issue; an ergonomics call. The spec doesn't discuss.

3. **Does `gh api ... -X PATCH -f body="…"` handle multi-line bodies with embedded backticks correctly?** The PR body is Markdown with code fences. `-f body="…"` in `gh api` is a form field; gh handles shell quoting, but multi-line with backticks inside `$(…)` subshells can mis-quote if the ship LLM writes the command as `-f body="$(cat review.md)"`. Recommend ship's example show `-f body="@file.md"` style instead of inlined `$()`.

## Error Handling

All three modified shell files (`load-config.sh`, `bootstrap.sh`, and the prose-level `ship/SKILL.md`) continue to use `set -euo pipefail`. `load-config.sh`'s new `env_test_cmd` capture line (`env_test_cmd="${FLOW_TEST_CMD:-}"`) uses the `:-` pattern, so it's safe with `set -u`. The `[[ -n "$env_test_cmd" ]]` override and `${FLOW_TEST_CMD:-}` default lines both handle unset-vs-empty correctly — verified by reading the script against the output in both a clean `/tmp/flow-test` repo and the flow repo itself.

One non-error-handling concern: if `.flow/config.sh` contains a syntax error (e.g., unquoted space in `FLOW_TEST_CMD=make test`), `source .flow/config.sh` under `set -euo pipefail` will bail the whole script. This is the documented behavior ("fails loudly", `references/config.md:3`) and matches the existing fields' behavior. Good.

One latent risk: the ship step uses `eval "$(…/load-config.sh)"`. If `FLOW_TEST_CMD` contains a value with `$` or backticks (e.g., `make test \$TARGET`), the `printf '%q'` escapes it safely for eval round-trip. Sanity-checked via `FLOW_TEST_CMD='echo $FOO' bash skills/flow/scripts/load-config.sh` producing `FLOW_TEST_CMD=echo\ \$FOO` which eval-assigns correctly.

## Test Coverage Gaps

No automated tests in this repo (intentional, captured by the plan's architecture decision #4). Manual smoke tests cover `load-config.sh` output shape. What remains unverified end-to-end:

1. **PR-body propagation never exercised.** The first real invocation is the PR that ships this feature. The Verify-in-reality checklist above covers the observations to make, but they're manual.
2. **`/flow-config` 4-question flow never dry-run.** The `commands/flow-config.md` edits are textual — no one has run the command to confirm `AskUserQuestion` is happy with the question shape (4 prompts, each with 3-4 options including a `(Recommended)` tag).
3. **The patch-via-`gh api` path for existing PRs has zero coverage.** The very first time this path runs will be during this workstream's own second ship round (if there is one).
4. **`bootstrap.sh` inline-precedence vs `load-config.sh` parity** is not covered by a diff test. A future drift would only surface when a field the user sets via env var behaves inconsistently across the two scripts.

Items (1)–(3) are the verify-in-reality items above. Item (4) is a standing "pattern-reuse" concern — see below.

## Pattern Reuse Opportunities

1. **`bootstrap.sh` and `load-config.sh` share an inlined-copy of precedence logic.** Pre-existing, called out in `bootstrap.sh:22-24`'s comment, and re-raised here because this PR adds a fourth field (`FLOW_TEST_CMD`) that exists in `load-config.sh` and not `bootstrap.sh`. If flow eventually grows a field that both need, the duplication becomes a real hazard. Options: (a) extract a sourceable `load-config-inline.sh` that both call; (b) accept the duplication and add a `shellcheck` or test that greps both files for the same field list. Deferred by the plan; acceptable for this round.

2. **"`FLOW_*` variable registration" is a four-touch change** every time a field is added: `references/config.md` table + example, `load-config.sh` (capture + override + default + emit = 4 lines), `bootstrap.sh` (maybe), and `commands/flow-config.md` (question + written file). A macro/generator isn't warranted at 5 fields, but at 8+ it will be. Flag for v3 reflection.

3. **`skills/review/references/findings-template.md` and recent review docs** have converged on the new section shape (`Status`, `Decisions needed`, `Verify in reality`, `Ship Summary`). Prior reviews were writing those sections by hand before the template had them. This PR closes the gap. Worth a one-line mention in the ship Step 3.5 summary: "findings template now matches recent review conventions — expect less template drift in future rounds."

## Files Changed

| File | Change |
|---|---|
| `agent/workstreams/2026-04-21-reflect-verify-and-test-cmd/01-spec-r1.md` | New spec; dogfoods the refreshed template (Status / Decisions / Verify in reality). |
| `agent/workstreams/2026-04-21-reflect-verify-and-test-cmd/02-plan-r1.md` | New plan; 13 numbered steps all marked `[x]`, with architecture decisions + explicit deferrals. |
| `agent/workstreams/2026-04-21-reflect-verify-and-test-cmd/spike-log.md` | New; 4 chronological entries (warm-fresh entry, branch-name choice, bootstrap-path deviation, reflect-scope deferral). |
| `commands/flow-config.md` | "3 questions" → "4 questions"; inserts "Test command" as question #2; writes `FLOW_TEST_CMD` into the generated `.flow/config.sh`. |
| `skills/flow/references/config.md` | Adds `FLOW_TEST_CMD` row to schema table; adds line to the example block. |
| `skills/flow/scripts/load-config.sh` | 4 lines added: env-capture, env-override, default, `printf '%q'` emission. |
| `skills/review/references/findings-template.md` | Adds `## Status`, `## Decisions needed`, `## Verify in reality`, `## Ship Summary` — all additive. |
| `skills/ship/SKILL.md` | Step 1.5 rewritten to branch on `FLOW_TEST_CMD`; Step 5 adds verify-items propagation + existing-PR patch path; Step 8 mirrors Step 1.5. |

## Quiz (prime human review)

1. Run `FLOW_TEST_CMD='echo $USER' bash skills/flow/scripts/load-config.sh` and predict the exact output line for `FLOW_TEST_CMD`. Does it preserve `$USER` as a literal or expand it? Why does this matter for ship Step 1.5's `eval` + subagent run?

2. In a repo whose `.flow/config.sh` contains `FLOW_TEST_CMD=""` and also has `FLOW_TEST_CMD="make test"` set in the user's shell environment, which value wins? Trace the precedence by reading lines 12, 14, 19-22, 26, and 36 of `load-config.sh`.

3. You re-ship a PR for a workstream whose r1 review had three unchecked `Verify in reality` items and whose r2 review has those same three items plus one new one. On GitHub, the user has ticked item #2. Per `skills/ship/SKILL.md:116,131`, what should the patched PR body's `## Post-merge verify` look like after re-ship? Name at least one way the current prose is ambiguous enough that two different ship LLMs would produce different answers.

4. Open `skills/flow/scripts/bootstrap.sh` lines 22-34. Explain why adding `FLOW_TEST_CMD` to `load-config.sh` did NOT require a parallel edit here, but why `FLOW_TEMPLATE_SPEC` does appear in both. What's the contract that decides?

5. Read the spec's Out-of-scope section (`01-spec-r1.md:45-48`) and the spike-log's 17:45 entry. Without those two artifacts, where else in the workstream would a reader find out that `/flow-reflect` reshape was considered and deferred? Is that trail robust to someone searching only by `grep -r "flow-reflect" skills/ commands/`?
