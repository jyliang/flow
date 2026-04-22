# Spike decision log

_Branch_: reflect-verify-and-test-cmd
_Thesis_: Reflection surfaced three cross-workstream drifts (verify items orphaned, findings template stale, ship test command repo-specific); applying Shape A (PR-body propagation + FLOW_TEST_CMD config) addresses the first two without adding ceremony, and formalizing this session as a spike dogfoods the "reflection outputs go through the pipeline" principle.
_Started_: 2026-04-21T17:30:00-04:00

Every auto-answered decision during this spike run is appended below, chronologically, by the LLM. Committed per implement-step so the human-review timeline is visible in `git log`.

## Decisions

### [2026-04-21T17:30:00-04:00] entry: warm-fresh
- **Context**: User invoked `/flow-spike` from a conversation where reflection had already produced 5 in-session edits on `main`. Entry mode is warm-fresh (stage `explore-empty` for this new branch; conversation is the source material). Spike's job is to retroactively package the ad-hoc work as a workstream + draft PR.
- **Thesis (synthesized)**: see top of file.
- **Starting stage**: explore (warm-fresh — distill the conversation into `01-spec-r1.md`).

### [2026-04-21T17:32:00-04:00] explore: branch name
- **Context**: Normally `spike-branch.sh` produces `spike-<slug>`. Here the user had already requested "finish the work here", implying a descriptive branch matching the prior workstream naming convention (kebab-case, no `spike-` prefix). The ad-hoc edits were already staged on `main` and needed to be carried to a feature branch before anything else.
- **Options**:
  1. `reflect-verify-and-test-cmd` (Recommended) — short kebab-case; mirrors the three touched surfaces (verify propagation + FLOW_TEST_CMD + template refresh).
  2. `spike-reflect-pipeline-findings` — follows `spike-<slug>` convention but reads as jargon.
  3. `flow-reflect-v1-apply` — ties to reflection framing but over-specific to v1.
- **Chose**: `reflect-verify-and-test-cmd`
- **Why**: Descriptive, matches prior workstream-folder convention, explicit about the two user-facing features being added.

### [2026-04-21T17:33:00-04:00] explore: bootstrap path
- **Context**: `bootstrap.sh` does `git checkout -b "$branch"` which fails if the branch already exists. Since the dirty tree needed to carry onto a feature branch before any scripted step, the branch had to be created manually first — making `bootstrap.sh` unusable as-is.
- **Options**:
  1. Manual scaffold: `git checkout -b <branch>`, `mkdir -p agent/workstreams/<date>-<branch>`, write `01-spec-r1.md` from the template by hand (Recommended).
  2. Stash → run `bootstrap.sh` on a clean `main` → pop the stash onto the new branch — would work but adds two stash operations and the bootstrap template substitution is trivial to do inline.
- **Chose**: option 1 (manual scaffold).
- **Why**: One command fewer; the template is 27 lines of markdown with three `{{PLACEHOLDERS}}` — manual substitution is cheaper than bootstrap's extra git moves. Flagged as a bootstrap.sh gap in the review's `Pattern Reuse Opportunities`.

### [2026-04-21T17:45:00-04:00] plan: scope boundary for "reshape /flow-reflect itself"
- **Context**: User's later observation — "reflection should generate ideas that feed through /flow instead of applying ad-hoc" — is a real design change to `commands/flow-reflect.md` + `skills/flow/references/reflection.md`. Including it in this workstream would roughly double the diff and mix two concerns (apply the reflection's outputs vs. reshape reflection's own protocol).
- **Options**:
  1. Ship Shape A changes only; defer the reflect-skill reshape to a follow-up workstream (Recommended). Lets this PR stay focused on what was already built in-session.
  2. Bundle the reflect reshape into this workstream — one PR with both fixes plus the protocol change.
- **Chose**: option 1.
- **Why**: Keeps the PR legible under review; the reshape deserves its own spec + plan because it changes a user-facing command contract. The deferral is explicit in the spec's "Decisions needed" and "Out of scope".

### [2026-04-21T18:05:00-04:00] review: auto-fix classification
- **Context**: LLM-review produced 0 critical, 4 suggestions, 4 nits, 3 questions. Per spike protocol, one auto-fix pass on mechanical + critical findings only; residuals flagged for human review.
- **Options**:
  1. Auto-fix all 8 non-question findings in one pass — some of them (S2 promote Step 5 algorithm, S3 HEREDOC conditional) involve design choices, not just typo-correction. Risky to mechanize.
  2. Auto-fix only the purely-mechanical findings (S1 drift-trap note, S4 subagent hedge, N1 example command, N3 prose tightening); flag S2, S3, N2, N4 and Q1–Q3 for human review (Recommended).
- **Chose**: option 2.
- **Why**: Matches the spike-protocol rule "auto-fix mechanical + critical, flag the rest." S2/S3 require picking between three candidate patch-algorithms and rewriting a template block — judgment calls that belong in human review. The four mechanical fixes are each one-line text swaps with obvious correct targets.

### [2026-04-21T18:08:00-04:00] review: applied auto-fixes
- **Context**: Applied the four mechanical fixes from the prior decision.
- **Fixes**:
  - `skills/flow/references/config.md`: tightened "before and after applying fixes" wording (N3); added the drift-trap note about `bootstrap.sh` inlined precedence (S1); swapped `bash scripts/tests/*.sh` example to `bash scripts/run-tests.sh` (N1).
  - `commands/flow-config.md`: swapped the same glob-prone `bash scripts/tests/*.sh` example to `bash scripts/run-tests.sh` (N1).
  - `skills/ship/SKILL.md`: dropped "(via a subagent for long-running commands)" hedge; now unconditionally "run it via a subagent" (S4).
- **Residuals flagged for human review**:
  - S2: Step 5's patch-not-rewrite algorithm needs to be promoted from spec into SKILL.md; three candidate approaches exist, not mechanical.
  - S3: Empty-verify HEREDOC conditional — needs template-block rewrite.
  - N2: Spec's `[x]` convention in Decisions-needed section — debatable, no single right answer.
  - N4: Cross-link from plan Risks to spike-log entry — optional polish.
  - Q1–Q3: Quiz-oriented questions, meant to prime human review; not findings to fix.
