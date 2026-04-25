---
name: docs-style
description: Apply when authoring or editing markdown docs in this repo — README, SKILL.md files, references, templates, or slash-command bodies. Use when creating a new skill or rewriting an existing doc. Keeps docs scannable for humans while preserving the structure LLMs depend on at runtime.
metadata:
  short-description: House style for repo markdown
---

# Docs Style

Every doc in this repo has two readers: a human scanning in a terminal or on GitHub, and the next author (agent or human) editing it. This skill is the shared contract between them — scannable, consistent, and safe to restructure.

When in doubt, consult `skills/flow/references/glossary.md` for canonical term choices.

## How to apply the ten principles

Each principle below is a one-line rule, one good example, one bad example. Apply them to every new doc and every edit to an existing one.

### Principle 1: Lede per section

Every `##` heading starts with a one-sentence summary of what the section covers. A reader who reads only the ledes should get the shape of the doc.

**Good:**
```markdown
## How to ship

Read the findings, fix what's mechanical, ask about the rest, push a clean PR.

### Step 1: Read findings
...
```

**Bad:**
```markdown
## How to ship

### Step 1: Read findings
...
```

### Principle 2: Verb-based heading names

`## How to review`, not `## Review process`. Verb-first tells the reader what they can *do* in this section.

**Good:** `## How to capture a rule`, `## How to handle spec/plan drift`

**Bad:** `## Rule capture`, `## Spec/plan drift handling`

**Exception — structural labels.** A small set of noun labels survive as cross-file structural markers, because consistency of shape across skills is itself a usability win. The allowed labels:

| Label | Where it appears | What it marks |
|---|---|---|
| `## Goal` | Every stage / internal skill | 1–3 sentences describing what the skill does. |
| `## Schema` | Config references | The shape of a config file or data structure. |
| `## Security` | Config references | Security constraints for the section's subject. |
| `## Conventions` | Stage skills | Where artifacts live, naming rules. |
| `## Related skills` | Most skills | Cross-reference block at the bottom. |

Add to the whitelist only when a label is truly structural (same shape and purpose across files), not as a generic escape hatch.

### Principle 3: Steps, not decimal steps

If "Step 1.5" exists, renumber or promote the half-step into a subsection of its neighbor. Decimal steps reveal edit-history, not reading order.

**Good:** `### Step 1`, `### Step 2`, `### Step 3`

**Bad:** `### Step 1`, `### Step 1.5`, `### Step 2`, `### Step 3.5`

### Principle 4: Rules in one place

DO / DO NOT rules collected into a single block per section, not sprinkled through prose.

**Good:**
```markdown
## How to review

...prose explaining the flow...

### Rules
- **DO** read full source files, not just diff hunks.
- **DO** grep for call sites before flagging dead code.
- **DO NOT** approve or request-changes — post as a comment review only.
```

**Bad:**
```markdown
## How to review

Here's how it works. *DO* read full files. Don't just use diff hunks.

Step 2 is to launch agents. **DO NOT** approve the PR.

Later, check cross-references. *DO* grep for call sites.
```

### Principle 5: One term per concept

Pick from `skills/flow/references/glossary.md`. Never mix `spec` and `Spec` and `the spec document` in the same doc.

**Good:** Every mention of the specification document is "spec" (lowercase), except when referring to the literal file path `01-spec-r<N>.md`.

**Bad:** "The Spec defines X. The spec document says Y. The specification file contains Z."

### Principle 6: Tables for comparisons

Three or more parallel items with the same shape → table. Bullets for narrative or non-parallel lists.

**Good:**
```markdown
| Stage | Input | Output |
|---|---|---|
| explore | idea | spec |
| plan | spec | plan |
| implement | plan | changes |
```

**Bad:**
```markdown
- Explore takes an idea and produces a spec.
- Plan takes a spec and produces a plan.
- Implement takes a plan and produces changes.
```

### Principle 7: Code fences always tagged

Every fence names its language: `bash`, `sh`, `markdown`, `text`, `yaml`, `json`. Never bare triple-backticks. Missing language hints break syntax highlighting on GitHub and most terminal renderers.

**Good:**
~~~markdown
```bash
gh pr view <number>
```
~~~

**Bad:**
~~~markdown
```
gh pr view <number>
```
~~~

### Principle 8: Callouts for criticals

A single admonition style, used sparingly: inflation kills the signal.

- `> **Note:**` — important but non-urgent context.
- `> **Warning:**` — if you skip this, something will break.
- `> **Tip:**` — optional time-saver.

**Good:**
```markdown
> **Warning:** Never rename a reference file — `SKILL.md` cross-references break silently.
```

**Bad:** Inline `**CRITICAL:**` bold scattered through prose, because it blurs into the surrounding text.

### Principle 9: File paths in backticks, always

Every path appearing in prose gets backticks. No raw paths.

**Good:** See `skills/flow/references/protocol.md` for the full schema.

**Bad:** See skills/flow/references/protocol.md for the full schema.

### Principle 10: Reader-of-two stance

Every doc opens with one sentence naming who reads it (human scanner? next-stage agent? both?). Frames the rest of the doc.

**Good:** *"Every doc in this repo has two readers: a human scanning in a terminal or on GitHub, and the next author (agent or human) editing it."*

**Bad:** *"This skill provides guidance for …"* — generic and tells the reader nothing about posture.

## How to look up a canonical term

The glossary is the authoritative term list for this repo. Read it before you invent a new term, and extend it when you catch drift.

See `skills/flow/references/glossary.md`. Extend the glossary there (not here).

## DO / DO NOT at a glance

One-glance checklist. Every item expands into a full principle above.

- **DO** add a one-sentence lede to every `##` section.
- **DO** use verb-first heading names (see principle 2 for the structural-label exception).
- **DO** number steps integer-only; promote half-steps into subsections.
- **DO** collect DO / DO NOT rules into one block per section.
- **DO** use the canonical term from the glossary; extend the glossary when you catch drift.
- **DO** reach for a table when you have three parallel items.
- **DO** tag every code fence with a language.
- **DO** reserve callouts (`> **Note:**`, `> **Warning:**`, `> **Tip:**`) for genuinely load-bearing context.
- **DO** wrap every file path in backticks.
- **DO** open every doc with one sentence naming its readers.
- **DO NOT** sprinkle DO / DO NOT bullets through prose.
- **DO NOT** capitalize `Spec` / `Plan` / `Findings` unless they open a sentence.
- **DO NOT** add decorative emoji.
- **DO NOT** rename a heading referenced by another doc without updating the referrer.
- **DO NOT** change a template's section structure — the stage skill that fills it depends on those headings.
- **DO NOT** introduce a new tool or dependency (mermaid, a doc generator, a linter plugin) for a docs-only change.

## Related skills

- `skills/teach/SKILL.md` — create or improve skills; cross-reference this doc when authoring a new skill.
- `skills/flow/references/glossary.md` — the canonical term list referenced by principle 5.
