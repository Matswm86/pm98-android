#!/usr/bin/env bash
# Stage 3 task 2 (movement, slice 4): drive the REAL marker-assignment pass FUN_005b94f0
# through the Ghidra PCode emulator and bank the mutated +0x150/+0x154 marker links (plus
# the possession-change clear). Ground truth that Pm98Movement.assign_markers must
# reproduce bit-for-bit (app/tests/test_assignmarker.gd).
#
# FUN_005b94f0(__fastcall this=sim-ctx) is the per-tick marking pass. param_1 IS the ctx
# (disasm 0x5b94f6 `mov ebx,ecx`; every helper call is `mov ecx,ebx`), so ctx +0/+4/+8 =
# our players base/count/team. It runs ONLY when we are not in possession (FUN_005b8c90:
# match+0x1664 == ctx+8). Passes: (poss) if match+0x1668 != match+0x1664 zero each OUR
# player's +0x13c..+0x178 (FUN_005b13c0); (A) clear our +0x150/+0x154; (B) for each
# opponent holding the ball (its +0x190->+0x40 == itself OR == ball+0x4c = match+0x165c)
# pick the lowest-scoring eligible OUR marker (score = our->opp matrix dist + |z-diff|/3,
# eligible = on-pitch AND anchor-gap < opp's) and wire +0x150/+0x154; (C) every still-
# unmarked OUR on-pitch player runs FUN_005b36f0 (select_mark_target) and wires the links.
# Integer-only (matrix + /3 magic + mul16); NO _ftol/LUT injection needed.
#
# Memory map (mirrors the marktarget/relmatrix oracles): ctx S@0x200000 (ECX), match
# M@0x210000, OUR P0@0x230000 / P1@0x2303bc (team 0), OPP Q0@0x240000 / Q1@0x2403bc (team
# 1, match+0x78c), team-desc TD@0x250000 (player+0x184), shared controller blk@0x252000
# (player+0x190). +0x150 stores an OPP pointer, +0x154 an OUR pointer; null=0. Readback
# maps each via its base ((ptr-base)/0x3bc, 0->-1).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/assignmarker_oracle.txt
SPEC=$SPECDIR/_assignmarker_run.spec
ROUT=$SPECDIR/_assignmarker_run.out

# Readback: the 8 marker links (P*/Q* +0x150/+0x154) + P0's possession-change scalars.
READS=(
  "0x230150 4" "0x230154 4" "0x23050c 4" "0x230510 4"      # P0/P1 +0x150/+0x154
  "0x240150 4" "0x240154 4" "0x24050c 4" "0x240510 4"      # Q0/Q1 +0x150/+0x154
  "0x23013c 4" "0x230158 4" "0x230178 4"                   # P0 marking-block scalars
)

emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b94f0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
zero    0x00200000 0x00002000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
zero    0x00250000 0x00002000
zero    0x00252000 0x00001000
mem 0x00200000 4 0x00230000     # ctx+0 our player base
mem 0x00200004 4 0x2            # ctx+4 our count
mem 0x00200008 4 0x0            # ctx+8 our team
mem 0x00200138 4 0x00210000     # ctx+0x138 match
mem 0x0021078c 4 0x00240000     # match+0x78c opp base
mem 0x00210790 4 0x2            # match+0x790 opp count
mem 0x0021165c 4 0x00240000     # ball+0x4c (match+0x165c) = ball opp Q0  [route 2]
mem 0x00211664 4 0x1            # match+0x1664 current possession team = opp
mem 0x00211668 4 0x1            # match+0x1668 previous possession team (== -> no change)
mem 0x00211820 4 0x0            # match+0x1820 alt scale
mem 0x00230004 4 0x40000        # P0.x
mem 0x00230008 4 0x40000        # P0.z
mem 0x0023000c 4 0x0            # P0.+0xc
mem 0x002303a4 4 0x40000        # P0.anchor (metric 0)
mem 0x002302b8 4 0x0            # P0 team 0
mem 0x002302bc 4 0x1            # P0 on-pitch
mem 0x002302c4 4 0x0            # P0 slot 0
mem 0x002300b0 4 0x0            # P0 current mark target = none
mem 0x00230184 4 0x00250000     # P0+0x184 team desc
mem 0x00230188 4 0x0021078c     # P0+0x188 opp desc (== match+0x78c descriptor)
mem 0x0023018c 4 0x00210000     # P0+0x18c match
mem 0x00230210 4 0x0            # P0 box xmin
mem 0x00230214 4 0x0            # P0 box ymin
mem 0x00230218 4 0x0            # P0 box zmin
mem 0x0023021c 4 0x1000000      # P0 box xmax
mem 0x00230220 4 0x1000000      # P0 box ymax
mem 0x00230224 4 0x1000000      # P0 box zmax
mem 0x00230110 4 0x50000        # matrix P0->Q0
mem 0x00230114 4 0x90000        # matrix P0->Q1
mem 0x002303c0 4 0x40000        # P1.x
mem 0x002303c4 4 0x40000        # P1.z
mem 0x002303c8 4 0x0            # P1.+0xc
mem 0x00230760 4 0x40000        # P1.anchor
mem 0x00230674 4 0x0            # P1 team 0
mem 0x00230678 4 0x1            # P1 on-pitch
mem 0x00230680 4 0x1            # P1 slot 1
mem 0x0023046c 4 0x0            # P1 current mark target = none
mem 0x00230540 4 0x00250000     # P1+0x184 team desc
mem 0x00230544 4 0x0021078c     # P1+0x188 opp desc
mem 0x00230548 4 0x00210000     # P1+0x18c match
mem 0x002305cc 4 0x0            # P1 box xmin
mem 0x002305d0 4 0x0            # P1 box ymin
mem 0x002305d4 4 0x0            # P1 box zmin
mem 0x002305d8 4 0x1000000      # P1 box xmax
mem 0x002305dc 4 0x1000000      # P1 box ymax
mem 0x002305e0 4 0x1000000      # P1 box zmax
mem 0x002304cc 4 0x90000        # matrix P1->Q0
mem 0x002304d0 4 0x50000        # matrix P1->Q1
mem 0x00240004 4 0x50000        # Q0.x
mem 0x00240008 4 0x50000        # Q0.z
mem 0x0024000c 4 0x0            # Q0.+0xc
mem 0x002403a4 4 0x0            # Q0.anchor (q_metric = |x+anchor| = 0x50000)
mem 0x002402b8 4 0x1            # Q0 team 1
mem 0x002402bc 4 0x1            # Q0 on-pitch
mem 0x002402c4 4 0x0            # Q0 slot 0
mem 0x00240190 4 0x00252000     # Q0+0x190 controller block
mem 0x002400e4 4 0x40000        # matrix Q0->P0
mem 0x002400e8 4 0x80000        # matrix Q0->P1
mem 0x002403c0 4 0x30000        # Q1.x
mem 0x002403c4 4 0x30000        # Q1.z
mem 0x002403c8 4 0x0            # Q1.+0xc
mem 0x00240760 4 0x0            # Q1.anchor
mem 0x00240674 4 0x1            # Q1 team 1
mem 0x00240678 4 0x1            # Q1 on-pitch
mem 0x00240680 4 0x1            # Q1 slot 1
mem 0x0024054c 4 0x00252000     # Q1+0x190 controller block
mem 0x002404a0 4 0x70000        # matrix Q1->P0
mem 0x002404a4 4 0x30000        # matrix Q1->P1
mem 0x00250000 4 0x00230000     # TD base
mem 0x00250004 4 0x2            # TD count
mem 0x002502fc 4 0x0            # TD+0x2fc
mem 0x00250300 4 0x0            # TD+0x300
mem 0x00250310 4 0x0            # TD+0x310 (0 = box mode)
mem 0x00252040 4 0x0            # blk+0x40 ball-holder ptr (route 1 off)
$1
maxsteps 2000000
EOF
  for r in "${READS[@]}"; do echo "read_mem $r" >> "$SPEC"; done
}

# Fixtures: name | pokes (';'-separated; appended AFTER the base so later writes win).
# Base = passB_route2: Q0 holds the ball (route 2), P0 is its best marker, PASS C wires
# P1->Q1. The others toggle one branch each.
FIX=(
"passB_route2|"
"in_possession|mem 0x00211664 4 0x0 ; mem 0x00211668 4 0x0"
"poss_change|mem 0x00211668 4 0x0 ; mem 0x0023013c 4 0x111 ; mem 0x00230158 4 0x222 ; mem 0x00230178 4 0x333"
"passB_route1|mem 0x0021165c 4 0x0 ; mem 0x00252040 4 0x00240000"
"passB_reject|mem 0x00240004 4 0x0 ; mem 0x002403a4 4 0x0"
"passC_taken_guard|mem 0x0021165c 4 0x0 ; mem 0x002300b0 4 0x00240000 ; mem 0x0023046c 4 0x00240000"
"off_pitch|mem 0x00230678 4 0x0"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 task 2 slice 4 marker-assignment (FUN_005b94f0) ground truth (PCode emu;" >> "$OUT"
echo "# integer-only, no float-import). Each row: 'FIX <name>' then the verbatim CALL line." >> "$OUT"
echo "# bases: P0=0x230000 P1=0x2303bc Q0=0x240000 Q1=0x2403bc ; null=0. +0x150 holds an" >> "$OUT"
echo "# OPP ptr, +0x154 an OUR ptr (map each via its base, 0 -> -1)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== assignmarker oracle -> $OUT ==="
cat "$OUT"
