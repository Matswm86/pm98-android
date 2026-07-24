# Shared env for the M4 wine MANAGER.EXE oracle harness (source me).
# Method + coords proven 2026-06-24 (handoff-pm98-kickoff-phase2-exit-LIVETRACED-2026-06-24):
# COSMIC/Xwayland box -> render + synthetic clicks REQUIRE `wine explorer /desktop=pm98,640x480`
# with the FULL windows path; bare/direct modes are unusable. MANAGER.INI must have FULL SCREEN: OFF.
export DISPLAY="${DISPLAY:-:1}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# Two concurrent drives collide: one wineprefix = one wineserver, and `explorer /desktop=<name>`
# REUSES an existing desktop of that name — a second boot on another DISPLAY then dies with
# `X Error ... BadWindow ... X_CreateWindow` (the first session's desktop window id). Overriding
# BOTH vars gives an isolated instance (`cp -a` the prefix, pick a fresh desktop name). Bit us
# 2026-07-24 (s53) against a parallel career session holding `pm98` on :2.
export WINEPREFIX="${PM98_WINEPREFIX:-$REPO/.wineprefix}"
export PM98_DESKTOP="${PM98_DESKTOP:-pm98}"
export PM98_DIR="$WINEPREFIX/drive_c/PM98"
export WINEDEBUG=-all
# All capture output (shots, dumps, logs) stays out of the repo:
export ORACLE_OUT="${ORACLE_OUT:-/tmp/claude-1000/-home-mats-MWM-AI/e7c3519a-b2a9-4e81-a0fd-417613d7ca18/scratchpad/m4}"
mkdir -p "$ORACLE_OUT"
WIN_NAME="$PM98_DESKTOP - Wine desktop"

win_id() { xdotool search --name "$WIN_NAME" 2>/dev/null | head -1; }
