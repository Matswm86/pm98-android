#!/usr/bin/env bash
# Oracle for FUN_005aa870 (the "arm-2 active tail", slice 2b-iv). Drives the REAL function from its own
# entry 0x5aa870 (ECX = player p, the char param_2 passed as a cdecl stack `arg`). The function builds a
# locomotion / pass target from a velocity blend (8*p.vel + p.pos) and an RNG-jittered heading toward the
# OPPONENT goal (FUN_005a44f0), writing p+0xa0/a4/a8 (reach), p+0x94/98/9c (loco), p+0x66 (heading),
# p+0x80/84/48/5e and set_position_code(0x24 off-pitch / 5 on-pitch); for param_2 == 0 it ALSO writes the
# ball chase target ball+0x68/6c/9c/a0/a4. GROUND TRUTH for Pm98Movement._arm2_active_tail
# (app/tests/test_arm2tail.gd).
#
# Leaf calls run for real: FUN_00590aa0 (vec3 store), FUN_005a44f0 (goal_target_x), FUN_005aac00
# (atan(vec-pos)-facing), FUN_005a5430 (set_position_code, reads the static POS_REMAP_LUT), FUN_005ee0f0
# (polar) + FUN_005ee080 (atan) via the cos/atan LUT + the _ftol round-to-zero thunk, and FUN_005ec250
# (rand) off DAT_006d3184. Two RNG draws per non-early-return run, in order: heading jitter then the z
# override.
#
# MEM MAP: p @0x230000 (ECX). p+0x190=ball @0x280000, p+0x18c=m @0x2a0000, p+0x188=teamstruct @0x2b0000,
# *(teamstruct+0)=ctx @0x2c0000 (ctx+0x2b8 team / +0x2c4 slot -> sVar11 = p[0xb8 + (slot+team*11)*2]).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/arm2tail_oracle.txt
SPEC=$SPECDIR/_arm2tail_run.spec
ROUT=$SPECDIR/_arm2tail_run.out
LUT=$SPECDIR/_arm2tail_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

# _ftol thunk (round-to-zero) for the atan/polar x87 path; same bytes as the 7260 oracles.
THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring shared by every fixture. p+0x190=ball, p+0x18c=m, p+0x188=teamstruct, teamstruct+0=ctx,
# m goal anchors (m+0x1820 X, m+0x19a0 orient, m+0x448 play-state). RNG seed DAT_006d3184. ctx slot/team 0.
CONST="$(poke 0x230190 0x280000);$(poke 0x23018c 0x2a0000);$(poke 0x230188 0x2b0000)
$(poke 0x2b0000 0x2c0000);$(poke 0x2c02b8 0);$(poke 0x2c02c4 0)
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 0);$(poke 0x2a0448 0)
$(poke 0x6d3184 0x4d2);$(poke 0x6d31c4 0)"

# Read back every mutation (signed LE; bytes where noted).
READS="read_mem 0x00230048 4
read_mem 0x00230040 4
read_mem 0x002300a0 4
read_mem 0x002300a4 4
read_mem 0x002300a8 4
read_mem 0x0023005e 1
read_mem 0x00230080 4
read_mem 0x00230084 4
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x00230066 2
read_mem 0x00280068 4
read_mem 0x0028006c 4
read_mem 0x0028009c 4
read_mem 0x002800a0 4
read_mem 0x002800a4 4
read_mem 0x006d3184 4"

# name|istack|extra-pokes.  p+0x40 action 0x1e (reaches the body); p.pos/facing/vel + ball.vel/pos set per
# fixture.  s1*: istack 1 (carrier bypassed, ball UNwritten).  s0: istack 0 + ball+0x40=p (carrier ok ->
# ball written).  s0nc: istack 0 + carrier != p (early return).  act13: action 0x13 (immediate return).
# m448: m+0x448 == 4 (sv4 forced 0 -> heading == facing).  sv11hi: large p[0xb8] flips the delta branch.
FIX=(
  "s1|0x1|$(poke 0x230040 0x1e);$(poke 0x2302b8 0);$(poke 0x230034 0x1000);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);$(poke 0x2303a0 50);$(poke 0x2302bc 1);$(poke 0x280020 0x6000);$(poke 0x280024 0x1000);$(poke 0x280028 -0x400)"
  "s1pos|0x1|$(poke 0x230040 0x1e);$(poke 0x2302b8 1);$(poke 0x230004 0x80000);$(poke 0x230008 -0x40000);$(poke 0x23000c 0x2000);$(poke 0x230034 0x3000);$(poke 0x230020 -0x3000);$(poke 0x230024 0x5000);$(poke 0x230028 0);$(poke 0x2303a0 70);$(poke 0x2302bc 0);$(poke 0x280020 0x2000);$(poke 0x280024 -0x6000);$(poke 0x280028 0x1000)"
  "s0|0x0|$(poke 0x230040 0x1e);$(poke 0x280040 0x230000);$(poke 0x2302b8 0);$(poke 0x230034 0x800);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);$(poke 0x2303a0 40);$(poke 0x2302bc 1);$(poke 0x280004 0x10000);$(poke 0x280008 0x8000);$(poke 0x28000c -0x2000);$(poke 0x280020 0x6000);$(poke 0x280024 0x1000);$(poke 0x280028 -0x400)"
  "s0nc|0x0|$(poke 0x230040 0x1e);$(poke 0x280040 0x999999);$(poke 0x2302b8 0);$(poke 0x230020 0x4000)"
  "act13|0x1|$(poke 0x230040 0x13);$(poke 0x230020 0x4000)"
  "m448|0x1|$(poke 0x230040 0x1e);$(poke 0x2302b8 0);$(poke 0x2a0448 4);$(poke 0x230034 0x1800);$(poke 0x230020 0x3000);$(poke 0x230024 0x2000);$(poke 0x230028 -0x800);$(poke 0x2303a0 60);$(poke 0x2302bc 1);$(poke 0x280020 0x4000);$(poke 0x280024 -0x3000);$(poke 0x280028 0x200)"
  "sv11neg|0x1|$(poke 0x230040 0x1e);$(poke 0x2302b8 0);$(poke2 0x2300b8 0x9000);$(poke 0x230034 0x1000);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);$(poke 0x2303a0 50);$(poke 0x2302bc 1);$(poke 0x280020 0x6000);$(poke 0x280024 0x1000);$(poke 0x280028 -0x400)"
)

emit_spec() {  # $1=istack  $2=extra-pokes
  {
    cat <<EOF
entry   0x005aa870
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
arg     $1
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
zero    0x002b0000 0x00001000
zero    0x002c0000 0x00001000
maxsteps 4000000
stub    0x00605ff0 0 0 atexit
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${2//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005aa870 (arm-2 active tail, slice 2b-iv). Field mutations read back at the function RET." >> "$OUT"
echo "# Row: ARM2 <name> istack=<0|1> | <abs-addr>=<signed LE> ... . p=0x230000 ball=0x280000 m=0x2a0000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ISTACK POKES <<<"$row"
  emit_spec "$ISTACK" "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  echo "ARM2 $NAME istack=$ISTACK | $KV" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== arm-2 active-tail oracle -> $OUT ==="
cat "$OUT"
