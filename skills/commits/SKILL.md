---
name: commits
description: Commit practices for implementation work — atomic commits, frequent checkpoints, never commit with failing tests. Auto-triggers when committing code or completing implementation steps.
metadata:
  short-description: Atomic commits and commit discipline
  internal: true
---

# Commit Discipline

## Goal

Maintain a clean, deployable commit history during implementation.

## How to commit during implementation

Commit after each working increment — one logical change per commit.

```bash
git add <specific-files>
git commit -m "Add user authentication endpoint"
```

* **DO** commit after each completed feature or working increment
* **DO** run the full test suite before committing
* **DO** use clear, descriptive commit messages explaining what was done
* **DO NOT** accumulate too many changes without committing
* **DO NOT** commit with failing tests — this is non-negotiable
* **DO NOT** bypass pre-commit hooks with `--no-verify` unless explicitly justified

## Critical commit checkpoints

Commit immediately after:
- Code generation (scaffolding, generators) — BEFORE any modifications
- Initial project setup
- Each completed phase or feature
- Adding or fixing tests
- Bug fixes
- Before starting new major work

## How to handle generated code

1. Run the generator command
2. Commit the generated code immediately with message like `"Generate [feature] scaffolding"`
3. Make modifications in a separate commit

* **DO NOT** mix generated code with manual modifications in the same commit
