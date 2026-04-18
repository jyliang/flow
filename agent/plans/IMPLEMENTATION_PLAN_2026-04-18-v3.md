# Plan: Flow v3 — reflection (twice-is-a-pattern + /flow-reflect)

## Status
plan → implement

## What was done
- Read v3 spec at `agent/spec.md`.
- Committed leans on open questions #1 (always-fire with silent-exit) and #2 (last 5 archives default, override via $ARGUMENTS).
- Scope: **small** (~150 LOC total — 1 new script, 3 new markdown, 2 markdown edits).

## Decisions needed (committed, flag for redirect)
- [x] **Ship-stage reflection fires every PR, silent when empty** (spec Q1). LLM sweep of conversation is cheap; false-positive rate (noise) is the risk, mitigated by 3-candidate cap.
- [x] **`/flow-reflect` defaults to last 5 archives** (spec Q2). `$ARGUMENTS` can override (`"all"`, `"3"`, `"pr-6,pr-7"`).
- [x] **Reuse `AskUserQuestion`'s 4-question cap** (spec Q3). Batch ship-stage + reflect output into single calls when possible.

## Verify in reality
- [ ] Confirm `teach` skill's existing rule-capture path works unchanged for the ship-stage "persist to CLAUDE.md" flow (spec constraint).
- [ ] Confirm `archive-summary.sh` output is stable against the two existing pr-6 / pr-7 archive dirs.

## Implementation Steps

### Step 1: `skills/flow/scripts/archive-summary.sh`

- [ ] Tests:
  - Run in repo with `agent/archive/pr-6` + `pr-7` → prints 2 lines, both with dates + titles.
  - Run in repo with no archive → prints nothing, exits 0.
  - Malformed archive (missing `spec.md`) → skips that dir, no error.
- [ ] Code: new executable script per spec. `date` fallback: frontmatter comment `<!-- date: ... -->` first, `stat`/`date -r` second, `unknown` last.
- [ ] Test run: scripted smoke tests captured. ← `[PASTE TEST SUMMARY HERE]`.

### Step 2: `skills/flow/references/reflection.md`

- [ ] Tests: docs-only; `wc -l` ≤ 100.
- [ ] Code: new reference doc. Content:
  - The "twice is a pattern" rule.
  - Qualifying vs non-qualifying observations (with examples).
  - The 3-candidate ship cap.
  - Scope of `/flow-reflect`.
  - When NOT to reflect (e.g., wordsmithing, one-off bugs).
- [ ] Test run: `wc -l skills/flow/references/reflection.md`. ← `[PASTE TEST SUMMARY HERE]`.

### Step 3: `commands/flow-reflect.md`

- [ ] Tests:
  - Run in repo with ≥ 2 archives → LLM produces 2-4 proposals via AskUserQuestion.
  - Run in repo with no archive → LLM says "not enough history yet".
  - `/flow-reflect 3` → LLM limits scope to last 3 archives.
  - `/flow-reflect all` → LLM considers all archives.
- [ ] Code: new command body. Inline shell: `!`$HOME/.claude/skills/flow/scripts/archive-summary.sh`` for orientation. LLM instructions: read archives per `$ARGUMENTS`, identify 2-4 patterns, surface each via `AskUserQuestion`.
- [ ] Test run: manual, deferred to post-install verification. ← `[PASTE TEST SUMMARY HERE]`.

### Step 4: Update `skills/ship/SKILL.md`

- [ ] Tests: `wc -l skills/ship/SKILL.md` — must stay under 200 lines (currently checked; addition ~8 lines).
- [ ] Code: add a step before the "Open PR" section titled "Reflection scan". Body: 4-5 sentences pointing at `flow/references/reflection.md`, cap at 3 candidates, silent-exit when none.
- [ ] Test run: `wc -l skills/ship/SKILL.md`. ← `[PASTE TEST SUMMARY HERE]`.

### Step 5: Update `skills/flow/SKILL.md` — pointer

- [ ] Tests: `wc -l` still under 300.
- [ ] Code: add a line in the Scripts section for `archive-summary.sh`; add a line under Related skills mentioning reflection.
- [ ] Test run: `wc -l skills/flow/SKILL.md && make list`. ← `[PASTE TEST SUMMARY HERE]`.

### Step 6: Verify `make install`

- [ ] Tests:
  - `make install` — `$HOME/.claude/skills/flow/scripts/archive-summary.sh` executable.
  - `$HOME/.claude/skills/flow/references/reflection.md` installed.
  - `$HOME/.claude/commands/flow-reflect.md` installed.
- [ ] Code: no Makefile change expected (existing `cp -r` handles new files).
- [ ] Test run: full install smoke. ← `[PASTE TEST SUMMARY HERE]`.

## Architecture Decisions

- **Event-driven, not background**: reflection fires at ship (guaranteed event) or explicit command. No cron, no session-start scan. Predictable cost.
- **Ephemeral detection**: LLM uses its context window for twice-detection at ship; no persisted scratch file. Keeps state simple; accepts that very long sessions may blur detection.
- **Reuse `teach`**: the "persist to CLAUDE.md" call goes through the existing teach rule-capture path. No new persistence primitive.
- **Hard 3-candidate cap at ship**: noise is the failure mode of reflection; 3 is a soft ceiling on interrupts-per-PR.

## Success Criteria
- [ ] All 6 implementation steps completed.
- [ ] Ship-stage reflection fires on every ship, silently exits when no candidates.
- [ ] `/flow-reflect` produces actionable proposals for repos with archives; graceful exit without.
- [ ] `skills/ship/SKILL.md` stays under 200 lines.
- [ ] `skills/flow/SKILL.md` stays under 300 lines.
- [ ] PR description points at spec's scope + explicit deferrals.
