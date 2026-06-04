Six words run everything:

| Word | Meaning |
|---|---|
| **flow** | A **linear chain** of steps you assemble and run. No branches mid-flow — you fork by starting a new flow from a checkpoint. |
| **step** | One **(skill, doc-type)** pair. The atomic unit. The skill produces; the doc-type captures. |
| **skill** | An **external capability** — a Claude Code skill. Flow orchestrates skills; it never edits or rates them. |
| **doc-type** | A **template plus frontmatter** describing a kind of document — markdown or HTML. Purely descriptive, nothing to execute. |
| **checkpoint** | The document a step emits. **Every checkpoint is a resume point** — that's the whole mechanic. |
| **spike / step** | The two ways to run a flow — the **only** toggle. Trust vs. review. Nothing else to configure. |

The diagram below shows a flow: skills and the doc-types they emit, output flowing left to right.
