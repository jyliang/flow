---
name: decision-record
purpose: capture why we chose X over Y, at the moment of choosing
audience: future readers (human or agent) reconstructing the reasoning
shape: context / decision / alternatives / consequences / status
lifecycle: immutable once accepted; a later record supersedes it by reference
format: markdown
maturity: stable
---

# decision-record

A durable note explaining a choice — read months later by whoever asks "why is it built this way?"

A decision record freezes the reasoning while it's fresh: the forces in play, the option taken, the options rejected and why, and what the choice commits you to. It is written to be read out of context, so it states the situation before the verdict.

## Template

~~~markdown
# Decision: <short title of the choice>

> **Status:** <proposed | accepted | superseded by <link>>
> **Date:** <YYYY-MM-DD>

## Context

<One-sentence lede. The forces at play — what made this decision necessary, the constraints, the tensions.>

## Decision

<One-sentence lede. What we chose, stated plainly — "We will do X.">

## Alternatives

<What else was on the table and why each was set aside. One line per option.>

- **<option>** — <why not>

## Consequences

<One-sentence lede. What this choice commits us to — the good, the bad, and what gets harder.>

## Status

<proposed | accepted | superseded — and by what, if superseded.>
~~~

## Example

> **Decision: Linear chains, not DAGs, for v1.** Status: accepted.
>
> **Context** — Flows could branch, but graph editing brings cycle detection, parallel execution, and visualization cost.
>
> **Decision** — A flow is a linear chain; forks happen by resuming from a checkpoint, not by branching mid-flow.
>
> **Alternatives** — *Full DAG* — rejected: editing and visualization burden for a capability checkpoints already give us. *Conditional steps* — deferred: no flow needs them yet.
>
> **Consequences** — Forking is free and the model stays tiny; genuinely parallel pipelines wait for a later version.

## Rules

- **DO** write the context so the record stands alone, read a year later.
- **DO** record the alternatives you rejected — the *why-not* is the value.
- **DO** mark status honestly; supersede by linking the newer record, never by editing.
- **DO NOT** rewrite an accepted record to match what you later wished you'd decided.
- **DO NOT** bury the decision — state it in one plain sentence under Decision.
