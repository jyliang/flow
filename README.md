# Flow

A skill system for Claude Code that moves work from idea to shipped PR through structured handoffs.

## The problem

AI coding tools get you 80% of the way. The last 20% is where they fail — they either silently guess wrong or dump everything on you to figure out. There's no good middle ground.

## The idea

Work moves through stages. Between each stage is a **document**. Every document serves two purposes:

1. **The human** reads it to understand what happened, edits it to redirect.
2. **The next agent** reads it to continue work.

The human can intervene at any document boundary — or skip it and let the pipeline flow. Documents are the API between human and AI, and between AI and AI.

## Stages

```
Idea
  ↓
 [explore]
  ↓
Spec              ← human: "is this what we're building?"
  ↓
 [plan]
  ↓
Plan              ← human: "is this how we're building it?"
  ↓
 [implement]
  ↓
Changes           ← human: normal code review
  ↓
 [review]         ← LLM review (clear eyes re-evaluation, can trigger self-fix)
  ↓
Findings          ← human: "what needs my judgment?"
  ↓
 [ship]
  ↓
PR                ← human review (final approval)
```

Document depth scales with task complexity. A one-line bug fix produces a 3-line spec and skips straight to implementation. A complex feature produces a full spec with impact analysis, a multi-step plan, and multiple review rounds. The structure is always there; the ceremony is proportional.

**Two "reviews" — keep them distinct**: **LLM review** happens inside the pipeline (bounded, one round + one fix pass by default). **Human review** happens on the PR after the pipeline completes (unbounded, your call).

## Workstream folders

Each piece of work lives at `agent/workstreams/<YYYY-MM-DD>-<branch>/` with stage-ordered filenames:

- `01-spec-r1.md` — explore output
- `02-plan-r1.md` — plan output
- `03-review-r1.md` — LLM-review output

Revisions create a new file rather than editing in place: `01-spec-r2.md`, `02-plan-r3.md`, etc. The previous `-rN` is frozen; the new file's `## Revisions` section explains what changed and why.

The folder is 1:1 with the branch. After a PR merges, the folder stays put — `ship` records the PR number into the spec's frontmatter comment (`<!-- ... pr: 42 -->`), and `workstreams-summary.sh` uses that marker as the filter for "shipped work."

## Revisions

Work isn't linear. During implementation you discover the spec was wrong. During review you realize the plan missed a step.

When this happens, the system **creates `01-spec-r2.md`** (or `02-plan-r2.md`, etc.) and the new file's `## Revisions` section captures what changed:

```markdown
## Revisions
- **implement → spec** 2026-04-16: Changed auth from JWT to session cookies
  **Why**: Existing middleware only supports sessions. Rewriting is out of scope.
  **Impact**: Plan steps 3-5 updated. No JWT dependency needed.
```

This is not a bug in the process — it's a feature. The revision trail answers questions humans ask each other: "Why does the code differ from the spec?" "When did we change the approach?" "Who decided this and why?"

## Slash commands

| Command | What it does |
|---|---|
| **`/flow`** | Single entry point. Detects current stage and advances. Empty workspace → asks for the idea. |
| **`/flow-adopt`** | Adopt the current conversation into a flow — distill into the workstream's `01-spec-r1.md` and advance. For when you're mid-chat and realize this should be a flow. |
| **`/flow-config`** | Configure (or reconfigure) this project's `.flow/config.sh` — template, stages, hooks. |
| **`/flow-reflect`** | Scan shipped workstreams for cross-PR patterns — CLAUDE.md additions, `.flow/config.sh` edits, stage-skill tweaks. Explicit opt-in. |
| **`/flow-spike "<thesis>"`** | Unattended **spike mode**: explore → plan → implement → 1 LLM-review round → draft PR for human review. Kick off, walk away, come back to something testable. |

## Skills

### User-facing

| Skill | What it does |
|---|---|
| **flow** | Single entry point — detects current stage and advances work |
| **spike** | Orchestrates `/flow-spike`: runs the full pipeline unattended, opens a draft PR for human review |
| **teach** | Create skills from patterns, or quick-capture a rule |

