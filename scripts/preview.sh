#!/usr/bin/env bash
# Serve the site locally and capture desktop + mobile screenshots.
#
#   ./scripts/preview.sh [path] [outdir]
#
# Examples:
#   ./scripts/preview.sh                                  # home (hero only)
#   ./scripts/preview.sh '/#projects'                     # one section
#   ./scripts/preview.sh all                              # every section
#   ./scripts/preview.sh /projects-details/flix-projects-details.html
#
# index.html hides every <section> behind `display: none` and reveals one at a
# time via hash links, so a screenshot of `/` shows ONLY the hero. Quote the
# path — an unquoted # starts a bash comment.
#
# Prefers Jekyll for exact fidelity; falls back to a plain static server,
# which renders everything correctly except that index.html's YAML front
# matter shows as stray text at the top of the page.

set -euo pipefail

PATH_TO_VIEW="${1:-/}"
OUTDIR="${2:-/tmp/portfolio-shots}"
PORT="${PORT:-4321}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$OUTDIR"
cd "$ROOT"

# Start the server in the background so we hold its exact PID. Killing by
# pattern would take down unrelated Jekyll servers, and a shared pidfile
# would collide between concurrent runs.
if bundle exec jekyll --version >/dev/null 2>&1; then
  echo "serving with jekyll on :$PORT"
  bundle exec jekyll serve --port "$PORT" >/dev/null 2>&1 &
  SERVED_BY="jekyll"
else
  echo "jekyll unavailable (try: bundle install) — falling back to static server"
  python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  SERVED_BY="static"
fi
SERVER_PID=$!

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Wait for the server to answer, and give up loudly rather than shooting
# screenshots at a dead port and failing later with a vaguer error.
ready=""
for _ in $(seq 1 40); do
  if curl -sf --noproxy '*' -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then
    ready=1
    break
  fi
  kill -0 "$SERVER_PID" 2>/dev/null || break   # server already exited
  sleep 0.25
done

if [ -z "$ready" ]; then
  echo "error: $SERVED_BY server never became reachable on port $PORT" >&2
  exit 1
fi

export NO_PROXY='*' HTTP_PROXY='' HTTPS_PROXY=''

if [ "$PATH_TO_VIEW" = "all" ]; then
  # The hero is captured from / with no hash. There is no #home, and the Home
  # nav link's #header target is a <header>, not a <section> — main.js only
  # reveals sections, so /#header hides the hero and renders a blank page.
  for s in "" about experience projects contact; do
    label="${s:-home}"
    frag="${s:+#$s}"
    node "$ROOT/scripts/shot.mjs" "http://127.0.0.1:$PORT/$frag" "$OUTDIR/$label-desktop.png" 1440 900
    node "$ROOT/scripts/shot.mjs" "http://127.0.0.1:$PORT/$frag" "$OUTDIR/$label-mobile.png" 390 844
  done
else
  URL="http://127.0.0.1:$PORT$PATH_TO_VIEW"
  node "$ROOT/scripts/shot.mjs" "$URL" "$OUTDIR/desktop.png" 1440 900
  node "$ROOT/scripts/shot.mjs" "$URL" "$OUTDIR/mobile.png" 390 844
fi

echo
echo "screenshots in $OUTDIR (served by $SERVED_BY)"
