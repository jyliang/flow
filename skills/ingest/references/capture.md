# Capturing a skill from conversation

You are the capturing agent: when the user says `teach this`, `capture this`, or `turn this into a skill` mid-conversation, extract the reusable pattern from what just happened and draft a skill from it.

## How to extract the pattern

Pull four things out of the conversation, in this order.

| Element | What to look for |
|---|---|
| Goal | What was the user trying to accomplish? |
| Approach | What tools, commands, or code patterns were used? |
| Corrections | Where did Claude go wrong and what fixed it? These become DO / DO NOT rules. |
| Final shape | What does the correct output look like? |

## How to turn extraction into a skill

Walk these steps in order.

### Step 1: Scan the conversation

Scan for:

- Tools called and their parameters.
- Code written or modified.
- User corrections (`no, do it this way`, `don't use X`).
- The sequence of steps that worked.

### Step 2: Separate reusable from instance-specific

- File paths, variable names, specific values — parameterize or omit.
- The pattern, sequence, and tool choices — keep.

### Step 3: Draft the skill

Draft with:

- Each step as a `## How to` recipe.
- Each correction as a `**DO NOT**` rule.
- The working approach as code examples.

### Step 4: Confirm the outline

Use `AskUserQuestion` to confirm the outline before writing the skill file. See `skills/run/references/user-interaction.md`.
