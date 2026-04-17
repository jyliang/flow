# Findings: flow-skill-refactor (local)

## Status
review → ship

## What was done
- Reviewed all changes on branch `flow-skill-refactor` vs `origin/main` (post-PR#2).
- Read full files for `Makefile`, `skills/flow/SKILL.md`, `skills/flow/references/boundaries.md`, `skills/flow/references/stage-detection.md`, `commands/next.md`, plus peer references (`protocol.md`, `user-interaction.md`) and all cross-linking SKILL.md files.
- Walked `make install` mentally + via `make -n install`. Traced the three audiences end-to-end.
- Found **0 critical, 3 suggestions, 3 nits, 2 questions**. No broken cross-references.

## How It Works (end-to-end)

**Goal** (inferred from diff + branch name): Slim `skills/flow/SKILL.md` by extracting detailed sections into topical `references/*.md` files; add slash-command install support to `Makefile`; install a `/next` command that delegates to the flow skill; archive PR #1's agent artifacts that were overwritten during PR #2.

**Audiences:**
1. **Contributor running `make install`** — installs skills + commands into `~/.claude/`.
2. **User typing `/next`** in any Claude Code session — triggers the flow skill.
3. **Claude reading `skills/flow/SKILL.md`** — follows the condensed entry + references.

**Trace 1 (`make install`):**
1. `mkdir -p ~/.claude/skills` → loop skills (`rm -rf` target + `cp -r`). Each skill dir fully replaced. ✓
2. `mkdir -p ~/.claude/commands` → loop commands (`cp` only). `next.md` lands at `~/.claude/commands/next.md`. ✓
3. Summary prints skill count + command count.

**Trace 2 (`/next [args]`):**
1. User types `/next <anything>` in any project.
2. Claude Code loads `~/.claude/commands/next.md`, substitutes `$ARGUMENTS`, executes body.
3. Body says "Use the `flow` skill to advance work." → Claude matches the flow skill by name. ✓

**Trace 3 (Claude reading SKILL.md):**
1. Reads `skills/flow/SKILL.md` (~58 lines now).
2. Sees pipeline, 6-rule stage detection, boundary ritual, pointers.
3. Follows pointers as needed: `references/stage-detection.md`, `references/boundaries.md`, `references/user-interaction.md`, `references/protocol.md`. All four exist. ✓

**End state matches goal for all three audiences.** Cross-refs from peer skills (`plan/`, `implement/`, `review/`, `ship/`, `tdd/`, `teach/`, `explore/`) all target `flow/references/user-interaction.md` and `flow/references/protocol.md` — both untouched, no broken links.

## Decisions needed

- [ ] **PR #2 review artifact**: `agent/reviews/auto-bump-marketplace-version-r1.md` is currently untracked. Options: (a) archive into `agent/archive/pr-2/` alongside this branch's cleanup of pr-1 artifacts, (b) leave at `agent/reviews/` as historical record, (c) delete (already served its purpose on the shipped PR).
- [ ] **`/next` vs `/flow`** naming: the command is installed as `/next`, but the skill is `flow`. Is `/next` the canonical entry name, or should the command file be renamed `flow.md` so it mirrors the skill name?

## Verify in reality

- [ ] Run `make install` after merge; confirm `~/.claude/commands/next.md` exists and the skills dir still mirrors the repo.
- [ ] In a fresh Claude Code session, type `/next` and confirm it triggers the flow skill (not some other preexisting `/next` binding).
- [ ] Confirm deleting `commands/next.md` in a future change and re-running `make install` does NOT leave a stale `~/.claude/commands/next.md`. (See S1 — expected to fail.)

## Critical
None.

## Suggestions

### S1 — Commands install loop doesn't prune stale files
**File**: `Makefile:16-21`

Skills are reinstalled with `rm -rf $(SKILLS_DIR)/$$name; cp -r` so renames and deletions propagate. Commands are only `cp`-ed, with no matching cleanup. If a command gets renamed (`next.md` → `flow.md`) or removed from the repo, the old file lingers in `~/.claude/commands/`.

Cheapest fix: wipe the command before copying, symmetric with skills:
```makefile
rm -f $(COMMANDS_DIR)/$$name; \
cp $$f $(COMMANDS_DIR)/$$name;
```

Stronger: wipe the whole `commands/` namespace first (`rm -f $(COMMANDS_DIR)/*.md`) before the loop — but that risks clobbering commands installed by other tools. The per-file `rm -f` is the safe middle ground.

### S2 — "Documents serve two purposes" framing dropped
**File**: `skills/flow/SKILL.md` (removed from old `## How it works`)

The old SKILL.md opened with a short framing: *Between each stage is a document that serves two purposes — (1) the human reads/edits it, (2) the next stage reads it as input.* This mental model does not appear in the new SKILL.md, `boundaries.md`, or `stage-detection.md`. It's implicit in `protocol.md` but not called out.

Small restoration: one sentence in SKILL.md intro (below line 10), e.g.:
> Each document serves two readers: the human reviews and edits it, the next stage consumes it as input.

Or add it as a 1-line preamble in `references/protocol.md`.

### S3 — `/next` installs into a global namespace without prefix
**File**: `commands/next.md`

`~/.claude/commands/` is a shared namespace across all Claude Code projects. `/next` is a fairly generic name — could collide with an existing user command or a future Claude Code built-in. Consider a prefix that mirrors the skill (`/flow-next`, `/flow`, or `/flow-advance`), or document the namespace collision risk in README.

## Nits

### N1 — `list` target only enumerates skills, not commands
**File**: `Makefile:26-34`

`make list` prints skill summary; now that commands are also installed, a symmetrical listing of commands would be consistent with the install output. Optional polish.

### N2 — Proportional ceremony section compressed aggressively
**File**: `skills/flow/SKILL.md:26`

Old SKILL.md had a worked example (small bug fix vs complex feature with bulleted breakdown). New SKILL.md has one sentence: *"Document depth scales with task complexity…"*. A reader with no context may not know how to judge "depth". Acceptable trade-off for brevity, and the examples likely belong in a references file if restored. Not worth changing unless you see agents over- or under-ceremonying in practice.

### N3 — Archive path uses `pr-1` but pr-1 was about something else
**File**: `agent/archive/pr-1/*`

`agent/archive/pr-1/` contains the spec/plan/review from the FIRST PR (the AskUserQuestion refactor). Confirmed by git log (`c3cabee Prefer AskUserQuestion…`). Naming is correct, just noting the archive convention is now established: `agent/archive/pr-<N>/{spec,plan,review}.md`. Going forward, PR #2's `auto-bump-marketplace-version-r1.md` should probably land in `agent/archive/pr-2/` per this convention (see Decisions needed).

## Questions

1. **No spec or plan for this branch.** The repo's own flow convention says every change goes through explore→plan→implement→review→ship. This branch jumped straight to implement (working tree mutations). Acceptable for small housekeeping, but the diff has ~7 non-trivial pieces (SKILL.md refactor, 2 new references, new Makefile install path, new slash command, archival). Do you want a retroactive spec/plan before opening the PR, or is "ship as-is with a good PR description" sufficient? My recommendation: good PR body is fine — this is genuinely mechanical — but flag it in the ship stage.

2. **Should `auto-bump-marketplace-version-r1.md` be committed in this PR or left untracked?** See Decisions needed.

## Error Handling
- `Makefile` loops use bash's default-unset behavior; a failing `cp` or `mkdir` will exit non-zero and halt make. ✓
- No silent catch-and-continue. ✓
- The command install loop does not check that `$(COMMAND_FILES)` is non-empty; if `commands/` is empty, the loop simply prints 0 and exits cleanly. ✓

## Test Coverage Gaps
This is markdown + Makefile boilerplate. No realistic unit tests. Manual verification is in **Verify in reality** above. Rated **gap: 2** (docs + install scripts, standard practice is post-merge smoke test).

## Pattern Reuse Opportunities
- Skill-install loop and command-install loop share shape but diverge on pruning behavior (S1). Minor DRY opportunity, not worth a shared macro at this size.
- New `references/stage-detection.md` and `references/boundaries.md` mirror the existing pattern (`references/protocol.md`, `references/user-interaction.md`). Clean pattern reuse. ✓

## Files Changed
- `Makefile` — adds `COMMANDS_DIR`, `COMMAND_FILES`, and a second install loop. See S1, N1.
- `skills/flow/SKILL.md` — shrunk from ~150 → ~58 lines; content moved to new references. See S2, N2.
- `skills/flow/references/boundaries.md` (new) — auto-advance/pause, revisions, review-finding triage, interaction rule. Clean extraction.
- `skills/flow/references/stage-detection.md` (new) — 4 stale-document scenarios with AskUserQuestion shapes. Clean extraction.
- `commands/next.md` (new) — 8-line slash command delegating to the flow skill. See S3.
- `agent/archive/pr-1/{spec,IMPLEMENTATION_PLAN_2026-04-17,local-main-r1}.md` — PR #1's artifacts moved from original locations into archive subdir. Preserves history.
- `agent/reviews/local-main-r1.md` (deleted, now at `agent/archive/pr-1/local-main-r1.md`) — shows in git as delete+add, but content-identical. `git commit -a` will record it as a rename.
- `agent/reviews/auto-bump-marketplace-version-r1.md` (untracked) — PR #2's findings doc. Decision needed (above).
