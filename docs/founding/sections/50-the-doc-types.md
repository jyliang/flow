A doc-type is **frontmatter plus a template** — markdown or HTML, whatever reads best to a human.

**Settled**{.badge .settled} · Frontmatter declares the doc's purpose, audience, shape, lifecycle, and render format.

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
[1-2 example docs]
```

The body is markdown by default, or HTML when a doc is human-facing and deserves to be read, not just parsed — this conviction doc is itself an HTML doc-type. Either way: no DSL, no execution semantics. If you can write a good design doc, you can write a doc-type.

**Settled**{.badge .settled} · Ship a bootstrap catalog of 6-8 doc-types.

- **spec** — intent
- **plan** — steps
- **findings** — review output
- **decision-record** — why we chose X
- **spike-log** — what was tried, what we learned
- **change-summary** — what shipped, for PR description

Each is hand-tested in real work before it ships.
