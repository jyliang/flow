<!-- pr: 6 -->

# Spec: Flow v1 — `/flow-adopt`, fast empty-state, bootstrap scripts

## Status
explore → plan

## What was done
- Brainstormed the shape of "scripts in the flow pipeline" across three conversation turns (2026-04-17).
- Identified four real subproblems hiding under the original "make `/flow` faster" ask:
  1. Mid-conversation adoption (biggest pain).
  2. Fast empty-state entry.
  3. Per-project config.
  4. Self-recovery / reflection.
- Agreed to **ship v1 = subproblems 1+2 plus the script-home convention**, defer 3 and 4.
- Resolved three key design questions (see Decisions below).

## Decisions needed (all resolved)
- [x] **Adopt shape**: `/flow-adopt` as a separate slash command, not a mode flag on `/flow`. Keeps the empty-state fast path clean; each command has one job.
- [x] **Config location (v2)**: User decides per-project via a scripted first-time conversation. Defer implementation; spec the question shape.
- [x] **Reflection trigger (v3)**: "Twice is a pattern" — any observation the LLM makes twice in a session surfaces at ship.

## Verify in reality
- [ ] After implementing, run `/flow` in an empty project and confirm the first LLM turn is "What do you want to build?" with no skill-preamble thinking.
- [ ] Mid-session, type `/flow-adopt` after a free-form discussion and confirm `agent/spec.md` captures the distilled idea + prior decisions, branch is created, and the next stage is plan.
- [ ] Confirm `skills/flow/scripts/*.sh` are installed by `make install` (currently only SKILL.md + references are copied when a skill dir is `cp -r`'d — this should Just Work, but verify).
- [ ] Confirm the `UserPromptSubmit` hook (or whichever mechanism we pick) actually injects stage context before the LLM sees the prompt. If Claude Code doesn't support this shape, fall back to command-body pre-instructions (see Open questions).

## Spec details

### Problem

`/flow` today routes everything through the LLM, including mechanical setup (stage detection, branch creation, template materialization). Two pains result:

1. **Empty-state latency**: First turn on a new idea costs one LLM round-trip just to arrive at "what do you want to build?". The LLM reads the skill, reasons about stage, writes a preamble, then asks. None of that adds value — the user's idea is the only input that matters.
2. **Mid-conversation rigidity**: When a free-form discussion evolves into something that should be a flow, there's no affordance to "adopt this conversation into a flow." The user has to re-type the idea, losing accumulated context and decisions.

A script layer can fix (1) deterministically. A new command verb + LLM distillation fixes (2) natively.

### Scope

**In:**
- New command: `commands/flow-adopt.md` — distills current conversation into `agent/spec.md`.
- Modified `commands/flow.md` — empty-state detection primes the LLM with a minimal instruction so the first turn is the idea prompt, nothing else.
- New shell scripts under `skills/flow/scripts/`:
  - `bootstrap.sh` — creates branch, materializes spec template, writes frontmatter. Called by both commands.
  - `detect-stage.sh` — prints the detected stage (explore / plan / implement / review / ship / done) for command bodies to consume.
- New template: `skills/flow/templates/spec.md` — placeholder spec body with frontmatter.
- `make install` installs scripts + templates (verify, don't change, since `cp -r` should already cover this).

**Out (deferred to v2/v3):**
- `.flow/config.yml` + per-project scripted first-time setup.
- Template overrides per project.
- Pre/post-stage hooks.
- `/flow reflect` and "twice is a pattern" auto-surface.

### Design

#### Primitive 1: `/flow-adopt`

**Command**: `commands/flow-adopt.md`

**Body (sketch):**
```
---
description: Adopt the current conversation into a flow. Distill into agent/spec.md and advance.
---

Use the `flow` skill. You are being invoked mid-conversation. Your job:

1. Read back through this conversation.
2. Extract: the idea, any decisions already made, open questions, constraints discussed.
3. Run `~/.claude/skills/flow/scripts/bootstrap.sh <branch-name>` to create the branch and materialize the spec template.
4. Populate `agent/spec.md` with the distilled content. Match the repo's spec style (see archived examples under `agent/archive/*/spec.md`).
5. Surface any unresolved decisions from the conversation as `AskUserQuestion`.
6. Ask about advancing to the plan stage.

$ARGUMENTS
```

**Shell script**: `skills/flow/scripts/bootstrap.sh`

Takes a branch name; creates the branch from main; copies `templates/spec.md` → `agent/spec.md`; substitutes date/branch/author placeholders; does not commit (LLM commits after populating content).

**Key behavior**: the LLM is front-and-center. Script is thin. The LLM uses its existing context window as the source material — no transcript-file parsing.

#### Primitive 2: Empty-state primed prompt

**Modified command**: `commands/flow.md`

Current body: loads the full flow skill, LLM detects stage, LLM asks what to build.

New body:
```
---
description: Move work forward from idea to shipped PR — detect stage, advance
---

Detected stage: !`$HOME/.claude/skills/flow/scripts/detect-stage.sh`

If the detected stage is `explore-empty`, your only first turn is: "What do you want to build?" No preamble, no skill summary.

For any other stage, use the `flow` skill to advance work.

$ARGUMENTS
```

Claude Code runs the `` !`...` `` shell expression before `$ARGUMENTS` substitution and embeds stdout literally. The LLM arrives with the stage already known.

**Shell script**: `skills/flow/scripts/detect-stage.sh`

Implements the 6-rule stage detection from `skills/flow/SKILL.md` in bash:
1. No `agent/spec.md` and no `agent/archive/*/spec.md` in-flight → `explore-empty`
2. Spec exists, no plan → `plan`
3. Plan exists with incomplete steps → `implement`
4. Plan complete or unreviewed changes on branch → `review`
5. Findings with unresolved items → `ship`
6. Open PR ready → `done`

Stdout: a single line, e.g. `explore-empty` or `plan`. Stderr: brief rationale for debugging.

#### Primitive 3: Script home + install path

**Location**: `skills/flow/scripts/` inside the skill dir. Installed by existing `make install` via `cp -r skills/flow $(SKILLS_DIR)/flow`. No Makefile change needed.

**Invocation convention**: command bodies use absolute path `~/.claude/skills/flow/scripts/<name>.sh`. LLM-authored invocations from within a session use the same path.

**Template home**: `skills/flow/templates/spec.md`. Same install story. Bootstrap script reads from `~/.claude/skills/flow/templates/spec.md`.

### Impact analysis

**Files to create:**
- `commands/flow-adopt.md`
- `skills/flow/scripts/bootstrap.sh`
- `skills/flow/scripts/detect-stage.sh`
- `skills/flow/templates/spec.md`

**Files to modify:**
- `commands/flow.md` — new body with stage-detect pre-execution + conditional empty-state instruction.
- `skills/flow/SKILL.md` — one-line pointer to the scripts dir under "Related skills" or a new "Scripts" section. Body < 300 lines per `teach/SKILL.md` convention.

**Files to consider:**
- `Makefile` — verify scripts are executable after install (chmod +x). May need a post-install step.
- `skills/flow/references/stage-detection.md` — note that the script mirrors the LLM-level logic; keep in sync.

### Constraints

- **Claude Code slash-command shell execution**: confirmed supported via `` !`<command>` `` inline syntax. Runs before `$ARGUMENTS` substitution, in the project working directory.
- **Script install permissions**: `cp -r` preserves mode. New scripts must be committed with `chmod +x` set, else they arrive non-executable. Git tracks the executable bit.
- **Stage-detection duplication**: the bash script and the LLM-level logic in `skills/flow/SKILL.md` now encode the same rules. This is a maintenance cost — v1 keeps the LLM logic as the authoritative spec; the script is an optimization. If they drift, the LLM logic wins.
- **No transcript parsing**: `/flow-adopt` does NOT try to read `~/.claude/projects/*/transcript.jsonl`. The LLM uses its own context window. Simpler, more robust, no Claude Code internals coupling.

### Open questions

1. ~~**Does Claude Code support `!command` inline shell execution inside slash command bodies?**~~ **Resolved (2026-04-18)**: Yes. Syntax is `` !`<command>` `` inline, or a ```` ```! ```` fenced block for multi-line. Runs before `$ARGUMENTS` substitution. Has the user's working directory, env, and PATH. Supports arbitrary bash. Docs: Claude Code "Inject dynamic context" under Slash Commands. No `UserPromptSubmit` hook needed for v1.
2. **Branch-naming convention for `/flow-adopt`**: LLM picks from conversation content? User prompts for one? Default to `flow-adopt-YYYYMMDD-HHmm` with an override flag in `$ARGUMENTS`? Lean: LLM proposes a name from conversation topic, user confirms via `AskUserQuestion`. Defer resolution to plan stage.
3. **Should `bootstrap.sh` be idempotent?** If `agent/spec.md` already exists, fail? Overwrite with backup? Leave it? Safe default: refuse and print the existing spec path; let the LLM decide how to recover. Defer resolution to plan stage.

## Future work

### v2 — Per-project config + scripted first-time setup

**Trigger**: user runs `/flow` in a project with no `.flow/config.yml`, and v2 is shipped.

**Scripted conversation (4 questions, skippable):**
1. "Where should flow config live for this project?" — `.flow/config.yml` (shared via git) or `~/.claude/flow/<project>/config.yml` (personal).
2. "Use default stages (explore → plan → implement → review → ship), or customize?" — default or custom.
3. "Any project-specific pre/post-stage hooks to wire up now?" — yes / later.
4. "Override any spec/plan/review templates now?" — yes / later.

Defaults: `.flow/` in repo, default stages, later, later. Three of four skippable in the 80% case.

**Config schema** (sketch):
```yaml
config_location: repo | user
stages: [explore, plan, implement, review, ship]   # or custom
extra_stages:
  - {after: implement, name: security-review, skill: security-review}
hooks:
  pre-review: .flow/hooks/pre-review.sh
templates:
  spec: .flow/templates/spec.md
```

**New primitive**: `/flow config` command + `skills/flow/scripts/config-init.sh`.

**Coupling to v1**: v2's `bootstrap.sh` should consult `.flow/config.yml` for template path and branch prefix. v1 scripts hard-code defaults; refactor is mechanical.

### v3 — Reflection and self-recovery

**Two axes** (per brainstorm):
1. **Project context**: detect when the LLM has repeated the same observation twice in a session (e.g., "migrations live in `db/migrations/*`"). At ship, surface via `AskUserQuestion`: "Persist this to `CLAUDE.md`?" Reuse the `teach` skill's rule-capture path.
2. **Flow system itself**: `/flow reflect` verb reads `agent/archive/*` and proposes tweaks to `.flow/config.yml` or stage skill bodies. Explicit-invocation only — no background scan.

**Trigger rule**: "twice is a pattern." Implementation: LLM maintains a session-scoped observation log (in `agent/.session-notes.md`?), checks for repeats, surfaces at ship boundary. Cross-session detection needs v2 config to know where session logs live.

**Coupling to v1/v2**: v3 assumes v2's config exists (where do persisted rules land?). Ship in order.

## References

- Brainstorm conversation: 2026-04-17, spanning "Flow v1 design" session.
- Prior PRs in `agent/archive/pr-1/` and `agent/archive/pr-2/` — spec style reference.
- `skills/flow/SKILL.md` — current flow semantics (preserve during v1).
- `skills/teach/SKILL.md` — rule-capture primitive that v3's reflection will reuse.
- `update-config` skill — for `.claude/settings.json` hook wiring if Open question #1 forces the hook path.
