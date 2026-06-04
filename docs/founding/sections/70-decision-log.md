| When | Decision |
|---|---|
| 2026-05-20 | **No source file — flows are authored interactively.** `flow new` is a wizard that generates the spike/step skills directly. Editing a flow means re-running it. |
| 2026-05-20 | **Skills discovered from `~/.claude` and project `.claude`.** Both global and project-local Claude skill dirs. Cross-tool support deferred. |
| 2026-05-20 | **User binds skill → doc-type at creation.** Flow does not infer the pairing. Keeps flow a pure, unopinionated substrate. |
| 2026-05-14 | **Flow is a pipeline-builder, not a fixed pipeline.** User assembles their own. Bootstrap catalog provides the vocabulary. |
| 2026-05-14 | **Doc-types are frontmatter + a template (markdown or HTML).** Purely descriptive — no DSL, no runtime, no execution semantics. |
| 2026-05-14 | **Linear chains for v1. DAGs deferred.** Forks happen by resuming from a checkpoint doc, not by branching mid-flow. |
| 2026-05-14 | **Spike vs step is the only mode toggle.** Trust vs review. No other knobs at the surface. |
| 2026-05-13 | **Flow does not use an LLM and does not improve skills.** Hard boundary. Flow is documentation expertise; skills and agents are external. |
