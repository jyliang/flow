# Document Protocol

Every stage agent writes a document following this protocol; the next stage agent (and the human reviewer) reads it. This doc is the shared schema between them.

For canonical term choices (`spec`, `plan`, `findings`, `stage`, `revision`), see `skills/flow/references/glossary.md`.

## Sections

Each document has a small always-present header, plus optional sections the stage agent includes only when they carry real content.

### Always present

Every stage document opens with status and a summary of work.

```markdown
# [Stage]: [Title]

## Status
[current stage] → [next stage]

## What was done
- Concrete summary of work performed
```

`Status` is one line. `What was done` scales with the task — one bullet for a small fix, a paragraph for a complex feature.

### Include when relevant

Three optional sections cover decisions, verification, and revision history.

```markdown
## Decisions needed
- [ ] **Decision A**: [Option 1] vs [Option 2]
  Context: why this matters, what each option implies

## Verify
- [ ] Test [specific scenario] in [specific environment]
- [ ] Confirm [assumption] with [person or data source]

## Revisions
- **[stage → this doc]** [date]: [What changed]
  **Why**: [What triggered the change — discovery during implementation, human redirect, review finding]
  **Impact**: [What downstream docs or code need updating]
```

| Section | Include when |
|---|---|
| Decisions needed | There are genuine choices. Omit for mechanical work. |
| Verify | Something needs manual testing or human confirmation. Not every task needs this, but you often can't predict which will. Include when the agent isn't confident the output is correct, or when correctness depends on something outside the codebase (device behavior, third-party API, stakeholder preference). |
| Revisions | A later stage changes this document. The most important section for human-to-human communication — see "How revisions work" below. |

### Stage-specific content

The bulk of the document — the actual deliverable (spec details, plan steps, findings). This IS the input for the next stage's agent. Its depth scales with the task.

## How revisions work

Work isn't linear. During implementation you discover the spec was wrong; during review you realize the plan missed a step. When that happens:

1. Go back and update the earlier document. Don't just fix the code and move on — the spec/plan is a communication artifact, not just an agent input.
2. Add a `## Revisions` entry to the document you changed, capturing which stage triggered the change (e.g., `implement → spec`), what changed and why (the discovery, not just the edit), and the impact on downstream documents or work.
3. Continue forward from the current stage, not from the revised document. The revision is a record, not a restart.

### Why revisions matter

The revision trail answers questions that humans ask each other:

- "Why does the implementation differ from the spec?" — Because the spec was revised during implementation (see Revisions).
- "When did we decide to change the approach?" — During step 3 of implementation, when we discovered X.
- "Who changed this and why?" — The agent flagged it during review, the human approved the change.

Without revisions, the spec says one thing and the code does another, and nobody remembers why.

### Example

Spec originally said:

> Use JWT tokens for authentication

During implementation, the agent discovers the existing middleware only supports session cookies. Rewriting middleware is out of scope. The agent:

1. Writes a spec revision at `agent/workstreams/<date>-<branch>/01-spec-r2.md` (keeping `01-spec-r1.md` frozen as history):

   ```markdown
   ## Revisions
   - **implement → spec** 2026-04-16: Changed auth from JWT to session cookies
     **Why**: Existing middleware (`src/middleware/auth.ts`) only supports sessions.
     Rewriting it is out of scope for this task.
     **Impact**: Plan steps 3-5 updated. No JWT dependency needed.
   ```

2. Writes a plan revision (`02-plan-r2.md`) reflecting the new approach.
3. Continues implementing with the revised approach.

A teammate reading the spec later sees both the original intent AND why it changed. The PR reviewer sees the revision trail and doesn't need to ask "why not JWT?"

### When the human triggers a revision

The human edits the spec directly — changes scope, adds constraints, removes a feature. The next agent that reads the document should:

1. Notice the edit (content differs from what the previous stage produced).
2. Add a revision entry attributing it to the human: `**human → spec**`.
3. Propagate the change to downstream documents.

## Who reads what

Each section serves a different reader.

| Section | Human | Next agent |
|---|---|---|
| Status | Orientation | Stage detection |
| What was done | Understanding | Skip |
| Decisions needed | **Primary interaction** | Reads resolved decisions |
| Verify | Action items | Skip |
| Revisions | **Communication trail** | Context for why things changed |
| Stage content | Deep review (optional) | **Primary input** |

## Document locations

Every workstream — in-flight or shipped — lives in `agent/workstreams/<YYYY-MM-DD>-<branch>/` (1:1 with the git branch). Merged workstreams stay put; their spec's frontmatter comment gets a `pr: <N>` field at ship time, which marks the workstream as shipped.

| Document | Path within workstream | Produced by |
|---|---|---|
| spec | `01-spec-r<N>.md` | explore |
| plan | `02-plan-r<N>.md` | plan |
| findings | `03-review-r<N>.md` | review |
| PR | GitHub (via `gh`); PR number written to spec frontmatter | ship |

Each document starts at `-r1`. A revision creates a new file with `-rN+1`; the previous file stays frozen. The new file's `## Revisions` section explains what changed, why, and the impact. "Latest" means the highest-`-rN` for a given stage prefix.
