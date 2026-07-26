#!/bin/bash
# Drive a fresh MANAGER.EXE from the title screen to the MANAGER MENU hub of a new
# MANAGER LEAGUE career, and stop there — the state `autodrive.py run` expects.
#
# `nav_kickoff.sh` does this and then walks on into a match; a season drive must NOT,
# because MATCH OPTIONS has to stay on the plan's own setting and the hub is the drive's
# entry screen. Same proven coords, same alert guard, cut at the hub.
#
# Usage: nav_career.sh [manager_name]   (boot.sh must have run first)
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
step 175 135            # TRAINER

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
