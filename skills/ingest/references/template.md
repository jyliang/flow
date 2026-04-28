# Skill template

Skill authors (human or agent) copy from this file when creating a new skill — it shows the directory layout, the `SKILL.md` skeleton, and which sections to include.

## How to lay out the directory

```text
skill-name/
├── SKILL.md                (required)
└── references/             (optional, for overflow)
    ├── interface/           (API surface files)
    └── topic.md             (topic-specific details)
```

## How to scaffold SKILL.md

Copy this skeleton and fill in the angle-bracket placeholders.

````markdown
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

- **DO** <correct pattern>
- **DO NOT** <common LLM mistake>

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

- Topic A: `references/topic-a.md`
- Topic B: `references/topic-b.md`
````

## How to choose which sections to include

| Section | When to include |
|---|---|
| Goal | Always |
| Quick start | Library or tool skills with setup steps |
| Fresh start | When LLM training data conflicts with correct usage |
| How to... | Always — this is the core of every skill |
| Additional references | When `SKILL.md` exceeds ~200 lines |
