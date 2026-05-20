#!/usr/bin/env bash
# Compare two recorded runs of the same task.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

task=""
run_a=""
run_b=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) task="$2"; shift 2 ;;
        --a)    run_a="$2"; shift 2 ;;
        --b)    run_b="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$task" ] || [ -z "$run_a" ] || [ -z "$run_b" ]; then
    echo "Usage: make eval-compare TASK=<id> A=<run-a> B=<run-b>" >&2
    exit 1
fi

dir_a="$RUNTIME_ROOT/evals/runs/$task/$run_a"
dir_b="$RUNTIME_ROOT/evals/runs/$task/$run_b"
[ -d "$dir_a" ] || { echo "missing: $dir_a" >&2; exit 1; }
[ -d "$dir_b" ] || { echo "missing: $dir_b" >&2; exit 1; }

field() { jq -r "$1 // \"—\"" "$2" 2>/dev/null || echo "—"; }

ka=$(field '.versions.kernel.sha_short' "$dir_a/manifest.json")
kb=$(field '.versions.kernel.sha_short' "$dir_b/manifest.json")
kab=$(field '.versions.kernel.branch'   "$dir_a/manifest.json")
kbb=$(field '.versions.kernel.branch'   "$dir_b/manifest.json")
ca=$(field '.versions.cell.sha_short'   "$dir_a/manifest.json")
cb=$(field '.versions.cell.sha_short'   "$dir_b/manifest.json")
cost_a=$(field '.metrics.cost_usd'      "$dir_a/manifest.json")
cost_b=$(field '.metrics.cost_usd'      "$dir_b/manifest.json")
dur_a=$(field '.metrics.duration_sec'   "$dir_a/manifest.json")
dur_b=$(field '.metrics.duration_sec'   "$dir_b/manifest.json")
proj_a=$(field '.project.path'          "$dir_a/manifest.json")
proj_b=$(field '.project.path'          "$dir_b/manifest.json")
branch_a=$(field '.project.branch'      "$dir_a/manifest.json")
branch_b=$(field '.project.branch'      "$dir_b/manifest.json")

echo
echo "Comparing task: $task"
echo "============================================================"
printf "                A: %s\n" "$run_a"
printf "                B: %s\n" "$run_b"
echo "------------------------------------------------------------"
printf "%-16s %-22s %-22s\n" "field"          "A"                       "B"
printf "%-16s %-22s %-22s\n" "kernel"         "$ka ($kab)"              "$kb ($kbb)"
printf "%-16s %-22s %-22s\n" "cell"           "$ca"                     "$cb"
printf "%-16s %-22s %-22s\n" "project"        "$(basename "$proj_a")"   "$(basename "$proj_b")"
printf "%-16s %-22s %-22s\n" "branch"         "$branch_a"               "$branch_b"
printf "%-16s %-22s %-22s\n" "cost (USD)"     "$cost_a"                 "$cost_b"
printf "%-16s %-22s %-22s\n" "duration (s)"   "$dur_a"                  "$dur_b"
echo

list_reviews() {
    local d="$1"
    if compgen -G "$d/reviews/*.md" >/dev/null; then
        for f in "$d/reviews"/*.md; do
            local name; name=$(basename "$f" .md)
            local lines; lines=$(wc -l < "$f" | tr -d ' ')
            printf "  %-20s (%s lines)\n" "$name" "$lines"
        done
    else
        echo "  (none)"
    fi
}

echo "Reviews on A:"
list_reviews "$dir_a"
echo "Reviews on B:"
list_reviews "$dir_b"
echo

# If both sides have a review by the same reviewer, suggest a side-by-side diff.
shared=()
if compgen -G "$dir_a/reviews/*.md" >/dev/null && compgen -G "$dir_b/reviews/*.md" >/dev/null; then
    for f in "$dir_a/reviews"/*.md; do
        n=$(basename "$f")
        [ -f "$dir_b/reviews/$n" ] && shared+=("$n")
    done
fi
if [ ${#shared[@]} -gt 0 ]; then
    echo "Shared reviewers — diff to compare prose feedback:"
    for n in "${shared[@]}"; do
        echo "  diff $dir_a/reviews/$n $dir_b/reviews/$n"
    done
    echo
fi

echo "Artifacts:"
echo "  A: ${dir_a#$RUNTIME_ROOT/}"
echo "  B: ${dir_b#$RUNTIME_ROOT/}"
echo
