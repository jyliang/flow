#!/usr/bin/env bash
# Scaffold a new eval task under evals/tasks/<id>/.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

task="${1:-}"
[ -z "$task" ] && {
    echo "Usage: make eval-task-new TASK=<id>" >&2
    exit 1
}

dest="$RUNTIME_ROOT/evals/tasks/$task"
[ -e "$dest" ] && { echo "Task already exists: $dest" >&2; exit 1; }

mkdir -p "$dest"

cat > "$dest/task.json" <<EOF
{
  "id": "$task",
  "type": "code",
  "title": "",
  "description": ""
}
EOF

cat > "$dest/prompt.md" <<EOF
# Prompt

Replace this with the exact prompt to pass to /flow:flow when running this eval.

> example: Add a /standup command that summarises my git activity over the last week.
EOF

# Render the task README from template, substituting {{task}}.
sed "s/{{task}}/$task/g" "$RUNTIME_ROOT/evals/templates/task-readme.md" > "$dest/README.md"

cat <<EOF
✓ Task scaffolded: evals/tasks/$task/

Next steps:
  1. Edit $dest/prompt.md           (the prompt to pass to /flow:flow)
  2. Edit $dest/README.md           (what this task evaluates, what good looks like)
  3. Edit $dest/task.json           (set title and description)
EOF
