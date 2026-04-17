---
name: teach
description: Create or improve Claude Code skills, or quick-capture a rule. Use when the user says "create a skill", "teach this", "remember this", "capture this rule", or states a convention to persist.
metadata:
  short-description: Create skills or capture rules
---

# Teach

Create new skills or improve existing ones. Also handles quick-capture of one-off rules and conventions.

## Quick capture

For simple rules and conventions — the user states it once, write it down, confirm, done.

### Simple rule or convention

Examples: "always use bun", "never auto-commit", "prefer guard over if-let"

Append to the appropriate CLAUDE.md:
- Project-specific rule -> `.claude/CLAUDE.md` (create if needed)
- Universal rule -> `~/.claude/CLAUDE.md`

Format as a concise bullet point. Group with related existing rules if any.

### Reusable pattern with code

Examples: "when setting up a new API route, always do X then Y"

Check if an existing skill covers this domain. If yes, add a recipe to it. If no, create a new skill using the full workflow below.

### Quick capture rules

1. Ask scope only if ambiguous — via `AskUserQuestion`:
   - Question: `"Is this rule system-wide or this-project-only?"`
   - Header: `Scope`
   - Options: `System-wide (~/.claude/)` / `This project only (.claude/)`
2. Do not interview — capture what was said, write it, confirm what was written and where
3. If the input is unclear, use `AskUserQuestion` for at most one clarifying question
4. Always show what was written and the file path after capturing

## Full skill creation

For workflows, patterns, or knowledge that need a proper skill.

## Where skills live

- **Project-level**: `.claude/skills/<skill-name>/SKILL.md` — scoped to a single repo
- **User-level**: `~/.claude/skills/<skill-name>/SKILL.md` — available everywhere

Default to project-level unless the skill is universally useful.

## Workflow

### 1. Clarify scope

Determine:
- What single concern does this skill address? (one skill = one concern)
- What should trigger it? (description sentence)
- Is there an existing skill that should be extended instead?

Scan existing skills before creating anything new.

### 2. Gather knowledge

Ask the user for (use free-form prompts — these are open-ended, not a choice between options; see `flow/references/user-interaction.md` "When NOT to use"):
- Concrete examples of the workflow or API
- Common mistakes or anti-patterns
- Reference material (docs, interfaces, schemas)

If the user says "just capture what we did" — extract the pattern from the current conversation. See `references/capture.md`.

### 3. Write the skill

Follow the structure in `references/template.md`. Key rules:

- **SKILL.md body < 300 lines** — move details to `references/`
- **Cookbook format** — use `## How to [verb]` sections with code examples
- **DO/DON'T bullets** after code blocks to catch LLM-specific mistakes
- **No prose essays** — code examples communicate faster and cheaper
- **Cross-reference** other skills by path (`skill-name/SKILL.md`) instead of duplicating

* **DO** use `AskUserQuestion` to confirm the outline before writing the skill file
* **DO** scan existing skills first to avoid duplicates
* **DO NOT** write vague descriptions like "Provides guidance for X" — include what it does and when to use it
* **DO NOT** dump everything into SKILL.md — split into references at ~200 lines
* **DO NOT** duplicate knowledge that exists in another skill — cross-reference it

### 4. Add references (if needed)

For large API surfaces or multi-topic domains:

```
skill-name/
├── SKILL.md              (cookbook + routing table)
└── references/
    ├── interface/         (.swiftinterface, .d.ts, or API surface files)
    ├── topic-a.md         (one file per sub-topic)
    └── topic-b.md
```

### 5. Validate

Check:
- [ ] Frontmatter has `name` and `description`
- [ ] Description is a clear capability statement with trigger phrases
- [ ] Body uses cookbook format with code examples
- [ ] DO/DON'T rules catch known LLM mistakes
- [ ] References are pointed to (not duplicated) from SKILL.md
- [ ] No unnecessary prose — every line earns its context cost
- [ ] Cross-references use relative skill paths

### 6. Iterate

After using the skill in real tasks:
- Notice where Claude still makes mistakes — add a DON'T rule
- Notice where Claude wastes tokens re-discovering something — add a recipe
- Notice where the skill is too long — split into references

## Design principles

For the full set of design guidelines, see `references/guidelines.md`.

## Related skills

None — this is the top-level skill for all knowledge capture.
