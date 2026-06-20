#!/usr/bin/env bash
# Stage 3 task 2 (ball ADVANCE post-physics TAIL): drive the REAL FUN_0058e2c0 through the Ghidra PCode
# emulator and bank the spin/facing/snapshot/drift outputs Pm98Movement._ball_spin/_ball_tail/_ball_drift
# must reproduce bit-for-bit (app/tests/test_balltail.gd).
#
# The tail is reached from the free-flight physics at 0x58eb09 (SPIN entry) then 0x58eb93 (trail/facing/
# snapshot). Same harness as run_balladvance_oracle.sh -- collision gates kept clear (match @0x210000
# zeroed -> match+0x5fac==0 + match+0x17f8==0), real cos/atan LUT injected, gravity DAT_0066c1b0/b4/b8
# poked, faithful _ftol at 0x252000. The render trail FUN_0058fda0 RUNS in-emu but only touches +0x74/
# +0xa8 (not read here). We bank, after CALL 0 RET:
#   +0x2c spin frame, +0x30 spin parity, +0x34 facing word, +0x84/+0x88/+0x8c at-rest snapshot,
#   plus pos +0x4/+0x8/+0xc and vel +0x20/+0x24/+0x28 (the slice-B physics that feeds the tail).
#
# Fixtures exercise every spin tier (dot16(vel,vel) vs 0x4000/0x226a/0xc04/0x222 + the slow toggle's two
# parities), the vel==0 snapshot, and the grounded-roll drift (proj of seeded snapshot onto heading).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/balltail_oracle.txt
SPEC=$SPECDIR/_balltail_run.spec
ROUT=$SPECDIR/_balltail_run.out
LUT=$SPECDIR/_balltail_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

B() { printf '0x%08x' $(( 0x230000 + $1 )); }
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=(
  "$(B 0x4) 4" "$(B 0x8) 4" "$(B 0xc) 4"                       # pos
  "$(B 0x20) 4" "$(B 0x24) 4" "$(B 0x28) 4"                    # vel
  "$(B 0x2c) 4" "$(B 0x30) 4" "$(B 0x34) 4"                    # spin frame / spin parity / facing word
  "$(B 0x84) 4" "$(B 0x88) 4" "$(B 0x8c) 4"                    # at-rest snapshot
)

emit_spec() {
  {
    cat <<EOF
entry   0x0058e2c0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00210000 0x00001000
maxsteps 800000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x002301d4 4 0x00210000
mem 0x0066c1b0 4 0x00000000
mem 0x0066c1b4 4 0x00000000
mem 0x0066c1b8 4 0xffffff4e
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

# free-flight tail fixture: timers 0 (-> free-flight), not held. pos/vel + seeds for +0x2c/+0x30/+0x84.
# $1=x $2=y $3=z  $4=vx $5=vy $6=vz  $7=spin2c $8=spin30  $9=snapx ${10}=snapy ${11}=snapz
fixt() {
  echo "$(poke "$(B 0x54)" 0);$(poke "$(B 0x5c)" 0);$(poke "$(B 0x68)" 0);$(poke "$(B 0x6c)" 0);$(poke "$(B 0x70)" 0);$(poke "$(B 0x60)" 0);$(poke "$(B 0x4)" "$1");$(poke "$(B 0x8)" "$2");$(poke "$(B 0xc)" "$3");$(poke "$(B 0x20)" "$4");$(poke "$(B 0x24)" "$5");$(poke "$(B 0x28)" "$6");$(poke "$(B 0x2c)" "$7");$(poke "$(B 0x30)" "$8");$(poke "$(B 0x84)" "$9");$(poke "$(B 0x88)" "${10}");$(poke "$(B 0x8c)" "${11}")"
}

FIX=(
  # spin tiers: airborne (pos.z>0 -> gravity vz-=178, vx/vy unchanged) so dot16(vel,vel) lands in band.
  "spin4|$(fixt 0x10000 0x10000 0x40000   0x20000 0 0      5 0   0 0 0)"   # s>=0x4000  -> +4
  "spin3|$(fixt 0x10000 0x10000 0x40000   0x7000 0 0       5 0   0 0 0)"   # 0x226a<s<0x4000 -> +3
  "spin2|$(fixt 0x10000 0x10000 0x40000   0x4000 0 0       5 0   0 0 0)"   # 0xc04<s<=0x226a -> +2
  "spin1|$(fixt 0x10000 0x10000 0x40000   0x2000 0 0       5 0   0 0 0)"   # 0x222<s<=0xc04 -> +1
  "togg0|$(fixt 0x10000 0x10000 0x40000   0x100 0 0        5 0   0 0 0)"   # s<=0x222, +0x30=0 -> step
  "togg1|$(fixt 0x10000 0x10000 0x40000   0x100 0 0        5 1   0 0 0)"   # s<=0x222, +0x30=1 -> hold
  # snapshot: grounded, |vx|,|vy|<0x22 -> roll-stop vel=0 -> tail snapshots pos into +0x84.
  "snap|$(fixt 0x3000 0x5000 0            0x10 0x10 0      7 1   0 0 0)"
  # drift: grounded roll (|vx|>=0x22) -> vel stays nonzero, pos.z==0 && vel.z==0 -> snapshot drifts.
  "drift|$(fixt 0x2000 0x2000 0           0x800 0x400 0    3 0   0x9000 0x1000 0)"
  # drift, snapshot behind the ball (negative offset) -> proj<=0 -> snapshot collapses onto pos.
  "drift_back|$(fixt 0x9000 0x9000 0      0x800 0x400 0    3 0   0x1000 0x1000 0)"
)

: > "$OUT"
echo "# Stage 3 task 2 ball ADVANCE post-physics TAIL (FUN_0058e2c0 0x58eb09..0x58ec96) PCode-emu truth." >> "$OUT"
echo "# spin +0x2c/+0x30 (dot16 tiers + slow toggle), facing +0x34, snapshot/drift +0x84/+0x88/+0x8c." >> "$OUT"
echo "# Collision gates clear; real cos/atan LUT + _ftol; render trail FUN_0058fda0 runs but isn't read." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  2c=$(echo "$LINE" | grep -oE "mem\[$(B 0x2c):4\]=[0-9-]+")  30=$(echo "$LINE" | grep -oE "mem\[$(B 0x30):4\]=[0-9-]+")  84=$(echo "$LINE" | grep -oE "mem\[$(B 0x84):4\]=[0-9-]+")"
done
echo "=== ball-tail oracle -> $OUT ==="
cat "$OUT"
