# Flow

A skill system for Claude Code that moves work from idea to shipped PR through structured handoffs.

## The problem

AI coding tools get you 80% of the way. The last 20% is where they fail — they either silently guess wrong or dump everything on you to figure out. There's no good middle ground.

## The idea

Work moves through stages. Between each stage is a **document**. Every document serves two purposes:

1. **The human** reads it to understand what happened, edits it to redirect
2. **The next agent** reads it to continue work

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
 [review]
  ↓
Findings          ← human: "what needs my judgment?"
  ↓
 [ship]
  ↓
PR
```

Document depth scales with task complexity. A one-line bug fix produces a 3-line spec and skips straight to implementation. A complex feature produces a full spec with impact analysis, a multi-step plan, and multiple review rounds. The system adapts — the structure is always there, the ceremony is proportional.

## Revisions

Work isn't linear. During implementation you discover the spec was wrong. During review you realize the plan missed a step.

When this happens, the system **revises the earlier document** and adds a revision entry:

```markdown
## Revisions
- **implement → spec** 2026-04-16: Changed auth from JWT to session cookies
  **Why**: Existing middleware only supports sessions. Rewriting is out of scope.
  **Impact**: Plan steps 3-5 updated. No JWT dependency needed.
```

This is not a bug in the process — it's a feature. The revision trail answers questions humans ask each other: "Why does the code differ from the spec?" "When did we change the approach?" "Who decided this and why?"

## Skills

### User-facing

| Skill | What it does |
|-------|-------------|
| **flow** | Single entry point — detects current stage and advances work |
| **teach** | Create skills from patterns, or quick-capture a rule |

### Stages (invoked by flow)

| Skill | Transition | Document |
|-------|-----------|----------|
| **explore** | idea → spec | `agent/spec.md` |
| **plan** | spec → plan | `agent/plans/IMPLEMENTATION_PLAN_*.md` |
| **implement** | plan → changes | code on branch |
| **review** | changes → findings | `agent/reviews/*` |
| **ship** | findings → PR | GitHub PR |

### Internal (auto-triggered)

| Skill | Referenced by |
|-------|--------------|
| **tdd** | implement |
| **commits** | implement, ship |
| **parallel** | explore, implement, review |

## Install

```bash
make install
```

Or copy any skill directory to `~/.claude/skills/`.

## Philosophy

**Documents are the interface.** Not CLI flags, not chat messages — documents on disk that both humans and agents can read and edit. The human's edits to a spec directly change what the agent plans. The human's edits to findings directly change what gets fixed.

**Human time is sacred.** The review system self-verifies every finding. The ship stage auto-fixes what's mechanical and only asks about what genuinely needs judgment.

**Revisions are communication.** When work deviates from the plan, the deviation itself is valuable information. The system captures it instead of losing it.

**The system evolves with you.** `teach` lets you codify patterns as you discover them. Skills are just markdown files — readable, editable, versionable.
