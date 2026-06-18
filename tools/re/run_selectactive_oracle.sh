#!/usr/bin/env bash
# Stage 3 task 2 (movement, slice 5a): drive the REAL phase-based active-player selector
# FUN_005b8f20 (the gate + phase 6/4/else branches only) through the Ghidra PCode emulator
# and bank the chosen active player + its +0x5c flag. Ground truth that
# Pm98Movement.select_active must reproduce bit-for-bit (app/tests/test_selectactive.gd).
#
# FUN_005b8f20(__fastcall this=sim-ctx) picks ctx[0x168] by the match phase (match+0x448),
# clearing the old active's +0x5c and setting the new one's. Branches covered HERE:
#   * FORCED: global byte DAT_006d31c4 != 0 -> active = match+0x438, set flag, return.
#   * phase 6 -> active = player[0].
#   * phase 4 -> drop the 2 highest +0x39c players, pick the highest +0x394 of the rest.
#   * else (phase 0 here) -> FUN_005b8ce0(0) = select_nearest(find_in_front=0).
# DEFERRED to slice 5b (separate oracle): phase 2 (LUT @0x6392c8) and phase 5/7 (the
# Win32-GlobalReAlloc set-piece queue). Only the else branch touches floats, so we inject
# the faithful _ftol @0x252000 (same as run_movement_oracle.sh) and need NO cos/atan LUT
# (find_in_front=0 -> no cone -> no atan).
#
# Memory map: sim-ctx S@0x200000, match M@0x210000, players P0@0x230000 / P1@0x2303bc /
# P2@0x230778 / P3@0x230b34 (stride 0x3bc), team-info T@0x250000 (all +0x184 -> T),
# injected _ftol@0x252000, phase struct @0x260000 (M+0x468 -> it, +0xfa0 = sub-phase).
# Active ptr (= EAX) and +0x5c flags read back by absolute address. Values decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/selectactive_oracle.txt
SPEC=$SPECDIR/_selectactive_run.spec
ROUT=$SPECDIR/_selectactive_run.out

# Readback: active ptr (ctx+0x168) + each player's +0x5c.
READS=(
  "0x200168 4"                                              # active ptr (== EAX)
  "0x23005c 1" "0x230418 1" "0x2307d4 1" "0x230b90 1"       # P0/P1/P2/P3 +0x5c
)

emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b8f20
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
zero    0x00200000 0x00002000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00250000 0x00001000
zero    0x00260000 0x00002000
mem 0x006d31c4 1 0x0
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x00200000 4 0x00230000     # ctx+0 player base
mem 0x00200004 4 0x4            # ctx+4 count
mem 0x00200008 4 0x0            # ctx+8 team
mem 0x00200138 4 0x00210000     # ctx+0x138 match
mem 0x00200168 4 0x0            # ctx+0x168 active = none
mem 0x00210438 4 0x0            # match+0x438 forced player = none
mem 0x00210448 4 0x0            # match+0x448 phase
mem 0x00211614 4 0x0            # ball x
mem 0x00211618 4 0x0            # ball y
mem 0x0021161c 4 0x0            # ball z
mem 0x00211644 4 0x0            # ball facing
mem 0x00211650 4 0x0            # controller = none
mem 0x0021165c 4 0x0            # other-control = none
mem 0x00211664 4 0x0            # controller team
mem 0x00210468 4 0x00260000     # match+0x468 -> phase struct
mem 0x00260fa0 4 0x0            # sub-phase = 0
mem 0x002302bc 4 0x1            # P0 on-pitch
mem 0x00230184 4 0x00250000     # P0+0x184 teaminfo
mem 0x0023018c 4 0x00210000     # P0+0x18c match
mem 0x00230678 4 0x1            # P1 on-pitch
mem 0x00230540 4 0x00250000     # P1 teaminfo
mem 0x00230548 4 0x00210000     # P1 match
mem 0x00230a34 4 0x1            # P2 on-pitch
mem 0x002308fc 4 0x00250000     # P2 teaminfo
mem 0x00230904 4 0x00210000     # P2 match
mem 0x00230df0 4 0x1            # P3 on-pitch
mem 0x00230cb8 4 0x00250000     # P3 teaminfo
mem 0x00230cc0 4 0x00210000     # P3 match
$1
maxsteps 3000000
EOF
  for r in "${READS[@]}"; do echo "read_mem $r" >> "$SPEC"; done
}

# Fixtures: name | pokes (';'-separated, appended after the base).
FIX=(
"forced|mem 0x006d31c4 1 0x1 ; mem 0x00200168 4 0x00230000 ; mem 0x0023005c 1 0x1 ; mem 0x00210438 4 0x002303bc"
"phase6|mem 0x00210448 4 0x6 ; mem 0x00200168 4 0x002303bc ; mem 0x00230418 1 0x1"
"phase4|mem 0x00210448 4 0x4 ; mem 0x0023039c 4 0x40 ; mem 0x00230758 4 0x30 ; mem 0x00230b14 4 0x20 ; mem 0x00230ed0 4 0x10 ; mem 0x00230b0c 4 0x50 ; mem 0x00230ec8 4 0x30"
"else_nearest|mem 0x00210448 4 0x0 ; mem 0x00230004 4 0x50000 ; mem 0x002303c0 4 0x20000 ; mem 0x0023077c 4 0x80000 ; mem 0x00230b38 4 0x90000"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 task 2 slice 5a phase active-selector (FUN_005b8f20: gate/6/4/else) ground" >> "$OUT"
echo "# truth (PCode emu; faithful _ftol injected, no LUT -- find_in_front=0). Each row:" >> "$OUT"
echo "# 'FIX <name>' then the verbatim CALL line. bases: P0=0x230000 P1=0x2303bc P2=0x230778" >> "$OUT"
echo "# P3=0x230b34 ; null=0 (active EAX -> index via (EAX-0x230000)/0x3bc, 0 -> -1)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9]+')"
done
echo "=== selectactive oracle -> $OUT ==="
cat "$OUT"
