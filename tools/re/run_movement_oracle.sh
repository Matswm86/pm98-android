#!/usr/bin/env bash
# Stage 3 task 2 (movement, first slice): drive the REAL nearest-player-to-ball
# selector FUN_005b8ce0 through the Ghidra PCode emulator and bank the exact mutated
# state. Ground truth that Pm98Movement.select_nearest must reproduce bit-for-bit
# (test_movement.gd).
#
# FUN_005b8ce0(__thiscall this=sim-ctx, char find_in_front) picks the eligible player
# (player+0x2bc != 0) nearest the ball by 3D Euclidean distance ftol(sqrt(dx^2+dy^2+
# dz^2)) and makes it the active player (sim-ctx+0x168), optionally gated to a +/-0x3555
# cone of the ball facing (find_in_front). NO RNG. Two emulation wrinkles:
#   * ftol = FUN_00605fb0 = `jmp [0x6233a4]`, an UNBOUND msvcrt _ftol import (target
#     0x251000 is below the image base -> unmapped -> HALT). We inject a faithful
#     truncate-toward-zero _ftol (fnstcw; or ah,0x0c (RC=11); fist; restore) at
#     0x252000 and repoint the IAT slot 0x6233a4 to it. Distances are kept to exact
#     integers (pure-axis / 3-4-5 offsets) so the result is rounding-mode independent.
#   * the cone gate calls FUN_005ee080 (atan_angle) which reads the arctan LUT, so the
#     cos+atan LUTs are injected (emit_lut_membts.py) -- same trick as the keeper/
#     dispatcher oracles. FUN_00590aa0 (vector store) + FUN_005943b0 (phase==0) are
#     real in-binary code and execute.
#
# Memory map: sim-ctx S@0x200000, match M@0x210000, players P0@0x230000 /
# P1@0x2303bc / P2@0x230778 (stride 0x3bc), team-info T@0x250000 (all players'
# +0x184 -> T), injected _ftol@0x252000, phase struct @0x260000 (M+0x468 -> it,
# +0xfa0 = phase). Active ptr / flags read back by absolute address. Values decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/movement_oracle.txt
SPEC=$SPECDIR/_movement_run.spec
ROUT=$SPECDIR/_movement_run.out
LUT=$SPECDIR/_movement_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8 (banked)

# Player absolute field addresses (base + stride*n). Used by the fixture pokes below.
#   P0=0x230000  P1=0x2303bc  P2=0x230778
# x=+4 y=+8 z=+0xc vel=+0x54/+0x58 f5c=+0x5c lock=+0x5d teaminfo=+0x184 match=+0x18c
# team=+0x2b8 onpitch=+0x2bc

emit_spec() {
  # $1 = find_in_front (arg)   $2 = pokes
  cat > "$SPEC" <<EOF
entry   0x5b8ce0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
arg     $1
zero    0x00200000 0x00002000
zero    0x00210000 0x00002000
zero    0x00230000 0x00001000
zero    0x00250000 0x00001000
zero    0x00260000 0x00002000
mem 0x006d31c4 1 0x0
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x00200000 4 0x00230000     # *param_1 = player base
mem 0x00200004 4 0x3            # count
mem 0x00200008 4 0x0            # team idx (param_1[2])
mem 0x00200138 4 0x00210000     # match (param_1[0x4e])
mem 0x00200168 4 0x0            # active ptr (param_1[0x5a]) = null
mem 0x00211650 4 0x0            # match+0x1650 controller = none
mem 0x0021165c 4 0x0            # match+0x165c other-control = none
mem 0x00211614 4 0x0            # ball x
mem 0x00211618 4 0x0            # ball y
mem 0x0021161c 4 0x0            # ball z
mem 0x00211644 4 0x0            # ball facing (s16)
mem 0x00210468 4 0x00260000     # match+0x468 -> phase struct
mem 0x00260fa0 4 0x0            # phase = 0
# P0 base fields (each `mem` MUST be its own line: PcodeEmu parses one directive/line)
mem 0x002302bc 4 0x1
mem 0x00230184 4 0x00250000
mem 0x0023018c 4 0x00210000
# P1 base fields
mem 0x00230678 4 0x1
mem 0x00230540 4 0x00250000
mem 0x00230548 4 0x00210000
# P2 base fields
mem 0x00230a34 4 0x1
mem 0x002308fc 4 0x00250000
mem 0x00230904 4 0x00210000
$2
EOF
  cat "$LUT" >> "$SPEC"
  cat >> "$SPEC" <<'EOF'
maxsteps 3000000
read_mem 0x00200168 4         # active ptr after
read_mem 0x0023005c 1         # P0 +0x5c
read_mem 0x00230418 1         # P1 +0x5c
read_mem 0x002307d4 1         # P2 +0x5c
read_mem 0x00230410 4         # P1 +0x54 (velocity x, for the reset fixture)
read_mem 0x00230414 4         # P1 +0x58 (velocity y)
EOF
}

