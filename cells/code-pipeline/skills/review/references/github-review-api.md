# GitHub Review API

## Posting a review with inline comments

Use `gh api` to post a single review containing all comments.

### Building the review payload

Construct the JSON payload with `jq` (never with string interpolation — avoids quoting bugs):

```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR_NUMBER=123

# Build comments array in a temp file
cat > /tmp/review-comments.json <<'EOF'
[
  {
    "path": "src/feature/handler.ts",
    "line": 42,
    "body": "**Bug**: Possible nil crash\n\n`user.name` is force-unwrapped but the API can return null for deleted accounts.\n\n```ts\nconst name = user.name ?? 'Unknown'\n```"
  }
]
EOF

# Post the review
jq -n --slurpfile comments /tmp/review-comments.json '{
  event: "COMMENT",
  body: "**Automated Review Summary**\n\n## Items requiring human attention\n\n- [ ] **handler.ts:42** — Nil safety for deleted accounts\n\n## Stats\n- Files reviewed: 5\n- Comments: 1",
  comments: $comments[0]
}' | gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews" \
  --method POST \
  --input -
```

* **DO** use `jq -n` to build JSON — it handles escaping correctly
* **DO** write comments to a temp file first, then compose the final payload
* **DO NOT** use bash heredocs with variable interpolation for JSON
* **DO NOT** use `--field` / `-f` flags for complex nested JSON — use `--input`

### Line number mapping

The `line` field refers to the line number in the **new version** of the file (right side of the diff). For deletions, use `side: "LEFT"` and the old line number.

For multi-line comments (highlight a range):

```json
{
  "path": "file.ts",
  "start_line": 10,
  "line": 15,
  "start_side": "RIGHT",
  "side": "RIGHT",
  "body": "comment spanning lines 10-15"
}
```

* **DO** verify line numbers against the actual file content before posting
* **DO NOT** guess line numbers from the diff hunk headers — count from the file

### Error handling

If the review fails (e.g., line number out of range):
1. Check that all `path` values match the diff exactly (relative to repo root)
2. Check that all `line` values are within the diff range
3. Retry with corrected values — do not silently skip

If a single comment has a bad line number, remove it and post the rest rather than failing the entire review.
