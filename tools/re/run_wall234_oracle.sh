#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice F): drive the REAL FUN_005b73a0 phase-4 DEFENSIVE-WALL branch
# (match+0x448==4, match+0x45c != team) through the Ghidra PCode emulator, exercising LOOPS 2-4
# (disasm 0x5b763e..0x5b7ba0) for players LEFT unassigned by loop 1. Ground truth for the loops 2-4
# in Pm98Movement._position_wall + _wall_nearest_opp (app/tests/test_wall234.gd).
#
# LOOP 2 (0x5b763e): a player with a mark-target ptr (player+0xb0) -> if on-pitch, unassigned, the
#   target unclaimed + pos_forward_ok(target): snap onto target, x -= iVar21, claim both.
# LOOP 3 (0x5b76ea): role NOT in {12,13,14,16,17}, unassigned -> nearest unclaimed valid-forward opp
#   within 1000.0 (0x3e80000), snap, x -= iVar21.
# LOOP 4 (0x5b78b1): unassigned -> nearest within 100.0 (0x640000); HIT: snap + x += (flag?+:-0x10000).
#   MISS: excluded role -> endpoint1 (+0x1e0); else goal_target_x + 2-draw RNG jitter
#   (x += +/-rng1*33, y = rng2*80 - 0x140000, z = 0). flag = (match+0x19a0 & 1) ^ player+0x2b8.
# iVar21 = (((match+0x19a0 & 1) ^ team) ? -0x10000 : +0x10000).  pos_forward_ok = FUN_005b04e0 (box +
#   goal-line abs(x) > m+0x1820 - 0x108000 + abs(y) < 0x1428f5 + sign(x) != sign(+0x3a4)). Distance =
#   ftol(sqrt(dx^2+dy^2+dz^2)); the faithful _ftol is injected at 0x252000 (import thunk 0x6233a4).
#
# Memory: ctx @0x230000, match @0x210000, OUR players @0x240000 (stride 0x3bc), OPP @0x250000.
#   opp base/count/keeper at match +0x78c / +0x790 / +0x8f4 (team 0). Each player +0x18c -> match.
#   Pitch box +0x1828..+0x183c kept wide so pos_forward_ok's box passes; loop-5 atan LUT injected;
#   loop-5 min-sep is a no-op (the one moved player ends far from the far-corner GK).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/wall234_oracle.txt
SPEC=$SPECDIR/_wall234_run.spec
ROUT=$SPECDIR/_wall234_run.out
LUT=$SPECDIR/_wall234_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

P() { printf '0x%08x' $(( 0x240000 + $1 * 0x3bc + $2 )); }   # our player $1, field offset $2
O() { printf '0x%08x' $(( 0x250000 + $1 * 0x3bc + $2 )); }   # opp player $1, field offset $2
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=( "$(P 1 0x4) 4" "$(P 1 0x8) 4" "$(P 1 0xc) 4" )       # target player P1 final pos

SETUP=""
add() { SETUP+="$(poke "$1" "$2");"; }

# Shared layout: P0 = GK id 0 (role 12) parked far at x=-0x2000000 (loop-5 min-sep no-op); O0 = keeper
# id 0 (seeds opp-claimed). The per-fixture builder appends P1 + the opponents + match orient/counts.
base_layout() {  # $1 = orient ; $2 = opp_count
  SETUP=""
  add "$(P 0 0x2c8)" 0xc;  add "$(P 0 0x2c4)" 0;  add "$(P 0 0x2bc)" 1;  add "$(P 0 0x18c)" 0x210000
  add "$(P 0 0x4)" -0x2000000;  add "$(P 0 0x2b8)" 0
  add "$(O 0 0x2c4)" 0;    add "$(O 0 0x18c)" 0x210000
  # match: phase 4, opponent's set-piece (0x45c=1 != team0), goalx base, opp descriptor + keeper.
  add 0x210448 4;  add 0x21045c 1;  add 0x211820 0x140000;  add 0x2116a4 0
  add 0x21078c 0x250000;  add 0x210790 "$2";  add 0x2108f4 0x250000
  add 0x211614 0;  add 0x211618 0;  add 0x21161c 0
  add 0x2119a0 "$1"
  # wide pitch box so pos_forward_ok's box test always passes for on-pitch coords.
  add 0x211828 -0x40000000;  add 0x211834 0x40000000
  add 0x21182c -0x40000000;  add 0x211838 0x40000000
  add 0x211830 -0x40000000;  add 0x21183c 0x40000000
}

# A valid-forward opponent at (x,y,z): on-pitch, id $1, role $2, anchor sign opposite x.
vfwd_opp() {  # $1 idx ; $2 id ; $3 role ; $4 x ; $5 y ; $6 z ; $7 anchor
  add "$(O $1 0x2c4)" "$2";  add "$(O $1 0x2c8)" "$3";  add "$(O $1 0x2bc)" 1;  add "$(O $1 0x18c)" 0x210000
  add "$(O $1 0x4)" "$4";  add "$(O $1 0x8)" "$5";  add "$(O $1 0xc)" "$6";  add "$(O $1 0x3a4)" "$7"
}

