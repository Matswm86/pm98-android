#!/bin/bash
# Print "WPID LPID": MANAGER.EXE's Windows PID (for winedbg attach) + Linux PID (for /proc/mem).
set -euo pipefail
source "$(dirname "$0")/env.sh"
WPID=$(printf 'info process\nquit\n' | winedbg 2>/dev/null | command grep -i "MANAGER.EXE" | awk '{print $1}' | head -1)
# NB: match the game itself, NOT the explorer.exe desktop wrapper whose cmdline
# also contains MANAGER.EXE (bit us 2026-07-07: /proc reads went to the wrong process).
# Two prefixes can run MANAGER.EXE at once (see env.sh PM98_WINEPREFIX) and the cmdline is
# identical, so pick the pid whose /proc/<pid>/environ carries THIS WINEPREFIX.
LPID=""
for p in $(pgrep -f '^C:.PM98.MANAGER\.EXE'); do
  if tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | command grep -qx "WINEPREFIX=$WINEPREFIX"; then
    LPID=$p; break
  fi
done
[ -n "$LPID" ] || LPID=$(pgrep -f '^C:.PM98.MANAGER\.EXE' | head -1)
[ -n "$WPID" ] && [ -n "$LPID" ] || { echo "MANAGER.EXE not found (WPID='$WPID' LPID='$LPID')" >&2; exit 1; }
echo "0x$WPID $LPID"
