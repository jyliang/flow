# Review: `/flow-spike` spike-mode flow

**Branch**: `flow-spike` (diff main...HEAD)
**Date**: 2026-04-21
**Reviewer**: Claude Code

## Summary

Spike is a well-designed spike-mode orchestration that unattends the flow pipeline (explore → plan → implement → LLM-review → draft PR) for thesis validation. The spec, plan, and implementation are internally consistent and clear on vocabulary. Key strengths: robust abort protocol, explicit adversarial-review guidance, and safety rails around draft status. 

**Critical risk identified**: AskUserQuestion interception mechanism relies entirely on LLM read-and-obey behavior. No structural guarantee prevents the LLM from pausing on AUQ despite explicit instruction. Recommend: either accept this risk or add a Skill-tool invocation wrapper. Detailed findings follow.

---

## 1. Decision-Policy Correctness & AUQ Interception

### Finding: Interception is behavioral, not structural

**Risk Level**: Medium (mitigated by strong wording, but not foolproof)

The decision policy is stated clearly in `skills/spike/SKILL.md:30-38` (skills/spike/SKILL.md:30):
- Pick `(Recommended)` option, else first
- Log to `agent/spike-log.md`
- Continue without pausing

And echoed in `commands/flow-spike.md:1` (top): "Do NOT interrupt the user at any point during this run."

**However**, the interception works at the LLM behavioral layer, not a structural one:
- Stage skills (explore, plan, implement, review, ship) contain `AskUserQuestion` calls in their bodies.
- Spike does not modify those skill bodies.
- The spike command/skill says "when you would call AskUserQuestion, apply the decision policy instead."
- The LLM must read this instruction, recognize every `AskUserQuestion` in a stage skill invocation, and substitute the decision policy.

**Vulnerability**: If the LLM invokes a stage skill directly (e.g., `/explore` or via Skill tool) without wrapping it in a context that says "you are in spike mode, intercept AUQ," the LLM could fall through to the normal flow and pause on the first AUQ.

**Evidence**:
- `skills/flow/references/user-interaction.md:27` correctly documents "spike intercepts at the orchestration layer," which is accurate but non-binding on an LLM that invokes the underlying skill bodies.
- `agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md:97` acknowledges this design ("stage skill bodies have `AskUserQuestion` calls; spike's decision policy intercepts at the LLM level").

### Mitigations in place

1. The spike command explicitly states "Do NOT interrupt" (line 5).
2. `skills/spike/SKILL.md` is clear on the policy at the top (line 30).
3. The `commands/flow-spike.md` narration says "Run the explore skill with the decision policy intercepting" (line 15), which signals the LLM's role.
4. All major decision points (explore, plan, implement, review boundaries) are listed in the skill guidance.

### Recommendation

**Accept this risk with reinforcement**. The instruction is sufficiently strong that a compliant LLM will execute correctly. If you want structural guarantees, consider:
- Wrapping stage-skill invocations in a Skill-tool call that enforces spike mode (e.g., a pseudo-skill `_run_stage_spike(explore)` that blocks AUQ at the tool level).
- Or: modify stage skills to accept an `--spike` flag that disables AUQ (breaks the "stage skills unchanged" design principle, not recommended).

Current approach is acceptable for spike mode; the cost of a miss (user interruption mid-spike) is a pause rather than data loss.

---

## 2. Abort Protocol Robustness

### Finding: Well-specified, no race conditions detected

**Risk Level**: Low

The abort protocol is comprehensive. From `skills/spike/SKILL.md:87-100`:
- Conditions: step-count ceiling, tests still failing after fix, unclear thesis, tool errors.
- Actions: commit outstanding work, open draft PR with `[SPIKE ABORTED]` title, explain reason, skip Quiz/Next moves sections.

**Evidence**:
- Abort happens *before* ship stage, so the branch is materialized but unreviewed.
- Draft status ensures the PR doesn't auto-merge.
- All three abort paths (step cap, test fail, tool error) lead to "commit + PR," no partial states.

**Verified**: The `commands/flow-spike.md:25` explicitly says "still opens a draft PR, titled `[SPIKE ABORTED]`," covering the no-silent-exit principle.

**No gaps found**: Each abort condition is actionable by the LLM; none require external intervention that could deadlock.

---

## 3. Adversarial Review Integrity

### Finding: Instruction is strong but depends on subagent discipline

**Risk Level**: Low-to-medium (mitigated by explicit anti-pattern section)

The adversarial read is mandated in `skills/spike/SKILL.md:64-68`:
- Four explicit internal questions before writing "What the spike shows"
- Grounded in evidence, not hypothetical

The anti-pattern section (`skills/spike/SKILL.md:78-84`) is **excellent**:
- Explicitly warns against rubber-stamp confirmation
- Requires: "If the LLM-review subagent cannot name strong evidence *against* the thesis, the 'What the spike shows' section should say so explicitly."
- This is more useful than false confidence.

