#!/bin/bash
# Drive a fresh MANAGER.EXE from the title screen to the KICK OFF screen of the reference
# fixture (manager "mats" = Bolton W, preseason rival 1 = Aston Villa at Villa Park), i.e. the
# match `data/pm98-m4-oracle/capture2/frame0_struct_import.json` was dumped from.
#
# Coords are the proven ones (README "Reproduce the capture"; handoff-pm98-kickoff-phase2-exit-
# LIVETRACED-2026-06-24). Snapshots land in $ORACLE_OUT as nav_NN_*.png — LOOK at nav_09_hub.png
# and nav_12_kickoff.png before attaching: the preseason injury roll is per-boot, and a hurt
# starter produces "The initial line-up is not correct" at the hub CONTINUE, which makes the
# whole run useless (the XI can never match the reference). Re-roll on that; roughly 1 in 2
# boots is clean.
#
# Usage: nav_kickoff.sh [manager_name]   (boot.sh must have run first)
set -euo pipefail
source "$(dirname "$0")/env.sh"
NAME="${1:-mats}"
C="$(dirname "$0")/click.sh"
S="$(dirname "$0")/snap.sh"

step() { bash "$C" "$1" "$2" "${3:-1}" >/dev/null; sleep "${4:-2}"; }

# The modal "PREMIER MANAGER 98" alert covers the hub with a white panel; (200,230) is pure
# white under it and dark green (50,70,0) on the bare hub. Test before clicking its OK — a
# blind click at the OK coords lands on the hub's NEWS button and derails the drive.
alert_up() {
  bash "$S" "$1" >/dev/null
  python3 - "$ORACLE_OUT/$1.png" <<'PY'
import sys
from PIL import Image
sys.exit(0 if Image.open(sys.argv[1]).convert("RGB").getpixel((200, 230)) == (255, 255, 255) else 1)
PY
}

# boot.sh returns as soon as the X window exists, several seconds before the title screen is
# interactive; clicking into that gap silently eats the first steps and the drive ends up in
# PRO-MANAGER LEAGUE instead (seen 2026-07-24). Settle first.
sleep "${PM98_NAV_SETTLE:-8}"
bash "$S" nav_00_title >/dev/null

step 165 277            # MANAGER LEAGUE
step 175 135            # TRAINER
bash "$S" nav_02_trainer >/dev/null

step 160 110 1 1        # name row 1
W=$(win_id)
xdotool mousemove --window "$W" 160 110; sleep 0.5
for ((i = 0; i < ${#NAME}; i++)); do xdotool key "${NAME:$i:1}"; sleep 0.2; done
sleep 1
step 291 318 1 1.5      # team shirt -> Bolton W
bash "$S" nav_04_team >/dev/null

step 565 438 1 3        # CONTINUE -> preseason
step 50 385 1 1.5       # rival 1 shirt -> Aston Villa
step 557 344 3 1.5      # SKIP the other three rivals
bash "$S" nav_07_preseason >/dev/null

step 567 452 1 3        # CONTINUE -> teams in championships
step 575 460 1 3        # CONTINUE -> manager menu hub
if alert_up nav_09_hub; then
  step 458 264 1 2      # a preseason news alert ("X is out for N weeks") -> OK
fi

step 588 267 1 3        # hub CONTINUE -> MATCH OPTIONS (or the lineup-rejected alert)
if alert_up nav_10_matchopts; then
  # "The initial line-up is not correct. A player is either banned or injured." — the preseason
  # injury roll hurt a starter, so this boot can never reproduce the reference XI.
  echo "BAD ROLL: line-up rejected (injured/banned starter). Reset the prefix and re-boot." >&2
  exit 3
fi
step 160 288 1 1        # WATCH
step 485 350 1 4        # OK -> line-up intro
step 320 240 2 3        # skip the intro
bash "$S" nav_12_kickoff >/dev/null

echo "nav done — inspect $ORACLE_OUT/nav_09_hub.png and nav_12_kickoff.png"
