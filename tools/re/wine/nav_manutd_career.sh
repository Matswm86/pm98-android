#!/bin/bash
# Drive a MANAGER LEAGUE career from the title screen to the manager hub, as
# Manchester Utd. at TOTAL level. `nav_kickoff.sh`'s sibling: that one stops at a fixture's
# KICK OFF screen for the M5 oracle, this one hands a live career to `autodrive.py run`.
#
# Why Man Utd and why this exists (2026-08-02, s90): the one screen the RE corpus still has
# no witness for is a SEMIFINAL / FINAL cup draw, and `FUN_004d9a00` only paints the draw at
# all when a human-managed club is in that round's own tie array (`club+0x5c != 0xffff`,
# read s89). So the manager's club has to REACH a semifinal, which makes the strongest club
# in the game the right pick and season 1 the best roll — the squad is still the real one.
#
# The blind drive does not manage the squad, so a career does not survive long: the s90 run
# was relegated in season 1 and then sacked at the start of season 2 with "your squad does
# not have the minimum number of players needed to play in any championship". Treat each run
# as ONE season-1 roll and re-run rather than expecting a long career.
#
# Coords are the proven ones (see nav_kickoff.sh + docs/re/matchday_flow_witness_re.md §8).
# The team grid: 10 kits a row, alphabetical, so Manchester Utd. is #14 = row 2, column 4.
# VERIFY the shot — the club name prints under the grid and in the player row.
#
# Usage: nav_manutd_career.sh [manager_name]   (boot.sh must have run first)
set -euo pipefail
source "$(dirname "$0")/env.sh"
NAME="${1:-MWM}"
C="$(dirname "$0")/click.sh"
S="$(dirname "$0")/snap.sh"

step() { bash "$C" "$1" "$2" "${3:-1}" >/dev/null; sleep "${4:-2}"; }

sleep "${PM98_NAV_SETTLE:-8}"
bash "$S" car_00_title >/dev/null

step 165 277            # MANAGER LEAGUE
step 445 300            # TOTAL
step 160 110 1 1        # the name row
W=$(win_id)
xdotool mousemove --window "$W" 160 110; sleep 0.5
for ((i = 0; i < ${#NAME}; i++)); do xdotool key "${NAME:$i:1}"; sleep 0.2; done
sleep 1
step 272 365 1 2        # the team grid, row 2 column 4 -> Manchester Utd.
bash "$S" car_01_team >/dev/null

step 565 438 1 3        # CONTINUE -> preseason rivals
step 50 385 1 1.5       # rival slot 1
step 557 344 3 1.5      # SKIP the other three
step 567 452 1 3        # CONTINUE -> teams in championships
step 575 460 1 3        # CONTINUE -> the manager hub
bash "$S" car_02_hub >/dev/null

echo "career up — LOOK at $ORACLE_OUT/car_01_team.png (must read Manchester Utd.) and car_02_hub.png"
