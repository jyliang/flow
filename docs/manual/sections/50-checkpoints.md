Every run writes a numbered trail of documents. Nothing is hidden; nothing is binary. The trail *is* the state.

```
.flow/runs/build-feature/
  2026-05-20T14-30/
    01-spec.md
    02-plan.md
    03-findings.md          ← edit me, then resume
    04-change-summary.md
```

Open any file. Read what the agent decided. Change it. Then pick up where you left off — or rewind:

```
# resume from a checkpoint
flow resume build-feature/2026-05-20T14-30 --from 03
```

> **Forking** — To explore an alternative, edit a checkpoint doc and resume from it — that's a fork. No branch syntax, no DAG. A new run captures the new path while the original trail stays intact.
