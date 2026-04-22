<!-- branch: docs-readability · date: 2026-04-22 · author: Jason Liang · pr: -->

# Spec: docs-readability

## Status
explore → plan

## What was done
- Inventoried all source MD files (32 files, ~2,155 lines): `README.md`, 12 `SKILL.md` files, 6 `flow/references/*.md`, 1 template, 5 `commands/*.md`, plus `review/references/`, `teach/references/`, `plan/references/`, and `spike/templates/`.
- Excluded `agent/workstreams/**/*.md` — those are frozen historical artifacts, not docs we author.
- Read representative samples (`README.md`, `flow/SKILL.md`, `ship/SKILL.md`, `review/SKILL.md`, `teach/SKILL.md`, `flow/references/protocol.md`, `commands/flow.md`) to diagnose pain points.
- Clarified scope and reader posture with user via `AskUserQuestion` (see Decisions needed for what was answered).

## Decisions needed

User already resolved the three scoping questions at explore-start:

- **Scope**: All MDs under `skills/` and `commands/`, plus `README.md` (32 files).
- **Reader**: Humans first, but LLM runtime behavior must be preserved. No finding that makes the doc prettier for humans but confuses Claude's skill loader or stage-detection is acceptable.
- **Change types**: Typography/structure, rewriting for clarity, visual aids, cross-doc consistency — all in scope.

Resolved at this boundary (user answered via `AskUserQuestion`):

- [x] **LLM-safety boundary → Aggressive**: restructure freely for human readability; fix LLM regressions reactively. Implication: plan must include a verification pass (spike spot-check) AND be prepared to iterate post-merge if a skill misfires.
- [x] **Style guide → Yes, as `skills/docs-style/SKILL.md`**: one-page skill capturing the 10 principles. Discoverable to `teach` for future skill creation.
- [x] **README.md scope → Full treatment**: apply the same principles as every other doc for corpus-wide coherence.

## Verify in reality

These can only be verified by re-running the system after changes land:

- [ ] Invoking `/flow` on an empty workspace still routes to the explore prompt (not `AskUserQuestion`) — regression risk if we restructure `commands/flow.md`.
- [ ] Invoking each stage skill (`explore`, `plan`, `implement`, `review`, `ship`) via Claude still loads the right references — regression risk if we rename or move reference files.
- [ ] Stage-detection bash (`scripts/detect-stage.sh`) still matches the rule list in `flow/SKILL.md` — both places describe the 6 rules; keep them in sync.
- [ ] Templates (`spec.md`, `plan-template.md`, `findings-template.md`, `pr-body.md`, `spike-log.md`) still produce valid workstream documents when filled by the relevant stage.
- [ ] A spot-check spike (`/flow-spike "tiny thesis"`) still runs end-to-end after the changes.

## Spec details

### Problem

The docs work — they trigger the right skills and tell Claude what to do — but they're painful for a human to *read*. Specific symptoms observed across the corpus:

1. **Step numbering drift.** `skills/ship/SKILL.md` has steps 1, 1.5, 2, 3, 3.5, 4, 5, 6, 7, 7.5, 8, 9. The decimal steps are late additions. The reading experience is "what did I miss?" every time.
2. **Inline DO/DON'T clutter.** Files interleave prose paragraphs with `* **DO**`, `* **DO NOT**`, `**CRITICAL:**` bullets. The asterisk style is inconsistent (sometimes `*`, sometimes `-`), and the rules are scattered instead of collected.
3. **No top-of-section summary.** Most `## How to [verb]` sections dive straight into step 1. A reader scanning for "what happens at this stage?" has to read every step.
4. **Terminology drift.** The same concept appears as `spec`, `Spec`, `the spec document`, `01-spec-r<N>.md`, and `the spec file` within a single doc. Pick one.
5. **Heading-level inconsistency.** Some SKILL.md files use `## Step 1: ...` (header as step), others use `### Step 1: ...` nested under `## How to [verb]`. Scanning for steps requires remembering which doc you're in.
6. **Table vs. list inconsistency.** README uses tables well for skills/commands. SKILL.md files use mostly bullet lists for comparable content (e.g., auto-fix criteria) where a small table would scan faster.
7. **Code-fence language hints.** Most fences specify `bash` / `markdown`, but a handful omit it, which drops syntax highlighting in GitHub and most terminal viewers.
8. **Diagram as ASCII art buried in prose.** `README.md` has a very nice `Idea → [explore] → Spec → ...` diagram at the top, but the same pipeline is repeated as an inline code block in `flow/SKILL.md` without the annotations that make the README version readable.
9. **Long paragraphs where lists scan faster.** Several sections (e.g., the "How to handle spec/plan drift" block in `review/SKILL.md`) pack 2-3 decision rules into a single paragraph.
10. **No visual callouts.** Critical constraints (like "CRITICAL: DON'T ASSUME CODE IS UNUSED" in `review/SKILL.md`) are inline bold instead of a proper Note/Warning block.

### Scope

**In scope** (32 files):

