<!-- branch: code-pipeline-reflect · date: 2026-05-06 · author: Jason Liang · pr: -->

# Spec: code-pipeline-reflect · explore → plan

> **What:** A prioritized improvement backlog for the `code-pipeline` cell, drawn from recent conversation friction, shipped-thread patterns, and a cell self-audit.
> **Why:** Friction has accumulated since the install-path unification (`4987ec9`) and the picker cleanup (`832f168`); the cell's own docs, templates, and disciplines now lag behind the conventions threads actually use.

## Scope

This thread delivers a triaged backlog in this spec; plan stage picks which slice ships next. In-scope: artifacts under `cells/code-pipeline/**` and the explore↔plan↔implement↔review↔ship contract those artifacts express. Out of scope: install/marketplace scripts (`scripts/install.sh`, `scripts/cell-link.sh`, `scripts/doctor.sh`) and kernel-level docs (`runtime/kernel/run/**`) — separate threads.

| File / area | Risk | Why it's in scope |
|---|---|---|
| `cells/code-pipeline/templates/spec.md` | low | Template missing lede placeholders + `## Revisions` slot — first-draft drift across every thread. |
| `cells/code-pipeline/stages/explore/explore.md` | low | Silent on warm-fresh / conversation-derived specs (the `flow:here` path); no escape for "small change, review-only" threads. |
| `cells/code-pipeline/stages/plan/plan.md` + `plan-template.md` | low | No branch for `FLOW_TEST_CMD=""` repos; same caveat re-derived in 4+ shipped plans. |
| `cells/code-pipeline/stages/review/review.md` | medium | Step 3 specialists miss a "Reference Resolver" — the docs-readability review proved this catches Critical findings. |
| `cells/code-pipeline/stages/review/findings-template.md:63` | low | Stale `ship/SKILL.md` ref; should be `stages/ship/ship.md`. |
| `cells/code-pipeline/disciplines/tdd.md` | low | Missing "no test framework" branch; plans keep re-inventing it inline. |
| `cells/code-pipeline/disciplines/*` (visibility) | low | Disciplines never cited in any thread artifact — invisible signal of whether they're applied. |
| `.flow/config.sh` (per-project, gitignored) | low | Stale `FLOW_TEMPLATE_SPEC=$HOME/.claude/cells/...` blocks `bootstrap.sh` on this machine. Surface as a doctor check, not a code edit. |

## Decisions

Resolved during explore — captured as one-liners.

| Question | Conclusion |
|---|---|
| How wide a conversation scan? | Recent ~2 weeks (Apr 22–May 6) plus shipped thread artifacts. Older sessions give diminishing signal. |
| Branch name? | `code-pipeline-reflect` — frames the work as reflection/retro, not a feature. |
| Is this one PR or many? | **One PR** bundling Groups 1–5; cell version moves `0.2.0 → 0.3.0`. |
| Reference Resolver lint scope? | Stage docs only (`cells/code-pipeline/stages/**`). Commands linting deferred to a sibling thread. |
| `## Disciplines applied` checklist enforcement? | **Soft** — omittable for trivial threads; review does not fail if missing. |
| Are install-script themes (Theme A from the conversation scan) in scope? | No — repo-root scripts ship through a different surface than the cell. Defer to a sibling thread. |
| Are kernel changes (e.g. `references/user-interaction.md`) in scope? | No — kernel evolution flows through `/flow:reflect` against the kernel doc, not through this cell-thread. |

## Design

Treat the backlog as five tightly-scoped change groups, ranked by impact × effort. Each is independently shippable; plan stage decides how many to sequence into a single PR vs. split.

**Group 1 — Spec template alignment (highest impact, lowest risk).** `templates/spec.md` currently has empty section headers; `cells/code-pipeline/stages/explore/explore.md` § *How to produce the spec* describes the *richer* shape with `[One-sentence lede]` placeholders. Bring the template up to match the doc, add an optional `## Revisions` placeholder, and align section names with the `(resolved/open)` annotation pattern that 7 of 11 historical specs invented inline. Evidence: every revised thread (`document-name`, `flow-spike`) had to invent placement of the revisions section; every recent spec writes ledes by hand because the template doesn't seed them.

