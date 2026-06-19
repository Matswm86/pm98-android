#!/usr/bin/env bash
# Stage 3 task 2 (driver resolution leaf): drive the REAL FUN_0058f0b0 through the Ghidra PCode
# emulator and bank the returned EAX. Ground truth for Pm98Movement.player_opposite_half
# (app/tests/test_halfpitch.gd). The driver FUN_00598740 calls it per team in the goal-area branch.
#
#   FUN_0058f0b0(__thiscall player; side): 1 iff sign(player.x) != sign(goalx), where goalx =
#     -(match+0x1820) when (match+0x19a0 & 1) == side, else +(match+0x1820). match = player+0x1d4.
# Pure integer, no sub-calls / RNG / LUT / ftol / stubs. EAX (auto-banked on RET) = return.
#
# Memory map: player P @0x230000 (P+0x1d4 -> match), match M @0x210000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/halfpitch_oracle.txt
SPEC=$SPECDIR/_halfpitch_run.spec
ROUT=$SPECDIR/_halfpitch_run.out

emit_spec() {
  # $1 = side arg, $2 = pokes
  {
    cat <<EOF
entry   0x0058f0b0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
mem 0x002301d4 4 0x00210000
mem 0x00211820 4 0x140000
EOF
    printf 'arg 0x%08x\n' $(( $1 & 0xffffffff ))
    printf '%s\n' "$2"
    echo "maxsteps 50000"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name $2 side $3 pokes
  emit_spec "$2" "${3//;/$'\n'}"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9-]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 driver resolution leaf FUN_0058f0b0 (half-pitch test) PCode-emu ground truth." >> "$OUT"
echo "# EAX = 1 iff sign(player.x) != sign(goalx); goalx = -(m+0x1820) when orient==side else +. m+0x1820=0x140000." >> "$OUT"

# orient=0,side=0 -> goalx=-0x140000(-); player.x>0(+) -> differ -> 1.
bank opp_x     0 "$(poke 0x2119a0 0);$(poke 0x230004 0x100000)"
# orient=0,side=0, player.x<0(-) -> same -> 0.
bank same_x    0 "$(poke 0x2119a0 0);$(poke 0x230004 -0x100000)"
# orient=0,side=1 -> goalx=+0x140000(+); player.x>0(+) -> same -> 0.
bank side1     1 "$(poke 0x2119a0 0);$(poke 0x230004 0x100000)"
# orient=1,side=0 -> goalx=+0x140000(+); player.x<0(-) -> differ -> 1.
bank orient1   0 "$(poke 0x2119a0 1);$(poke 0x230004 -0x100000)"
# player.x==0 -> sign bucket +1; goalx=-0x140000(-) -> differ -> 1 (tests sign(0)=+).
bank zero_x    0 "$(poke 0x2119a0 0);$(poke 0x230004 0)"

echo "=== halfpitch oracle -> $OUT ==="
cat "$OUT"
