#!/usr/bin/env bash
# Ball PREDICTED-TRAJECTORY builder (FUN_0058fda0, entry 0x0058fda0): drive the REAL function through the
# Ghidra PCode emulator and bank the 16-slot forward-trajectory buffer it writes at ball+0x114..0x1d4
# (16 vec3, stride 12) plus the 3 segment lengths at +0x74/+0x78/+0x7c. This is the buffer _grid9490_build
# reads for the lean's gate-4 catch zone + the 7260 marker builders -- it was WRONGLY deferred as
# "render trail, no sim read" (run_balltail_oracle.sh's own note), which is M5 divergence #1's root cause.
#
# Same emu harness as run_balltail_oracle.sh, with ONE deliberate change: the _ftol stub at 0x252000 is
# the TRUNCATING form (sub esp,8 / fisttp [esp] / mov eax,[esp] / add esp,8 / ret). The classic
# fnstcw/or ah,0xC/fldcw/fist stub the other oracles use forces round-toward-zero via the control word,
# but PcodeEmu's fist ignores fldcw and rounds-to-nearest (verified: an exact time-to-ground of 5.70
# emu-rounds to 6, hardware _ftol truncates to 5). fisttp lifts to Ghidra's round-toward-zero FLOAT2INT
# regardless of control word, so the emu now matches the real game's truncation. real cos/atan LUT
# injected (0x6d31c8 / 0x6d71c8), ball region zeroed then pos/vel seeded. FUN_0058fda0 is
# self-contained: its first loop builds the 3 bounce-segments in scratch (+0x74/+0xa8/+0xcc/+0xf0) from
# pos(+0x4/8/c)+vel(+0x20/24/28) only, its second loop samples them into +0x114. No external seed needed.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/ballpredict_oracle.txt
SPEC=$SPECDIR/_ballpredict_run.spec
ROUT=$SPECDIR/_ballpredict_run.out
LUT=$SPECDIR/_ballpredict_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

B() { printf '0x%08x' $(( 0x230000 + $1 )); }
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# READS: the 48 ints of the +0x114 trajectory buffer (16 slots x vec3) + the 3 segment lengths +0x74/78/7c.
READS=()
for k in $(seq 0 47); do READS+=("$(B $((0x114 + 4*k))) 4"); done
READS+=("$(B 0x74) 4" "$(B 0x78) 4" "$(B 0x7c) 4")

emit_spec() {
  {
    cat <<EOF
entry   0x0058fda0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00210000 0x00001000
maxsteps 2000000
membts 0x00252000 83EC08DB0C248B042483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x002301d4 4 0x00210000
EOF
    cat "$LUT"
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

# fixture: pos(x,y,z)+vel(vx,vy,vz). $1x $2y $3z $4vx $5vy $6vz
fixt() {
  echo "$(poke "$(B 0x4)" "$1");$(poke "$(B 0x8)" "$2");$(poke "$(B 0xc)" "$3");$(poke "$(B 0x20)" "$4");$(poke "$(B 0x24)" "$5");$(poke "$(B 0x28)" "$6")"
}

FIX=(
  # GROUND ROLL (pos.z==0 && vel.z==0) -- the kickoff regime the lean's catch reads.
  "roll_kick|$(fixt -38265 -117125 0   -3777 -11564 0)"   # actual M5 clk~9 rolling kickoff ball
  "roll_x|$(fixt 0 0 0                  0x8000 0 0)"       # pure +x roll
  "roll_diag|$(fixt 0x1000 0x2000 0     0x4000 0x3000 0)" # diagonal roll
  "roll_slow|$(fixt 0x3000 0x5000 0     0x10 0x10 0)"     # near roll-stop (|v|<0x22)
  # AIRBORNE (vel.z!=0 or pos.z!=0) -- gravity/bounce segmented arc.
  "air|$(fixt 0 0 0x20000               0x4000 0x2000 0x8000)"
  "air2|$(fixt 0x5000 0 0x10000         0x2000 0x6000 0x4000)"
  "air_down|$(fixt 0 0 0x8000           0x3000 -0x2000 -0x2000)"
  # M5 s50: the LIVE t1.i10 fork ticks. The port's +0x114 ladder at these is perfectly linear
  # (slot[i] = pos.xy + i*4*vel.xy), which is what feeds the runaway b0040 bisection. If the real
  # builder saturates or bends instead, that -- not b0040 -- is the clk-639 target flip's root.
  "m5_clk638|$(fixt 757224 -1948268 154494   13633 2451 6892)"
  "m5_clk639|$(fixt 770857 -1945817 161386   13633 2451 6714)"
  "m5_clk640|$(fixt 784490 -1943366 168100   13633 2451 6536)"
)

: > "$OUT"
echo "# FUN_0058fda0 (0x0058fda0) ball PREDICTED-TRAJECTORY builder PCode-emu truth." >> "$OUT"
echo "# 16-slot buffer ball+0x114..0x1d4 (vec3 stride 12) + segment lengths +0x74/78/7c. Read by" >> "$OUT"
echo "# _grid9490_build (lean gate-4 catch zone) + 7260 marker builders. cos/atan LUT + _ftol injected." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  slot0=($(echo "$LINE" | grep -oE "mem\[$(B 0x114):4\]=[0-9-]+" | grep -oE '[0-9-]+$'),$(echo "$LINE" | grep -oE "mem\[$(B 0x118):4\]=[0-9-]+" | grep -oE '[0-9-]+$'))"
done
echo "=== ball-predict oracle -> $OUT ==="
cat "$OUT"