# Fixtures: name | find_in_front | pokes (';'-separated). Positions use exact-integer
# distances (pure-axis or 3-4-5 scaled by 0x10000) so ftol truncation is exact.
#   P0.x=0x230004 P1.x=0x2303c0 P2.x=0x23077c ; .y=+4 ; .z=+8 from .x
FIX=(
"near3|0|mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000 ; mem 0x0023077c 4 0x80000"
"near3_3d|0|mem 0x00230004 4 0x30000 ; mem 0x00230008 4 0x40000 ; mem 0x002303c8 4 0x20000 ; mem 0x0023077c 4 0x80000"
"cone_skip|1|mem 0x00230004 4 0x50000 ; mem 0x002303c4 4 0x20000 ; mem 0x0023077c 4 0x40000"
"cone_keep|1|mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000 ; mem 0x00230780 4 0x80000"
"owned1650|0|mem 0x00211650 4 0x00230000 ; mem 0x00211664 4 0x0 ; mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000"
"owned165c|0|mem 0x0021165c 4 0x002303bc ; mem 0x00230674 4 0x0 ; mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000"
"lock_keep|0|mem 0x00200168 4 0x00230000 ; mem 0x0023005d 1 0x1 ; mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000"
"velreset|0|mem 0x002303c0 4 0x20000 ; mem 0x00230004 4 0x1300000 ; mem 0x0023077c 4 0x1300000 ; mem 0x002502ee 1 0x1 ; mem 0x00230410 4 0xAAAA ; mem 0x00230414 4 0xBBBB"
"none_inrange|0|mem 0x00230004 4 0x1300000 ; mem 0x002303c0 4 0x1300000 ; mem 0x0023077c 4 0x1300000"
"ineligible|0|mem 0x002302bc 4 0x0 ; mem 0x00230678 4 0x0 ; mem 0x00230a34 4 0x0 ; mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

: > "$OUT"
echo "# Stage 3 task 2 movement (FUN_005b8ce0 nearest-to-ball) ground truth (PCode emu;" >> "$OUT"
echo "# faithful _ftol injected @0x252000, LUT injected, exact-integer distances). decimal." >> "$OUT"
echo "# base addrs: P0=2293760 P1=2294716 P2=2295672 ; null=0" >> "$OUT"
echo "# M name | active | p0_5c | p1_5c | p2_5c | p1_v54 | p1_v58 | RET" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME FIF POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$FIF" "$POKES"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'M %-13s | %-8s | %-3s | %-3s | %-3s | %-6s | %-6s | %s\n' \
    "$NAME" "$(mval "$S" 0x200168)" \
    "$(mval "$S" 0x23005c)" "$(mval "$S" 0x230418)" "$(mval "$S" 0x2307d4)" \
    "$(mval "$S" 0x230410)" "$(mval "$S" 0x230414)" "${RET:-?}" >> "$OUT"
  echo "[M $NAME] active=$(mval "$S" 0x200168) p1_5c=$(mval "$S" 0x230418) v54=$(mval "$S" 0x230410) $RET"
done
echo "=== movement oracle -> $OUT ==="
cat "$OUT"