### Stages (invoked by flow)

| Skill | Transition | Document |
|---|---|---|
| **explore** | idea → spec | `agent/workstreams/<date>-<branch>/01-spec-r<N>.md` |
| **plan** | spec → plan | `agent/workstreams/<date>-<branch>/02-plan-r<N>.md` |
| **implement** | plan → changes | code on branch |
| **review** | changes → findings | `agent/workstreams/<date>-<branch>/03-review-r<N>.md` |
| **ship** | findings → PR | GitHub PR (records `pr:` in spec; workstream folder stays at `agent/workstreams/<date>-<branch>/`) |

### Internal (auto-triggered)

| Skill | Referenced by |
|---|---|
| **tdd** | implement |
| **commits** | implement, ship |
| **parallel** | explore, implement, review |

## Per-project configuration

Flow reads `.flow/config.sh` at the repo root for per-project overrides. First run of `/flow` in a project with no config fires a 3-question scripted setup; defaults are frictionless. See `skills/flow/references/config.md` for the schema.

Precedence for every setting: **environment variable > `.flow/config.sh` > built-in default**.

Minimal example:
```sh
# .flow/config.sh
FLOW_TEMPLATE_SPEC=".flow/templates/spec.md"
```

## Reflection

After a few shipped PRs, `/flow-reflect` can scan `agent/workstreams/` (filtered to the ones with `pr:` set) looking for patterns worth acting on — "same suggestion appeared across three reviews", "decision repeatedly deferred" — and propose concrete changes. Every proposal goes through `AskUserQuestion`; nothing lands silently.

Separately, the ship stage fires a **"twice is a pattern"** scan at the end of every PR: if the LLM stated the same non-obvious fact about the project twice this session without it being in `CLAUDE.md`, you'll get a prompt to persist. Silent when nothing qualifies. See `skills/flow/references/reflection.md`.

## Install

Flow ships as both a Claude Code plugin and a `skills.sh`-compatible skill pack. Pick whichever matches your agent.

### Claude Code (native plugin)

```
/plugin marketplace add jyliang/flow
/plugin install flow
```

Updates: `/plugin update flow`. Remove: `/plugin uninstall flow`.

### Any agent via `npx skills`

Works for Claude Code, Cursor, Codex, Copilot, Windsurf, and [40+ others](https://github.com/vercel-labs/skills#supported-agents).

```bash
# Install globally for Claude Code
npx skills add jyliang/flow -g -a claude-code

# Install for a different agent (e.g. Cursor)
npx skills add jyliang/flow -g -a cursor

# Project-scoped (commits skills into the repo)
npx skills add jyliang/flow -a claude-code

# Pick individual skills
npx skills add jyliang/flow --skill flow --skill review -g -a claude-code
```

Updates: `npx skills update`. Remove: `npx skills remove flow`.

### Local development

For iterating on flow itself, use the Makefile to copy the working tree into `~/.claude/`:

```bash
make install    # skills/ and commands/ both installed
make list       # show installed skills and commands
```

## Philosophy

**Documents are the interface.** Not CLI flags, not chat messages — documents on disk that both humans and agents can read and edit. The human's edits to a spec directly change what the agent plans. The human's edits to findings directly change what gets fixed.

**Every user-facing decision is an `AskUserQuestion`.** Free-form prose is for status, narration, and summaries only. Exception: spike mode auto-resolves and logs.

**Human time is sacred.** The LLM-review stage auto-fixes what's mechanical and only asks about what genuinely needs judgment. Spike mode pushes this further for thesis-validation work where the human engages only at the draft PR.

**Revisions are communication.** When work deviates from the plan, the deviation itself is valuable information. The system captures it instead of losing it.

**The system evolves with you.** `teach` lets you codify patterns as you discover them. `/flow-reflect` proposes changes based on your own archive. Skills are just markdown files — readable, editable, versionable.
