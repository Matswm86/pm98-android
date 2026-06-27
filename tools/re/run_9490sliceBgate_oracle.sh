#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE B-i GATES -- the off-ball early-bail + proximity + action + ball + scan-entry
# guards (decompile L121-150, L221-230). We drive the REAL FUN_005a9490 from its TRUE entry 0x5a9490
# (__fastcall ECX = p) with a NON-carrier player and TRACE two checkpoints to see how far each fixture gets:
#   GRID @ 0x5a996b  -- the grid loop body (reached iff early-bail + proximity + action gates all pass).
#   SCAN @ 0x5a9a17  -- the marker-scan entry (reached iff ALSO the ball guards + scan-entry gate pass).
# tracehits are emitted as PC crosses each checkpoint, so the reach signal is robust even if the scan body
# (run un-stubbed past the checkpoint) later HALTs. GROUND TRUTH for Pm98Movement._lean9490_offball_reaches_scan
# (app/tests/test_9490sliceB.gd, GATE rows). carrier (for the early-bail fixtures) @ 0x290000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceBgate_oracle.txt
SPEC=$SPECDIR/_9490sliceBgate_run.spec
ROUT=$SPECDIR/_9490sliceBgate_run.out
LUT=$SPECDIR/_9490sliceBgate_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring: p+0x190=ball, p+0x18c=m, p+0x184=gs, p+0x188=teamstruct, DAT_006d31c4=0 (live).
CONST="$(poke 0x230190 0x280000)
$(poke 0x23018c 0x2a0000)
$(poke 0x230184 0x250000)
$(poke 0x230188 0x2b0000)
$(poke 0x6d31c4 0)"

# name|pokes.  p @0x230000 (non-carrier: ball+0x40 != p). carrier @0x290000 when used.
FIX=(
  # all gates pass -> reaches SCAN. no carrier, p at ball pos, action 0, scan flags set.
  "reach|$(poke 0x280040 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x280004 0);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280070 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # proximity fail: p.x 0x200000 from ball.x 0 (> 0x1e0000) -> no GRID.
  "prox|$(poke 0x280040 0);$(poke 0x230040 0);$(poke 0x230004 0x200000);$(poke 0x280004 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # action gate fail: action 5 (not 0..3 / 0xb / 0x1c) -> no GRID.
  "act5|$(poke 0x280040 0);$(poke 0x230040 5);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # action 0xb passes the action gate (GRID) but trips the scan-entry gate (action==0xb) -> no SCAN.
  "actB|$(poke 0x280040 0);$(poke 0x230040 0xb);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x280070 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # busy foreign carrier (action 0x1f always-busy, +0x2bc==0) -> early bail, no GRID.
  "carrierbusy|$(poke 0x280040 0x290000);$(poke 0x290040 0x1f);$(poke 0x2902bc 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # non-busy foreign carrier: passes early bail + proximity + action (GRID) but ball+0x40 != 0 -> no SCAN.
  "carrierfree|$(poke 0x280040 0x290000);$(poke 0x290040 0);$(poke 0x2902bc 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x280070 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
  # scan-entry gate: p+0x54 == 0 -> GRID but no SCAN.
  "scan54|$(poke 0x280040 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x280070 0);$(poke 0x230054 0);$(poke 0x2302bc 1)"
  # scan-entry gate: p+0x2bc == 0 -> GRID but no SCAN.
  "scan2bc|$(poke 0x280040 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x280070 0);$(poke 0x230054 1);$(poke 0x2302bc 0)"
  # ball guard: ball+0x70 != 0 -> GRID but no SCAN.
  "ball70|$(poke 0x280040 0);$(poke 0x230040 0);$(poke 0x230004 0);$(poke 0x280004 0);$(poke 0x280070 1);$(poke 0x230054 1);$(poke 0x2302bc 1)"
)

emit_spec() {  # $1=pokes
  {
    cat <<EOF
entry   0x005a9490
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00002000
zero    0x00250000 0x00001000
zero    0x002b0000 0x00001000
zero    0x00674000 0x00001000
maxsteps 3000000
stub    0x00605ff0 0 0 atexit
trace   0x005a996b GRID
trace   0x005a9a17 SCAN
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "$CONST"
    printf '%s\n' "${1//;/$'\n'}"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a9490 Slice B-i GATES. Row: BGATE <name> | grid=<0|1> scan=<0|1> (tracehits)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  GRID=0; SCAN=0
  echo "$LINE" | grep -q 'GRID=[1-9]' && GRID=1
  echo "$LINE" | grep -q 'SCAN=[1-9]' && SCAN=1
  echo "BGATE $NAME | grid=$GRID scan=$SCAN" >> "$OUT"
  echo "[$NAME] grid=$GRID scan=$SCAN $(echo "$LINE" | grep -oE '(RET|HALT) steps=[0-9]+' || true)"
done
echo "=== 9490 Slice B-i gate oracle -> $OUT ==="
cat "$OUT"
