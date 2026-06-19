#!/usr/bin/env bash
# Stage 3 task 2 (ball ADVANCE, vtable+0xc on match+0x1610): drive the REAL FUN_0058e2c0 through the
# Ghidra PCode emulator and bank the outputs Pm98Movement.ball_advance must reproduce bit-for-bit
# (app/tests/test_balladvance.gd).
#
# SLICE A = prologue timers + the lerp branch (disasm 0x58e2c0..0x58e357):
#   +0x58 = +0x54; decrement +0x5c/+0x70/+0x68 each iff nonzero; then iff (post-dec) +0x68==0 AND
#   +0x6c!=0: N=ORIGINAL +0x6c; +0x6c-=1; pos[axis] += (target[axis]-pos[axis])/N (idiv trunc->0),
#   target = +0x9c/+0xa0/+0xa4, pos = +0x4/+0x8/+0xc.
#
# SLICE B = the free-flight branch (disasm 0x58e35c held-gate; integration + gravity + bounce + roll
#   at 0x58e969..0x58eb09). Reached when (post-dec) +0x68 != 0 OR +0x6c == 0. We force it with
#   +0x6c==0. Both collision gates are kept clear (match @0x210000 zeroed -> match+0x5fac==0 skips the
#   goal sweep, match+0x17f8==0 skips the post loop) so execution runs straight: prologue bbox (temp
#   pos.z += 0x23d7 @0x58e437, undone @0x58e96c) -> integration pos += vel -> bounce/gravity/roll ->
#   spin (FUN_005ee500 reads vel only) -> trail/facing tail. None of the deferred work writes pos or
#   vel, so both read clean. Gravity DAT_0066c1b0/b4/b8 = [0,0,-178] (set by FUN_0058e030) is poked.
#   Bounce damping FUN_005edfa0(.,0xc51e) horiz / -(.,0x9c28) vert; settle |vz|<0x28f; roll-stop
#   |vx|,|vy|<0x22 else subtract polar_vec(0x22, atan(vx,vy)) (real cos/atan LUT + faithful _ftol).
#
# Memory: ball B @0x230000 (field $1 = B(off)); match @0x210000 (zeroed). Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/balladvance_oracle.txt
SPEC=$SPECDIR/_balladvance_run.spec
ROUT=$SPECDIR/_balladvance_run.out
LUT=$SPECDIR/_balladvance_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8 (roll-friction path)

