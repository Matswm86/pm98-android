#!/usr/bin/env bash
# Stage 3 task 2 (movement leaves): drive the FIVE small geometry primitives through the
# Ghidra PCode emulator and bank the output vec3 each writes. Ground truth that Pm98Trig's
# vec3_store / vec3_sub / vec3_scale_ratio / clamp_min_sep / mid_offset must reproduce
# bit-for-bit (app/tests/test_trig_lut.gd::_test_moveleaves).
#
#   FUN_00590aa0  vec3_store(this=dest, x, y, z)                 -- 3 dword stores, ret 0xc
#   FUN_00590ae0  vec3_sub(this=a, dest, b)  -> dest = a - b      -- ret 0x8
#   FUN_005ee290  vec3_scale_ratio(this=v, mult, div) -> v*=mult/div (64-bit imul; idiv) ret 0x8
#   FUN_005ee2d0  clamp_min_sep(this=p1, p2, box) -> push p1 to >= box from p2  -- ret 0x8
#   FUN_005ee3f0  mid_offset(this=p1, p2, box, p4) -> p1 = p4 + mid(p1, p2)     -- ret 0xc
#
# 5ee2d0/5ee3f0 use ftol(sqrt(.)) so the faithful truncate-toward-zero _ftol is injected at
# 0x252000 and the IAT thunk 0x6233a4 repointed to it (FUN_00605fb0 = `jmp [0x6233a4]`).
# 5ee2d0's dist==0 branch calls polar_vec (FUN_005ee0f0), which reads the cos LUT @0x6d31c8 --
# the cos+atan LUTs are injected for ALL fixtures (harmless), same trick as the planarmag/
# movement oracles. Distances are kept to perfect squares so ftol truncation is exact.
#
# Memory map (all in the zeroed data window 0x200000..0x201000):
#   VA @0x200000  VB @0x200010  VC @0x200020  V4 @0x200030   (each a 3xint32 vec3)
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/moveleaf_oracle.txt
SPEC=$SPECDIR/_moveleaf_run.spec
ROUT=$SPECDIR/_moveleaf_run.out
LUT=$SPECDIR/_moveleaf_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

VA=0x00200000; VB=0x00200010; VC=0x00200020; V4=0x00200030

# LE-int32 poke of a possibly-negative decimal -> a `mem` directive line.
poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }
# `arg` directive carrying a possibly-negative decimal (or a hex address verbatim).
argline() { printf 'arg 0x%08x' $(( $1 & 0xffffffff )); }

