#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice D): drive the REAL FUN_005b73a0 phase-4 DEFENSIVE-WALL branch
# (match+0x448 == 4, match+0x45c != team) through the Ghidra PCode emulator and bank the resulting
# OUR-player positions. Ground truth for Pm98Movement._position_wall (app/tests/test_wall.gd).
#
# LOOP 1 role-based pulling: our role 5/6 -> first unclaimed opponent role 9 (copy xyz, x-=iVar21);
#   our role 10 -> opponent role 10; our role 2/3 (first, sign(P+0x1e4)==sign(match+0x16a4)) -> wall
#   anchor x=+/-(0x8000-match+0x1820), y=sign(match+0x16a4)*0x40000, z=0. iVar21 = (((match+0x19a0&1)^
#   team)?-0x10000:+0x10000). LOOP 5 sets facing + a min-sep that is a NO-OP here (players kept far
#   apart). Loops 2-4 are skipped (every our player is assigned by loop 1). Phase 4 RETs after loop 5.
#
#   ctx+0x2e0 = 0 -> relmatrix (FUN_005b8690) throttle-skips. cos/atan LUT injected for the loop-5
#   facing atan (FUN_005ee080). RNG unused on these paths. CALL RET rows.
#
# Memory: ctx @0x230000, match @0x210000, OUR players @0x240000 (stride 0x3bc, 4 players P0..P3),
#   OPP players @0x250000 (stride 0x3bc, 3 opps O0..O2). opp base/count/keeper at match +0x78c/+0x790/
#   +0x8f4 (team 0). Each player +0x18c -> match.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/wall_oracle.txt
SPEC=$SPECDIR/_wall_run.spec
ROUT=$SPECDIR/_wall_run.out
LUT=$SPECDIR/_wall_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

P() { printf '0x%08x' $(( 0x240000 + $1 * 0x3bc + $2 )); }   # our player $1, field offset $2
O() { printf '0x%08x' $(( 0x250000 + $1 * 0x3bc + $2 )); }   # opp player $1, field offset $2
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=(
  "$(P 1 0x4) 4" "$(P 1 0x8) 4" "$(P 1 0xc) 4"               # P1 (role 5 -> opp role 9)
  "$(P 2 0x4) 4" "$(P 2 0x8) 4" "$(P 2 0xc) 4"               # P2 (role 10 -> opp role 10)
  "$(P 3 0x4) 4" "$(P 3 0x8) 4" "$(P 3 0xc) 4"               # P3 (role 2 -> wall anchor)
)

# Fixed player/opp layout (shared by both fixtures; orient at 0x2119a0 is overridden per fixture).
SETUP=""
add() { SETUP+="$(poke "$1" "$2");"; }
# OUR players (count 4): P0 GK(role 0xc,id 0), P1(role 5,id 1), P2(role 10,id 2), P3(role 2,id 3).
add "$(P 0 0x2c8)" 0xc;  add "$(P 0 0x2c4)" 0;  add "$(P 0 0x2bc)" 1;  add "$(P 0 0x18c)" 0x210000
add "$(P 1 0x2c8)" 5;    add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 2 0x2c8)" 10;   add "$(P 2 0x2c4)" 2;  add "$(P 2 0x2bc)" 1;  add "$(P 2 0x18c)" 0x210000
add "$(P 3 0x2c8)" 2;    add "$(P 3 0x2c4)" 3;  add "$(P 3 0x2bc)" 1;  add "$(P 3 0x18c)" 0x210000
add "$(P 3 0x1e4)" 0x10000;  add "$(P 3 0x2b8)" 0                       # ep1.y (+) ; team 0
# OPP players (count 3): O0 keeper(id 0), O1(role 9,id 1) @(0x200000,0x100000,0), O2(role 10,id 2).
add "$(O 0 0x2c4)" 0;    add "$(O 0 0x18c)" 0x210000
add "$(O 1 0x2c8)" 9;    add "$(O 1 0x2c4)" 1;  add "$(O 1 0x18c)" 0x210000
add "$(O 1 0x4)" 0x200000;  add "$(O 1 0x8)" 0x100000;  add "$(O 1 0xc)" 0
add "$(O 2 0x2c8)" 10;   add "$(O 2 0x2c4)" 2;  add "$(O 2 0x18c)" 0x210000
add "$(O 2 0x4)" 0x400000;  add "$(O 2 0x8)" 0x180000;  add "$(O 2 0xc)" 0

emit_spec() {
  # $1 = orient (match+0x19a0)
  {
    cat <<EOF
entry   0x005b73a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
zero    0x00250000 0x00002000
maxsteps 600000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x4
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
mem 0x00210448 4 0x4
mem 0x0021045c 4 0x1
mem 0x002116a4 4 0x00030000
mem 0x00211820 4 0x00140000
mem 0x0021078c 4 0x00250000
mem 0x00210790 4 0x3
mem 0x002108f4 4 0x00250000
mem 0x00211614 4 0x0
mem 0x00211618 4 0x0
mem 0x0021161c 4 0x0
mem 0x002119a0 4 0x$(printf '%x' "$1")
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

bank() {  # $1 name $2 orient
  emit_spec "$2"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice D (phase-4 defensive-wall, loop 1 + loop 5) PCode-emu truth." >> "$OUT"
echo "# our role 5->opp9, role 10->opp10, role 2->wall anchor; iVar21 sign per orient. CALL RET rows." >> "$OUT"
echo "# relmatrix throttle-skipped; atan LUT injected; loop-5 min-sep no-op (players far apart)." >> "$OUT"
bank wall_orient0 0    # iVar21 = +0x10000 ; wall anchor x not negated (team 0 == orient&1 0)
bank wall_orient1 1    # iVar21 = -0x10000 ; wall anchor x negated (team 0 != orient&1 1)
echo "=== wall oracle -> $OUT ==="
cat "$OUT"
