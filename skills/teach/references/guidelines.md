# Skill design guidelines

Both skill authors (human or agent) read this file when drafting or revising a skill — the principles below keep skills small, discoverable, and cheap to load.

## How to scope a skill

One skill maps to exactly one library, workflow, or concept. Never bundle multiple concerns into one skill.

## How to layer content for progressive disclosure

Split each skill across three layers so only what's needed loads at each moment.

| Layer | Always loaded? | Target size |
|---|---|---|
| Frontmatter (name + description) | Yes | ~30 words |
| `SKILL.md` body | When skill triggers | 100–300 lines |
| `references/` | When Claude needs them | Unlimited |

## How to structure the body as a cookbook

Structure the body as `## How to [verb]` sections. Each is a self-contained recipe: a code block followed by a rules block.

````markdown
## How to do X

```lang
code example
```

- **DO** correct pattern
- **DO NOT** common mistake
````

### Rules

- **DO** lead with code examples — they communicate faster and cost fewer tokens than prose.
- **DO NOT** write theory or essays.

## How to write DO / DO NOT rules

Place sharp, specific anti-patterns right after code blocks. Target mistakes the LLM would make from stale training data or wrong generalizations.

## How to write reference files

A reference file covering an entire topic can be ~30 lines. Just code examples and DO / DO NOT rules. No prose.

## How to include API surface files

Bundle `.swiftinterface`, `.d.ts`, OpenAPI specs, or similar API surfaces in `references/interface/`. These are the most token-dense, authoritative source of truth.

## How to cross-reference other skills

When one skill needs knowledge from another, reference by path:

```markdown
ALWAYS consult `other-skill/SKILL.md` for [topic].
```

- **DO** cross-reference by path.
- **DO NOT** duplicate the referenced content inline.

## How to write instructions

Use imperative voice: `Use X`, `Add Y`, not `You should use X`.
