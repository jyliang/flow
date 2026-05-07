#!/usr/bin/env bash
# Capture a flow run as an eval record.
#
# Discovers the most recent thread under <project>/agent/threads/, copies it,
# generates a diff against the base branch, and writes a manifest pinned to
# the current kernel and active-cell SHAs.

set -euo pipefail

RUNTIME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

task=""
thread_dir=""
project_dir=""
base_branch="main"
cost_usd="null"
duration_sec="null"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task)     task="$2"; shift 2 ;;
        --thread)   thread_dir="$2"; shift 2 ;;
        --project)  project_dir="$2"; shift 2 ;;
        --base)     base_branch="$2"; shift 2 ;;
        --cost)     cost_usd="$2"; shift 2 ;;
        --duration) duration_sec="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

[ -z "$task" ] && {
    echo "Usage: make eval-record TASK=<id> [PROJECT=<path>] [THREAD=<dir>] [BASE=main] [COST=<usd>] [DURATION=<sec>]" >&2
    exit 1
}

if [ ! -d "$RUNTIME_ROOT/evals/tasks/$task" ]; then
    echo "Task not found: $task" >&2
    echo "Available tasks:" >&2
    ls "$RUNTIME_ROOT/evals/tasks" 2>/dev/null | grep -v '^\.gitkeep$' | sed 's/^/  /' >&2 || echo "  (none — scaffold one with: make eval-task-new TASK=<id>)" >&2
    exit 1
fi

# Discover thread_dir if not given.
if [ -z "$thread_dir" ]; then
    [ -z "$project_dir" ] && project_dir="$(pwd)"
    threads_root="$project_dir/agent/threads"
    if [ ! -d "$threads_root" ]; then
        echo "No agent/threads/ in $project_dir." >&2
        echo "Pass --thread <dir> explicitly, or run from a project that has flow threads." >&2
        exit 1
    fi
    thread_dir=$(find "$threads_root" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n1)
    [ -z "$thread_dir" ] && { echo "No threads found in $threads_root" >&2; exit 1; }
fi

[ -d "$thread_dir" ] || { echo "Thread dir not found: $thread_dir" >&2; exit 1; }

# Derive project_dir from thread_dir if still unset.
if [ -z "$project_dir" ]; then
    project_dir=$(git -C "$thread_dir" rev-parse --show-toplevel 2>/dev/null) || {
        echo "Could not derive project dir from $thread_dir; pass --project explicitly" >&2
        exit 1
    }
fi

# Derive branch: prefer spec.md frontmatter, fall back to the project's HEAD.
branch=""
if [ -f "$thread_dir/spec.md" ]; then
    branch=$(grep -E '^branch:[[:space:]]' "$thread_dir/spec.md" 2>/dev/null | head -n1 | sed -E 's/^branch:[[:space:]]*//' | tr -d '"')
fi
[ -z "$branch" ] && branch=$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Pin versions.
kernel_sha=$(git -C "$RUNTIME_ROOT" rev-parse HEAD)
kernel_sha7=${kernel_sha:0:7}
kernel_branch=$(git -C "$RUNTIME_ROOT" rev-parse --abbrev-ref HEAD)

cell_path=""
cell_name="(none)"
cell_sha=""
cell_sha7=""
cell_branch=""
if [ -L "$FLOW_HOME/active-cell" ]; then
    cell_path=$(readlink "$FLOW_HOME/active-cell")
    cell_name=$(basename "$cell_path")
    if [ -d "$cell_path/.git" ]; then
        cell_sha=$(git -C "$cell_path" rev-parse HEAD 2>/dev/null || echo "")
        cell_sha7=${cell_sha:0:7}
        cell_branch=$(git -C "$cell_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    fi
fi

# Run-id and destination.
ts=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
run_id="${ts}-${kernel_sha7}"
dest="$RUNTIME_ROOT/evals/runs/$task/$run_id"
mkdir -p "$dest/reviews"

# Copy thread (skip if missing).
if [ -d "$thread_dir" ]; then
    cp -R "$thread_dir" "$dest/thread"
fi

# Generate diff. base_branch...branch shows what's on the branch since it diverged from base.
diff_path="$dest/diff.patch"
if [ -n "$branch" ] && git -C "$project_dir" rev-parse --verify "$base_branch" >/dev/null 2>&1; then
    git -C "$project_dir" diff "$base_branch...$branch" > "$diff_path" 2>/dev/null || {
        echo "  warning: git diff $base_branch...$branch failed; trying $base_branch..HEAD" >&2
        git -C "$project_dir" diff "$base_branch..HEAD" > "$diff_path" 2>/dev/null || : > "$diff_path"
    }
else
    : > "$diff_path"
    echo "  warning: could not generate diff — branch=$branch base=$base_branch" >&2
fi

# Snapshot the prompt.
[ -f "$RUNTIME_ROOT/evals/tasks/$task/prompt.md" ] && cp "$RUNTIME_ROOT/evals/tasks/$task/prompt.md" "$dest/prompt.md"

# Manifest.
recorded_at=$(date -u +%FT%TZ)
jq -n \
  --arg run_id "$run_id" \
  --arg task "$task" \
  --arg recorded_at "$recorded_at" \
  --arg kernel_sha "$kernel_sha" \
  --arg kernel_sha7 "$kernel_sha7" \
  --arg kernel_branch "$kernel_branch" \
  --arg cell_name "$cell_name" \
  --arg cell_sha "$cell_sha" \
  --arg cell_sha7 "$cell_sha7" \
  --arg cell_branch "$cell_branch" \
  --arg project_path "$project_dir" \
  --arg branch "$branch" \
  --arg base "$base_branch" \
  --arg thread_src "$thread_dir" \
  --argjson cost "$cost_usd" \
  --argjson duration "$duration_sec" \
  '{
     run_id: $run_id,
     task: $task,
     recorded_at: $recorded_at,
     versions: {
       kernel: { sha: $kernel_sha, sha_short: $kernel_sha7, branch: $kernel_branch },
       cell:   { name: $cell_name, sha: $cell_sha, sha_short: $cell_sha7, branch: $cell_branch }
     },
     project: { path: $project_path, branch: $branch, base: $base },
     source: { thread_dir: $thread_src },
     metrics: { cost_usd: $cost, duration_sec: $duration },
     notes: ""
   }' > "$dest/manifest.json"

cat <<EOF
✓ Recorded run: $task/$run_id
  → $dest

  versions: kernel=$kernel_sha7 ($kernel_branch)  cell=$cell_name@$cell_sha7
  project:  $project_dir
  branch:   $branch  (vs $base_branch)
  thread:   $thread_dir

Next:
  make eval-review TASK=$task RUN=$run_id
EOF
