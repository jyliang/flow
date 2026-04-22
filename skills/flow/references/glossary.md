# Glossary

One term per concept, across every doc in this repo. Pick the term in the left column; avoid the terms in the middle.

## Reader

Two audiences scan this glossary:

- **Humans** editing a doc — pick the canonical term, don't guess.
- **Next authors (agents or humans)** — reference it when reviewing for drift.

## Terms

| Use | Don't use | Why |
|---|---|---|
| spec | Spec, the spec document, the spec file, the specification | One term. Lowercase. Refers to the content, not the file. Use the path (`01-spec-r<N>.md`) only when you mean the file literally. |
| plan | Plan, the plan document, the implementation plan | Same rule as spec. |
| findings | Findings, the findings document, the review output | Same rule as spec. Note: "findings" is plural; treat as a collective noun (`the findings say …`). |
| workstream folder | workstream directory, the folder, the workstream | The `agent/workstreams/<date>-<branch>/` directory that holds one piece of work. |
| stage | phase, pipeline step, pipeline stage | One of `explore` / `plan` / `implement` / `review` / `ship`. Phases are *within* a stage (e.g., a plan may have phases). |
| skill | Skill, skill file, the SKILL.md | Lowercase noun. The file path is `skills/<name>/SKILL.md` when you need to refer to the file. |
| rule | convention, guideline, principle | A rule is a one-line DO or DO NOT. A *principle* is higher-level guidance (use it only in `docs-style/SKILL.md`). |
| revision | revised version, update, new version | The `-r<N>` suffix on a workstream document. `01-spec-r2.md` is the second revision. |
| pipeline | flow, the flow, the full flow | The idea → PR sequence. "Flow" refers to the skill or the repo; "pipeline" refers to the sequence of stages. |
| draft PR | draft pull request, WIP PR, pre-review PR | The GitHub artifact produced at ship stage (and in spike mode) that a human reviews before merge. |
| boundary | handoff, transition point, stage gate | The point between two stages where the current doc is finalized and the next stage starts. Boundaries are where `AskUserQuestion` fires. |
| trigger phrase | trigger, keyword, activation phrase | The text in a skill's frontmatter `description:` that the skill loader matches on. |
| ship | publish, release, deliver | The stage that turns findings into a PR. Not "release" — that's GitHub-release terminology. |
| auto-fix | quick fix, trivial fix | A fix applied without asking, per the auto-fix rules in `ship/SKILL.md`. |

## How to extend this glossary

Add a row only when you catch a second term being used for an existing concept. Never add a term that appears in exactly one doc — it's not drift yet. Link the row's left column from the place you canonicalized it.
