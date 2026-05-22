---
name: spec
purpose: capture intent before planning — what and why, never how
audience: human reviewer · the next skill in the chain
shape: scope / decisions / design / constraints / verification / open
lifecycle: append-only within a run; a revision supersedes the prior spec
format: markdown
maturity: stable
---

# spec

The first checkpoint in most flows — read by a human approving direction and by the next skill consuming intent.

A spec answers *what* ships and *why* it matters. It never prescribes *how* — that belongs to the plan. Lead with the governing thought (the What/Why blockquote), then support it with sections a skimmer can re-orient on in ten seconds.

## Template

~~~markdown
# Spec: <subject>

> **What:** <one sentence — what this spec delivers>
> **Why:** <one sentence — the problem it solves or value it creates>

## Scope

<One-sentence lede. What's in, what's out.>

## Decisions

<One-sentence lede. Questions resolved while writing the spec — conclusions only, not the deliberation.>

## Design

<One-sentence lede. The shape of the solution at a high level.>

## Constraints

<One-sentence lede. Hard rules, guardrails, forbidden changes.>

## Verification

<One-sentence lede. What must be true once the work ships.>

- [ ] <thing to check>

## Open

<One-sentence lede, or go straight to the list if there's only one item.>

- <unresolved question for the next step>
~~~

## Example

> **What:** A `/standup` command that summarizes the day's git activity into a Slack-ready digest.
> **Why:** Engineers retype the same status by hand every morning; the data already lives in `git log`.
>
> **Scope** — In: a slash command reading `git log --since` for the current author. Out: multi-repo aggregation, calendar data.
>
> **Decisions** — Author scope only (no team rollup) — keeps v1 to one `git` call. Markdown output — Slack renders it directly.
>
> **Open** — Which time window is the default: since-midnight, or last-24h?

## Rules

- **DO** lead every section with a one-sentence conclusion, then the evidence.
- **DO** collapse a resolved question into a one-line conclusion under Decisions.
- **DO** push genuine unknowns to Open rather than guessing.
- **DO NOT** include implementation steps, file lists, or code — that is the plan's job.
- **DO NOT** drop a constraint or open question on revision; restructure freely, but preserve content.
