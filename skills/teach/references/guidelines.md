# Skill Design Guidelines

## 1. One skill per concern

Each skill maps to exactly one library, workflow, or concept. Never bundle multiple concerns into one skill.

## 2. Progressive disclosure (three layers)

| Layer | Always loaded? | Target size |
|---|---|---|
| Frontmatter (name + description) | Yes | ~30 words |
| SKILL.md body | When skill triggers | 100-300 lines |
| references/ | When Claude needs them | Unlimited |

## 3. Cookbook format

Structure the body as `## How to [verb]` sections. Each is a self-contained recipe:

```markdown
## How to do X

```lang
code example
```

* **DO** correct pattern
* **DO NOT** common mistake
```

No theory, no essays. Code examples communicate faster and cost fewer tokens.

## 4. DO/DON'T rules catch LLM-specific mistakes

Place sharp, specific anti-patterns right after code blocks. Target mistakes the LLM would make from stale training data or wrong generalizations.

## 5. Reference files are terse and code-first

A reference file covering an entire topic can be ~30 lines. Just code examples and DO/DON'T rules. No prose.

## 6. API surface files as references

Bundle `.swiftinterface`, `.d.ts`, OpenAPI specs, or similar API surfaces in `references/interface/`. These are the most token-dense, authoritative source of truth.

## 7. Cross-reference, don't duplicate

When one skill needs knowledge from another, reference by path:

```markdown
ALWAYS consult `other-skill/SKILL.md` for [topic].
```

## 8. Imperative voice

Write instructions in imperative form: "Use X", "Add Y", not "You should use X".
