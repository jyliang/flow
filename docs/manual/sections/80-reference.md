| Command | What it does |
|---|---|
| `flow new` | Interactive wizard: name the flow, pick skills in order, bind a doc-type to each. Generates the spike + step skills. |
| `flow list` | Show every flow you've defined. |
| `flow edit <name>` | Reopen the wizard prefilled and regenerate both skills. |
| `flow rm <name>` | Delete a flow and its generated skills. |
| `flow resume <run> --from <NN>` | Resume a run from checkpoint `NN`. Edit the doc first to fork. |
| `/flow:<name>-spike` | Run the flow end-to-end, no pauses. Emits a spike log. |
| `/flow:<name>-step` | Run the flow pausing at every doc for review, edit, or abort. |
