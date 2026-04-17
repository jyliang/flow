# Skill Template

Copy and customize this structure for new skills.

## Directory structure

```
skill-name/
├── SKILL.md                (required)
└── references/             (optional, for overflow)
    ├── interface/           (API surface files)
    └── topic.md             (topic-specific details)
```

## SKILL.md template

```markdown
---
name: <skill-name>
description: <One sentence: what capability this provides and when to use it>
metadata:
  short-description: <Compressed version>
---

# <Skill Title>

## Goal

<1-2 sentences: what this skill enables>

## How to <do thing A>

```<lang>
<code example>
```

* **DO** <correct pattern>
* **DO NOT** <common LLM mistake>

## How to <do thing B>

### Step 1: <substep>

```<lang>
<code>
```

### Step 2: <substep>

```<lang>
<code>
```

## Additional references

* Topic A: `references/topic-a.md`
* Topic B: `references/topic-b.md`
```

## Section usage guide

| Section | When to include |
|---|---|
| Goal | Always |
| Quick start | Library/tool skills with setup steps |
| Fresh start | When LLM training data conflicts with correct usage |
| How to... | Always — this is the core of every skill |
| Additional references | When SKILL.md exceeds ~200 lines |
