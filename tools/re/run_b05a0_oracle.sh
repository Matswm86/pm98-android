#!/usr/bin/env bash
# Gate oracle for FUN_005b05a0 PHASE 1 (the near-ball pull-in), 0x5b05a0..0x5b07c3, that opens the
# dribble-grid block (FUN_005a7260 L242-249 -> call). The FULL function is 1140 bytes (0x5b05a0..
# 0x5b0a13) with TWO phases; phase 2 (0x5b07c4..) is the sector-grid approach-ball steer, reached on
# EVERY phase-1 gate-fail, and is a separate unported slice. Drives the REAL function under the Ghidra
# PCode emulator with FUN_005b0040 (the pull-in move) STUBBED, and observes whether b0040 is CALLED --
# i.e. did phase 1 take the pull-in branch. GROUND TRUTH for Pm98Movement._near_ball_pullin_decide
# (test_b05a0.gd). NOTE: rows where b0040 is NOT called HALT (not RET) -- that is control falling into
# the unported phase-2 steer (5a16c0/5a1700/5a89c0/MulDiv, not set up here), NOT an emulator error.
#
# this(ECX) = p. b05a0 reads p+0x18c (m), p+0x190 (ball), p+0x2b8 (team), p+0x184 (gs). Gates:
#   (1) bbox: ball.pos in [m+0x1828,0x1834] x [m+0x182c,0x1838] x [m+0x1830,0x183c].
#   (2) near: any of ball.pos / ball+0x168 / ball+0x1bc within (0xf8000,0xd8000,0x320000) of the team
#       goal anchor [goal_target_x(m,team),0,0] (FUN_005a44f0 + FUN_00590aa0 run REAL).
#   (3) carrier: bail when ball+0x40 owned by a TEAMMATE (carrier.team == p.team).
#   (4) clearance: FUN_005b1070(p, gs, ball.pos, 0x20000) runs REAL (geometry leaves + ftol + LUT);
#       b0040 fires ONLY when clearance >= 0x20000 (lane clear). setl/jne => `< radius` returns.
# b0040 STUBBED (retval 0, ret-arg 0) so its CALL is observed via stubhits but its body never runs.
#
# Memory: p @0x230000 (ECX), gs @0x250000 (+0 roster base 0x270000, +4 count), m @0x260000,
# ball @0x280000, roster players @0x270000 (stride 0x3bc), carrier @0x290000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b05a0_oracle.txt
SPEC=$SPECDIR/_b05a0_run.spec
ROUT=$SPECDIR/_b05a0_run.out
LUT=$SPECDIR/_b05a0_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant struct fields (p ptrs + team, m bbox/goal anchor, gs roster base). p.pos = (0,0,0).
CONST="$(poke 0x230184 0x250000);$(poke 0x23018c 0x260000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0)
$(poke 0x261820 0x100000);$(poke 0x2619a0 1)
$(poke 0x261828 0);$(poke 0x261834 0x200000)
$(poke 0x26182c 0xfff00000);$(poke 0x261838 0x100000)
$(poke 0x261830 0xfff00000);$(poke 0x26183c 0x100000)
$(poke 0x250000 0x270000)"
# goal anchor = goal_target_x(orient=1, x=0x100000, team=0): (1&1)=1 != 0 -> NOT negated -> +0x100000.

# name|gs_count|pokes  (ball/carrier/roster per fixture; ball.pos=[0x100000,0,0] == the anchor => NEAR)
FIX=(
  # bbox fail: ball.x past the box -> early return, b0040 never reached.
  "bboxfail|0|$(poke 0x280004 0x300000);$(poke 0x280040 0)"
  # near fail: in bbox but all 3 ref-points off the anchor (anchor1 x-gap 0xf9000>=0xf8000, 2/3 zero).
  "nearfail|0|$(poke 0x280004 0x1f9000);$(poke 0x280040 0)"
  # near via ANCHOR 2 (ball+0x168): anchor1 misses, ball+0x168 == anchor -> near; clear lane -> MOVE.
  "near2|1|$(poke 0x280004 0x1f9000);$(poke 0x280168 0x100000);$(poke 0x280040 0)"
  # near via ANCHOR 3 (ball+0x1bc): anchor1+2 miss, ball+0x1bc == anchor -> near; clear lane -> MOVE.
  "near3|1|$(poke 0x280004 0x1f9000);$(poke 0x2801bc 0x100000);$(poke 0x280040 0)"
  # carrier SAME team -> bail before the lane test (no move).
  "carriersame|0|$(poke 0x280004 0x100000);$(poke 0x280040 0x290000);$(poke 0x2902b8 0)"
  # carrier DIFFERENT team -> proceed; clear lane -> MOVE.
  "carrierdiff|1|$(poke 0x280004 0x100000);$(poke 0x280040 0x290000);$(poke 0x2902b8 1)"
  # no carrier, roster has 1 INACTIVE player -> clearance sentinel (clear) -> MOVE.
  "clearmove|1|$(poke 0x280004 0x100000);$(poke 0x280040 0)"
  # no carrier, roster has 1 ACTIVE player ON the lane (0x80000,0,0) -> clearance ~0 < radius -> no move.
  "blockednomove|1|$(poke 0x280004 0x100000);$(poke 0x280040 0);$(poke 0x270004 0x80000);$(poke 0x270008 0);$(poke 0x27000c 0);$(poke 0x2702bc 1)"
)

emit_spec() {  # $1=gs_count $2=pokes
  {
    cat <<EOF
entry   0x005b05a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00250000 0x00000100
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00002000
zero    0x00290000 0x00001000
maxsteps 400000
stub    0x005b0040 0 0 b0040
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    printf '%s\n' "${CONST//;/$'\n'}"
    poke 0x250004 "$1"; echo            # gs+4 = roster count
    printf '%s\n' "${2//;/$'\n'}"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Gate oracle FUN_005b05a0 (near-ball pull-in). b0040=1 iff the interception move was CALLED." >> "$OUT"
echo "# Row: B05A0 <name> <RET/HALT> steps=<n> b0040=<0|1>." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME CNT POKES <<<"$row"
  emit_spec "$CNT" "$POKES"
  run_emu
  SUM=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  STEPS=$(echo "$SUM" | grep -oE '(RET|HALT) steps=[0-9]+')
  if grep -q 'STUB b0040' "$ROUT"; then HIT=1; else HIT=0; fi
  echo "B05A0 $NAME $STEPS b0040=$HIT" >> "$OUT"
done
echo "=== b05a0 oracle -> $OUT ==="
cat "$OUT"
