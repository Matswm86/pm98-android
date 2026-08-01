#!/bin/bash
# Arm a TOTAL-level career for the B9 youth capture, then hand it to `autodrive.py run`.
#
# B9 (docs/re/youth_re.md §B9) needs three things the port has never witnessed un-occluded:
# a FILLED "PLAYERS FOUND" panel, a filled YOUTH TEAM roster row, and the training chips.
# All three only exist once a YOUTH TEAM SCOUT and a YOUTH TEAM MANAGER are employed and
# the six SEARCH CAPABILITY LEDs are armed, and none of that is reachable below TOTAL
# level -- at TRAINER the hub's PLAYERS icon answers "This option is automatic in Trainer
# level." (proven live 2026-08-01, s82 §4).
#
# Every coordinate below was walked click by click against the live window in s82 and is
# recorded in docs/re/youth_re.md; nothing here is inferred.
#
# Usage: tools/re/wine/arm_b9.sh [manager_name]
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

NAME="${1:-mats}"
step() { bash ./click.sh "$1" "$2" "${3:-1}" >/dev/null; sleep "${4:-2}"; }
# A snapshot is a progress note, not a step. ffmpeg x11grab fails whenever the game
# has just re-created its window, and under `set -e` that killed a run that was
# otherwise fine (three times on 2026-08-01) -- so snaps may never abort the drive.
snap() { bash ./snap.sh "$1" >/dev/null 2>&1 || echo "  (snap $1 skipped)"; }

bash ./boot.sh
PM98_LEVEL=total bash ./nav_career.sh "$NAME"

# --- CLUB PERSONNEL: hire the YOUTH TEAM SCOUT, then the YOUTH TEAM MANAGER -----------
step 102 441            # hub -> STAFF / CLUB PERSONNEL
step 426 425            # SIGN -> the staff dialog
step 493 293            # role list -> YOUTH SCOUT
step 131 308            # top row SIGN -> C. Stump 4.5* GBP32,000
sleep 2
step 493 263            # role list -> YOUTH MAN.
step 131 308            # top row SIGN -> P. Klachinsky 5* GBP36,000
sleep 2
step 493 375            # OK
step 571 445            # RETURN -> hub
snap b9_00_staff_hired

# --- YOUTH TEAM: flip all six SEARCH CAPABILITY LEDs NO -> YES, then SEARCH -----------
step 234 390            # hub -> SQUAD MANAGEMENT
step 579 372            # -> YOUTH TEAM
snap b9_01_youth_before
for x in 36 161; do
  for y in 176 194 212; do
    step "$x" "$y" 1 0.8
  done
done
snap b9_02_leds_armed
step 278 203            # SEARCH -> "The scout is now searching for players ..."
snap b9_03_search_armed
step 571 440            # back out of YOUTH TEAM
step 577 450            # back out of SQUAD MANAGEMENT -> hub

echo "armed; handing over to autodrive"
exec python3 ./autodrive.py run plans/season_youth_b9.json
