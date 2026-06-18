#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE helpers): drive the per-team-side coordinate primitives the
# per-player DECIDE FUN_005a3400 (and the positioning fn FUN_005b73a0) call, and bank
# their output. Ground truth that Pm98Movement.goal_target_x / mirror_to_side / vec_compose
# must reproduce bit-for-bit (app/tests/test_decidehelper.gd). Pure integer -- no LUT, no ftol.
#
#   FUN_005a44f0  goal_target_x(__thiscall match; team)  -> EAX = +-match[0x1820]   ret 0x4
#   FUN_005a4510  mirror_to_side(__thiscall match; out, team, in) -> out = mirror(in)  ret 0xc
#   FUN_005b11f0  vec_compose(__thiscall out; in2d, z)   -> out = [in2d.x, in2d.y, z]  ret 0x8
#
# Memory: match struct @0x210000 (so +0x1820 -> 0x211820, +0x19a0 -> 0x2119a0); vecs in the
# 0x200000 window (IN @0x200000, OUT @0x200020). Zero region spans both (0x200000 + 0x12000).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decidehelper_oracle.txt
SPEC=$SPECDIR/_decidehelper_run.spec
ROUT=$SPECDIR/_decidehelper_run.out

M=0x00210000; IN=0x00200000; OUT_V=0x00200020

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }
argline() { printf 'arg 0x%08x' $(( $1 & 0xffffffff )); }

# emit_spec ENTRY ECX "argdec ..." "POKE_LINES" "RADDR ..."
emit_spec() {
  local entry=$1 ecx=$2 args=$3 pokes=$4 reads=$5
  {
    echo "entry   $entry"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $ecx"
    echo "zero    0x00200000 0x00012000"
    echo "maxsteps 200000"
    [ -n "$pokes" ] && printf '%s\n' "$pokes"
    for a in $args; do argline "$a"; echo; done
    for r in $reads; do echo "read_mem $r 4"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# bank a scalar (EAX) result row
bank_scalar() {
  local name=$1 fn=$2 incsv=$3 line eax
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  eax=$(echo "$line" | grep -oE 'EAX=[0-9-]+' | head -1 | cut -d= -f2)
  echo "FIX $name fn=$fn in=$incsv out=$eax" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT)') EAX=$eax"
}

# bank a vec3 (3x read_mem at OUT_V) result row
bank_vec() {
  local name=$1 fn=$2 incsv=$3 line o0 o1 o2
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  o0=$(echo "$line" | grep -oE "mem\[0x200020:4\]=[0-9-]+" | cut -d= -f2)
  o1=$(echo "$line" | grep -oE "mem\[0x200024:4\]=[0-9-]+" | cut -d= -f2)
  o2=$(echo "$line" | grep -oE "mem\[0x200028:4\]=[0-9-]+" | cut -d= -f2)
  echo "FIX $name fn=$fn in=$incsv out=$o0,$o1,$o2" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT)') -> $o0,$o1,$o2"
}

: > "$OUT"
echo "# Stage 3 task 2 DECIDE helpers (FUN_005a44f0/5a4510/5b11f0) PCode-emu ground truth." >> "$OUT"
echo "# Row: FIX <name> fn=<addr> in=<input ints, csv> out=<scalar | 3-int vec>. signed LE." >> "$OUT"

# ---- FUN_005a44f0 goal_target_x(match; team): in = orient19a0, x1820, team ; out = EAX ----
emit_spec 0x005a44f0 "$M" "1"   "$(poke 0x2119a0 1)
$(poke 0x211820 1081344)" ""
run_emu; bank_scalar gt_eq   5a44f0 "1,1081344,1"      # (1&1)==1 -> neg
emit_spec 0x005a44f0 "$M" "1"   "$(poke 0x2119a0 0)
$(poke 0x211820 1081344)" ""
run_emu; bank_scalar gt_ne   5a44f0 "0,1081344,1"      # 0 != 1 -> keep
emit_spec 0x005a44f0 "$M" "0"   "$(poke 0x2119a0 0)
$(poke 0x211820 524288)" ""
run_emu; bank_scalar gt_eq0  5a44f0 "0,524288,0"       # 0==0 -> neg

# ---- FUN_005a4510 mirror_to_side(match; out, team, in): in = orient19a0, team, vx,vy,vz ----
emit_spec 0x005a4510 "$M" "$OUT_V 0 $IN"   "$(poke 0x2119a0 1)
$(poke 0x200000 196608)
$(poke 0x200004 -262144)
$(poke 0x200008 65536)" "0x00200020 0x00200024 0x00200028"
run_emu; bank_vec mir_flip   5a4510 "1,0,196608,-262144,65536"    # bit=1^0=1 -> flip x,y
emit_spec 0x005a4510 "$M" "$OUT_V 1 $IN"   "$(poke 0x2119a0 1)
$(poke 0x200000 196608)
$(poke 0x200004 -262144)
$(poke 0x200008 65536)" "0x00200020 0x00200024 0x00200028"
run_emu; bank_vec mir_noflip 5a4510 "1,1,196608,-262144,65536"    # bit=1^1=0 -> keep

# ---- FUN_005b11f0 vec_compose(out; in2d, z): in = a0, a1, z ; out = [a0, a1, z] ----
emit_spec 0x005b11f0 "$OUT_V" "$IN 458752"   "$(poke 0x200000 327680)
$(poke 0x200004 -131072)
$(poke 0x200008 99999)" "0x00200020 0x00200024 0x00200028"
run_emu; bank_vec compose    5b11f0 "327680,-131072,458752"       # z=0x70000; in2d[2]=99999 ignored

echo "=== decidehelper oracle -> $OUT ==="
cat "$OUT"
