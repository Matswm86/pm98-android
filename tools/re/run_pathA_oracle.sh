#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice H): drive the REAL FUN_005b73a0 phase-5 tail PATH A (disasm
# 0x5b8211..0x5b854c, match+0x448==5 && match+0x19cc != 0 && match+0x45c != team) through the Ghidra
# PCode emulator and bank the resulting OUR-player positions + facing + position-code. Ground truth for
# Pm98Movement._phase5_tail_pathA.
#
# NOTE: path A runs ONLY after the phase-5 DEFENSIVE WALL (same entry condition). To keep the wall
# RNG-free, every OUR player is an EXCLUDED role (12/13/14): wall loop 3 skips it, loop 4 finds no
# unclaimed opponent (the lone keeper is pre-claimed) -> snaps it to endpoint1 (+0x1e0). Then path A:
#   pass 1 -- clamp off taker (0xa0000, no-op: taker parked far), reflect through taker if outside the
#     pitch box [+0x1828..+0x183c], face the ball, insertion-sort by role CLASS (excluded roles -> 2);
#   pass 2 -- the top-N (N = match+0x19cc) slots: set_position_code(0x1c) + anchor + polar_vec(radius,
#     taker_facing+0x4000), radius = ftol((s*0.45 - N*0.225) * 65536); face the ball.
# anchor = taker_pos + polar_vec(0x93333, taker_facing). The all-equal-class insertion exercises the
# memmove that shifts POINTER slots but not PRIORITY slots (the stale-slot reorder). atan/cos LUT +
# faithful _ftol injected.
#
# Memory: ctx @0x230000, match @0x210000, OUR players @0x240000 (stride 0x3bc, ids 1/2/3/4 role 12/13/14/16),
#   keeper opp @0x250000 (id 0, pre-claimed), taker @0x270000 (facing @+0x34). ball = match+0x1614.
#   memmove (ds:0x6233d4) overridden to an injected backward-copy stub at 0x253000 (msvcrt isn't loaded).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/pathA_oracle.txt
SPEC=$SPECDIR/_pathA_run.spec
ROUT=$SPECDIR/_pathA_run.out
LUT=$SPECDIR/_pathA_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

P() { printf '0x%08x' $(( 0x240000 + $1 * 0x3bc + $2 )); }   # our player $1, field offset $2
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }
add() { SETUP+="$(poke "$1" "$2");"; }

READS=()
for i in 0 1 2 3; do
  READS+=("$(P $i 0x4) 4" "$(P $i 0x8) 4" "$(P $i 0xc) 4" "$(P $i 0x34) 4" "$(P $i 0x40) 4")
done

# A player: id, role, endpoint1 (= wall loop-4 miss target = pre-pass-1 position).
mk_player() {  # $1 idx ; $2 id ; $3 role ; $4 ex ; $5 ey ; $6 ez
  add "$(P $1 0x2bc)" 1;  add "$(P $1 0x2c8)" "$3";  add "$(P $1 0x2c4)" "$2"
  add "$(P $1 0x18c)" 0x210000;  add "$(P $1 0x2b8)" 0
  add "$(P $1 0x1e0)" "$4";  add "$(P $1 0x1e4)" "$5";  add "$(P $1 0x1e8)" "$6"
  add "$(P $1 0x4)" "$4";  add "$(P $1 0x8)" "$5";  add "$(P $1 0xc)" "$6"
}

build() {  # $1 = N (match+0x19cc)
  SETUP=""
  # match: phase 5, 0x19cc = N, opponent's set-piece (0x45c=1 != team0), taker, ball, opp/keeper.
  add 0x210448 5;  add 0x2119cc "$1";  add 0x21045c 1;  add 0x210438 0x270000
  add 0x2119a0 0;  add 0x2116a4 0;  add 0x211820 0x140000
  add 0x211614 0x80000;  add 0x211618 0;  add 0x21161c 0
  add 0x21078c 0x250000;  add 0x210790 1;  add 0x2108f4 0x250000          # opp base/count/keeper
  # moderate pitch box: P1 endpoint1 (x=0x2000000) sits OUTSIDE -> reflected through taker.
  add 0x211828 -0x800000;  add 0x211834 0x800000
  add 0x21182c -0x800000;  add 0x211838 0x800000
  add 0x211830 -0x800000;  add 0x21183c 0x800000
  # keeper opp O0 (id 0, pre-claimed -> never a candidate). +0x2c4 = 0x2502c4.
  add 0x2502c4 0
  # taker parked far (clamp no-op), facing 0x2000 -> anchor offset direction.
  add 0x270004 0x5000000;  add 0x270008 0;  add 0x27000c 0;  add 0x270034 0x2000
  # OUR players: ids 1/2/3/4, excluded roles 12/13/14/16. P0,P2,P3 inside box; P1 outside -> reflect.
  mk_player 0 1 12 0x100000  0x100000 0
  mk_player 1 2 13 0x2000000 0        0
  mk_player 2 3 14 -0x100000 0x200000 0
  mk_player 3 4 16 0x300000  -0x180000 0
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
zero    0x00250000 0x00001000
zero    0x00270000 0x00001000
maxsteps 800000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
membts 0x00253000 57568B7C240C8B7424108B4C241485C97409498A040E88040FEBF35E5FC3
mem 0x006233d4 4 0x00253000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x4
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
mem 0x006d3184 4 0x1
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

bank() {  # $1 name ; $2 N
  build "$2"
  emit_spec
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice H (phase-5 tail PATH A, defensive distribution) PCode-emu truth." >> "$OUT"
echo "# excluded-role players -> wall endpoint1; path A fans the top-N around the anchor. CALL RET rows." >> "$OUT"

# Only EVEN N is banked: radius = 14745.6*(2*slot - N), so even N keeps every fan radius a multiple of
# 2*0.225*65536 (fractions .0/.2/.4) -- OFF the .5 truncation boundary. Odd N (e.g. -44236.8) is where
# the REAL x87 _ftol (truncate toward zero -> -44236, what Pm98Movement does) and the PCode emulator's
# `fist` (which round-to-nearests, ignoring the injected truncate control word -> -44237) DISAGREE, so
# an odd-N oracle would bank the emulator's rounding artifact, not the real binary. See test_pathA.gd.
# N=2: slots 0,1 fanned (stale-reorder -> P2,P0); P1 reflected-endpoint (outside box) kept; P3 endpoint.
bank pathA_n2 2
# N=4: all four fanned (stale-reorder -> P2,P0,P3,P1), radii -58982/-29491/0/+29491 (all off-boundary).
bank pathA_n4 4

echo "=== pathA oracle -> $OUT ==="
cat "$OUT"
