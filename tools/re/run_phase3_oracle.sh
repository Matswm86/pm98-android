#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice B): drive the REAL FUN_005b73a0 phase-3 (kickoff/restart) branch
# through the Ghidra PCode emulator and bank the positioning outputs. Ground truth for
# Pm98Movement._position_phase3 (app/tests/test_positionteam.gd::phase3 fixtures).
#
# OUR team (match+0x45c == team): find the nearest on-pitch teammate to the taker (min |x-taker.x|,
#   != taker), RNG-jitter its x and y partway toward the taker (2 FUN_005ec250 draws, factor =
#   (rand*50)>>15, /100 via the 0x51eb851f magic; y also + sign(y-gap)*0x70000), then set the TAKER's
#   facing (+0x34/+0x64) = atan(np - taker). z unchanged.
# ELSE (opponent's set-piece): clamp role player ctx+0x200's x to the taker's goal side, set its y=0.
#
#   ctx+0x2e0 seeded 0 -> FUN_005b8690 (relmatrix) increments to 1 and SKIPS (throttle) -> no player
#   iteration, no relmatrix LUT use. The cos/atan LUT IS injected for the taker-facing atan
#   (FUN_005ee080); FUN_005ec250 RNG seed @0x6d3184 (srand). NO _ftol/stubs needed.
#
# Memory map: ctx C @0x230000, match M @0x210000, players @0x240000 stride 0x3bc (P0=taker @0x240000,
# P1 @0x2403bc, P2 @0x240778); each player +0x18c -> match.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/phase3_oracle.txt
SPEC=$SPECDIR/_phase3_run.spec
ROUT=$SPECDIR/_phase3_run.out
LUT=$SPECDIR/_phase3_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

READS=(
  "0x0024077c 4" "0x00240780 4"                             # P2.x / P2.y (our-team: jittered nearest)
  "0x00240034 4"                                            # P0/taker facing (+0x34, our-team)
  "0x002403c0 4" "0x002403c4 4"                             # P1.x / P1.y (else: clamped role)
)

emit_spec() {
  # $1 = seed (srand), $2 = pokes
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
mem 0x00210448 4 0x3
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

# OUR-team setup: match+0x45c=0 (==team0); taker P0@0x240000 at origin; P1.x=0x50000, P2.x=0x30000 ->
# P2 is nearest. all on-pitch. P2.y=0x40000 for the y-jitter.
OUR="$(poke 0x21045c 0);$(poke 0x240004 0);$(poke 0x240008 0);$(poke 0x2402bc 1);$(poke 0x2403c0 0x50000);$(poke 0x2403c4 0x20000);$(poke 0x240678 1);$(poke 0x24077c 0x30000);$(poke 0x240780 0x40000);$(poke 0x240a34 1)"
# ELSE setup: match+0x45c=1 (!=team0); taker P0.x=0x20000; orient0 -> goalx<0 -> min; role=ctx+0x200=P1, role.x=0x60000.
ELSE="$(poke 0x21045c 1);$(poke 0x240004 0x20000);$(poke 0x2119a0 0);$(poke 0x211820 0x140000);$(poke 0x230200 0x002403bc);$(poke 0x2403c0 0x60000);$(poke 0x2403c4 0x11111)"

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice B (phase-3 kickoff/restart positioning) PCode-emu truth." >> "$OUT"
echo "# our-team: jitter nearest teammate toward taker (RNG) + taker facing; else: clamp role ctx+0x200." >> "$OUT"
echo "# relmatrix throttle-skipped (ctx+0x2e0=0); atan LUT injected; RNG seed @0x6d3184. CALL RET rows." >> "$OUT"
bank our_jitter 12345 "$OUR"
bank our_seed1  1     "$OUR"
bank else_min   1     "$ELSE"
echo "=== phase3 oracle -> $OUT ==="
cat "$OUT"
