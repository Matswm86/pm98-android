#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE B-i -- the off-ball GOAL-AIM scalars + rotated trajectory GRID
# (decompile L189-220 / asm 0x5a98b2-0x5a99c5). We drive the REAL FUN_005a9490 ENTERED MID-FUNCTION at
# 0x5a98b2 (the goal-aim setup, just past the gates + table init) so the angle scalars and the 16-entry
# grid are computed for real, then STUB 0x5a99c5 (the instruction right after the grid loop) so the harness
# pops [esp] (= retSentinel) and RETs the instant the grid is built -- the scan never runs.
#
# Frame: sp0 = 0x308000 => entry esp = sp0-4 = 0x307ffc ([esp] = sentinel). esp returns to 0x307ffc at
# 0x5a99c5 (every transient push/pop balances). Stack slots (abs):
#   grid  local_c0  = [esp+0x58]  = 0x308054   (grid[j] at 0x308054 + 12*j, 16 rows of 3 int32)
#   local_e8        = [esp+0x38] (esp=0x307ff4 at the store) = 0x30802c   (expect low16 == 0)
#   local_ec        = [esp+0x2c]                              = 0x308028   (expect low16 == goal-aim A)
# ESI = p @0x230000, EDI = &p.x = 0x230004, p+0x190 = ball @0x280000, p+0x18c = m @0x2a0000.
# Leaves run for real: FUN_00590aa0/590ae0 (vec store/sub), FUN_005ee080 (atan, needs LUT + _ftol thunk),
# FUN_005ee670 (rotate, needs cos LUT). GROUND TRUTH for Pm98Movement._grid9490_build + _lean9490_goal_aim
# (app/tests/test_9490sliceB.gd). rng-free.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceBi_oracle.txt
SPEC=$SPECDIR/_9490sliceBi_run.spec
ROUT=$SPECDIR/_9490sliceBi_run.out
LUT=$SPECDIR/_9490sliceBi_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Read the 16 grid vec3 back (work[j] at 0x308054 + 12*j) + the two scalars.
READS="read_mem 0x00308028 4
read_mem 0x0030802c 4
$(for j in $(seq 0 15); do for o in 0 4 8; do printf 'read_mem 0x%08x 4\n' $(( 0x308054 + 12*j + o )); done; done)"

# name|extra-pokes.  Each fixture sets p.pos, facing, team, m.orient(+0x19a0), m.goalx(+0x1820), and the 16
# trajectory slots ball+0xc*(0x17+j).  goalx_anchor m+0x1820, orient m+0x19a0 -> goal_target_x(orient,gx,1-team).
mk_traj() {  # emit the 16 trajectory slots for ball@0x280000: traj(s) = [bx + sx*s, by*(s-0x1f), bz*s]
  local bx=$1 sx=$2 by=$3 bz=$4 s
  for s in $(seq 23 38); do
    printf '%s;%s;%s;' \
      "$(poke $(( 0x280000 + 0xc*s ))       $(( bx + sx*s )))" \
      "$(poke $(( 0x280000 + 0xc*s + 4 ))   $(( by*(s-31) )))" \
      "$(poke $(( 0x280000 + 0xc*s + 8 ))   $(( bz*s )))"
  done
}

FIX=(
  # facing 0 (identity rotate), p.pos 0, team 0, orient 1, goalx +0x100000 -> aim = atan(+0x100000, 0)
  "f0|$(poke2 0x230034 0);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2302b8 0);$(poke 0x2a19a0 1);$(poke 0x2a1820 0x100000);$(mk_traj 0x40000 0x9000 0x3000 0x700)"
  # facing 0x4000 (quarter turn), p.pos nonzero, team 1, orient 0, goalx 0x100000
  "fq|$(poke2 0x230034 0x4000);$(poke 0x230004 0x12000);$(poke 0x230008 -0x8000);$(poke 0x23000c 0x400);$(poke 0x2302b8 1);$(poke 0x2a19a0 0);$(poke 0x2a1820 0x100000);$(mk_traj 0x60000 0x7000 0x4000 0x500)"
  # facing 0x2000 (eighth turn), p.pos nonzero, team 0, orient 0 -> goalx NEGATED branch
  "fe|$(poke2 0x230034 0x2000);$(poke 0x230004 -0x4000);$(poke 0x230008 0x9000);$(poke 0x23000c 0x800);$(poke 0x2302b8 0);$(poke 0x2a19a0 0);$(poke 0x2a1820 0x100000);$(mk_traj 0x50000 0x8800 0x3500 0x600)"
  # p.y > goal line so aim angle is negative (exercise local_ec sign, local_e8 still 0)
  "fn|$(poke2 0x230034 0x6000);$(poke 0x230004 0x8000);$(poke 0x230008 0x40000);$(poke 0x23000c -0x1000);$(poke 0x2302b8 1);$(poke 0x2a19a0 1);$(poke 0x2a1820 0x140000);$(mk_traj 0x30000 0xa000 0x2800 0x900)"
)

emit_spec() {  # $1=extra-pokes
  {
    cat <<EOF
entry   0x005a98b2
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ESI 0x00230000
reg     EDI 0x00230004
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
maxsteps 4000000
stub    0x005a99c5 0 0 BUILT
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "$(poke 0x230190 0x280000)"
    printf '%s\n' "$(poke 0x23018c 0x2a0000)"
    printf '%s\n' "${1//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a9490 Slice B-i (goal-aim scalars + rotated grid). Read at the stub-RET after the grid loop." >> "$OUT"
echo "# Row: B9490i <name> <built=0|1> | 0x308028=<local_ec> 0x30802c=<local_e8> 0x308054=<g0.x> ... (signed LE)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  if echo "$LINE" | grep -q 'stubhits=.*BUILT'; then BUILT=1; else BUILT=0; fi
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ' || true)
  echo "B9490i $NAME $BUILT | $KV" >> "$OUT"
  echo "[$NAME] built=$BUILT $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+' || true)"
done
echo "=== 9490 Slice B-i oracle -> $OUT ==="
cat "$OUT"
