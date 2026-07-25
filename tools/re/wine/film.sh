#!/bin/bash
# Record the wine desktop window to PNG frames. For screens that ANIMATE (the cup-draw
# drum, the pre-match line-up reveal, screen transitions) a single snap.sh is useless —
# the frame rate and the sprite order are the thing being captured.
#   film.sh NAME SECONDS [FPS]   -> $ORACLE_OUT/film_NAME/f%04d.png
set -euo pipefail
source "$(dirname "$0")/env.sh"
W=$(win_id); [ -n "$W" ] || { echo "no game window" >&2; exit 1; }
NAME="${1:?name}"; SECS="${2:-10}"; FPS="${3:-25}"
DIR="$ORACLE_OUT/film_$NAME"
rm -rf "$DIR"; mkdir -p "$DIR"
ffmpeg -loglevel error -y -f x11grab -framerate "$FPS" -window_id "$W" -draw_mouse 0 \
  -i "$DISPLAY" -t "$SECS" "$DIR/f%04d.png"
echo "$DIR ($(ls "$DIR" | wc -l) frames at ${FPS}fps)"