**Potential gap**: The instruction assumes the LLM-review subagent will honestly try to falsify the thesis. An LLM that is motivated to "confirm" the work it just built could still find weak counter-evidence and bury it under stronger pro-evidence.

**Mitigations**:
- The PR body template (`skills/spike/templates/pr-body.md:25-29`) includes a comment: "MUST cover: Strongest evidence FOR, strongest evidence AGAINST, what would falsify, what skeptical reviewer would push back on." This is in the template the LLM fills, so it's a reminder at fill time.
- The Quiz section (`skills/spike/templates/pr-body.md:36-42`) is authored by the review stage and should probe assumptions adversarially.

**Recommendation**: No change. The instruction is strong enough. Human review is the backstop; if the LLM review is dishonest, the human will catch it (that's why it's draft, not ready).

---

## 4. Script Edge Cases

### Finding: Script is robust; minor semantic issue identified

**Risk Level**: Low

The `spike-branch.sh` script handles:
- **Unicode normalization**: `café` → `caf-r-sum-` (loses accents via `tr -c 'a-z0-9-'`). This is acceptable for branch names; branch names are ASCII-safe this way. ✓
- **Long theses**: Truncates at 40 chars slug, appends timestamp. "validate that the new approach is way faster..." → `spike-validate-that-the-new-approach-is-way-fa-<timestamp>`. Clean. ✓
- **Empty thesis**: Exits with code 2, usage message. ✓
- **Multiple colons/hyphens**: Normalized to single hyphens via `sed -E 's/-+/-/g'`. ✓

**Tested manually**:
```
spike-test-unicode-caf-r-sum-20260421-1047  ✓
spike-validate-that-the-new-approach-is-way-fa-20260421-1047  ✓
spike-hello-world-20260421-1047  ✓
(empty) → usage error  ✓
```

**Semantic observation**: Very long theses like "validate that the new approach is way faster than the old one which we should deprecate soon" get truncated to `spike-validate-that-the-new-approach-is-way-fa-<timestamp>`, losing semantic clarity. The timestamp ensures uniqueness, but the slug becomes less meaningful. This is acceptable tradeoff for branch names, but worth noting: **a user might kick off `/flow-spike` with two very similar long theses and get confusingly similar branch names**. Recommend: user responsibility (keep theses concise), not a script fix.

---

## 5. Safety Rails Enforceability

### Finding: All rails are LLM-enforced; only draft status is structural

**Risk Level**: Medium (acceptable for unattended LLM work)

The safety rails (skills/spike/SKILL.md:102-110):
1. **Draft PR only** — `gh pr create --draft`. Never `gh pr ready`, never merge.
2. **No main touches** — never push/rebase to main.
3. **No force push** — make new commits instead.
4. **No reflection** — skip `/flow-reflect`.
5. **Clean branch** — refuse if `agent/spec.md` exists.
6. **Audit log append-only**.

**Structural guarantees**:
- `gh pr create --draft` sets draft status structurally. GitHub does not auto-promote a draft PR to ready unless explicitly called. ✓

**LLM-enforced rules**:
- Rules 2–6 depend on the LLM not calling `git push origin main`, `git push --force`, etc.
- The command and skill explicitly warn against these ("HARD rules" in commands/flow-spike.md:21-22).

**Vulnerability**: `gh pr create` has no built-in flag to prevent auto-merge settings. If the repo has auto-merge enabled by default on draft PRs, the PR could merge automatically. **Unlikely but worth noting**: most repos don't auto-merge drafts by default, and the command says "never `--auto`," implying the LLM should not set it.

**Recommendation**: Acceptable. The draft status is structural; the others are LLM-enforced and clearly documented. If you want stronger guarantees, a pre-flight check (`gh repo view <repo> --json=autoMerge`) could verify the repo doesn't auto-merge drafts, but that's defense-in-depth.

---

## 6. Terminology Audit: "Review" Ambiguity

### Findings: Vocabulary is tight within spike; spec-level clarity is good

**Risk Level**: Low

Searched for bare "review" in spike artifacts:

**In `skills/spike/SKILL.md`**:
- Line 20: "**LLM review**: the `review` skill" — qualified ✓
- Line 21: "**Human review**: happens on the draft PR" — qualified ✓
- Line 23: "Anywhere this skill says bare 'review'...should be rewritten" — meta-instruction ✓
- Line 59: "### LLM review" — heading is qualified ✓
- Line 61: "Use the normal `review` skill" — context is clear ✓
- Line 62: "Do NOT re-run LLM review" — qualified ✓
- Line 63: "flagged for human review" — qualified ✓
- Line 74: "Never `gh pr merge`. Those are human-review decisions" — qualified ✓
- Line 78: "## Adversarial-review anti-pattern" — qualified ✓

