#!/usr/bin/env bash
# Open a PR for current cell edits.
# - If origin is set and gh is available: push branch, open draft PR.
# - Otherwise: format-patch and tell the user how to apply once a remote is wired.
# cell-pr.sh <name|""> <title> <body>

set -euo pipefail

FLOW_HOME="${FLOW_HOME:-$HOME/.flow}"

name="${1:-}"
title="${2:-}"
body="${3:-}"

if [ -z "$name" ]; then
    if [ -L "$FLOW_HOME/active-cell" ]; then
        target=$(readlink "$FLOW_HOME/active-cell")
        name=$(basename "$target")
    else
        echo "No active cell and NAME not given." >&2
        exit 1
    fi
else
    target="$FLOW_HOME/cells/$name"
fi

if [ ! -d "$target/.git" ]; then
    echo "Not a cell repo: $target" >&2
    exit 1
fi

cd "$target"
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "Refusing to open PR from $branch — cut a branch first via cell-branch.sh." >&2
    exit 1
fi

if [ -z "$title" ]; then
    title="evolution: ${branch}"
fi
if [ -z "$body" ]; then
    body="Auto-opened by reflect."
fi

if git remote get-url origin >/dev/null 2>&1 && command -v gh >/dev/null 2>&1; then
    git push -u origin "$branch"
    gh pr create --draft --title "$title" --body "$body"
    echo "✓ Draft PR opened on origin for branch '$branch'."
else
    patch_dir="$FLOW_HOME/state/patches"
    mkdir -p "$patch_dir"
    safe_branch="${branch//\//-}"
    out="$patch_dir/${name}-$(date +%Y%m%d-%H%M%S)-${safe_branch}.patch"
    git format-patch -1 --stdout > "$out"
    cat <<EOF
No remote (or gh missing) for cell '$name'.
Patch staged: $out

To finish: link a remote, then push and open the PR.
  make cell-link-remote URL=git@github.com:you/your-cell.git
  cd ${target} && git push -u origin ${branch}
EOF
fi
