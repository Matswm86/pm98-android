#!/usr/bin/env bash
# Stage 3 task 2 (movement leaf): drive the REAL planar-magnitude helper FUN_005b1260 through
# the Ghidra PCode emulator and bank EAX. Ground truth that Pm98Trig.planar_mag must reproduce
# bit-for-bit (app/tests/test_trig_lut.gd). This is the reusable "length of a 2D vector via the
# trig LUT" primitive the player-move fns (FUN_005b70e0 nearest-search, FUN_005a3400 decide) call.
#
# FUN_005b1260(__fastcall ECX = ptr to {x:int32 @+0, y:int32 @+4}) returns (disasm 0x5b1260):
#   ang = atan_angle(x, y)                       (FUN_005ee080, s16)
#   return muladd16(x, COS[(ang+8>>4)&0xfff], y, COS[(0x3ff8-ang>>4)&0xfff])   (FUN_005edfb0)
# i.e. muladd16(x, cos_a(ang), y, sin_a(ang)) -- the projection of (x,y) onto its own unit
# direction == its LUT-approximated length. Integer-only (no _ftol); only the cos LUT @0x6d31c8
# + atan LUT @0x6d71c8 are needed (injected via emit_lut_membts.py). The faithful _ftol @0x252000
# is kept (harmless) so the base matches run_relmatrix_oracle.sh.
#
# Memory map: vec @0x200000 (x@0x200000, y@0x200004), injected _ftol@0x252000. EAX = the result.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/planarmag_oracle.txt
SPEC=$SPECDIR/_planarmag_run.spec
ROUT=$SPECDIR/_planarmag_run.out
LUT=$SPECDIR/_planarmag_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b1260
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
zero    0x00200000 0x00001000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
$1
maxsteps 2000000
EOF
  cat "$LUT" >> "$SPEC"
  echo "read_mem 0x200000 4" >> "$SPEC"
  echo "read_mem 0x200004 4" >> "$SPEC"
}

# Fixtures: name | x y (signed decimal poked as LE int32).
FIX=(
"v_xaxis|65536 0"          # (1.0, 0)        -> 1.0
"v_345|196608 262144"      # (3.0, 4.0)      -> ~5.0
"v_diag|-131072 131072"    # (-2.0, 2.0)     -> ~2.828
"v_zero|0 0"               # (0,0)           -> 0
"v_skew|458752 -98304"     # (7.0, -1.5)     -> ~7.159
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# LE-int32 poke of a possibly-negative decimal.
poke() { local addr=$1 val=$2; printf 'mem %s 4 0x%08x' "$addr" $(( val & 0xffffffff )); }

: > "$OUT"
echo "# Stage 3 task 2 movement leaf FUN_005b1260 (planar magnitude) PCode-emu ground truth." >> "$OUT"
echo "# Each row: 'FIX <name>' then the verbatim CALL line; EAX = muladd16(x,cos,y,sin)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME XY <<<"$row"
  read -r X Y <<<"$XY"
  POKES="$(poke 0x00200000 "$X")"$'\n'"$(poke 0x00200004 "$Y")"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9-]+')"
done
echo "=== planarmag oracle -> $OUT ==="
cat "$OUT"
