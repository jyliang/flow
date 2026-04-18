# Reflection

Reflection is how flow learns. Two axes, two triggers — both gated on user consent.

## Axis (a) — project-context drift

**When**: last step of the ship stage, on every PR.

**Rule — "twice is a pattern"**: if the LLM has told the user the same non-obvious fact about the project ≥ 2 times in this session, and that fact is not already in `CLAUDE.md`, surface it as a candidate for persistence.

**Qualifying "fact"** — a concrete statement about the project:
- Paths: *"migrations live in `db/migrations/*.sql`"*
- Conventions: *"this repo uses `make install`, not `npm install`"*
- Gotchas: *"`gh pr edit --body` fails because of GraphQL deprecation; use `gh api` instead"*

**Non-qualifying**:
- Status updates: *"I'm reading the file now"*
- Restatements during summaries: *"I changed X, Y, and Z"*
- Transient reasoning: *"let me check the diff"*
- Wordsmith tweaks: *"we should rename `foo` to `bar`"* — use review, not reflection

**Surface shape** — one `AskUserQuestion` per candidate:
- Q: *"I mentioned `<fact>` twice this session. Persist to `CLAUDE.md`?"*
- Options: `Yes, add (Recommended)` / `No, not worth it` / `Rephrase first`

**Hard cap**: 3 candidates per ship. If more than 3 qualify, pick the top-3 by (repetition count × non-obviousness). Never interrupt the user with > 3 reflection questions.

**Silent exit**: if there are no candidates, reflection says nothing and ship proceeds normally.

**Persistence**: the `teach` skill handles the actual `CLAUDE.md` write.

## Axis (b) — flow-system drift

**When**: explicit `/flow-reflect` invocation.

**Input**: `$ARGUMENTS` selects scope:
- `all` (default) — every `agent/archive/pr-*/`
- `N` — last N archives
- `pr-6,pr-7` — specific archive subset

**What to look for** — cross-archive patterns:
- Same suggestion appearing in 2+ review docs (e.g., "Makefile install loop doesn't prune" noted across PRs) → propose fix to the code.
- Decisions repeatedly deferred ("defer to v2" in 3 specs) → propose scheduling.
- Stages consistently skipped ("no plan for this branch" in 4 PRs) → propose config change (`FLOW_STAGES`) or skill edit.

**What NOT to look for**:
- One-off bugs (that's review's job).
- Formatting of archived docs.
- Outcomes that are already done.

**Surface shape** — 2-4 proposals, each via `AskUserQuestion`. Each proposal is one of:
- Update to `CLAUDE.md` (new convention).
- Edit to `.flow/config.sh` (template, stages, hooks).
- Tweak to a stage skill file (show proposed diff; user decides).

**No archives yet**: if `agent/archive/` has fewer than 2 PRs, say "not enough history yet" and exit. Reflection needs data.

## Never

- Write to `CLAUDE.md`, `.flow/config.sh`, or any skill file silently. Every change goes through `AskUserQuestion`.
- Run reflection as a background scan. Only at ship or explicit command.
- Reflect on reflection itself (the LLM cataloging its own reflections). That way lies noise.
