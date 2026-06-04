Flow runs as a Claude Code plugin. Install it from the marketplace:

```
claude plugin marketplace add jyliang/flow
claude plugin install flow@flow
```

Every command then appears under the `/flow:` namespace inside Claude Code.

### Where Flow finds your skills

When you build a flow, Flow discovers the skills you can chain from two places — global first, then project-local:

```
# global — shared across every project
~/.claude/skills/

# project-local — checked into the repo
./.claude/skills/
```

> **Note** — Cross-tool discovery (Cursor, Cline, and friends) is deferred — Flow reads Claude skills today. Local development: clone the repo and `make install` to point the plugin at your working copy.
