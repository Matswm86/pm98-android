#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice A): drive the REAL per-team positioning pass FUN_005b73a0
# through the Ghidra PCode emulator for the OPEN-PLAY path and bank the prologue effects. Ground
# truth for Pm98Movement.position_team (app/tests/test_positionteam.gd).
#
# For a non-set-piece phase (match+0x448 in {0,1,2,6}) FUN_005b73a0 = relationship matrix
# (FUN_005b8690, throttled) + reset the throttle counter param_1[0xb8] (ctx+0x2e0) = -1, then the
# phase dispatch falls straight to the TAIL which returns (match+0x448 != 5). The off-ball
# positioning branches (phases 3/4/5/7) never fire, so NO player is touched.
#   ctx+0x2e0 seeded 0 -> FUN_005b8690 increments to 1 and SKIPS (throttle), so no player iteration
#   and no LUT/RNG; FUN_005b73a0 then overwrites ctx+0x2e0 = -1. NO stubs needed.
#
# Memory map: ctx C @0x230000 (C+0=players base, C+4=count, C+8=team, C+0x138=match, C+0x2e0=throttle),
# match M @0x210000, player P @0x240000 (a sentinel +0x4 to prove the open-play path is no-op).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/positionteam_oracle.txt
SPEC=$SPECDIR/_positionteam_run.spec
ROUT=$SPECDIR/_positionteam_run.out

READS=( "0x002302e0 4" "0x00240004 4" )                     # ctx+0x2e0 (-> -1) ; player+0x4 (untouched)

emit_spec() {
  # $1 = pokes
  {
    cat <<EOF
entry   0x005b73a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
maxsteps 200000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x1
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
mem 0x00240004 4 0x12340000
EOF
    printf '%s\n' "$1"
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

bank() {  # $1 name $2 phase
  emit_spec "$(poke 0x210448 $2)"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  2e0=$(echo "$line" | grep -oE 'mem\[0x2302e0:4\]=[0-9-]+')  P4=$(echo "$line" | grep -oE 'mem\[0x240004:4\]=[0-9-]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice A (per-team positioning, OPEN-PLAY path) PCode-emu truth." >> "$OUT"
echo "# Non-set-piece phase -> relmatrix(skip via throttle) + ctx+0x2e0 = -1 + TAIL return; no player" >> "$OUT"
echo "# touched. ctx+0x2e0 seeded 0; reads ctx+0x2e0 (-> -1=4294967295) + player+0x4 (-> 0x12340000)." >> "$OUT"
bank phase0 0
bank phase1 1
bank phase6 6
echo "=== positionteam oracle -> $OUT ==="
cat "$OUT"