**In `commands/flow-spike.md`**:
- Line 18: "1 LLM-review round" — qualified ✓

**In `skills/spike/templates/pr-body.md`**:
- Line 3: "awaiting human review" — qualified ✓
- Line 5: "Human review is the only human touchpoint" — qualified ✓
- Line 25 comment: "Adversarial thesis read produced by LLM-review" — qualified ✓

**In spec/plan**:
- Consistent use of "LLM-review" and "human review" throughout. ✓

**Conclusion**: Vocabulary is tight. Zero instances of bare "review" in a context where it's ambiguous. The meta-instruction in SKILL.md:23 is a good hedge.

---

## 7. Spec/Plan Alignment

### Finding: Complete alignment; all spec decisions implemented

**Risk Level**: None

Checking spec decisions (agent/spec.md: Decisions needed section, lines 13-19) against implementation:

| Spec Decision | Plan Addressed | Implementation | Status |
|---------------|----------------|-----------------|--------|
| LLM-review depth (single round, no loop) | agent/plans line 13 | SKILL.md:61-62 | ✓ |
| Audit log in `agent/spike-log.md` | agent/plans line 14 | SKILL.md:36, templates/spike-log.md | ✓ |
| Recommended-option fallback | agent/plans line 15 | SKILL.md:34-35 | ✓ |
| Reflection skipped | agent/plans line 16 | SKILL.md:76, commands line 20 | ✓ |
| Runtime ceiling (≤20 steps, no wall-clock timeout) | agent/plans line 17 | SKILL.md:51 | ✓ |
| Terminology (LLM review / human review) | agent/plans line 18 | SKILL.md:19-23, user-interaction.md:27 | ✓ |

**Verify in reality** (spec line 21-25):
- [ ] End-to-end pipeline without interrupts — not yet validated (requires live spike run)
- [ ] Adversarial review honesty — instruction is strong, human review is backstop
- [ ] Draft status sticks — confirmed for GitHub behavior
- [ ] Parallel spike runs don't collide — timestamps + git isolation should handle this

**Conclusion**: Spec and plan fully implemented; verify items are either blocked on live testing or deferred to human review.

---

## 8. Additional Observations

### LLM-review quiz authorship clarity
- `skills/spike/SKILL.md:69` says "produce 3–5 quiz questions" after the adversarial read.
- `agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md:13` clarifies: "LLM-review stage" authors them (because it has the end-to-end view).
- This is correct and well-specified. ✓

### Abort on existing spec.md
- `agent/plans/IMPLEMENTATION_PLAN_2026-04-21.md:14` says refuse like bootstrap.sh, force a new branch.
- `skills/spike/SKILL.md:108` says "refuse if `agent/spec.md` already exists."
- This prevents accidents (overwriting prior spike artifacts). ✓

### PR title truncation to 60 chars
- Spec (line 115 of IMPLEMENTATION_PLAN) and SKILL.md:73 both say `<thesis-first-60-chars>`.
- This is enforced at ship time (LLM responsibility, not scripted).
- Acceptable; the user-provided thesis is the source of truth.

---

## Risk Summary Table

| Area | Risk | Severity | Mitigation | Acceptability |
|------|------|----------|-----------|---|
| AUQ interception (behavioral, not structural) | LLM could miss instruction and pause | Medium | Strong wording + LLM discipline | Accept (spike-mode OK with brief pause) |
| Abort protocol race | Branch half-done with no PR | Low | All abort paths commit + open PR | Acceptable |
| Review rubber-stamping | LLM-review confirms thesis without real evidence | Low-Medium | Anti-pattern section + human review backstop | Acceptable |
| Script edge cases (long theses) | Branch names lose meaning | Low | Timestamp ensures uniqueness; user responsibility for concise thesis | Acceptable |
| Safety rails (draft-only, no force-push) | LLM could accidentally violate | Medium | Draft status is structural; others are LLM-enforced | Acceptable (no structural escape) |
| Terminology ambiguity | "Review" conflated with LLM/human | Low | Vocabulary is tight throughout artifacts | Non-issue |
| Spec/plan alignment | Implementation misses spec intent | None | Full traceability verified | Complete |

---

## Conclusion

The `/flow-spike` feature is **ready to ship**. The design is sound, specifications are clear, and safety rails are appropriately enforced for a tool that runs unattended by design. The primary risk — AUQ interception — is behavioral rather than structural, but the instruction is strong enough to mitigate for a spike-mode tool where a brief pause is not catastrophic.

Key strengths:
- Clear two-review vocabulary ("LLM review" vs "human review")
- Robust abort protocol that never leaves the branch in limbo
- Strong adversarial-review anti-pattern guidance
- Draft-status structural guarantee prevents accidental merge

Recommend: ship as-is, then monitor first few spike runs for unexpected AUQ pauses (suggesting the interception instruction wasn't clear enough).

