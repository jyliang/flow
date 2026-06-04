A flow is a chain of **(skill, doc-type)** pairs. The skill does the work; the doc-type is the document it hands to the next step. Every document is a checkpoint you can read, edit, and resume from.

Flow doesn't host the model, judge the output, or improve your skills — those belong to you and to your agents. Flow's one job is knowing *what kind of document belongs between skill A and skill B*, and making every handoff a human-readable artifact instead of opaque agent state.

It ships the construction kit and a catalog of doc-types — not one fixed pipeline. You build your own.

> **In one line** — Assemble a flow → run it **spike** (all at once) or **step** (pausing at every doc) → inspect, edit, or fork from any checkpoint.
