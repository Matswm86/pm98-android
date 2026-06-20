#!/usr/bin/env bash
# Stage 3 task 2 (GOALKEEPER advance): drive the REAL FUN_005a22d0 through the Ghidra PCode emulator and
# bank the keeper state Pm98Movement.keeper_advance must reproduce bit-for-bit (app/tests/test_keeperadv.gd).
#
# FUN_005a22d0 slides the keeper x along the goal line to shadow the ball: accel +/-0x28f toward ball.x
# (gated by goal-mouth boundary flags), friction 0xa3/frame toward 0, clamp |vel|<=0x1555, keeper.x +=
# vel, then face by vel sign (atan to the ball when stopped). It reads the cos LUT (via the FUN_005edfb0
# projection == Pm98Trig.planar_mag) and the atan LUT (FUN_005ee080), so both LUTs are injected; no FPU
# (all integer imul/idiv), so no _ftol. The trailing FUN_005a50c0 sprite call is STUBBED to a bare ret
# (it draws from +0x40/+0x30 and writes no sim field we read).
#
# Memory: match M@0x200000, keeper K@0x230000 (K+0x18c -> M). Reads: +0x3c0 vel, +0x4 x, +0x34 facing
# word, +0x40 position code.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/keeperadv_oracle.txt
SPEC=$SPECDIR/_keeperadv_run.spec
ROUT=$SPECDIR/_keeperadv_run.out
LUT=$SPECDIR/_keeperadv_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

# emit_spec  TEAM KX KY VEL  BX BY LINE
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5a22d0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00200000 0x00002000
zero    0x00230000 0x00001000
maxsteps 2000000
membts 0x005a50c0 C3
mem 0x006d31c4 1 0x0
mem 0x0023018c 4 0x00200000
mem 0x002303bc 4 $1
mem 0x00230004 4 $2
mem 0x00230008 4 $3
mem 0x002303c0 4 $4
mem 0x00201614 4 $5
mem 0x00201618 4 $6
mem 0x00201820 4 $7
EOF
  cat "$LUT" >> "$SPEC"
  cat >> "$SPEC" <<EOF
read_mem 0x002303c0 4
read_mem 0x00230004 4
read_mem 0x00230034 4
read_mem 0x00230040 4
EOF
}

# name           TEAM  KX         KY        VEL      BX          BY         LINE
MATRIX=(
  "far_right_t1   1     0x40000    0x0       0x0      0x180000    0x0        0x100000"
  "far_left_t1    1     0xc0000    0x0       0x0      0x40000     0x0        0x100000"
  "far_deadband   1     0x100000   0x0       0x0      0x110000    0x80000    0x180000"
  "close_invR     1     0x110000   0x0       0x0      0x100000    0x0        0x180000"
  "close_invL     1     0x110000   0x0       0x0      0x120000    0x0        0x180000"
  "team2_far      2    -0x40000    0x0       0x0     -0x180000    0x0        0x100000"
  "clamp_max      1     0x40000    0x0       0x1500   0x180000    0x0        0x180000"
  "at_right_blk   1     0x100000   0x0       0x0      0x180000    0x0        0x100000"
)

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
: > "$OUT"
echo "# Stage 3 task 2 GOALKEEPER advance (FUN_005a22d0) PCode-emu ground truth. cols decimal (uint32)." >> "$OUT"
echo "# FUN_005a50c0 sprite stubbed to ret; LUTs injected. Each row: FIX <name> + verbatim CALL line." >> "$OUT"
echo "# reads: +0x3c0 vel, +0x4 x, +0x34 facing, +0x40 pos-code." >> "$OUT"
for row in "${MATRIX[@]}"; do
  read -r NAME TEAM KX KY VEL BX BY LINE <<<"$row"
  emit_spec "$TEAM" "$KX" "$KY" "$VEL" "$BX" "$BY" "$LINE"
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  LINE_OUT=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE_OUT" >> "$OUT"
  echo "[$NAME] vel=$(mval "$LINE_OUT" 0x2303c0) x=$(mval "$LINE_OUT" 0x230004) face=$(mval "$LINE_OUT" 0x230034) code=$(mval "$LINE_OUT" 0x230040) $(echo "$LINE_OUT" | grep -oE 'CALL 0 (RET|HALT)')"
done
echo "=== keeper-advance oracle -> $OUT ==="
cat "$OUT"
