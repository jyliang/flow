- **Spike**{.badge .spike} runs end-to-end, never pauses, and writes a **spike log** of what it did. Reach for it when you trust the flow and want a draft fast.
- **Step**{.badge .step} pauses at every checkpoint with **Yes / Adjust / Pause**. Edit the document, advance, or stop and resume later. Reach for it when the work needs your judgment in the loop.

Invoke the generated skill in Claude Code:

```
# run it all at once
/flow:build-feature-spike

# walk it doc by doc
/flow:build-feature-step
```
