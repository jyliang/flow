---
name: ingest
description: Kernel primitive — turn input into a reusable skill. Decompose a conversation, doc, codebase walk, or stated rule into either a quick-capture (CLAUDE.md bullet) or a full skill in the active cell. Use when the user says "teach this", "create a skill", "remember this", "capture this rule", or states a convention to persist.
metadata:
  short-description: Kernel — input → skill
---

# Ingest

Kernel primitive: take any input — a conversation, a PDF, a codebase walk, a stated rule — and decompose it into reusable skills. The biological analog is digestion: raw input enters whole, gets broken into nutrients, the useful parts are absorbed, the residue dropped. The system stores extracted skills, not the raw input.

User-facing slash command: `/teach`. The user *teaches*; the system *ingests*.

Two modes: **quick capture** for simple rules, **full skill creation** for workflows. New skills land in the active cell (`~/.flow/active-cell/skills/`) via the cell's branch + PR workflow — see `skills/reflect/SKILL.md` for the auto-apply contract.

## Quick capture

For simple rules — the user states it once, write it down, confirm, done.

### How to capture a simple rule

Examples: "always use bun", "never auto-commit", "prefer guard over if-let".

Append to the appropriate `CLAUDE.md`:

| Scope | File |
|---|---|
| Project-specific rule | `.claude/CLAUDE.md` (create if needed) |
| Universal rule | `~/.claude/CLAUDE.md` |

Format as a concise bullet point. Group with related existing rules if any.

### How to capture a reusable pattern with code

Example: "when setting up a new API route, always do X then Y".

Check if an existing skill covers this domain. If yes, add a recipe to it. If no, create a new skill using the full workflow below.

### Quick-capture rules

1. Ask scope only if ambiguous — via `AskUserQuestion`:
   - Question: `"Is this rule system-wide or this-project-only?"`
   - Header: `Scope`
   - Options: `System-wide (~/.claude/)` / `This project only (.claude/)`
2. Do not interview — capture what was said, write it, confirm what was written and where.
3. If the input is unclear, use `AskUserQuestion` for at most one clarifying question.
4. Always show what was written and the file path after capturing.

## Full skill creation

For workflows, patterns, or knowledge that need a proper skill.

### Where skills live

| Scope | Path | Use when |
|---|---|---|
| Active cell | `~/.flow/active-cell/skills/<skill-name>/SKILL.md` | Default — the skill is part of the active pipeline. Lands via `cell-branch` + `cell-pr`. |
| Project-level | `.claude/skills/<skill-name>/SKILL.md` | Scoped to a single repo, not part of any cell. |
| User-level (kernel) | This runtime repo's `skills/<skill-name>/SKILL.md` | Only for kernel primitives. Don't add here from user invocations. |

### Step 1: Clarify scope

Determine:

- What single concern does this skill address? (one skill = one concern)
- What should trigger it? (description sentence)
- Is there an existing skill that should be extended instead?

Scan existing skills before creating anything new.

### Step 2: Gather knowledge

Ask the user for (use free-form prompts — these are open-ended, not a choice between options; see `skills/run/references/user-interaction.md` "When NOT to use"):

- Concrete examples of the workflow or API.
- Common mistakes or anti-patterns.
- Reference material (docs, interfaces, schemas).

If the user says "just capture what we did", extract the pattern from the current conversation. See `references/capture.md`.

### Step 3: Write the skill

Follow the structure in `references/template.md`.

#### Rules

- **DO** keep the `SKILL.md` body under 300 lines — move details to `references/`.
- **DO** use cookbook format: `## How to [verb]` sections with code examples.
- **DO** add DO / DO NOT bullets after code blocks to catch LLM-specific mistakes.
- **DO** cross-reference other skills by path (`skill-name/SKILL.md`) instead of duplicating.
- **DO** use `AskUserQuestion` to confirm the outline before writing the skill file.
- **DO** scan existing skills first to avoid duplicates.
- **DO NOT** write prose essays — code examples communicate faster and cheaper.
- **DO NOT** write vague descriptions like "Provides guidance for X" — include what it does and when to use it.
- **DO NOT** dump everything into `SKILL.md` — split into references at ~200 lines.
- **DO NOT** duplicate knowledge that exists in another skill — cross-reference it.

### Step 4: Add references (if needed)

For large API surfaces or multi-topic domains:

```text
skill-name/
├── SKILL.md              (cookbook + routing table)
└── references/
    ├── interface/         (.swiftinterface, .d.ts, or API surface files)
    ├── topic-a.md         (one file per sub-topic)
    └── topic-b.md
```

### Step 5: Validate

Check:

- [ ] Frontmatter has `name` and `description`.
- [ ] Description is a clear capability statement with trigger phrases.
- [ ] Body uses cookbook format with code examples.
- [ ] DO / DO NOT rules catch known LLM mistakes.
- [ ] References are pointed to (not duplicated) from `SKILL.md`.
- [ ] No unnecessary prose — every line earns its context cost.
- [ ] Cross-references use relative skill paths.

### Step 6: Iterate

After using the skill in real tasks:

- Notice where Claude still makes mistakes — add a DON'T rule.
- Notice where Claude wastes tokens re-discovering something — add a recipe.
- Notice where the skill is too long — split into references.

## Design principles

Every new or edited skill must follow the house docs style — it keeps skills scannable for humans and predictable for the loader.

- `skills/run/references/style.md` — the ten principles to apply whenever authoring or editing any skill. Read this before writing a new skill.
- `references/guidelines.md` — the full set of skill-authoring rules specific to ingest.

## Related skills

- `run` — the orchestrator that consumes cell skills.
- `reflect` — the partner primitive that proposes evolutions to existing skills (vs. ingest, which creates new ones).

