#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice G): drive the REAL FUN_005b73a0 phase-7 wall-ELSE branch
# (match+0x448==7, match+0x19a0 != 4) through the Ghidra PCode emulator and bank the resulting OUR-
# player positions + facing. Ground truth for Pm98Movement._position_phase7_wall.
#
# For each on-pitch non-taker player: scan the 11-entry &DAT_00639270 role table for `flag`
# (= team != match+0x45c); the FIRST unclaimed entry matching the player role (+0x2c8) snaps it to a
# defensive-wall slot (x = +/-(0x109999 - goalXscale), y = +/-(Yscale - trunc(Yscale*(flag+1+2*idx)/11)),
# z = 0; both negated iff (orient ^ (1-side)) != 0). The claimed bitmap is shared across players. Then
# EVERY eligible player: clamp_min_sep off the taker (0xa0000); snap x to +/-(goalXscale - 0x110000)
# when within 0x109999 of the goal line (neg iff (orient ^ side) != 0); face the ball. RNG-free; atan
# LUT injected; faithful _ftol at 0x252000 (clamp_min_sep scale path).
#
# Memory: ctx @0x230000, match @0x210000, OUR players @0x240000 (stride 0x3bc), taker @0x270000
#   (a separate struct, except the taker_p fixture where match+0x438 = &P1 so P1 is skipped). Each
#   player +0x18c -> match. ball = match+0x1614 = origin. Taker parked far so clamp is a no-op.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/phase7wall_oracle.txt
SPEC=$SPECDIR/_phase7wall_run.spec
ROUT=$SPECDIR/_phase7wall_run.out
LUT=$SPECDIR/_phase7wall_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

P() { printf '0x%08x' $(( 0x240000 + $1 * 0x3bc + $2 )); }   # our player $1, field offset $2
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

SETUP=""
READS=()
add() { SETUP+="$(poke "$1" "$2");"; }
rd() { READS+=("$(P "$1" 0x4) 4" "$(P "$1" 0x8) 4" "$(P "$1" 0xc) 4" "$(P "$1" 0x34) 4"); }

# A player: on-pitch, role $2, match ptr, seeded pos ($3,$4,$5).
mk_player() {  # $1 idx ; $2 role ; $3 x ; $4 y ; $5 z
  add "$(P $1 0x2bc)" 1;  add "$(P $1 0x2c8)" "$2";  add "$(P $1 0x18c)" 0x210000
  add "$(P $1 0x4)" "$3";  add "$(P $1 0x8)" "$4";  add "$(P $1 0xc)" "$5"
}

# match: phase 7, orient $1 (0x19a0, must != 4), set-piece side $2 (0x45c), goalx $3, yscale $4,
# taker ptr $5, ball at origin, count $6.
base_match() {  # $1 orient ; $2 side ; $3 goalx ; $4 yscale ; $5 taker ; $6 count
  SETUP="";  READS=()
  add 0x210448 7;  add 0x2119a0 "$1";  add 0x21045c "$2"
  add 0x211820 "$3";  add 0x211824 "$4";  add 0x210438 "$5"
  add 0x211614 0;  add 0x211618 0;  add 0x21161c 0
  add 0x230004 "$6"
  # taker parked far (clamp no-op) unless it aliases a player.
  add 0x270004 0x3000000;  add 0x270008 0;  add 0x27000c 0
}

emit_spec() {
  {
    cat <<EOF
entry   0x005b73a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
zero    0x00270000 0x00001000
maxsteps 600000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
EOF
    cat "$LUT"
    printf '%s\n' "${SETUP//;/$'\n'}"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {  # $1 name
  emit_spec
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice G (phase-7 wall-else, match+0x19a0 != 4) PCode-emu truth." >> "$OUT"
echo "# matched roles snap to wall slot then goal-line snap; unmatched roles run clamp/snap/face. CALL RET." >> "$OUT"

# --- F1 flag0 (team0==side0): row0 [12,7,8,16,13,9,17,10,18,11,14]. P0 role7(idx1), P1 role8(idx2),
#     P2 role99 (no match, seeded far -> clamp no-op, no goal-line snap). orient 0. ---
base_match 0 0 0x40000 0x180000 0x270000 3
mk_player 0 7 0 0 0;  mk_player 1 8 0 0 0;  mk_player 2 99 0x5000000 0x1000000 0
rd 0; rd 1; rd 2
bank flag0

# --- F2 flag1 (team0 != side1): row1 [3,11,18,5,15,4,6,8,7,2,0]. P0 role11(idx1), P1 role3(idx0),
#     P2 role99. orient 0. ---
base_match 0 1 0x40000 0x180000 0x270000 3
mk_player 0 11 0 0 0;  mk_player 1 3 0 0 0;  mk_player 2 99 0x5000000 0x1000000 0
rd 0; rd 1; rd 2
bank flag1

# --- F3 orient bit 1 (0x19a0=1, side0 -> flag0 row0). P0 role12(idx0), P1 role7(idx1). ---
base_match 1 0 0x40000 0x180000 0x270000 2
mk_player 0 12 0 0 0;  mk_player 1 7 0 0 0
rd 0; rd 1
bank orient1

# --- F4 taker aliases P1 (match+0x438 = &P1): on-pitch P1 is SKIPPED as the taker (sentinel pos
#     retained). P0 role7, P2 role8 -> matched + placed. ---
base_match 0 0 0x40000 0x180000 "$(P 1 0)" 3
mk_player 0 7 0 0 0;  mk_player 2 8 0 0 0
mk_player 1 4 0x7777777 0x6666666 0x5555555    # on-pitch role4, but == taker -> skipped
rd 0; rd 1; rd 2
bank taker_p

echo "=== phase7wall oracle -> $OUT ==="
cat "$OUT"
