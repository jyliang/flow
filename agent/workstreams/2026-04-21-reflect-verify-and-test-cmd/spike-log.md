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
