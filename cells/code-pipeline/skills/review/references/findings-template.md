# Findings Document Template

The review stage fills this scaffold to produce the findings document the ship stage reads next. Copy the code block below into the thread file and fill the placeholders.

Save as `./agent/threads/<YYYY-MM-DD>-<branch>/03-review-r<N>.md`. PR-vs-local distinction lives in the frontmatter comment, not the filename.

```markdown
<!-- branch: [branch] · date: [YYYY-MM-DD] · author: [git user] · pr: [PR URL or omit for local] · base: [base branch] -->

# Findings: [PR "#<number> - <title>" or "Local changes on <branch>"] · review → ship

> **What:** [one sentence — what the change does]  
> **Why:** [one sentence — the spec/ticket goal it serves]

## Changes

[One-sentence lede. Technical summary: components involved, data flow, key implementation choices.]

### Files

- [path] — [what changed]

## Walkthrough

[One-sentence lede. End-to-end trace per audience — catches goal-level bugs that line-by-line review misses.]

- **[Audience 1]:** [entry → gate → output. Does the end state match the goal?]
- **[Audience 2]:** [same]

## Risk

[Rating: low / medium / high. Justify: files changed, hot paths, concurrency, revert difficulty, regression likelihood.]

## Findings

### Critical

[Issues that must be fixed before merge. Include findings from Error Handling Hunter, Test Coverage Analyzer, Pattern Reuse Scanner — classified by severity, not by source agent.]

### Suggestions

[Improvements that would be nicer but aren't blocking.]

### Nits

[Minor style/naming/formatting observations.]

## Verification

[One-sentence lede. Post-merge checks that can't be done from the diff alone — live commands, UI behavior, production config.]

- [ ] [thing to check]

## Open

[One-sentence lede. Decisions or clarifying questions the human must resolve before ship.]

- [ ] **[file:line]**: [decision or question requiring human judgment]

## Ship trail

<!-- Appended by ship stage — do not fill during review. -->
<!-- Records what ship did with the findings: auto-fixed (N), user-approved (N), skipped, deferred. See ship/SKILL.md Step 5. -->
```
