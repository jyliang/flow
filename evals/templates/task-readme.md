# {{task}}

**What this task evaluates:** _(fill in: what aspects of flow are we testing here? doc quality on a fresh-repo task? code quality on a bugfix? something else?)_

## Prompt

See `prompt.md`. Pass that to `/flow:flow` verbatim when running this eval.

## How to run a fresh run

1. Open a Claude Code session in the target project (or set up a fixture for it).
2. Run `/flow:flow` with the prompt from `prompt.md`. Let flow walk through the stages — answer boundary prompts the way a real user would.
3. After flow ships (or pauses), capture from this repo:
   ```
   make eval-record TASK={{task}} PROJECT=<path-to-project>
   ```
   Add `COST=<usd> DURATION=<sec>` if you tracked them.
4. Review:
   ```
   make eval-review TASK={{task}} RUN=<run-id>
   ```

## What's a good outcome?

_(fill in: what does flow doing well on this task look like? a tight diff? a plan that referenced the right files? specifics that the reviewer should look for — these become the "what should flow learn" section anchors.)_

## Notes

_(running history of observations across runs of this task — what's been improving, what's still a problem, what we've tried.)_
