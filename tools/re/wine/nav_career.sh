#!/bin/bash
# Drive a fresh MANAGER.EXE from the title screen to the MANAGER MENU hub of a new
# MANAGER LEAGUE career, and stop there — the state `autodrive.py run` expects.
#
# `nav_kickoff.sh` does this and then walks on into a match; a season drive must NOT,
# because MATCH OPTIONS has to stay on the plan's own setting and the hub is the drive's
# entry screen. Same proven coords, same alert guard, cut at the hub.
#
# Usage: PM98_LEVEL=total nav_career.sh [manager_name]   (boot.sh must have run first)
# PM98_LEVEL: trainer (default) | manager | accountant | total
set -euo pipefail
source "$(dirname "$0")/env.sh"
NAME="${1:-mats}"
C="$(dirname "$0")/click.sh"
S="$(dirname "$0")/snap.sh"

step() { bash "$C" "$1" "$2" "${3:-1}" >/dev/null; sleep "${4:-2}"; }

# The modal "PREMIER MANAGER 98" alert covers the hub with a white panel; (200,230) is pure
# white under it and dark green on the bare hub. Test before clicking its OK — a blind click
# at the OK coords lands on the hub's NEWS button and derails the drive.
alert_up() {
  bash "$S" "$1" >/dev/null
  python3 - "$ORACLE_OUT/$1.png" <<'PY'
import sys
from PIL import Image
sys.exit(0 if Image.open(sys.argv[1]).convert("RGB").getpixel((200, 230)) == (255, 255, 255) else 1)
PY
}

sleep "${PM98_NAV_SETTLE:-8}"
bash "$S" nav_00_title >/dev/null

step 165 277            # MANAGER LEAGUE
# SELECT LEVEL. Coordinates are the centres of NivelScreen's reversed client rects offset
# by the dialog origin (93,32): TRAINER (123,87,120x105), MANAGER (372,88,149x104),
# ACCOUNTANT (121,241,132x124), TOTAL (365,238,153x128).
#
# The level is LOAD-BEARING for any drive that touches the squad: at TRAINER level the
# whole TRANSFER MARKET quarter is automatic, and clicking PLAYERS answers with the modal
# "This option is automatic in Trainer level." instead of opening SQUAD MANAGEMENT. That is
# what really stopped B9's probe (2026-08-01, verified live against the window) -- not the
# hub coordinate, which is correct.
case "${PM98_LEVEL:-trainer}" in
  total)      step 441 302 ;;   # TOTAL
  manager)    step 446 140 ;;   # MANAGER
  accountant) step 187 303 ;;   # ACCOUNTANT
  *)          step 175 135 ;;   # TRAINER (default, unchanged)
esac

step 160 110 1 1        # name row 1
W=$(win_id)
xdotool mousemove --window "$W" 160 110; sleep 0.5
for ((i = 0; i < ${#NAME}; i++)); do xdotool key "${NAME:$i:1}"; sleep 0.2; done
sleep 1
step 291 318 1 1.5      # team shirt -> Bolton W

step 565 438 1 3        # CONTINUE -> preseason
step 50 385 1 1.5       # rival 1 shirt -> Aston Villa
step 557 344 3 1.5      # SKIP the other three rivals

step 567 452 1 3        # CONTINUE -> teams in championships
step 575 460 1 3        # CONTINUE -> manager menu hub
if alert_up nav_09_hub; then
  step 458 264 1 2      # a preseason news alert ("X is out for N weeks") -> OK
fi

bash "$S" nav_career_hub >/dev/null
echo "career started — hub frame at $ORACLE_OUT/nav_career_hub.png"
