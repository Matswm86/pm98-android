#!/bin/bash
# Click at window-relative coords inside the wine desktop. Usage: click.sh X Y [count]
set -euo pipefail
source "$(dirname "$0")/env.sh"
W=$(win_id); [ -n "$W" ] || { echo "no game window" >&2; exit 1; }
xdotool windowactivate --sync "$W" 2>/dev/null || true
xdotool windowraise "$W" 2>/dev/null || true
sleep 0.3
for _ in $(seq 1 "${3:-1}"); do
  xdotool mousemove --window "$W" "$1" "$2" click 1
  sleep 0.4
done
