A doc-type is just a file: frontmatter that declares what the document is for, then a template body. No DSL, no execution semantics. If you can write a good design doc, you can write a doc-type.

```yaml
---
name: spec
purpose: capture intent before planning — what + why, not how
audience: human reviewer, downstream plan skill
shape: problem / goals / non-goals / constraints / open-questions
lifecycle: append-only; supersedes prior specs
format: markdown            # or html for human-facing, visually-rich docs
maturity: stable
---
[template body with section guidance]
[1–2 example docs]
```

### The frontmatter fields

| Field | Declares |
|---|---|
| `name` | The doc-type's identifier, used when you bind it to a skill. |
| `purpose` | What this document is for — one line. |
| `audience` | Who reads it: a human, the next skill, or both. |
| `shape` | The sections the document should contain. |
| `lifecycle` | How it evolves — append-only, superseding, etc. |
| `format` | `markdown` by default, or `html` when a doc is human-facing and deserves to be read, not just parsed. |
| `maturity` | How settled the doc-type is — `stable`, `draft`. |

> **Markdown or HTML** — The body renders however it reads best. This very manual is an HTML doc-type — frontmatter plus a template, nothing to execute.
