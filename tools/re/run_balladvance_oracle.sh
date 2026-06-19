#!/usr/bin/env bash
# Stage 3 task 2 (ball ADVANCE, vtable+0xc on match+0x1610): drive the REAL FUN_0058e2c0 through the
# Ghidra PCode emulator and bank the SLICE-A outputs (timers + lerp-to-target) that
# Pm98Movement.ball_advance must reproduce bit-for-bit (app/tests/test_balladvance.gd).
#
# SLICE A = the prologue timers + the lerp branch (disasm 0x58e2c0..0x58e357):
#   +0x58 = +0x54; decrement +0x5c/+0x70/+0x68 each iff nonzero; then iff (post-dec) +0x68==0 AND
#   +0x6c!=0: N=ORIGINAL +0x6c; +0x6c-=1; pos[axis] += (target[axis]-pos[axis])/N (idiv trunc->0),
#   target = +0x9c/+0xa0/+0xa4, pos = +0x4/+0x8/+0xc. Then the real fn runs the FUN_0058fda0 trail
#   tail + facing(+0x34) -- neither touches pos/step/timers, so they read clean. All fixtures keep
#   velocity (+0x20) nonzero so the 0x58ebb1 epilogue takes the je->ret (does not snapshot pos).
#
# The lerp/held paths never dereference the match (+0x1d4) but we point it at a zeroed region for
# safety. The tail's atan/polar (FUN_005ee080/0f0) read zeroed LUTs (we do not read their outputs);
# a faithful _ftol is injected in case the tail import-thunks it. No RNG.
#
# Memory: ball B @0x230000 (field $1 = B(off)); match @0x210000 (zeroed). Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/balladvance_oracle.txt
SPEC=$SPECDIR/_balladvance_run.spec
ROUT=$SPECDIR/_balladvance_run.out

B() { printf '0x%08x' $(( 0x230000 + $1 )); }
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=(
  "$(B 0x4) 4" "$(B 0x8) 4" "$(B 0xc) 4"                       # +0x4/+0x8/+0xc position
  "$(B 0x6c) 4"                                                # +0x6c step count (post-decrement)
  "$(B 0x58) 4" "$(B 0x5c) 4" "$(B 0x68) 4" "$(B 0x70) 4"      # +0x58 copy + the 3 decremented timers
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
zero    0x006d3000 0x00001000
zero    0x006d7000 0x00001000
maxsteps 400000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x002301d4 4 0x00210000
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

# field pokes: timers (+0x54/+0x5c/+0x68/+0x6c/+0x70), pos (+0x4/+0x8/+0xc), target (+0x9c/+0xa0/+0xa4),
# velocity +0x20 nonzero (clean epilogue ret).
fix() {  # $1=54 $2=5c $3=68 $4=6c $5=70  $6=x $7=y $8=z  $9=tx ${10}=ty ${11}=tz
  echo "$(poke "$(B 0x54)" "$1");$(poke "$(B 0x5c)" "$2");$(poke "$(B 0x68)" "$3");$(poke "$(B 0x6c)" "$4");$(poke "$(B 0x70)" "$5");$(poke "$(B 0x4)" "$6");$(poke "$(B 0x8)" "$7");$(poke "$(B 0xc)" "$8");$(poke "$(B 0x9c)" "$9");$(poke "$(B 0xa0)" "${10}");$(poke "$(B 0xa4)" "${11}");$(poke "$(B 0x20)" 0x10000)"
}

FIX=(
  "lerp_pos|$(fix 0x1234 3 1 4 5   0x100000 0x200000 0x80000   0x500000 0x600000 0x180000)"
  "lerp_neg|$(fix 0x2 1 0 3 0      0x500000 0x500000 0x100000  0x100000 0x100000 0x0)"
  "lerp_n1|$(fix 0x9 0 0 1 2       0x111111 0x222222 0x33333   0x777777 0x888888 0x99999)"
  "lerp_guard|$(fix 0xabcd 0 0 2 0  0 0 0                      0x80000 -0x80000 0x40000)"
)

: > "$OUT"
echo "# Stage 3 task 2 ball ADVANCE slice A (FUN_0058e2c0 timers + lerp-to-target) PCode-emu ground truth." >> "$OUT"
echo "# +0x58=+0x54; dec +0x5c/+0x70/+0x68 iff !=0; lerp iff +0x68(post-dec)==0 && +0x6c!=0:" >> "$OUT"
echo "# N=orig +0x6c; +0x6c-=1; pos[a] += (target[a]-pos[a])/N (idiv). vel +0x20!=0 -> clean ret." >> "$OUT"
echo "# Each row: FIX <name> + verbatim CALL line. Reads: pos +0x4/+0x8/+0xc, step +0x6c, timers." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  x=$(echo "$LINE" | grep -oE "mem\[$(B 0x4):4\]=[0-9-]+")  6c=$(echo "$LINE" | grep -oE "mem\[$(B 0x6c):4\]=[0-9-]+")"
done
echo "=== ball-advance oracle -> $OUT ==="
cat "$OUT"
