#!/usr/bin/env bash
# Open $EDITOR on a long-form qualitative review for an eval run.
# Saves to evals/runs/<task>/<run-id>/reviews/<reviewer>.md.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

task=""
run_id=""
reviewer=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task)     task="$2"; shift 2 ;;
        --run)      run_id="$2"; shift 2 ;;
        --reviewer) reviewer="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$task" ] || [ -z "$run_id" ]; then
    echo "Usage: make eval-review TASK=<id> RUN=<run-id> [REVIEWER=<name>]" >&2
    exit 1
fi

run_dir="$RUNTIME_ROOT/evals/runs/$task/$run_id"
[ -d "$run_dir" ] || { echo "run not found: $run_dir" >&2; exit 1; }

# Default reviewer = git user, slugified.
if [ -z "$reviewer" ]; then
    raw=$(git config user.name 2>/dev/null || echo "human")
    reviewer=$(echo "$raw" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    [ -z "$reviewer" ] && reviewer="human"
fi

mkdir -p "$run_dir/reviews"
review_file="$run_dir/reviews/$reviewer.md"

# First-time render: pre-fill the template with run metadata.
if [ ! -f "$review_file" ]; then
    template="$RUNTIME_ROOT/evals/templates/review.md"
    [ -f "$template" ] || { echo "missing template: $template" >&2; exit 1; }
    reviewed_at=$(date -u +%FT%TZ)
    sed -e "s|{{run_id}}|$run_id|g" \
        -e "s|{{task}}|$task|g" \
        -e "s|{{reviewer}}|$reviewer|g" \
        -e "s|{{reviewed_at}}|$reviewed_at|g" \
        "$template" > "$review_file"

    # Append an artifact index so the reviewer has paths in-editor.
    {
        echo ""
        echo "---"
        echo ""
        echo "## Artifact index (for reading alongside)"
        echo ""
        echo "Manifest:"
        if [ -f "$run_dir/manifest.json" ] && command -v jq >/dev/null 2>&1; then
            jq -r '"  kernel: \(.versions.kernel.sha_short) (\(.versions.kernel.branch))",
                   "  cell:   \(.versions.cell.name) @ \(.versions.cell.sha_short)",
                   "  project: \(.project.path)",
                   "  branch:  \(.project.branch) vs \(.project.base)",
                   "  cost:    \(.metrics.cost_usd // "—")",
                   "  duration: \(.metrics.duration_sec // "—")"' "$run_dir/manifest.json"
        fi
        echo ""
        echo "Thread docs:"
        if [ -d "$run_dir/thread" ]; then
            find "$run_dir/thread" -type f -name '*.md' | sort | while read -r f; do
                printf "  %s\n" "${f#$RUNTIME_ROOT/}"
            done
        fi
        echo ""
        if [ -s "$run_dir/diff.patch" ]; then
            lines=$(wc -l < "$run_dir/diff.patch" | tr -d ' ')
            echo "Diff: evals/runs/$task/$run_id/diff.patch ($lines lines)"
        else
            echo "Diff: (empty)"
        fi
    } >> "$review_file"
fi

echo "Opening: $review_file"
"${EDITOR:-vi}" "$review_file"
echo "✓ Review saved: ${review_file#$RUNTIME_ROOT/}"
