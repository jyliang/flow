#!/bin/sh
# Serve the composite docs over HTTP.
#
# The docs are `composite` doc-types: each index.html loads its prose
# (sections/*.md) and diagrams (diagrams/*.mermaid) at runtime via fetch().
# Browsers block fetch() of local files over file://, so double-clicking
# index.html shows empty sections. Serve over HTTP instead — that's all
# this script does.
#
#   ./docs/serve.sh [port]

set -e
cd "$(dirname "$0")"
PORT="${1:-8731}"

printf '\nFlow docs — serving on http://localhost:%s\n' "$PORT"
printf '  Conviction Doc : http://localhost:%s/founding/index.html\n' "$PORT"
printf '  The Manual     : http://localhost:%s/manual/index.html\n\n' "$PORT"
printf 'Ctrl-C to stop.\n\n'

exec python3 -m http.server "$PORT"
