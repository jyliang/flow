---
name: spike-log
purpose: record what was tried and what we learned on an end-to-end run
audience: a human reviewing an unattended run · whoever picks the work back up
shape: thesis / decisions / what-shipped / what-we-learned / next
lifecycle: append-only — entries accrete chronologically as the run proceeds
format: markdown
maturity: stable
---

# spike-log

The trail an unattended (spike) run leaves behind — read by the human who reviews the result without having watched it happen.

A spike runs end to end without pausing, so its log *is* the human touchpoint. It records the thesis being tested, every decision the run made on its own (with the rationale), what got built, and what the run actually taught us — including evidence against the thesis.

## Template

~~~markdown
# Spike log: <thesis, one line>

> **Thesis:** <the one sentence this run set out to validate>
> **Started:** <ISO-8601 timestamp>

## Decisions

<Appended chronologically as the run makes each call. One block per decision.>

### <timestamp> — <short decision label>

- **Context:** <what was being decided, one sentence>
- **Chose:** <the option taken>
- **Why:** <one-sentence rationale>

## What shipped

<One-sentence lede. What exists at the end of the run, in plain English — not diff-level detail.>

## What we learned

<One-sentence lede. The honest read on the thesis.>

- **For:** <strongest evidence the thesis holds>
- **Against:** <strongest evidence it doesn't>
- **Falsifier:** <what would have disproved it; did it?>

## Next

<One-sentence lede. Continue iterating, or archive and reframe?>
~~~

## Example

> **Thesis:** A pure `git log` reader is enough for a useful standup digest.
>
> **Decisions** — *Default window* → since-midnight (matches a workday; one fewer flag). *Empty day* → print "no activity" rather than nothing (less confusing).
>
> **What we learned** — *For:* the digest matched a hand-written one on three sample days. *Against:* merge commits doubled some entries. *Falsifier:* a day with rebases — it did distort the count, so dedup is needed.

## Rules

- **DO** append decisions as they happen, with the rationale — the log is the audit trail.
- **DO** state evidence *against* the thesis as plainly as the evidence for it.
- **DO** end with a clear next move, not a shrug.
- **DO NOT** rewrite earlier entries to look prescient — the log is chronological.
- **DO NOT** dump the diff here; summarize what shipped in prose.
