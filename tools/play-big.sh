#!/bin/bash
# PM98 play session, upscaled.
#
# MANAGER.EXE renders a fixed 640x480 surface, so nothing inside wine can make it
# bigger. Chain instead:
#   nested rootful Xwayland (:7, 640x480)  <-- wine renders here, no WM, no decorations
#     -> x11vnc on :7
#       -> TigerVNC viewer on the real display, scaled (default 200% = 1280x960).
# Input goes to :7 only, so the viewer window can cover anything without a click loop.
#
# Usage:  tools/play-big.sh                        # fullscreen, 2.25x (1440x1080)
#         WINDOWED=1 SCALE=2:nb tools/play-big.sh  # 1280x960 window, integer-crisp
#         tools/play-big.sh stop
# F8 = viewer menu (leave fullscreen / disconnect).
set -euo pipefail

PREFIX="${PM98_PLAY_PREFIX:-$HOME/pm98/wineprefix-play}"
XDISP="${PM98_PLAY_DISPLAY:-:7}"
PORT="${PM98_PLAY_PORT:-5907}"
[ -n "${HACK:-}" ] && EXE=MANAGER_HACK.EXE   # 3-forwards patch (tools/hack/build_hack_exe.py)
SCALE="${SCALE:-2.25:nb}"  # x11vnc server-side scale; 2.25 = 1440x1080 (fills 1080p height)
                           # :nb = nearest-neighbour, no blending. SCALE=2:nb = crisp integer 1280x960.
VIEW_DISPLAY="${VIEW_DISPLAY:-:1}"
LOG_DIR="${PM98_PLAY_LOGS:-/tmp/pm98-play}"
mkdir -p "$LOG_DIR"

stop() {
  WINEPREFIX="$PREFIX" wineserver -k 2>/dev/null || true
  pkill -f "x11vnc .*-rfbport $PORT" 2>/dev/null || true
  pkill -f "Xvfb $XDISP" 2>/dev/null || true
  pkill -f "Xwayland .*$XDISP" 2>/dev/null || true   # pre-2026-07-26 sessions
  echo "stopped"
}

[ "${1:-}" = "stop" ] && { stop; exit 0; }

stop; sleep 1

# 1. nested X server, exactly game-sized (no WM => wine's desktop window is undecorated).
# MUST be headless: a rootful Xwayland is a Wayland surface, so COSMIC stops its frame
# callbacks when it is hidden/occluded and the match clock freezes mid-BRIEF (2026-07-26).
Xvfb "$XDISP" -screen 0 640x480x24 -nolisten tcp > "$LOG_DIR/xvfb.log" 2>&1 &
for i in $(seq 1 20); do DISPLAY=$XDISP xdotool getdisplaygeometry >/dev/null 2>&1 && break; sleep 0.5; done
DISPLAY=$XDISP xdotool getdisplaygeometry >/dev/null 2>&1 || { echo "FAIL: Xwayland $XDISP (see $LOG_DIR/xwayland.log)" >&2; exit 1; }

# 2. game
cd "$PREFIX/drive_c/PM98"
WINEPREFIX="$PREFIX" DISPLAY=$XDISP WINEDEBUG=-all \
  nohup wine explorer /desktop=pm98play,640x480 "C:\\PM98\\${EXE:-MANAGER.EXE}" > "$LOG_DIR/wine.log" 2>&1 &
for i in $(seq 1 60); do
  DISPLAY=$XDISP xdotool search --name "pm98play - Wine desktop" >/dev/null 2>&1 && break; sleep 1
done

# 3. mirror :7, upscaled server-side (TigerVNC 1.13 dropped viewer-side scaling,
#    and x11vnc bails out if it thinks the session is Wayland -> hide those vars).
env -u WAYLAND_DISPLAY XDG_SESSION_TYPE=x11 DISPLAY=$XDISP \
  nohup x11vnc -scale "$SCALE" -localhost -nopw -forever -shared -repeat \
  -rfbport "$PORT" > "$LOG_DIR/x11vnc.log" 2>&1 &
for i in $(seq 1 20); do ss -ltn 2>/dev/null | grep -q ":$PORT " && break; sleep 0.5; done

# 4. viewer on the real desktop (1:1 -> already scaled by x11vnc)
# TigerVNC 1.13 has no viewer-side scaling, so the window must be opened at the
# already-scaled framebuffer size or COSMIC hands it an arbitrary one (1279x600 here).
VIEW_ARGS=()
if [ -n "${WINDOWED:-}" ]; then
  VIEW_ARGS+=(-geometry "${GEOMETRY:-1280x960+40+40}")
else
  VIEW_ARGS+=(-FullScreen)
fi
echo "game on $XDISP at scale $SCALE (F8 = viewer menu; 'tools/play-big.sh stop' to quit)"
DISPLAY="$VIEW_DISPLAY" exec vncviewer "${VIEW_ARGS[@]}" localhost::"$PORT"
