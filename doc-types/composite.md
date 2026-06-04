---
name: composite
purpose: assemble a human-facing document from an HTML host plus MD and Mermaid fragments
audience: human reader (in a browser) · authors editing one fragment at a time
shape: host (index.html) / sections (*.md) / diagrams (*.mermaid) / assets
lifecycle: long-lived; fragments evolve independently; the host changes only when structure does
format: html
maturity: draft
---

# composite

A document whose *structure* lives in HTML and whose *content* lives in companion markdown and Mermaid files. Read by humans in a browser; authored as small fragments so a change to one section never forces a rewrite of the whole.

The host is the skeleton — navigation, layout, the order of things. The fragments are the meat — prose in `sections/`, diagrams in `diagrams/`. The browser renders everything at load time with [marked](https://marked.js.org) for markdown and [Mermaid](https://mermaid.js.org) for diagrams. No build step, no server — open `index.html` and read.

Use this when a single `.md` file has grown to the point that multiple authors collide on it, when diagrams matter as much as prose, or when the document deserves a real layout (sidebar, columns, callouts) instead of a long scroll.

## Template

A composite is a directory, not a file. The convention is fixed so a reader (or a script) always knows where to look:

~~~
<doc-name>/
  index.html              # the host — structure, nav, layout
  sections/               # prose fragments, one section per file
    00-overview.md
    10-<topic>.md
    ...
  diagrams/               # Mermaid diagrams, one per file
    <name>.mermaid
  assets/                 # images, fonts, anything else (optional)
~~~

`index.html` declares the document and references its fragments by relative path. Sections are numbered (`00-`, `10-`, `20-`) so the filesystem order matches reading order; gaps let you insert without renaming.

~~~html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title><!-- subject --></title>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script type="module">
    import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs";
    mermaid.initialize({ startOnLoad: false });
    async function render() {
      for (const el of document.querySelectorAll("[data-md]")) {
        const src = await fetch(el.dataset.md).then(r => r.text());
        el.innerHTML = marked.parse(src);
      }
      for (const el of document.querySelectorAll("[data-mermaid]")) {
        el.textContent = await fetch(el.dataset.mermaid).then(r => r.text());
        el.classList.add("mermaid");
      }
      await mermaid.run();
    }
    render();
  </script>
</head>
<body>
  <header>
    <h1><!-- subject --></h1>
    <p><strong>What:</strong> <!-- one sentence --></p>
    <p><strong>Why:</strong> <!-- one sentence --></p>
  </header>

  <nav><!-- links to the sections below --></nav>

  <main>
    <section id="overview" data-md="sections/00-overview.md"></section>

    <section id="architecture">
      <h2>Architecture</h2>
      <div data-mermaid="diagrams/architecture.mermaid"></div>
      <div data-md="sections/10-architecture.md"></div>
    </section>

    <!-- repeat for each section -->
  </main>
</body>
</html>
~~~

Each fragment is plain markdown or plain Mermaid — no frontmatter, no host-specific syntax. A fragment is editable on its own and previews correctly in any markdown viewer.

~~~markdown
<!-- sections/00-overview.md -->
The system ingests events from three sources and fans them into per-tenant queues.
Tenants opt in via the admin console; opt-out is reversible within 30 days.
~~~

~~~
%% diagrams/architecture.mermaid
flowchart LR
  A[Source] --> B{Router}
  B --> C[Queue A]
  B --> D[Queue B]
~~~

## Example

A composite called `auth-rewrite/`:

~~~
auth-rewrite/
  index.html
  sections/
    00-overview.md          # what the rewrite is and why
    10-current-state.md     # the system as it exists today
    20-target-state.md      # the system after the rewrite
    30-migration.md         # how we get from one to the other
    40-risk.md              # what could go wrong
  diagrams/
    current-state.mermaid   # referenced from 10-current-state.md's section
    target-state.mermaid    # referenced from 20-target-state.md's section
    migration-timeline.mermaid
~~~

`index.html` lays out a two-column page: a left-rail nav with anchors to each section, a right column that loads the five `sections/*.md` fragments in order and the three `diagrams/*.mermaid` inline with the sections they belong to. The whole document opens by double-clicking `index.html`.

## Rules

- **DO** keep the host structural — layout, nav, and `<section data-md="…">` references only. Prose belongs in a fragment.
- **DO** name section files with a numeric prefix (`00-`, `10-`, `20-`) so reading order is filesystem order; leave gaps for inserts.
- **DO** put exactly one Mermaid diagram per `.mermaid` file — fragments are atomic.
- **DO** make each fragment readable on its own: no host-specific includes, no cross-fragment references that only resolve after rendering.
- **DO** pin CDN versions for `marked` and `mermaid` (e.g. `mermaid@10`) so the document renders the same way next year.
- **DO NOT** inline prose or diagrams in `index.html` — if you're tempted, the doc-type isn't paying its keep; use a plain markdown doc instead.
- **DO NOT** introduce a build step. The point of this shape is "open the file and read"; a build step breaks that.
- **DO NOT** reach across fragments at runtime (no shared JS state, no cross-fetches). If two sections need the same fact, repeat it or extract a shared `sections/` fragment they both reference.
