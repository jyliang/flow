---
name: parallel
description: Guidelines for using parallel subagents effectively — when to parallelize, when to serialize, and how to preserve context. Auto-triggers during exploration, review, and implementation work.
metadata:
  short-description: Parallel subagent usage patterns
  internal: true
---

# Parallel Agents

## Goal

Maximize throughput by using parallel subagents for independent work while serializing operations that must be sequential.

## How to parallelize implementation work

Spawn parallel subagents for all independent operations:

- Reading multiple files simultaneously
- Searching codebase across different areas
- Implementing changes across multiple files
- Exploring directories and understanding structure
- Researching technical concepts via web search

* **DO** spawn multiple subagents in a single turn when tasks are independent
* **DO** use subagents for all file edits to preserve main context
* **DO NOT** edit files directly in the main context during implementation loops

## How to handle sequential operations

Use a single subagent for operations that must not conflict:

- Running tests
- Running build commands
- Database migrations
- Any operation with shared mutable state

## How to explore large codebases

For broad exploration, spawn subagents to:
1. Find and read all files relevant to the task
2. Return file paths and implementation details
3. Search for existing implementations before creating new ones

* **DO** search for existing implementations before writing new code
* **DO NOT** assume a feature isn't implemented — study the source code first
