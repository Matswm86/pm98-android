#!/usr/bin/env bash
# Stage 3 task 2 (movement, slice 2): drive the REAL relationship-matrix builder
# FUN_005b8690 (which tail-calls the role selector FUN_005b8a60) through the Ghidra
# PCode emulator and bank the exact mutated state. Ground truth that
# Pm98Movement.build_relationship_matrix + _select_roles must reproduce bit-for-bit
# (app/tests/test_relmatrix.gd).
#
# FUN_005b8690(__fastcall this=sim-ctx) is THROTTLED: it increments ctx+0x2e0 (&7) and
# only does work on the wrap to 0 (every 8th call). When it runs it builds, per player,
# the pairwise angle (atan FUN_005ee080 == Pm98Trig.atan_angle, minus facing +0x34) at
# 0xb8+(slot+team*11)*2 and the projected planar distance (cos/sin LUT + muladd16
# FUN_005edfb0) at 0xe4+(slot+team*11)*4, plus +0x17c (nearest opponent) and +0x180
# (nearest opponent within a ~65deg facing cone, seed 1000.0=0x3e80000). team-0's
# context also fills the cross-team half + every opponent (match+0x78c) and then runs
# FUN_005b8a60, which picks 3 OUR-team role players into ctx +0x1fc/+0x200/+0x204
# (furthest-from-anchor / nearest-to-anchor / nearest-to-ball-3D, the last forced to the
# controller match+0x1650 when its team is ours). NO RNG.
#
# Emulation wrinkles (same as run_movement_oracle.sh): FUN_005b8a60's ball distance is
# ftol(sqrt(dx^2+dy^2+dz^2)) and ftol = `jmp [0x6233a4]` is an unbound msvcrt import, so
# we inject a faithful truncate-toward-zero _ftol @0x252000 and repoint the IAT slot.
# Ball distances are kept exact-integer (3-4-5 / 6-8-10) so the truncation is
# rounding-mode independent. The cos LUT @0x6d31c8 + atan LUT @0x6d71c8 are injected
# (emit_lut_membts.py) since the matrix reads them directly. The projected-distance
# muladd16 is native integer pcode.
#
# Memory map: sim-ctx S@0x200000 (ECX), match M@0x210000, OUR players P0@0x230000 /
# P1@0x2303bc (team 0, stride 0x3bc), OPP players Q0@0x240000 / Q1@0x2403bc (team 1,
# match+0x78c), injected _ftol@0x252000. Ball at the origin. All fields read back by
# absolute address; values decimal (unsigned LE).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/relmatrix_oracle.txt
SPEC=$SPECDIR/_relmatrix_run.spec
ROUT=$SPECDIR/_relmatrix_run.out
LUT=$SPECDIR/_relmatrix_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8 (banked)

# Readback set (object base + offset), applied to every fixture. S role/tick fields
# plus each player's matrix slots. P/Q within-team partner is slot index; cross slots
# are +11. width 2 = angle (s16), width 4 = dist / role-ptr / tick.
READS=(
  "0x2001fc 4" "0x200200 4" "0x200204 4" "0x2002e0 4"      # S: furthest nearest ball tick
  "0x2300ba 2" "0x2300e8 4" "0x2300ce 2" "0x2300d0 2"      # P0: ang/dist->P1 ; ang->Q0/Q1
  "0x230110 4" "0x230114 4" "0x23017c 4" "0x230180 4"      # P0: dist->Q0/Q1 ; +0x17c/+0x180
  "0x230474 2" "0x2304a0 4" "0x23048a 2" "0x23048c 2"      # P1: ang/dist->P0 ; ang->Q0/Q1
  "0x2304cc 4" "0x2304d0 4" "0x230538 4" "0x23053c 4"      # P1: dist->Q0/Q1 ; +0x17c/+0x180
  "0x2400b8 2" "0x2400ba 2" "0x2400e4 4" "0x2400e8 4"      # Q0: ang->P0/P1 ; dist->P0/P1
  "0x24017c 4" "0x240180 4"                                # Q0: +0x17c/+0x180
  "0x240474 2" "0x240476 2" "0x2404a0 4" "0x2404a4 4"      # Q1: ang->P0/P1 ; dist->P0/P1
  "0x240538 4" "0x24053c 4"                                # Q1: +0x17c/+0x180
)

