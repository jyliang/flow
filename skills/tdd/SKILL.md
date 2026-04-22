---
name: tdd
description: Test-driven development discipline for implementation work. Auto-triggers when writing tests, implementing features, or working through implementation plans.
metadata:
  short-description: TDD discipline for implementation
  internal: true
---

# TDD Discipline

Auto-triggered skill read by the implementing agent while writing tests or code. Enforces test-first development and strict pass requirements.

## Goal

Make every implementation step start with a failing test and end with a passing one — no exceptions.

## How to implement a feature

Three steps: write tests, implement, verify.

### Step 1: Write tests first

Write tests covering the expected behavior before writing implementation code.

#### Rules

- **DO** write tests that cover happy path, edge cases, and error scenarios.
- **DO NOT** write empty test bodies, skipped tests, or commented-out tests.
- **DO NOT** create placeholder implementations — write production-ready code.

### Step 2: Implement the code

Write the minimum code to make the tests pass.

#### Rules

- **DO** study existing source code before implementing — don't assume features aren't already implemented.
- **DO NOT** guess requirements — use `AskUserQuestion` if unsure (see `skills/flow/references/user-interaction.md`).

### Step 3: Run tests and verify

Run the relevant test suite after each implementation step.

#### Rules

- **DO** capture and study test output.
- **DO** fix failures immediately before proceeding.
- **DO NOT** move to the next step with failing tests.
- **DO NOT** mark steps complete without all tests passing.

## How to handle test failures

1. Investigate the failure immediately.
2. Fix the test or the code — never comment out or skip a failing test.
3. Re-run and verify the fix.
4. Document non-obvious fixes.

## Testing scope

What to cover and at which level:

- Unit tests for business logic.
- Integration tests for workflows (use real dependencies where patterns exist — inspect existing tests for examples).
- E2E tests for critical user paths.
- Think about the full user journey, not just the happy path.
