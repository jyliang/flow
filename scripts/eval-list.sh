#!/usr/bin/env bash
# List eval tasks and recorded runs.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Tasks:"
found=0
for d in "$RUNTIME_ROOT/evals/tasks"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    [ "$name" = ".gitkeep" ] && continue
    title=""
    if [ -f "$d/task.json" ] && command -v jq >/dev/null 2>&1; then
        title=$(jq -r '.title // ""' "$d/task.json" 2>/dev/null)
    fi
    printf "  %-32s %s\n" "$name" "$title"
    found=$((found + 1))
done
if [ $found -eq 0 ]; then echo "  (none — scaffold one with: make eval-task-new TASK=<id>)"; fi

echo
echo "Runs:"
found=0
for task_dir in "$RUNTIME_ROOT/evals/runs"/*/; do
    [ -d "$task_dir" ] || continue
    task=$(basename "$task_dir")
    [ "$task" = ".gitkeep" ] && continue
    for run_dir in "$task_dir"*/; do
        [ -d "$run_dir" ] || continue
        run_id=$(basename "$run_dir")
        review_count=$(find "$run_dir/reviews" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
        kernel="?"
        if [ -f "$run_dir/manifest.json" ] && command -v jq >/dev/null 2>&1; then
            kernel=$(jq -r '.versions.kernel.sha_short // "?"' "$run_dir/manifest.json" 2>/dev/null)
        fi
        plural="s"
        [ "$review_count" = "1" ] && plural=""
        printf "  %-22s %-40s kernel=%s  %s review%s\n" "$task" "$run_id" "$kernel" "$review_count" "$plural"
        found=$((found + 1))
    done
done
if [ $found -eq 0 ]; then echo "  (none — capture one with: make eval-record TASK=<id>)"; fi