emit_spec() {
  # $1 = pokes
  cat > "$SPEC" <<EOF
entry   0x5b8690
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
zero    0x00200000 0x00002000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
mem 0x006d31c4 1 0x0
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x00200000 4 0x00230000     # *param_1 = our player base
mem 0x00200004 4 0x2            # our count
mem 0x00200008 4 0x0            # our team idx
mem 0x00200138 4 0x00210000     # match
mem 0x002002e0 4 0x7            # tick counter (7 -> +1&7=0 triggers work)
mem 0x0021078c 4 0x00240000     # match+0x78c = opp base
mem 0x00210790 4 0x2            # match+0x790 = opp count
mem 0x00211614 4 0x0            # ball x
mem 0x00211618 4 0x0            # ball y
mem 0x0021161c 4 0x0            # ball z
mem 0x00211650 4 0x0            # controller = none
mem 0x00211664 4 0x0            # controller team
mem 0x002302b8 4 0x0            # P0 team 0
mem 0x002302bc 4 0x1            # P0 on-pitch
mem 0x002302c4 4 0x0            # P0 slot 0
mem 0x00230674 4 0x0            # P1 team 0
mem 0x00230678 4 0x1            # P1 on-pitch
mem 0x00230680 4 0x1            # P1 slot 1
mem 0x002402b8 4 0x1            # Q0 team 1
mem 0x002402bc 4 0x1            # Q0 on-pitch
mem 0x002402c4 4 0x0            # Q0 slot 0
mem 0x00240674 4 0x1            # Q1 team 1
mem 0x00240678 4 0x1            # Q1 on-pitch
mem 0x00240680 4 0x1            # Q1 slot 1
$1
EOF
  cat "$LUT" >> "$SPEC"
  { echo "maxsteps 3000000"; for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

# Fixtures: name | pokes (';'-separated; appended AFTER the base so later writes win).
# Positions are exact-integer ball distances (3-4-5 / 8-6-10). Facings 0 in t0_2v2 so
# the +0x180 cone split is by-construction (P0 has an opponent due +x = in front; P1
# does not). t1_within uses nonzero facings to exercise the (ang - facing) store.
FIX=(
"t0_2v2|mem 0x00230004 4 0x30000 ; mem 0x00230008 4 0x40000 ; mem 0x002303a4 4 0x10000 ; mem 0x002303c0 4 0x80000 ; mem 0x002303c4 4 0x60000 ; mem 0x00230760 4 0x70000 ; mem 0x00240004 4 0x60000 ; mem 0x00240008 4 0x40000 ; mem 0x002403c0 4 0x40000 ; mem 0x002403c4 4 0xc0000"
"t1_within|mem 0x00200008 4 0x1 ; mem 0x00230034 4 0x1000 ; mem 0x002303f0 4 0x9000 ; mem 0x00230004 4 0x30000 ; mem 0x00230008 4 0x40000 ; mem 0x002303a4 4 0x10000 ; mem 0x002303c0 4 0x80000 ; mem 0x002303c4 4 0x60000 ; mem 0x00230760 4 0x70000"
"tick_skip|mem 0x002002e0 4 0x0 ; mem 0x00230004 4 0x30000 ; mem 0x00230008 4 0x40000 ; mem 0x002303c0 4 0x80000 ; mem 0x002303c4 4 0x60000 ; mem 0x00240004 4 0x60000 ; mem 0x00240008 4 0x40000 ; mem 0x002403c0 4 0x40000 ; mem 0x002403c4 4 0xc0000"
"ctrl_forced|mem 0x00211650 4 0x002303bc ; mem 0x00211664 4 0x0 ; mem 0x00230004 4 0x30000 ; mem 0x00230008 4 0x40000 ; mem 0x002303a4 4 0x10000 ; mem 0x002303c0 4 0x80000 ; mem 0x002303c4 4 0x60000 ; mem 0x00230760 4 0x70000 ; mem 0x00240004 4 0x60000 ; mem 0x00240008 4 0x40000 ; mem 0x002403c0 4 0x40000 ; mem 0x002403c4 4 0xc0000"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 task 2 slice 2 relationship-matrix (FUN_005b8690 + FUN_005b8a60) ground" >> "$OUT"
echo "# truth (PCode emu; faithful _ftol injected, cos/atan LUT injected, exact-integer" >> "$OUT"
echo "# ball distances). Each row: 'FIX <name>' then the verbatim CALL line (decimal LE)." >> "$OUT"
echo "# bases: S=0x200000 P0=0x230000 P1=0x2303bc Q0=0x240000 Q1=0x2403bc ; role-ptr null=0" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== relmatrix oracle -> $OUT ==="
cat "$OUT"
