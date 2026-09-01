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

if bundle exec jekyll --version >/dev/null 2>&1; then
  echo "serving with jekyll on :$PORT"
  bundle exec jekyll serve --port "$PORT" --detach >/dev/null
  SERVED_BY="jekyll"
else
  echo "jekyll unavailable (try: bundle install) — falling back to static server"
  python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  echo $! > /tmp/portfolio-preview.pid
  SERVED_BY="static"
fi

cleanup() {
  if [ "$SERVED_BY" = "jekyll" ]; then
    pkill -f "jekyll serve" 2>/dev/null || true
  else
    kill "$(cat /tmp/portfolio-preview.pid 2>/dev/null)" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Wait for the server to answer.
for _ in $(seq 1 40); do
  if curl -sf --noproxy '*' -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then break; fi
  sleep 0.25
done

export NO_PROXY='*' HTTP_PROXY='' HTTPS_PROXY=''

if [ "$PATH_TO_VIEW" = "all" ]; then
  for s in home about experience projects contact; do
    node "$ROOT/scripts/shot.mjs" "http://127.0.0.1:$PORT/#$s" "$OUTDIR/$s-desktop.png" 1440 900
    node "$ROOT/scripts/shot.mjs" "http://127.0.0.1:$PORT/#$s" "$OUTDIR/$s-mobile.png" 390 844
  done
else
  URL="http://127.0.0.1:$PORT$PATH_TO_VIEW"
  node "$ROOT/scripts/shot.mjs" "$URL" "$OUTDIR/desktop.png" 1440 900
  node "$ROOT/scripts/shot.mjs" "$URL" "$OUTDIR/mobile.png" 390 844
fi

echo
echo "screenshots in $OUTDIR (served by $SERVED_BY)"
