# Shared env for the M4 wine MANAGER.EXE oracle harness (source me).
# Method + coords proven 2026-06-24 (handoff-pm98-kickoff-phase2-exit-LIVETRACED-2026-06-24):
# COSMIC/Xwayland box -> render + synthetic clicks REQUIRE `wine explorer /desktop=pm98,640x480`
# with the FULL windows path; bare/direct modes are unusable. MANAGER.INI must have FULL SCREEN: OFF.
export DISPLAY=:1
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export WINEPREFIX="$REPO/.wineprefix"
export PM98_DIR="$WINEPREFIX/drive_c/PM98"
export WINEDEBUG=-all
# All capture output (shots, dumps, logs) stays out of the repo:
export ORACLE_OUT="${ORACLE_OUT:-/tmp/claude-1000/-home-mats-MWM-AI/b1f0f3cd-1c45-40ea-bd96-4346f66b7c7c/scratchpad/m4}"
mkdir -p "$ORACLE_OUT"
WIN_NAME="pm98 - Wine desktop"

win_id() { xdotool search --name "$WIN_NAME" 2>/dev/null | head -1; }