**Group 2 — Explore stage doc: warm-fresh + escape hatch.** `explore.md` only describes "study source code → write spec." Two recurring paths are missing: (a) conversation-derived specs (the `/flow:here` warm-fresh path — `spike.md:38` documents this for spike but explore doesn't), and (b) small/housekeeping changes that legitimately skip explore+plan (`2026-04-17-flow-skill-refactor/` shipped review-only and self-flagged the gap). Add two short sub-sections.

**Group 3 — `disciplines/tdd.md`: empty-`FLOW_TEST_CMD` branch.** Four shipped plans (`auto-bump-marketplace-version`, `prefer-askuserquestion`, `flow-v1-adopt`, `flow-v2-config`) carry near-identical "no test framework, smoke-tests in shell" caveats inline. Move that into `tdd.md` as a documented branch; add one line to `plan.md` Step 2 that points at it. Removes 4× duplicated prose, gives implement.md a defined behavior when `FLOW_TEST_CMD=""`.

**Group 4 — Review stage: Reference Resolver specialist.** `review.md` Step 3 launches parallel specialists. Add a fourth that grep-validates step-numbers (`Step \d`, `Step N.M`), section-name backticks (``Step 7.5``, ``"Conversation absorption"``), and file paths in stage docs and commands. Evidence: `2026-04-22-docs-readability/03-review-r1.md` Critical findings #1–4 are entirely this class; `2026-04-21-reflect-verify-and-test-cmd/03-review-r1.md` Suggestion #1 is the same. Lowest effort to ship; biggest payoff per review.

**Group 5 — Stale ref + visibility cleanups.** Fix `findings-template.md:63` (`ship/SKILL.md` → `stages/ship/ship.md`). Add a one-line "Disciplines applied" checklist to `plan-template.md` so threads either cite or skip each discipline — eliminates the "invisible signal" surprise.

## Constraints

Hard rules and guardrails for this thread.

- **DO NOT** modify install scripts, marketplace registration, or kernel-level docs in this thread — explicitly out of scope (see Decisions).
- **DO NOT** rewrite historical thread artifacts under `agent/threads/*` — they are frozen records; only forward changes to templates/docs.
- **DO** preserve every existing rule and section in stage docs verbatim; this is restructuring + adding, not pruning. The docs-readability thread's "no new content during a readability pass" rule applies.
- **DO** keep each group's diff small enough to read in one sitting. If Group 4 grows beyond one specialist worth of prose, split it.
- **Cell version bump:** `cell.yaml` version moves from `0.2.0` → `0.3.0` only if Groups 1–4 ship together; a single-group PR bumps to `0.2.1`.

## Verification

What must hold after the change ships.

- [ ] Every section in `templates/spec.md` has either a lede placeholder or remains intentionally bare with a comment explaining why.
- [ ] `templates/spec.md` includes an optional `## Revisions` slot with a one-line usage note.
- [ ] `explore.md` covers (a) warm-fresh entry and (b) review-only/housekeeping escape hatch — each in ≤6 lines.
- [ ] `disciplines/tdd.md` has a "When `FLOW_TEST_CMD` is empty" sub-section; `plan.md` Step 2 references it.
- [ ] `review.md` Step 3 lists a Reference Resolver specialist with a one-line job description and target patterns.
- [ ] `findings-template.md` no longer references `ship/SKILL.md`.
- [ ] `plan-template.md` has a "Disciplines applied" checklist (`tdd`, `commits`, `parallel`, with `n/a` allowed).
- [ ] `make lint-docs` (existing) passes.
- [ ] A dry-run of `/flow:flow` from this branch detects stage correctly and finds the new template.

## Open

Items deferred to sibling threads or future work.

- **Bigger asks queued for separate threads:** quiz-mode review (asked twice in conversations), reflect-as-flow re-entry (`/flow:reflect` running through the pipeline), n8n-style modular step import. Feature-sized; don't belong in a reflection thread.
- **Per-machine doctor check** for `.flow/config.sh` stale paths — install-area, sibling thread.
- **Command linting** (`commands/*.md`) — sibling thread, likely a `scripts/lint-commands.sh` analogue of `make lint-docs`.
