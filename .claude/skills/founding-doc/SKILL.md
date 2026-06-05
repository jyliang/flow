---
name: founding-doc
description: Produce a founding doc (a Conviction Doc) for a product or project — a human-facing composite HTML doc where every claim is tagged with its conviction level. Use when the user says "founding doc", "conviction doc", "write the founding doc for X", or wants to capture a product thesis for sharpening, not announcing.
metadata:
  short-description: Founding doc / Conviction Doc generator
---

# Founding Doc

A founding doc has two readers: a **human** sharpening the product thesis (founder, early team), and the **next contributor** who needs to know what's load-bearing before they touch anything. It is written for sharpening, not announcing — so every claim carries a conviction badge that says exactly how settled it is.

The output is a `composite` doc-type (see [`doc-types/composite.md`](../../../doc-types/composite.md)): an HTML host plus markdown and Mermaid fragments, served over HTTP. The host is the skeleton; the convictions live in `sections/*.md`; diagrams live in `diagrams/*.mermaid`.

## Goal

Turn a product concept into a `docs/founding/` composite where the thesis is split into ~10 sections, every claim is tagged **Settled** / **Leaning** / **Open**, and the doc is readable with one `make serve-docs`.

## How to produce a founding doc

Work through the beats in order. Gather the convictions first, write second, generate last.

### Step 1: Gather the convictions

Interview the user (or read what they gave you) until you can name, for the product:

- **The bet** — the one conviction that stays true for 20 years, independent of today's tech.
- **The problem** — what's broken now, stated as something a user feels.
- **The principle** — the single rule the whole product obeys.
- **What it is / is not** — the shape, and the adjacent products it deliberately refuses to be.
- **The domain model** — the core nouns and how they relate. This is the heart; give it one or two dedicated sections and at least one diagram.
- **Decisions** — what's been settled and when.
- **Open questions** — what's genuinely undecided.
- **First moves** — the next concrete steps. If the product is pre-execution, frame these as exploration and keep them light.

Don't invent convictions the user hasn't expressed. A thin doc with honest tags beats a thick doc of guesses.

### Step 2: Tag every claim

Each load-bearing sentence opens with a conviction badge. This is the whole point of the format — a reader knows in one glance where to push.

| Badge | Markdown | Means |
|---|---|---|
| Settled | `**Settled**{.badge .settled}` | Load-bearing. Don't touch without a strong reason. |
| Leaning | `**Leaning**{.badge .leaning}` | The chosen-for-now answer. Fine to challenge. |
| Open | `**Open**{.badge .open}` | Active debate. Push here. |

A brand-new product is mostly **Leaning** and **Open**, with a few **Settled** convictions. If everything is Settled, you're announcing, not sharpening — re-tag honestly.

### Step 3: Lay out the sections

Use this skeleton. Sections are numbered `00-`, `10-`, `20-` so filesystem order is reading order; leave gaps to insert. Adapt the middle (domain) sections to the product; keep the bookends.

| File | Section | Notes |
|---|---|---|
| `00-the-bet.md` | The Bet | The 20-year conviction. Rendered as a `hero`. |
| `10-the-problem.md` | The Problem | What's broken, felt by a user. |
| `20-the-principle.md` | The Principle | The one rule. Rendered as a `hero`. |
| `30-what-<x>-is.md` | What It Is | The shape of the product. |
| `40-…` / `50-…` | Domain model | One or two product-specific sections; put the diagram here. |
| `60-what-<x>-is-not.md` | What It's Not | The adjacent products it refuses to be. |
| `70-decision-log.md` | Decision Log | A dated table of settled decisions. |
| `80-open-questions.md` | Open Questions | All `Open` claims, gathered. Titled "Push Here". |
| `90-first-moves.md` | First Moves | Next steps; light and exploratory if pre-execution. |

### Step 4: Generate the composite

Copy the templates and fill them in. Paths are relative to the project root.

- `docs/founding/index.html` — from `templates/index.html`. Fill the title, deck, dateline, and the chip-nav + `<section>` list to match your sections. Keep the `<head>` (CSS + render script) verbatim.
- `docs/founding/sections/*.md` — one fragment per section. Plain markdown, conviction badges, no frontmatter.
- `docs/founding/diagrams/*.mermaid` — one diagram per file. The domain model almost always earns one.

Each fragment must read on its own — no host-specific includes, no cross-fragment references that only resolve after rendering.

### Step 5: Wire the make command concept

Copy `templates/Makefile` to the project root and `templates/serve.sh` to `docs/serve.sh`, then `chmod +x docs/serve.sh`. The composite loads its fragments via `fetch()`, which browsers block over `file://` — so the doc must be read over HTTP. `make serve-docs` is the supported way in; never tell the user to double-click `index.html`.

### Rules

- **DO** tag every load-bearing claim with exactly one conviction badge.
- **DO** keep `index.html` structural — layout, nav, and `data-md` / `data-mermaid` references only. Prose belongs in a fragment.
- **DO** give the domain model its own section(s) and at least one diagram.
- **DO** pin the CDN versions already in the template (`markdown-it@14`, `mermaid@10`) so the doc renders the same next year.
- **DO** verify the doc serves: run `docs/serve.sh` on a scratch port and `curl` the index, one section, and one diagram for `200`s before handing off.
- **DO NOT** invent convictions or over-tag as Settled to look decisive.
- **DO NOT** inline prose or diagrams into `index.html`.
- **DO NOT** introduce a build step — the format is "serve and read", nothing more.

## Related skills

- [`doc-types/composite.md`](../../../doc-types/composite.md) — the doc-type this skill emits; read it for the host/fragment contract.
- `docs-style` (global skill, `~/.claude/skills/docs-style/`) — house style for the markdown fragments.
