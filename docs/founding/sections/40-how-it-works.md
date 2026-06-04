**Settled**{.badge .settled} · The atomic unit is a (skill, doc-type) pair.

The user binds each skill to a doc-type when building the flow; flow never infers or imposes the pairing. Skills stay agnostic — they don't need to know about flow. This preserves the boundary that lets flow remain a substrate.

**Settled**{.badge .settled} · Checkpoint trail lives under `.flow/runs/<flow>/<timestamp>/`.

Numbered files like `01-spec.md`, `02-plan.md`, `03-findings.md`. Resume via `flow resume <run-id> --from <NN>`. Edit any file before resuming to fork the run.

**Settled**{.badge .settled} · Flow discovers skills from both `~/.claude/skills` and the project's `.claude/skills`.

Global and project-local skills, the same resolution Claude Code already uses. Cross-tool discovery (Cursor, Cline, and the rest) is deferred until a flow needs it.

```
flow new          # interactive: pick skills and doc-types
flow list         # show defined flows
flow edit <name>  # reopen the wizard, regenerate skills
flow rm <name>    # delete a flow

# generated skills are invoked through Claude Code:
/flow-build-feature-spike
/flow-build-feature-step
```