# emit_spec ENTRY ECX "argdec argdec ..." "POKE_LINES" "RADDR RADDR RADDR"
emit_spec() {
  local entry=$1 ecx=$2 args=$3 pokes=$4 reads=$5
  {
    echo "entry   $entry"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $ecx"
    echo "zero    0x00200000 0x00001000"
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "mem 0x006233a4 4 0x00252000"
    echo "maxsteps 2000000"
    cat "$LUT"
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

# emit a `FIX <name> fn=<tag> in=<csv> out=<o0,o1,o2>` row from the emulator read_mem trio.
bank() {
  local name=$1 fn=$2 incsv=$3 r0=$4 r1=$5 r2=$6
  local line o0 o1 o2
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  o0=$(echo "$line" | grep -oE "mem\[$r0:4\]=[0-9-]+" | head -1 | cut -d= -f2)
  o1=$(echo "$line" | grep -oE "mem\[$r1:4\]=[0-9-]+" | head -1 | cut -d= -f2)
  o2=$(echo "$line" | grep -oE "mem\[$r2:4\]=[0-9-]+" | head -1 | cut -d= -f2)
  echo "FIX $name fn=$fn in=$incsv out=$o0,$o1,$o2" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT)') -> $o0,$o1,$o2"
}

: > "$OUT"
echo "# Stage 3 task 2 movement leaves (FUN_00590aa0/590ae0/5ee290/5ee2d0/5ee3f0) PCode-emu" >> "$OUT"
echo "# ground truth. Row: FIX <name> fn=<addr> in=<input ints, csv> out=<3 output int32s>." >> "$OUT"
echo "# faithful _ftol @0x252000 + cos/atan LUT injected; outputs read back as signed LE u32." >> "$OUT"

# ---- FUN_00590aa0  vec3_store(dest=VC, x, y, z) -------------------------------------
emit_spec 0x00590aa0 "$VC" "65536 131072 -196608" "" "0x00200020 0x00200024 0x00200028"
run_emu; bank store_basic 590aa0 "65536,131072,-196608" 0x200020 0x200024 0x200028

# ---- FUN_00590ae0  vec3_sub(a=VA, dest=VC, b=VB) -> VC = VA - VB ---------------------
POK="$(poke 0x200000 327680)
$(poke 0x200004 196608)
$(poke 0x200008 -65536)
$(poke 0x200010 131072)
$(poke 0x200014 262144)
$(poke 0x200018 65536)"
emit_spec 0x00590ae0 "$VA" "$VC $VB" "$POK" "0x00200020 0x00200024 0x00200028"
run_emu; bank sub_basic 590ae0 "327680,196608,-65536,131072,262144,65536" 0x200020 0x200024 0x200028

# ---- FUN_005ee290  vec3_scale_ratio(v=VC, mult, div) -> v *= mult/div ----------------
# even halve
POK="$(poke 0x200020 262144)
$(poke 0x200024 -196608)
$(poke 0x200028 131072)"
emit_spec 0x005ee290 "$VC" "1 2" "$POK" "0x00200020 0x00200024 0x00200028"
run_emu; bank scale_half 5ee290 "262144,-196608,131072,1,2" 0x200020 0x200024 0x200028
# negative-odd: exercises trunc-toward-zero (not floor)
POK="$(poke 0x200020 7)
$(poke 0x200024 -7)
$(poke 0x200028 0)"
emit_spec 0x005ee290 "$VC" "1 2" "$POK" "0x00200020 0x00200024 0x00200028"
run_emu; bank scale_negodd 5ee290 "7,-7,0,1,2" 0x200020 0x200024 0x200028
# ratio 5/3 with a negative component
POK="$(poke 0x200020 196608)
$(poke 0x200024 -262144)
$(poke 0x200028 65536)"
emit_spec 0x005ee290 "$VC" "5 3" "$POK" "0x00200020 0x00200024 0x00200028"
run_emu; bank scale_ratio53 5ee290 "196608,-262144,65536,5,3" 0x200020 0x200024 0x200028

# ---- FUN_005ee2d0  clamp_min_sep(p1=VA, p2=VB, box) ---------------------------------
# inside + dist<box -> push out (3-4-5 delta, dist=0x50000)
POK="$(poke 0x200000 196608)
$(poke 0x200004 262144)
$(poke 0x200008 0)
$(poke 0x200010 0)
$(poke 0x200014 0)
$(poke 0x200018 0)"
emit_spec 0x005ee2d0 "$VA" "$VB 393216" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank clamp_move 5ee2d0 "196608,262144,0,0,0,0,393216" 0x200000 0x200004 0x200008
# box test fails (|dx|>=box) -> unchanged
POK="$(poke 0x200000 196608)
$(poke 0x200004 0)
$(poke 0x200008 0)
$(poke 0x200010 0)
$(poke 0x200014 0)
$(poke 0x200018 0)"
emit_spec 0x005ee2d0 "$VA" "$VB 131072" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank clamp_nobox 5ee2d0 "196608,0,0,0,0,0,131072" 0x200000 0x200004 0x200008
# box passes but dist>=box -> unchanged (dist=0x50000, box=0x45000)
POK="$(poke 0x200000 196608)
$(poke 0x200004 262144)
$(poke 0x200008 0)
$(poke 0x200010 0)
$(poke 0x200014 0)
$(poke 0x200018 0)"
emit_spec 0x005ee2d0 "$VA" "$VB 282624" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank clamp_nodist 5ee2d0 "196608,262144,0,0,0,0,282624" 0x200000 0x200004 0x200008
# coincident (dist==0) -> polar_vec(box,0) offset (exercises the cos LUT branch)
POK="$(poke 0x200000 65536)
$(poke 0x200004 65536)
$(poke 0x200008 0)
$(poke 0x200010 65536)
$(poke 0x200014 65536)
$(poke 0x200018 0)"
emit_spec 0x005ee2d0 "$VA" "$VB 65536" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank clamp_coincide 5ee2d0 "65536,65536,0,65536,65536,0,65536" 0x200000 0x200004 0x200008

# ---- FUN_005ee3f0  mid_offset(p1=VA, p2=VB, box, p4=V4) ------------------------------
# inside + dist<box -> p4 + midpoint
POK="$(poke 0x200000 196608)
$(poke 0x200004 262144)
$(poke 0x200008 0)
$(poke 0x200010 0)
$(poke 0x200014 0)
$(poke 0x200018 0)
$(poke 0x200030 1048576)
$(poke 0x200034 1048576)
$(poke 0x200038 0)"
emit_spec 0x005ee3f0 "$VA" "$VB 393216 $V4" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank mid_basic 5ee3f0 "196608,262144,0,0,0,0,393216,1048576,1048576,0" 0x200000 0x200004 0x200008
# negative-odd delta -> trunc-toward-zero /2 (dx=-3, dist=3)
POK="$(poke 0x200000 5)
$(poke 0x200004 0)
$(poke 0x200008 0)
$(poke 0x200010 8)
$(poke 0x200014 0)
$(poke 0x200018 0)
$(poke 0x200030 0)
$(poke 0x200034 0)
$(poke 0x200038 0)"
emit_spec 0x005ee3f0 "$VA" "$VB 65536 $V4" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank mid_negodd 5ee3f0 "5,0,0,8,0,0,65536,0,0,0" 0x200000 0x200004 0x200008
# box test fails -> unchanged
POK="$(poke 0x200000 524288)
$(poke 0x200004 0)
$(poke 0x200008 0)
$(poke 0x200010 0)
$(poke 0x200014 0)
$(poke 0x200018 0)
$(poke 0x200030 0)
$(poke 0x200034 0)
$(poke 0x200038 0)"
emit_spec 0x005ee3f0 "$VA" "$VB 131072 $V4" "$POK" "0x00200000 0x00200004 0x00200008"
run_emu; bank mid_nobox 5ee3f0 "524288,0,0,0,0,0,131072,0,0,0" 0x200000 0x200004 0x200008

echo "=== moveleaf oracle -> $OUT ==="
cat "$OUT"
