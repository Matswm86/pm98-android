#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice C): drive the REAL FUN_005b73a0 phase-7 SCATTER sub-branch
# (match+0x19a0 == 4) through the Ghidra PCode emulator and bank the scattered positions. Ground
# truth for Pm98Movement._position_phase7 (app/tests/test_phase7.gd).
#
# For each eligible player (not the taker; on-pitch OR off-pitch on our set-piece side
# team==match+0x45c): angle = (rand1*0x10000)>>15, radius = (rand2*0xa00)>>7, then pos (+0x4) =
# endpoint1 (+0x1e0) = endpoint2 (+0x1ec) = polar_vec(radius, angle). Two FUN_005ec250 draws per
# processed player (angle then radius), in player order.
#
#   ctx+0x2e0 = 0 -> relmatrix (FUN_005b8690) increments to 1 and SKIPS (no player iteration / no
#   relmatrix LUT). The cos LUT IS injected for polar_vec (FUN_005ee0f0); RNG seed @0x6d3184.
#
# Memory map: ctx C @0x230000, match M @0x210000, players @0x240000 stride 0x3bc (P0=taker, P1, P2);
# each player +0x18c -> match.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/phase7_oracle.txt
SPEC=$SPECDIR/_phase7_run.spec
ROUT=$SPECDIR/_phase7_run.out
LUT=$SPECDIR/_phase7_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

READS=(
  "0x002403c0 4" "0x002403c4 4" "0x002403c8 4"              # P1.x / P1.y / P1.z
  "0x0024059c 4"                                            # P1.endpoint1.x (+0x1e0)
  "0x0024077c 4" "0x00240780 4"                             # P2.x / P2.y
)

emit_spec() {
  # $1 = seed, $2 = pokes
  {
    cat <<EOF
entry   0x005b73a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
maxsteps 400000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x3
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
mem 0x00210448 4 0x7
mem 0x002119a0 4 0x4
mem 0x00210438 4 0x00240000
mem 0x0024018c 4 0x00210000
mem 0x0024054c 4 0x00210000
mem 0x00240904 4 0x00210000
EOF
    printf 'mem 0x006d3184 4 0x%08x\n' $(( $1 & 0xffffffff ))
    cat "$LUT"
    printf '%s\n' "$2"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name $2 seed $3 pokes
  emit_spec "$2" "${3//;/$'\n'}"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice C (phase-7 scatter, match+0x19a0==4) PCode-emu ground truth." >> "$OUT"
echo "# each eligible player -> polar_vec((rand2*0xa00)>>7, (rand1*0x10000)>>15); 2 draws/player." >> "$OUT"
echo "# relmatrix throttle-skipped; cos LUT injected; RNG seed @0x6d3184. CALL RET rows." >> "$OUT"
# all on-pitch, match+0x45c=0: P1 (draws 1,2) + P2 (draws 3,4) scattered; taker P0 skipped.
bank scatter_seed1 1 "$(poke 0x21045c 0);$(poke 0x2402bc 1);$(poke 0x240678 1);$(poke 0x240a34 1)"
# match+0x45c=1 (!= team0): P1 off-pitch -> SKIPPED (no draws); P2 on-pitch -> scattered (draws 1,2).
bank offpitch_skip 1 "$(poke 0x21045c 1);$(poke 0x2402bc 1);$(poke 0x240678 0);$(poke 0x2403c0 0x11110000);$(poke 0x240a34 1)"
echo "=== phase7 oracle -> $OUT ==="
cat "$OUT"
