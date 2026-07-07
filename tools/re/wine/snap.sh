#!/bin/bash
# Screenshot the wine desktop window -> $ORACLE_OUT/<name>.png.
# ffmpeg x11grab -window_id (the 07-02 walkthrough method, watch_original_screens.sh).
set -euo pipefail
source "$(dirname "$0")/env.sh"
W=$(win_id); [ -n "$W" ] || { echo "no game window" >&2; exit 1; }
ffmpeg -loglevel error -y -f x11grab -window_id "$W" -draw_mouse 0 \
  -i :1 -frames:v 1 "$ORACLE_OUT/${1:-view}.png"
echo "win=$W -> $ORACLE_OUT/${1:-view}.png"
