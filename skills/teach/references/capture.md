# Capturing a Skill from Conversation

When the user says "teach this", "capture this", or "turn this into a skill" mid-conversation, extract the pattern from what just happened.

## What to extract

1. **The goal** — what was the user trying to accomplish?
2. **The approach** — what tools, commands, or code patterns were used?
3. **Corrections** — where did Claude go wrong and what fixed it? These become DO/DON'T rules.
4. **The final shape** — what does the correct output look like?

## Extraction process

1. Scan the conversation for:
   - Tools called and their parameters
   - Code written or modified
   - User corrections ("no, do it this way", "don't use X")
   - The sequence of steps that worked

2. Identify what's reusable vs. what's specific to this instance:
   - File paths, variable names, specific values -> parameterize or omit
   - The pattern, sequence, tool choices -> keep

3. Draft a skill with:
   - Each step as a `## How to` recipe
   - Each correction as a `* **DO NOT**` rule
   - The working approach as code examples

4. Ask the user to review before writing the skill file.
