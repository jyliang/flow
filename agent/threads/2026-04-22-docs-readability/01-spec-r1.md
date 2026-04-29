<!-- branch: docs-readability · date: 2026-04-22 · author: Jason Liang · pr: 14 -->

# Spec: docs-readability · explore → plan

> **What:** A readability pass across all 32 authored Markdown files in the repo, plus a new `skills/docs-style/SKILL.md` that captures the 10 principles used to rewrite them.  
> **Why:** The docs work — they trigger the right skills and route Claude — but they're painful for a human to scan, and the repo's surface is now wide enough that the skim cost is blocking contributors and reviewers.

## Scope

32 authored Markdown files get the full treatment; frozen historical records and private `CLAUDE.md` files do not.

| Directory | Files | Risk |
|---|---|---|
| Repo root | `README.md` | Low |
| `skills/*/SKILL.md` | 12 files | **High** — LLM-consumed at runtime |
| `skills/flow/references/` | 6 files | Medium — LLM-consumed via SKILL.md cross-refs |
| `skills/flow/templates/spec.md` | 1 file | **High** — filled literally each `bootstrap.sh` run |
| `skills/review/references/` | 2 files | Medium |
| `skills/teach/references/` | 3 files | Low-medium |
| `skills/plan/references/plan-template.md` | 1 file | **High** — filled at runtime |
| `skills/spike/templates/` | 2 files | **High** — filled at runtime |
| `commands/` | 5 files | Medium — contain embedded bash and conditionals |

**Out of scope:** `agent/workstreams/**/*.md` (frozen historical records), `CLAUDE.md` files, generated output.

## Decisions

Three scoping questions were resolved at explore-start, and three implementation stances were set at the explore→plan boundary.

| Question | Answer |
|---|---|
| Which files? | All MDs under `skills/`, `commands/`, and `README.md` (32 files) |
| Who's the reader? | Humans first — but LLM runtime behavior must be preserved |
| What changes are in scope? | Typography, structure, clarity rewrites, visual aids, cross-doc consistency — all in |
| LLM-safety stance? | Aggressive: restructure for humans, fix regressions reactively, plan must include a spike |
| Style-guide location? | `skills/docs-style/SKILL.md`, so `teach` can reference it |
| README.md scope? | Full treatment, same principles as every other doc |

## Design

Apply ten style principles uniformly across the corpus; they also become `skills/docs-style/SKILL.md`.

The observed problems concentrate into ten patterns:

| # | Problem | Example |
|---|---|---|
| 1 | Step numbering drift | `ship/SKILL.md` has steps 1, 1.5, 2, 3, 3.5 … |
| 2 | DO/DON'T rules scattered | Interleaved in prose, inconsistent bullet style (`*` vs `-`) |
| 3 | No section summary | `## How to [verb]` dives straight into step 1 with no lede |
| 4 | Terminology drift | Same concept called: `spec`, `Spec`, `the spec document`, `01-spec-r<N>.md` |
| 5 | Inconsistent heading levels | Some docs use `## Step 1:`, others use `### Step 1:` under `## How to` |
| 6 | Tables underused | Bullet lists where a table would scan faster (e.g. auto-fix criteria) |
| 7 | Untagged code fences | Some fences omit `bash`/`markdown` — drops syntax highlighting |
| 8 | Diagram quality gap | `flow/SKILL.md` has a bare code block; `README.md` has an annotated diagram |
| 9 | Paragraphs instead of lists | Decision rules packed into prose blocks (e.g. `review/SKILL.md`) |
| 10 | No visual callouts | `CRITICAL:` warnings are inline bold, not structured admonitions |

Each pattern gets one principle:

1. **One-sentence lede per section.** Every `##` heading starts with a one-liner. Reading only ledes gives you the shape of the doc.
2. **Verb-based headings.** `## How to review`, not `## Review process`.
3. **No decimal steps.** `Step 1.5` means renumber or promote to a subsection. Never add `.5`.
4. **Rules in one place.** DO/DON'T rules go in a single block per section — a `#### Rules` sub-header or a `> **Rules**` callout — not sprinkled through prose.
5. **One term per concept.** Canonical terms live in `flow/references/protocol.md`. Every doc uses them. Examples: `spec` (not "the spec document"), `workstream folder`, `stage`, `finding`.
6. **Tables for comparisons.** Three or more parallel items with the same shape → table. Bullets for narrative or non-parallel lists.
7. **Code fences always tagged.** `bash`, `markdown`, `sh`, `text`. Never bare triple-backticks.
8. **Callouts for criticals.** One style: `> **Note:**`, `> **Warning:**`, `> **Tip:**`. Use sparingly — inflation kills the signal.
9. **File paths in backticks, always.** Every `path/to/file.md` reference in backticks; no raw paths in prose.
10. **Reader-of-two stance.** Every doc opens with one sentence naming who reads it (human, agent, or both).

**Ship shape:** one PR on `docs-readability`, staged commits by risk tier so a reviewer can bisect.

```
1. templates/         ← highest risk, reviewable in isolation
2. references/        ← medium risk
3. skills/*/SKILL.md  ← medium-high risk
4. README.md + commands/  ← lowest risk
```

## Constraints

Hard rules that bound the restructuring — violating any of these breaks the runtime.

- Never rename a section heading that a slash-command or another SKILL.md references by name — grep first.
- Never rename a reference file (`protocol.md`, `boundaries.md`, etc.) — would break cross-refs.
- Never change the structure of a runtime-filled template (`spec.md`, `plan-template.md`, etc.).
- Preserve the exact text of trigger phrases in SKILL.md `description:` frontmatter.
- No new tooling, no emojis, no mermaid, no doc generators — plain GitHub-flavored Markdown only.
- No backwards-compat shims or removal comments. If a sentence is gone, it's gone.
- No direct pushes to `main`; the single PR merges via review.

## Verification

Five post-change checks that can only be confirmed by running the system — wire these into the plan.

- [ ] `/flow` on an empty workspace still routes to the explore prompt (not `AskUserQuestion`)
- [ ] Each stage skill (`explore`, `plan`, `implement`, `review`, `ship`) still loads the right references
- [ ] `scripts/detect-stage.sh` still matches the rule list in `flow/SKILL.md` (both places describe 6 rules — keep in sync)
- [ ] Templates (`spec.md`, `plan-template.md`, `findings-template.md`, `pr-body.md`, `spike-log.md`) still produce valid workstream documents
- [ ] Spot-check spike (`/flow-spike "tiny thesis"`) runs end-to-end

## Open

- Should we add a `make lint-docs` target (grep for untagged fences and raw paths)? Nice-to-have — escalate to plan.
