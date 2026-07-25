#!/bin/bash
# Click at window-relative coords inside the wine desktop. Usage: click.sh X Y [count]
set -euo pipefail
source "$(dirname "$0")/env.sh"
W=$(win_id); [ -n "$W" ] || { echo "no game window" >&2; exit 1; }
# PM98_NO_RAISE=1 leaves the desktop stacking alone (the game window keeps stealing focus
# from whatever the owner is doing otherwise). Clicks are XTEST-warped to window-relative
# coords either way, so they still land; only the raise is skipped.
if [ "${PM98_NO_RAISE:-0}" != "1" ]; then
  xdotool windowactivate --sync "$W" 2>/dev/null || true
  xdotool windowraise "$W" 2>/dev/null || true
fi
sleep 0.3
for _ in $(seq 1 "${3:-1}"); do
  xdotool mousemove --window "$W" "$1" "$2" click 1
  sleep 0.4
done
