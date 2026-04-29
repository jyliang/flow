<!-- branch: flow-spike · date: 2026-04-21 · author: Jason Liang · pr: -->

# Spec: `/flow-spike` — enter from any conviction point (r2)

## Revisions
- **implement → spec** 2026-04-21: Broadened the entry contract. r1 modeled `/flow-spike` as a fresh-workspace verb taking a thesis argument; user clarified it should be invokable **mid-conversation at any stage**, whenever the human has enough conviction at a particular point to let the LLM run the rest unattended.
  **Why**: the primary use case is "we've been discussing this for 30 messages; take it from here." Forcing the human to restart + re-type a thesis throws away the conversation context that already contains everything spike needs.
  **Impact**: `commands/flow-spike.md` accepts empty `$ARGUMENTS`; the LLM synthesizes the thesis from conversation context when missing. `skills/spike/SKILL.md` gains a "Conversation absorption" section and a stage-entry matrix. The fresh-thesis path still works unchanged — this revision adds entry modes, doesn't remove any. r1's abort conditions and safety rails are unchanged.

## Status
explore → plan (revision)

## What was done
- Picked up r1's design; refined the entry contract based on user feedback (2026-04-21).
- Mapped the three scenarios spike should handle and the one behavior that covers them.
- Kept r1's core unchanged: single LLM-review round, decision policy, adversarial read, quiz, draft-only safety rails, audit log. Only the ingress is different.

## Decisions needed (committed, flag for redirect)
- [x] **Thesis is optional**: if `$ARGUMENTS` is empty, LLM distills a one-sentence thesis from conversation context. If non-empty, `$ARGUMENTS` wins (explicit override). Either way, the thesis gets recorded verbatim in the spec + audit log + PR body.
- [x] **Stage entry is detected, not declared**: spike reads the current branch's workstream (if any) via `detect-stage.sh` and picks up from wherever detection lands. No `--from-stage` flag.
- [x] **Existing workstream = resume, not refuse**: if the user is on a branch with a partial workstream from prior `/flow`, spike takes over from the detected stage. The decision policy kicks in immediately; prior `AskUserQuestion` decisions already answered by the human stay answered.
- [x] **Audit log seeds with context**: the first entry in `spike-log.md` when spike enters mid-conversation is `[<timestamp>] entry: adopted from conversation at message N`, with a short summary of the context it absorbed. This makes the entry mode auditable during human review.

## Verify in reality
- [ ] Fresh workspace + thesis arg: `/flow-spike "validate X"` behaves exactly like r1.
- [ ] Fresh workspace + no thesis: LLM distills thesis from conversation, continues unattended.
- [ ] Mid-workstream (partial spec only): LLM picks up at plan stage, uses existing spec, continues unattended. Audit log records "adopted existing workstream at plan stage".
- [ ] Mid-workstream (plan complete, implementing): LLM picks up at implement stage. Decision policy applies to any remaining AUQs.
- [ ] Confirm parallel runs on different branches still don't collide (workstream folders are per-branch).

## Spec details

### Problem

r1 required a specific invocation shape: `/flow-spike "<thesis>"` in a clean workspace. That's one valid entry, but not the most common one — the common case is:

> "We've been talking about X for a while. I'm convinced enough. Go build it and come back with a draft PR."

Forcing the user to re-type the thesis + start over throws away context and creates friction. The feature exists to SAVE human time; requiring a clean restart undoes that.

### Three entry scenarios, one behavior

| Scenario | State | Spike's entry action |
|---|---|---|
| **Cold** | Empty workspace. User passes `$ARGUMENTS` as thesis. | Original r1 path. Create branch, materialize workstream, run full pipeline. |
| **Warm (fresh branch, no workstream)** | Branch has no workstream folder. Conversation has rich context. | LLM distills thesis from conversation. Create workstream, materialize `01-spec-r1.md` with distilled content + any existing conversation decisions, run full pipeline. |
| **Warm (existing workstream)** | Branch has a partial workstream from prior `/flow` work. | Don't create a new workstream. Read current state via `detect-stage.sh`; decision policy takes over from that stage forward. Prior human answers to AUQ already in docs are preserved. |

All three end at the same place: a draft PR with the 7-section review package, `spike-log.md` capturing every auto-decision, and the workstream folder updated.

### Design

#### Command body (`commands/flow-spike.md`)

New logic before invoking the skill:

1. If on a branch named `main` (or the repo default), refuse — spike must run on a feature branch. (Matches existing safety rail "no main touches".)
2. Run `detect-stage.sh` to determine current state.
3. If workstream exists (detect-stage returned a non-`explore-empty` stage): **resume**. Skip bootstrap; let the skill pick up.
4. Otherwise: **fresh or warm-fresh**:
   - If `$ARGUMENTS` non-empty, thesis = `$ARGUMENTS`.
   - If empty, LLM synthesizes a one-sentence thesis from conversation context, then confirms by writing it to the audit log's first entry.
   - Compute branch name via `spike-branch.sh`.
   - Run `bootstrap.sh` to create branch + workstream.
   - Materialize `spike-log.md` with seeded context.
   - Run explore with the distilled content populating `01-spec-r1.md`.

#### Skill (`skills/spike/SKILL.md`)

Add a new section "Conversation absorption" describing the three scenarios and the detection logic. Keep all other sections (decision policy, stage-by-stage, adversarial read, abort protocol, safety rails) unchanged.

Add one rule to "Decision policy": when adopting mid-workstream, spike does NOT retroactively override already-resolved decisions in the spec/plan. It only applies to new decisions from this point forward.

#### Audit-log seeding

When spike enters from a mid-conversation state, the first `spike-log.md` entry is a synthetic one:

```
### [<timestamp>] entry: adopted from conversation
- **Context**: Conversation was mid-<stage>. Key points absorbed: <3-5 bullets>.
- **Thesis (synthesized)**: <LLM's one-sentence read of what we're validating>
- **Starting stage**: <plan | implement | review | ship>
```

This makes the entry point visible during human review.

### Impact analysis

**Files to modify:**
- `commands/flow-spike.md` — entry logic per above. `$ARGUMENTS` optional.
- `skills/spike/SKILL.md` — new "Conversation absorption" section; small tweak to decision policy for the resume case.

**Files NOT touched:**
- `spike-branch.sh` — still takes a thesis string. LLM supplies it.
- `bootstrap.sh` — unchanged (still creates workstream fresh; resume case skips this script entirely).
- Templates (`pr-body.md`, `spike-log.md`) — unchanged; new first-entry format is LLM-authored per the skill.

### Constraints

- **No code change to detect-stage.sh** — the skill uses it as-is.
- **Branch-name continuity** — in resume mode, the branch name is already set; spike doesn't rename. In warm-fresh mode, `spike-branch.sh` produces `spike-<slug>`. This means a resumed non-`spike-` branch (e.g., `foo-feature`) stays `foo-feature`; the workstream folder retains whatever prefix it already had. Acceptable.
- **Safety rails unchanged** — draft PR only, no main touches, step-count ceiling, etc. all carry over.

### Open questions

1. **What if the branch is `main`?** Lean: refuse loudly. Covered in design, confirmed above.
2. **If thesis synthesis is genuinely ambiguous** (conversation is too broad), does spike ask or abort? Lean: abort per the existing protocol — "fundamentally unclear thesis" is already a documented abort trigger. Human retries with explicit `$ARGUMENTS`.
3. **Does the resume case re-run the adversarial LLM-review** if findings already exist on the branch? Lean: yes, always. One LLM-review round is the contract; spike doesn't trust prior LLM reviews without re-running adversarially.
