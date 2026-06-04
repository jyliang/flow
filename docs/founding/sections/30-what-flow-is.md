**Settled**{.badge .settled} · Flow is a pipeline-builder CLI.

Users assemble their own pipelines from skills and doc-types. Flow does not ship "the one true pipeline" — it ships the construction kit and the doc-type catalog.

**Settled**{.badge .settled} · A flow is a linear chain. Forks happen by starting a new flow from a checkpoint doc, not by branching mid-flow.

DAGs were considered and rejected for v1. They add graph editing, cycle detection, parallel execution, and visualization burden — for a capability (forking) that linear-plus-checkpoint gives us for free.

**Settled**{.badge .settled} · Two execution modes, one toggle: spike and step.

**Spike** runs end-to-end, never pauses, produces a spike log. **Step** pauses at every doc for human review, edit, or abort. This collapses the "too many make options" complaint into one axis: trust vs review.

**Settled**{.badge .settled} · Each flow compiles to two generated skills: `flow-{name}-spike` and `flow-{name}-step`.

There is no separate source file. `flow new` is an interactive wizard, and the two generated skills are the only artifacts. Editing a flow means re-running the wizard — `flow edit` reopens it prefilled and regenerates both skills.
