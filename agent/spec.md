# Spec: Flow v3 — reflection and self-recovery

## Status
explore → plan

## What was done
- v1 (PR #6, merged): `/flow-adopt`, fast empty-state, scripts home.
- v2 (PR #7, merged): per-project `.flow/config.sh`, scripted first-time setup.
- v3 scope confirmed from the 2026-04-17 brainstorm: reflection across two axes.
- Committed leans on key design questions to keep v3 shippable (see Decisions).

## Decisions needed (committed, flag for redirect)
- [x] **Two axes, two triggers**: (a) project-context drift — detected at **ship** via "twice is a pattern" (LLM scans its own conversation for repeat observations), (b) flow-system drift — detected via explicit `/flow-reflect` command reading `agent/archive/*`. No background scans.
- [x] **No new persistent scratch file**: LLM uses its context window for the "twice" detection at ship. Keeps state ephemeral; no `agent/.session-notes.md` to manage.
- [x] **Persistence target for axis (a)**: `CLAUDE.md` (per-project) by default. The `teach` skill already handles rule-capture; reuse it.
- [x] **Persistence target for axis (b)**: `.flow/config.sh` updates or suggested edits to stage skill files. User approves each proposed change individually via `AskUserQuestion`.

## Verify in reality
- [ ] Ship a PR where the LLM said the same non-obvious thing twice in conversation → at ship boundary, LLM surfaces via `AskUserQuestion` asking to persist to `CLAUDE.md`.
- [ ] Ship a PR where the LLM said nothing twice → no reflection prompt fires (silent, no noise).
- [ ] Run `/flow-reflect` in a repo with ≥3 archived PRs → LLM summarizes patterns across archives, proposes changes, user approves per-item.
- [ ] Run `/flow-reflect` in a repo with no archive → LLM says "not enough history yet" and exits gracefully.

## Spec details

### Problem

After v1 + v2, users can run flow and customize per project. But the system doesn't learn. Two gaps:

1. **Project-context drift** — the LLM keeps telling the user the same fact twice (e.g., "migrations live in `db/migrations/*.sql`") without the fact ever making it into `CLAUDE.md`. The user has to notice + manually capture. Wasted interaction cycles.
2. **Flow-system drift** — after a few PRs, patterns emerge: "explore stage always asks the same 3 questions", "ship stage never uses the dry-run flag first". These are tweakable via `.flow/config.sh` or stage skill edits, but no one notices until they bite.

v3 adds a reflection layer for both.

### Scope

**In:**
- Ship-stage reflection: when the ship skill wraps up, LLM checks its own conversation for facts stated twice and surfaces via `AskUserQuestion` — "persist to CLAUDE.md?". One short decision at PR time, no noise when nothing's repeated.
- `commands/flow-reflect.md` — explicit reflect command. LLM reads `agent/archive/*/{spec,IMPLEMENTATION_PLAN,local-*-r1}.md`, `.flow/config.sh`, and current stage skills. Proposes changes grouped by (CLAUDE.md updates / config.sh edits / stage skill tweaks). User accepts per-group via `AskUserQuestion`.
- `skills/flow/references/reflection.md` — the "twice is a pattern" rule, decision tree, examples of good/bad reflections.
- `skills/flow/scripts/archive-summary.sh` — helper for `/flow-reflect` that prints one-line summaries of archived PRs (title + date from git log). Cheap, lets the LLM ground its reflection without reading every archive file in full.
- Update `skills/ship/SKILL.md` — add a final step: "Before closing ship, scan the conversation for repeat observations and offer to persist via the reflection reference."

**Out (post-v3):**
- Automatic scan across sessions ("last week you said X three times"). Needs cross-session state the LLM doesn't have natively.
- Auto-applying reflections without user approval. Always gate on consent.
- Reflection for skills outside flow (teach, commits, etc.) — they have their own existing learning paths.

### Design

#### Axis (a): ship-stage "twice is a pattern"

**Trigger**: last step of `skills/ship/SKILL.md` before PR creation.

**Detection**: LLM reviews its own conversation in context window. For each observation it made to the user, count occurrences. Anything said ≥2 times about this project that is NOT already in `CLAUDE.md` is a reflection candidate.

**Qualifying "observation"**: a statement of fact about the project (paths, conventions, build commands, gotchas). NOT a status update, NOT a summary, NOT LLM reasoning. Examples:
- ✓ "Migrations live in `db/migrations/*.sql`" said twice.
- ✓ "This repo uses `make install` not `npm install`" said twice.
- ✗ "I'm reading the file now" said twice — status, not fact.

**Surface shape**: `AskUserQuestion` (1 question per candidate, max 3 per ship):
- Q: "I mentioned `<fact>` twice this session. Persist to CLAUDE.md?"
- Options: `Yes, add (Recommended)` / `No, not worth it` / `Rephrase first`.

If user says "Rephrase first", they provide new wording, LLM writes exact text.

**False-positive budget**: 3 candidates max per ship. Hard cap to avoid noise. If LLM detects >3, surface top-3 by (how non-obvious × how often repeated).

#### Axis (b): `/flow-reflect`

**Trigger**: explicit user invocation.

**Body sketch (`commands/flow-reflect.md`):**

```
Read:
1. `agent/archive/*/` — archived specs, plans, reviews from recent PRs.
2. `.flow/config.sh` — current project config.
3. Current `CLAUDE.md` (project + user global).
4. `skills/flow/scripts/archive-summary.sh` output for orientation.

Identify 2-4 patterns worth acting on. For each, propose one change:
- Update to CLAUDE.md (new rule or convention).
- Edit to `.flow/config.sh` (template path, extra stages, hooks dir).
- Suggested tweak to a stage skill (surface; user decides later).

Surface via AskUserQuestion — one question per proposal, max 4 total.

If there's no archive (< 2 archived PRs), say "not enough history yet" and exit.
```

**Pattern types to look for:**
- Same phrase appearing in multiple archived findings ("the Makefile install loop doesn't prune" → S1 across 2 PRs).
- Decisions repeatedly deferred ("defer to v2" showing up in 3 specs → time to schedule).
- Stages consistently skipped ("no plan for this branch" in 4 PRs → maybe plan stage is overkill for housekeeping).

**Not to look for:**
- Surface-level formatting tweaks.
- Wordsmithing the skill prose.
- One-off bugs (that's what review finds).

#### `archive-summary.sh`

```bash
#!/usr/bin/env bash
# Print a one-line summary per archived PR: pr-N, date, title.
# Used by /flow-reflect for orientation without reading every archive in full.

set -euo pipefail
for dir in agent/archive/pr-*/; do
  pr="$(basename "$dir" | sed 's/pr-//')"
  spec="$dir/spec.md"
  if [[ -f "$spec" ]]; then
    title="$(head -1 "$spec" | sed 's/^# *Spec: *//')"
    date="$(grep -o 'date: [0-9-]*' "$spec" 2>/dev/null | head -1 | sed 's/date: //')"
    [[ -z "$date" ]] && date="$(date -r "$spec" +%Y-%m-%d 2>/dev/null || echo 'unknown')"
    printf 'pr-%s  %s  %s\n' "$pr" "$date" "$title"
  fi
done
```

#### `references/reflection.md`

One-page doc with:
- The "twice is a pattern" rule + qualifying examples.
- The 3-candidate ship-stage cap.
- What NOT to reflect on.
- The `/flow-reflect` command's scope.

#### `skills/ship/SKILL.md` update

Add one step before the PR-creation section:
```
### Step N: Reflection scan (optional, silent when empty)

Before opening the PR, scan this session's conversation for observations
stated ≥2 times that aren't in CLAUDE.md. For each (max 3), surface via
AskUserQuestion: persist / skip / rephrase. See `flow/references/reflection.md`.
```

Should be a one-paragraph addition. Skill body stays under 200 lines.

### Impact analysis

**Files to create:**
- `commands/flow-reflect.md`
- `skills/flow/scripts/archive-summary.sh`
- `skills/flow/references/reflection.md`

**Files to modify:**
- `skills/ship/SKILL.md` — add the reflection-scan step.
- `skills/flow/SKILL.md` — one-line pointer to `references/reflection.md` under the Scripts or Related skills section.

**Files to consider:**
- `teach/SKILL.md` — does the existing rule-capture path work unchanged for v3's "persist to CLAUDE.md" call? Expected yes, verify during review.

### Constraints

- **No background state**: reflection is event-driven (ship boundary, explicit command). No cron, no background scan. Predictable latency.
- **No automatic writes**: every persistence goes through `AskUserQuestion`. Never write to `CLAUDE.md` silently.
- **Noise budget**: 3 candidates max at ship. If more exist, surface top-3 by weight (repetition × non-obviousness). The 4th+ goes into a `agent/reviews/local-*-r1.md`-style note that the user sees at review time.
- **Context budget**: `archive-summary.sh` lets the LLM grok the archive in ≤200 tokens; it can read individual archive files only when a pattern hint emerges.

### Open questions

1. **Does the ship-stage reflection fire on every PR or only when the session is long enough to have repetitions?** Lean: always fire, but silent-exit when no candidates. The cost is one LLM sweep of the conversation — cheap in context window.
2. **How does `/flow-reflect` handle a repo with archives from multiple distinct features?** Does it narrow to recent (last 5 archives) or all? Lean: last 5, configurable via `$ARGUMENTS`.
3. **Should reflection respect the flow skill's `AskUserQuestion` contract (max 4 questions per call)?** Yes — batch ship-stage + reflect command output into single calls when possible.

## References

- Brainstorm: 2026-04-17 session, "reflection + self-recovery" segment.
- v1 archive: `agent/archive/pr-6/`.
- v2 archive: `agent/archive/pr-7/`.
- `skills/teach/SKILL.md` — rule-capture primitive v3 reuses.
- `skills/ship/SKILL.md` — where the axis-(a) trigger lives.