emit_spec() {  # $1 = seed
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
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x2
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
EOF
    printf 'mem 0x006d3184 4 0x%08x\n' $(( $1 & 0xffffffff ))
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

bank() {  # $1 name ; $2 seed
  emit_spec "$2"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice F (phase-4 wall LOOPS 2-4) PCode-emu ground truth." >> "$OUT"
echo "# l2=mark-target; l3=nearest<=1000; l4 hit<=100 / endpoint / goal+RNG. CALL RET rows." >> "$OUT"

# --- LOOP 2: P1 role 4, mark-target = &O1 (valid-forward). orient 0 -> iVar21 = +0x10000. ---
base_layout 0 2
add "$(P 1 0x2c8)" 4;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0xb0)" "$(O 1 0)"          # mark-target ptr -> O1
vfwd_opp 1 1 7 0x100000 0x40000 0x20000 -0x10000            # O1 @(16,4,2), valid -> P1=(0xf0000,0x40000,0x20000)
bank l2_marktarget 1

# --- LOOP 3: P1 role 4, no mark-target, two valid opps; picks the NEAREST (O1). orient 0. ---
base_layout 0 3
add "$(P 1 0x2c8)" 4;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
vfwd_opp 1 1 7 0x80000  0 0 -0x10000                        # O1 near (dist 0x80000) -> chosen
vfwd_opp 2 2 7 0x200000 0 0 -0x10000                        # O2 far  (dist 0x200000)
bank l3_nearest_o0 1                                         # P1 = (0x80000-0x10000, 0, 0) = (0x70000,0,0)

# --- LOOP 3 orient 1: iVar21 = -0x10000 -> x -= -0x10000 = +0x10000. ---
base_layout 1 3
add "$(P 1 0x2c8)" 4;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
vfwd_opp 1 1 7 0x80000  0 0 -0x10000
vfwd_opp 2 2 7 0x200000 0 0 -0x10000
bank l3_nearest_o1 1                                         # P1 = (0x80000+0x10000, 0, 0) = (0x90000,0,0)

# --- LOOP 4 HIT orient 0: P1 EXCLUDED role 12 (loop-3 skips it), opp within 100.0 -> hit + x-0x10000. ---
base_layout 0 2
add "$(P 1 0x2c8)" 0xc;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
vfwd_opp 1 1 7 0x100000 0 0 -0x10000                        # dist 0x100000 < 0x640000
bank l4_hit_o0 1                                             # flag 0 -> P1 = (0x100000-0x10000,0,0)=(0xf0000,0,0)

# --- LOOP 4 HIT orient 1: flag 1 -> x += +0x10000. ---
base_layout 1 2
add "$(P 1 0x2c8)" 0xc;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
vfwd_opp 1 1 7 0x100000 0 0 -0x10000
bank l4_hit_o1 1                                             # flag 1 -> P1 = (0x100000+0x10000,0,0)=(0x110000,0,0)

# --- LOOP 4 MISS excluded role -> endpoint1 (+0x1e0). opp valid but FAR (> 100.0). ---
base_layout 0 2
add "$(P 1 0x2c8)" 0xc;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
add "$(P 1 0x1e0)" 0x111111;  add "$(P 1 0x1e4)" 0x222222;  add "$(P 1 0x1e8)" 0x333333
vfwd_opp 1 1 7 0x2000000 0 0 -0x10000                       # dist 0x2000000 > 0x640000 -> MISS
bank l4_endpoint 1                                          # P1 = endpoint1 = (0x111111,0x222222,0x333333)

# --- LOOP 4 MISS non-excluded -> goal_target_x + RNG. opp_count 1 (keeper only, claimed) -> no candidate. ---
base_layout 0 1
add "$(P 1 0x2c8)" 4;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
bank l4_goalrng_o0 1                                        # orient0,team0,flag0: x=-0x140000+rng1*33; y=rng2*80-0x140000

# --- LOOP 4 goal-RNG orient 1: flag 1 -> goalx = +0x140000, jitter_x negated. ---
base_layout 1 1
add "$(P 1 0x2c8)" 4;  add "$(P 1 0x2c4)" 1;  add "$(P 1 0x2bc)" 1;  add "$(P 1 0x18c)" 0x210000
add "$(P 1 0x2b8)" 0;  add "$(P 1 0x4)" 0;  add "$(P 1 0x8)" 0;  add "$(P 1 0xc)" 0
bank l4_goalrng_o1 1

echo "=== wall234 oracle -> $OUT ==="
cat "$OUT"
