# Reflection

Ship-stage agents and the human invoking `/flow-reflect` read this doc — it defines how flow learns from its own history without silently mutating config or skills.

Reflection has two axes and two triggers — both gated on user consent.

## Axis (a): project-context drift

Runs as the last step of the ship stage, on every PR, to catch project facts worth persisting.

**Rule — "twice is a pattern"**: if the LLM has told the user the same non-obvious fact about the project at least 2 times in this session, and that fact is not already in `CLAUDE.md`, surface it as a candidate for persistence.

### What qualifies as a fact

| Qualifies (concrete project statement) | Does not qualify |
|---|---|
| Paths: *"migrations live in `db/migrations/*.sql`"* | Status updates: *"I'm reading the file now"* |
| Rules: *"this repo uses `make install`, not `npm install`"* | Restatements during summaries: *"I changed X, Y, and Z"* |
| Gotchas: *"`gh pr edit --body` fails because of GraphQL deprecation; use `gh api` instead"* | Transient reasoning: *"let me check the diff"* |
| | Wordsmith tweaks: *"we should rename `foo` to `bar`"* — use review, not reflection |

### Surface shape

One `AskUserQuestion` per candidate:

- **Q**: *"I mentioned `<fact>` twice this session. Persist to `CLAUDE.md`?"*
- **Options**: `Yes, add (Recommended)` / `No, not worth it` / `Rephrase first`

### Rules

- **DO** cap at 3 candidates per ship; if more than 3 qualify, pick the top-3 by (repetition count × non-obviousness).
- **DO** exit silently when there are no candidates — ship proceeds normally.
- **DO** delegate the actual `CLAUDE.md` write to the `teach` skill.
- **DO NOT** interrupt the user with more than 3 reflection questions.

## Axis (b): flow-system drift

Runs only on explicit `/flow-reflect` invocation, looking across shipped workstreams for cross-workstream patterns.

### Scope

`$ARGUMENTS` selects which workstreams to examine:

| Argument | Meaning |
|---|---|
| `all` (default) | Every shipped workstream under `agent/workstreams/` (those whose spec has a `pr:` value). |
| `N` | Last N shipped workstreams. |
| `pr-6,pr-7` | Specific subset (matches the `pr:` number in each workstream's `01-spec-r*.md` frontmatter). |

### What to look for

| Pattern | Proposal |
|---|---|
| Same suggestion appearing in 2+ review docs (e.g., "Makefile install loop doesn't prune" noted across PRs) | Fix to the code. |
| Decisions repeatedly deferred ("defer to v2" in 3 specs) | Schedule the deferred work. |
| Stages consistently skipped ("no plan for this branch" in 4 PRs) | Config change (`FLOW_STAGES`) or skill edit. |

### What NOT to look for

- One-off bugs — that's review's job.
- Formatting of archived docs.
- Outcomes that are already done.

### Surface shape

2–4 proposals, each via `AskUserQuestion`. Each proposal is one of:

- Update to `CLAUDE.md` (new rule).
- Edit to `.flow/config.sh` (template, stages, hooks).
- Tweak to a stage skill file (show proposed diff; user decides).

> **Note:** If fewer than 2 workstreams under `agent/workstreams/` have a `pr:` value, say "not enough history yet" and exit. Reflection needs data.

## Rules

- **DO NOT** write to `CLAUDE.md`, `.flow/config.sh`, or any skill file silently — every change goes through `AskUserQuestion`.
- **DO NOT** run reflection as a background scan — only at ship or explicit command.
- **DO NOT** reflect on reflection itself (the LLM cataloging its own reflections). That way lies noise.
