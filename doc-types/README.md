# Doc-type catalog

The documents that flow between skills. Read by humans authoring a flow and by the `flow` CLI, which inlines a doc-type's contract into the skills it generates.

A doc-type is **frontmatter plus a template** — purely descriptive, nothing to execute. The frontmatter declares what the document is for; the template body is the shape a skill fills in. If you can write a good design doc, you can write a doc-type.

## The bootstrap set

| Doc-type | Purpose |
|---|---|
| `spec` | Intent before planning — the *what* and *why*, never the how. |
| `plan` | The ordered, checkable steps that turn a spec into work. |
| `findings` | What a review surfaced — issues, risks, what passed. |
| `decision-record` | Why we chose X over Y, captured at the moment of choosing. |
| `spike-log` | What was tried and learned on an end-to-end run. |
| `change-summary` | What shipped — ready to drop into a PR description. |
| `composite` | A human-facing document built from an HTML host plus MD and Mermaid fragments. |

## Frontmatter fields

| Field | Declares |
|---|---|
| `name` | The doc-type's identifier, used when you bind it to a skill. |
| `purpose` | What this document is for — one line. |
| `audience` | Who reads it: a human, the next skill, or both. |
| `shape` | The sections the document should contain. |
| `lifecycle` | How it evolves — append-only, superseding, immutable. |
| `format` | `markdown` by default, or `html` when a doc is human-facing and deserves to be read, not just parsed. |
| `maturity` | How settled the doc-type is — `stable` or `draft`. |

## Authoring your own

Drop a new `<name>.md` (or `.html`) in this directory: the frontmatter above, a `## Template` block (a single `~~~markdown` or `~~~html` fence — the CLI extracts it verbatim), and at least one worked example. It joins the catalog the next time you run `flow new`.

There is no DSL and no runtime. Don't rename a doc-type that a generated flow already binds — regenerate the flow with `flow edit` instead.
