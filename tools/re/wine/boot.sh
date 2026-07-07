#!/bin/bash
# Boot MANAGER.EXE in a 640x480 wine virtual desktop (the only mode that renders AND
# accepts synthetic clicks on this box). Idempotent: reuses a running instance.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ -n "$(win_id)" ]; then echo "already running: window $(win_id)"; exit 0; fi

# FULL SCREEN: OFF is load-bearing (proven 06-24); byte-copy of the proven INI.
printf 'MUSIC: OFF\r\nMUSIC VOLUME: 100\r\nSOUND: OFF\r\nSOUND VOLUME: 100\r\nTRANSITIONS: ON\r\nFULL SCREEN: OFF\r\nSCREEN POSITION: 44, 44\r\n' > "$PM98_DIR/MANAGER.INI"

cd "$PM98_DIR"
nohup wine explorer /desktop=pm98,640x480 'C:\PM98\MANAGER.EXE' \
  > "$ORACLE_OUT/wine_boot.log" 2>&1 &

for i in $(seq 1 60); do
  sleep 1
  [ -n "$(win_id)" ] && { echo "window up after ${i}s: $(win_id)"; exit 0; }
done
echo "FAIL: no '$WIN_NAME' window after 60s (see $ORACLE_OUT/wine_boot.log)" >&2
exit 1