B() { printf '0x%08x' $(( 0x230000 + $1 )); }
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=(
  "$(B 0x4) 4" "$(B 0x8) 4" "$(B 0xc) 4"                       # +0x4/+0x8/+0xc position
  "$(B 0x20) 4" "$(B 0x24) 4" "$(B 0x28) 4"                    # +0x20/+0x24/+0x28 velocity
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

# SLICE-A field pokes: timers (+0x54/+0x5c/+0x68/+0x6c/+0x70), pos (+0x4/+0x8/+0xc), target
# (+0x9c/+0xa0/+0xa4), velocity +0x20 nonzero (clean epilogue ret -> lerp branch).
fix() {  # $1=54 $2=5c $3=68 $4=6c $5=70  $6=x $7=y $8=z  $9=tx ${10}=ty ${11}=tz
  echo "$(poke "$(B 0x54)" "$1");$(poke "$(B 0x5c)" "$2");$(poke "$(B 0x68)" "$3");$(poke "$(B 0x6c)" "$4");$(poke "$(B 0x70)" "$5");$(poke "$(B 0x4)" "$6");$(poke "$(B 0x8)" "$7");$(poke "$(B 0xc)" "$8");$(poke "$(B 0x9c)" "$9");$(poke "$(B 0xa0)" "${10}");$(poke "$(B 0xa4)" "${11}");$(poke "$(B 0x20)" 0x10000)"
}

# SLICE-B field pokes: force the free-flight branch (all timers 0 -> +0x6c==0). pos +0x4/+0x8/+0xc,
# vel +0x20/+0x24/+0x28. $7=held writes byte ball+0x63 (high byte of dword +0x60).
fixb() {  # $1=x $2=y $3=z  $4=vx $5=vy $6=vz  $7=held(0/1)
  local h60=0; [ "${7:-0}" = "1" ] && h60=0x01000000
  echo "$(poke "$(B 0x54)" 0);$(poke "$(B 0x5c)" 0);$(poke "$(B 0x68)" 0);$(poke "$(B 0x6c)" 0);$(poke "$(B 0x70)" 0);$(poke "$(B 0x60)" $h60);$(poke "$(B 0x4)" "$1");$(poke "$(B 0x8)" "$2");$(poke "$(B 0xc)" "$3");$(poke "$(B 0x20)" "$4");$(poke "$(B 0x24)" "$5");$(poke "$(B 0x28)" "$6")"
}

FIX=(
  # --- slice A: lerp / held-guard ---
  "lerp_pos|$(fix 0x1234 3 1 4 5   0x100000 0x200000 0x80000   0x500000 0x600000 0x180000)"
  "lerp_neg|$(fix 0x2 1 0 3 0      0x500000 0x500000 0x100000  0x100000 0x100000 0x0)"
  "lerp_n1|$(fix 0x9 0 0 1 2       0x111111 0x222222 0x33333   0x777777 0x888888 0x99999)"
  "lerp_guard|$(fix 0xabcd 0 0 2 0  0 0 0                      0x80000 -0x80000 0x40000)"
  # --- slice B: integration + gravity + bounce + roll ---
  # airborne (post-int pos.z>0) -> gravity vel.z += -178; vel.x/vel.y unchanged.
  "fb_gravity|$(fixb 0x10000 0x20000 0x40000   0x1000 -0x2000 0x3000   0)"
  # post-int pos.z<0 -> bounce: pos.z=0, vx,vy *=0xc51e, vz = -mul16(vz,0x9c28) (|vz| stays > 0x28f).
  "fb_bounce|$(fixb 0x5000 0x6000 0x1000       0x8000 -0x4000 -0x9000  0)"
  # bounce with small vz -> after damping |vz| < 0x28f -> settle vz=0.
  "fb_settle|$(fixb 0x4000 0x4000 0x100        0x100 0x100 -0x200      0)"
  # grounded (post-int pos.z==0 && vel.z==0), both |vx|,|vy| < 0x22 -> full stop.
  "fb_rollstop|$(fixb 0x3000 0x3000 0          0x10 -0x20 0           0)"
  # grounded roll, |vx| >= 0x22 -> vel -= polar_vec(0x22, atan(vx,vy)) (real LUT).
  "fb_rollfric|$(fixb 0x3000 0x3000 0          0x800 0x400 0          0)"
  # held (byte ball+0x63 set) -> tail only, pos/vel unchanged.
  "fb_held|$(fixb 0x1000 0x2000 0x3000         0x100 0x200 0x300      1)"
)

: > "$OUT"
echo "# Stage 3 task 2 ball ADVANCE (FUN_0058e2c0) PCode-emu ground truth. SLICE A (timers + lerp)" >> "$OUT"
echo "# + SLICE B (free-flight: pos+=vel, gravity [0,0,-178], ground bounce/settle, roll-stop/friction)." >> "$OUT"
echo "# Collision gates clear (match zeroed); spin/tail run but never write pos/vel. cos/atan LUT + _ftol." >> "$OUT"
echo "# Each row: FIX <name> + verbatim CALL line. Reads: pos +0x4/+0x8/+0xc, vel +0x20/+0x24/+0x28," >> "$OUT"
echo "# step +0x6c, timers +0x58/+0x5c/+0x68/+0x70." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  x=$(echo "$LINE" | grep -oE "mem\[$(B 0x4):4\]=[0-9-]+")  vz=$(echo "$LINE" | grep -oE "mem\[$(B 0x28):4\]=[0-9-]+")"
done
echo "=== ball-advance oracle -> $OUT ==="
cat "$OUT"
