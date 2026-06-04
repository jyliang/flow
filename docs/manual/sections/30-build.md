There's no config file to hand-write. `flow new` is an interactive wizard, and the two skills it generates are the only artifacts.

```
flow new
```

1. **Name the flow.** Something short — `build-feature`, `triage-bug`, `write-rfc`. It becomes the name of the generated skills.
2. **Pick skills, in order.** Flow lists what it found in your skill directories. Choose them in the sequence they should run. Linear only — no branches.
3. **Bind a doc-type to each.** For every skill, you choose which document it leaves behind, from the catalog. *You* decide the pairing — Flow never infers or imposes it.
4. **Done.** Flow compiles the chain into two skills and writes them out. There is nothing else to edit.

Two skills are generated — one per run mode:

```
flow-build-feature-spike   # run end-to-end
flow-build-feature-step    # pause at every doc
```

> **Editing later** — Run `flow edit <name>` — it reopens the wizard prefilled and regenerates both skills. The generated skills carry a "do not edit" header; change the flow, not the output.