| Directory | Files | Risk |
|---|---|---|
| Repo root | `README.md` | Low — docs-only, highest visibility. |
| `skills/*/SKILL.md` | 12 files | **Medium-high** — LLM-consumed at runtime. Preserve triggers, preserve DO/DON'T rules, preserve cross-references. |
| `skills/flow/references/` | 6 files | Medium — LLM-consumed when a SKILL.md points at them. Path must stay identical. |
| `skills/flow/templates/spec.md` | 1 file | **High** — LLM fills this literally each `bootstrap.sh` run. Structural changes cascade. |
| `skills/review/references/` | 2 files (`github-review-api.md`, `findings-template.md`) | Medium — same as flow/references. |
| `skills/teach/references/` | 3 files | Low-medium — mostly read, less "filled". |
| `skills/plan/references/plan-template.md` | 1 file | High — like `spec.md`, filled at runtime. |
| `skills/spike/templates/` | 2 files (`pr-body.md`, `spike-log.md`) | High — filled at runtime. |
| `commands/` | 5 files | Medium — slash-command bodies, some contain embedded bash and conditionals. |

**Out of scope:**
- `agent/workstreams/**/*.md` — frozen historical records, not docs we author.
- `CLAUDE.md` files — these are private to the user (not in repo).
- Any generated output or `node_modules` if it appears.

### Design

The rewriting work is structural, not cosmetic. We apply a small, explicit set of principles uniformly.

#### Principles (the human-readability "style guide")

1. **One-sentence lede per section.** Every `##` heading starts with a one-line summary of what this section covers. A reader who reads only the ledes gets the shape of the doc.
2. **Verb-based heading names.** `## How to review`, not `## Review process`. Already mostly followed; enforce consistently.
3. **Steps, not decimal steps.** If a "Step 1.5" exists, it's a sign steps need renumbering *or* that the half-step should be promoted into a subsection of its neighbor. We renumber or inline; we don't add `.5`.
4. **Rules in one place.** DO / DON'T rules collected into a single block per section (a fenced `> **Rules**` callout or a bulleted list under a `#### Rules` sub-header), not sprinkled through prose.
5. **One term per concept.** A per-repo glossary in `flow/references/protocol.md` (or a new short `glossary.md`) fixes the canonical term; every doc uses it. Examples: "spec" (lowercase, no "the spec document"), "workstream folder", "stage", "finding".
6. **Tables for comparisons.** ≥3 parallel items with the same shape → table. Bullets for narrative or non-parallel lists.
7. **Code fences always tagged.** `bash`, `markdown`, `sh`, `text`. Never bare triple-backticks.
8. **Callouts for criticals.** A single admonition style: `> **Note:** …` / `> **Warning:** …` / `> **Tip:** …`. Used sparingly — inflation kills the signal.
9. **File paths in backticks, always.** Every `path/to/file.md` reference in backticks; no raw paths in prose.
10. **Reader-of-two stance.** Every doc opens with one sentence naming who reads it (human? next-stage agent? both?). Frames the rest of the doc.

#### Mechanics

- **One PR, staged commits.** Each commit groups files that share risk profile (e.g., "templates", "references", "SKILL.md files", "README + commands"). Reviewer can bisect.
- **No content deletions without a note.** If we remove a sentence or section, the commit message says why.
- **LLM-safety guardrails**:
  - Never rename a section heading that a slash-command or another SKILL.md references by name ("`## Quick capture`", "`## How revisions work`", etc.) without grep-checking references.
  - Never rename a reference file (`protocol.md`, `boundaries.md`, etc.) — would break SKILL.md cross-refs.
  - Never change the structure of a template (`spec.md`, `plan-template.md`) — would change what gets produced downstream.
  - Preserve the exact text of **trigger phrases** in SKILL.md `description:` frontmatter — those are matched by the skill loader.
  - After the edits, run `/flow-spike "no-op thesis"` end-to-end to verify the full pipeline still works.

#### Deliverables

1. A style-guide doc (~1 page) capturing principles 1-10 above. Location TBD per the "style guide as deliverable" decision. **Recommendation:** `skills/docs-style/SKILL.md` so `teach` can reference it when users create new skills.
2. Edits to all 32 in-scope files applying the principles.
3. A one-line revision entry in this spec's downstream `02-plan-r1.md` if the plan stage discovers a principle that needs adjusting.

### Constraints

- **No backwards-compat shims.** Per project CLAUDE.md-ish feedback: don't add `// removed for Y reason` markers. If a sentence is gone, it's gone.
- **Branch + PR workflow.** All changes on `docs-readability` branch; single PR; no direct pushes to main.
- **Small-batch commits.** Reviewer should be able to read each commit independently. No "Apply readability improvements across all files" 2,000-line mega-commit.
- **No dependencies added.** This is a docs-only change. No mermaid, no new tooling, no new doc generator. Plain GitHub-flavored markdown only.
- **Don't introduce emojis** unless they earn their place (e.g., replacing the textual "CRITICAL" label — and even then only if we decide it). Avoid decorative emoji.

### Open questions

- Style-guide location resolved: `skills/docs-style/SKILL.md` (user answered at explore→plan boundary).
- Do we want any mechanical linting (e.g., a `make lint-docs` target that greps for untagged code fences and raw paths)? Nice-to-have. *Escalate to plan stage.*
