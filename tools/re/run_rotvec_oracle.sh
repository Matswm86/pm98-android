#!/usr/bin/env bash
# Stage 3 task 2 (axis-rotation leaves): drive FUN_005ee670 / 005ee6e0 / 005ee750 through the Ghidra
# PCode emulator and bank the rotated vec3 each writes in place. Ground truth for Pm98Trig.rot_vec3
# (app/tests/test_rotvec.gd). These are the shared rotation primitives the goal-frame sweep FUN_005f3b80
# and the post narrow-phase FUN_005efac0 use to move a segment into / out of collider-local space.
#
#   FUN_005ee670  rotate (x, y), z fixed   [about Z]   thiscall(this=vec3, angle_word) ret 0x4
#   FUN_005ee6e0  rotate (x, z), y fixed   [about Y]
#   FUN_005ee750  rotate (y, z), x fixed   [about X]
#   a' = (a*cos - b*sin)>>16 ; b' = (a*sin + b*cos)>>16 ; cos/sin via COS LUT @0x6d31c8 (FUN_005edfb0).
#
# Pure integer (no FPU) -- only the cos LUT is needed; inject it. Vec @0x200000, angle via `arg`.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/rotvec_oracle.txt
SPEC=$SPECDIR/_rotvec_run.spec
ROUT=$SPECDIR/_rotvec_run.out
LUT=$SPECDIR/_rotvec_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 (+atan, harmless)

V=0x00200000
poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# emit_spec ENTRY  X Y Z  ANGLE
emit_spec() {
  {
    echo "entry   $1"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $V"
    echo "zero    0x00200000 0x00001000"
    echo "maxsteps 200000"
    cat "$LUT"
    poke $((V)) "$2"; echo
    poke $((V + 4)) "$3"; echo
    poke $((V + 8)) "$4"; echo
    printf 'arg 0x%08x\n' $(( $5 & 0xffffffff ))
    echo "read_mem $V 4"
    printf 'read_mem 0x%08x 4\n' $((V + 4))
    printf 'read_mem 0x%08x 4\n' $((V + 8))
  } > "$SPEC"
}

# name        ENTRY      X          Y          Z         ANGLE
MATRIX=(
  "z_q       0x5ee670   0x10000    0x0        0x30000   0x4000"    # +90deg about Z: (x,y)->(0,x)
  "z_oct     0x5ee670   0x20000   -0x10000    0x12345   0x2000"    # +45deg about Z
  "z_neg     0x5ee670  -0x18000    0x8000     0x7777   -0x1800"
  "y_q       0x5ee6e0   0x10000    0x55555    0x0       0x4000"    # +90deg about Y: (x,z)->(0,x)
  "y_oct     0x5ee6e0   0x20000    0x9999    -0x10000   0x2abc"
  "y_neg     0x5ee6e0  -0x14000    0x3333     0x28000  -0x3000"
  "x_q       0x5ee750   0x44444    0x10000    0x0       0x4000"    # +90deg about X: (y,z)->(0,y)
  "x_oct     0x5ee750   0x1234     0x20000    0x8000    0x1500"
  "x_neg     0x5ee750   0x6666    -0x18000    0x10000  -0x2200"
)

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
: > "$OUT"
echo "# Stage 3 task 2 axis-rotation leaves (FUN_005ee670/6e0/750) PCode-emu truth. cols decimal (uint32)." >> "$OUT"
echo "# reads: vec +0 +4 +8 after the in-place rotation. cos LUT injected." >> "$OUT"
for row in "${MATRIX[@]}"; do
  read -r NAME ENTRY X Y Z ANGLE <<<"$row"
  emit_spec "$ENTRY" "$X" "$Y" "$Z" "$ANGLE"
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  L=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $L" >> "$OUT"
  echo "[$NAME] x=$(mval "$L" 0x200000) y=$(mval "$L" 0x200004) z=$(mval "$L" 0x200008) $(echo "$L" | grep -oE 'CALL 0 (RET|HALT)')"
done
echo "=== rotvec oracle -> $OUT ==="
cat "$OUT"
