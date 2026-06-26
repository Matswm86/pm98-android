#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE A -- the ACTIVE-CARRIER branch (decompile L55-120, param_1 == ball+0x40).
# Drives the REAL function from its own entry 0x5a9490 (__fastcall ECX = player p). Slice A fires only when
# p IS the ball's active carrier; it aims the carried ball ahead of the player's facing and either:
#   * (chase) far ahead (|rot.x - 0x4ccc| > 0x10000) + action not 8/9 + p+0x2bc != 0 -> FUN_0058ed50
#     RELEASES the ball (ball+0x40 -> 0) and returns;
#   * (anim)  p+0x68 != 0 -> return (ball-anim already running);
#   * (near)  |rot.x - 0x4ccc| < 0x6667 -> return (too close, no push);
#   * (slow)  ball planar speed (FUN_005edfb0) < 0x8001 -> rewrite ball.pos (+4/+8/+0xc);
#   * (fast)  else -> zero ball.vel, start ball-anim (+0x68=1, +0x6c, +0x9c/a0/a4 target),
#             and if p+0x2bc != 0 FUN_005a5430(0xb) (set_position_code) on the player.
# GROUND TRUTH for Pm98Movement.lean_9490 (app/tests/test_9490.gd).
#
# Leaves run for real: FUN_005ee670 (rotate), FUN_005ee080 (atan), FUN_00436fb0+FUN_005edfb0 (planar
# speed), FUN_005ee0f0 (polar), FUN_005ee1c0 (scale), FUN_005a1700 (vec add), FUN_005ee290 (scale-ratio),
# FUN_00590ae0 (vec sub), FUN_0058ed50 (ball release), FUN_005a5430 (set_position_code, POS_REMAP_LUT).
# rng-free (Slice A draws 0 RNG). Facing = 0 in every fixture so the -facing rotate is identity and
# |rot.x - 0x4ccc| == ball.x - p.x - 0x4ccc is directly controllable.
#
# MEM MAP: p @0x230000 (ECX). p+0x190=ball @0x280000, p+0x18c=m @0x2a0000, p+0x184=gs @0x250000,
# p+0x188=teamstruct @0x2b0000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceA_oracle.txt
SPEC=$SPECDIR/_9490sliceA_run.spec
ROUT=$SPECDIR/_9490sliceA_run.out
LUT=$SPECDIR/_9490sliceA_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

# _ftol thunk (round-to-zero); Slice A draws no sqrt but keep it mapped (harmless, matches template).
THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring: p+0x190=ball, p+0x18c=m, p+0x184=gs, p+0x188=teamstruct. m anchors zeroed.
CONST="$(poke 0x230190 0x280000);$(poke 0x23018c 0x2a0000);$(poke 0x230184 0x250000);$(poke 0x230188 0x2b0000)
$(poke 0x6d31c4 0)"

# Read back every Slice-A mutation candidate (signed LE; bytes where noted).
READS="read_mem 0x00230040 4
read_mem 0x0023002c 4
read_mem 0x00230030 4
read_mem 0x00280004 4
read_mem 0x00280008 4
read_mem 0x0028000c 4
read_mem 0x00280020 4
read_mem 0x00280024 4
read_mem 0x00280028 4
read_mem 0x00280040 4
read_mem 0x00280068 4
read_mem 0x0028006c 4
read_mem 0x0028009c 4
read_mem 0x002800a0 4
read_mem 0x002800a4 4"

# name|extra-pokes.  Every fixture: carrier (ball+0x40 = p), facing 0.  Controlled forward distance via
# ball.x - p.x; ball.y/z = p.y/z so the rotate plane keeps rot.y/z = 0.
#   chase    : dist 0x20000 (>0x10000), action 0, p+0x2bc=1     -> ball release (ball+0x40 -> 0)
#   anim     : dist 0x8000 (<=0x10000 skip chase), p+0x68=1     -> return, no writes
#   near     : dist 0x2000 (<0x6667), p+0x68=0                  -> return, no writes
#   slow1/2/3: dist 0x8000, small ball.vel (speed<0x8001)       -> ball.pos rewrite (3 input variants)
#   fast     : dist 0x8000, big ball.vel, p+0x2bc=1             -> ball.vel=0 + anim + a5430(0xb)
#   fast_n2bc: dist 0x8000, big ball.vel, p+0x2bc=0             -> ball.vel=0 + anim, NO a5430
FIX=(
  "chase|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0x24ccc);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0);$(poke 0x280024 0);$(poke 0x280028 0)"
  "anim|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke2 0x230034 0);$(poke 0x230068 1);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0);$(poke 0x28000c 0)"
  "near|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0x6ccc);$(poke 0x280008 0);$(poke 0x28000c 0)"
  "slowA|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "slowB|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0x4000);$(poke 0x28000c 0);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "slowC|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0);$(poke 0x28000c 0x3000);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "slowD|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0x10000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "slowE|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xe000);$(poke 0x280008 0x2000);$(poke 0x28000c 0x1000);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "fast|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x40000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "fast_n2bc|$(poke 0x230040 0);$(poke 0x2302bc 0);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0xcccc);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x40000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "fastP|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0x8000);$(poke 0x230008 0x2000);$(poke 0x23000c 0x400);$(poke2 0x230034 0);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0x14ccc);$(poke 0x280008 0x2000);$(poke 0x28000c 0x400);$(poke 0x280020 0x40000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "fastR|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0x4000);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0);$(poke 0x280008 0x10000);$(poke 0x28000c 0);$(poke 0x280020 0x40000);$(poke 0x280024 0);$(poke 0x280028 0)"
  "slowR|$(poke 0x230040 0);$(poke 0x2302bc 1);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke2 0x230034 0x4000);$(poke 0x230068 0);$(poke 0x280040 0x230000);$(poke 0x280004 0);$(poke 0x280008 0x10000);$(poke 0x28000c 0);$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0)"
)

emit_spec() {  # $1=extra-pokes
  {
    cat <<EOF
entry   0x005a9490
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
zero    0x00250000 0x00001000
zero    0x002b0000 0x00001000
zero    0x00674000 0x00001000
maxsteps 6000000
stub    0x00605ff0 0 0 atexit
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${1//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a9490 Slice A (active-carrier branch, L55-120). Field mutations at the function RET." >> "$OUT"
echo "# Row: A9490 <name> | <abs-addr>=<signed LE> ... . p=0x230000 ball=0x280000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ' || true)
  echo "A9490 $NAME | $KV" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+' || true)"
done
echo "=== 9490 Slice A oracle -> $OUT ==="
cat "$OUT"
