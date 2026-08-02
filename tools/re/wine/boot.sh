#!/bin/bash
# Boot MANAGER.EXE in a 640x480 wine virtual desktop (the only mode that renders AND
# accepts synthetic clicks on this box). Idempotent: reuses a running instance.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ -n "$(win_id)" ]; then echo "already running: window $(win_id)"; exit 0; fi

# FULL SCREEN: OFF is load-bearing (proven 06-24); byte-copy of the proven INI.
# PM98_TRANSITIONS=OFF for a capture run: with fades ON, a passive recorder banks mid-blit
# frames that pollute pixel diffs against the port. Default stays ON (the proven config).
printf 'MUSIC: OFF\r\nMUSIC VOLUME: 100\r\nSOUND: OFF\r\nSOUND VOLUME: 100\r\nTRANSITIONS: %s\r\nFULL SCREEN: OFF\r\nSCREEN POSITION: 44, 44\r\n' \
  "${PM98_TRANSITIONS:-ON}" > "$PM98_DIR/MANAGER.INI"

# PM98_EXE names the executable inside C:\PM98 to boot. It exists for ONE reason
# (2026-08-02, s91): a SEMIFINAL / FINAL cup draw cannot be captured from the stock EXE,
# because FUN_004d9a00 refuses to paint a draw the managed club is not in (s89), and five
# career drives failed to get there. `build_hack_exe.py --cheats=cupdraw_always` flips that
# one gate byte and nothing else. The stock EXE stays the default.
cd "$PM98_DIR"
nohup wine explorer "/desktop=$PM98_DESKTOP,640x480" "C:\\PM98\\${PM98_EXE:-MANAGER.EXE}" \
  > "$ORACLE_OUT/wine_boot.log" 2>&1 &

for i in $(seq 1 60); do
  sleep 1
  [ -n "$(win_id)" ] && { echo "window up after ${i}s: $(win_id)"; exit 0; }
done
echo "FAIL: no '$WIN_NAME' window after 60s (see $ORACLE_OUT/wine_boot.log)" >&2
exit 1
