#!/usr/bin/env bash
# Stage 3 task 2 (ball collision box leaves): drive the REAL FUN_00590b10 (vec3 += scalar) and
# FUN_00590b30 (strict AABB overlap) through the Ghidra PCode emulator and bank their effect/return.
# Ground truth for Pm98Movement.box_add3 / boxes_overlap (app/tests/test_collbox.gd). Both are leaves
# of the goal/post collision loop in FUN_0058e2c0 (the next unported ball-physics slice).
#
#   FUN_00590b10(__thiscall v3; s): v3[0..2] += s (3 int32). read_mem v3.
#   FUN_00590b30(__thiscall A; B): 1 iff per axis max(A.min,B.min) < min(A.max,B.max); each box is
#     [minx,miny,minz,maxx,maxy,maxz]. EAX = return. Pure integer; no RNG/LUT/ftol/sub-calls.
#
# Memory map: A / v3 @0x230000 (6 int32), B @0x230020 (6 int32).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/collbox_oracle.txt
SPEC=$SPECDIR/_collbox_run.spec
ROUT=$SPECDIR/_collbox_run.out

emit_spec() {
  # $1 entry, $2 ECX(this), $3 args(space-sep), $4 pokes(';'->nl), $5 reads(space-sep "addr")
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $2
zero    0x00230000 0x00002000
EOF
    for a in $3; do printf 'arg 0x%08x\n' $(( a & 0xffffffff )); done
    printf '%s\n' "${4//;/$'\n'}"
    for r in $5; do echo "read_mem $r 4"; done
    echo "maxsteps 100000"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name $2 entry $3 ecx $4 args $5 pokes $6 reads
  emit_spec "$2" "$3" "$4" "$5" "$6"
  local line="" try
  for try in 1 2 3 4 5; do                # Ghidra headless occasionally yields empty ROUT; retry.
    run_emu
    line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
    [ -n "$line" ] && break
  done
  [ -n "$line" ] || { echo "ERROR: $1 produced no CALL line after 5 tries" >&2; exit 1; }
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9-]+( mem\[.*)?' || true)"
}

V3() { echo "$(poke 0x230000 $1);$(poke 0x230004 $2);$(poke 0x230008 $3)"; }          # v3/A.min @0x230000
A() { echo "$(poke 0x230000 $1);$(poke 0x230004 $2);$(poke 0x230008 $3);$(poke 0x23000c $4);$(poke 0x230010 $5);$(poke 0x230014 $6)"; }
B() { echo "$(poke 0x230020 $1);$(poke 0x230024 $2);$(poke 0x230028 $3);$(poke 0x23002c $4);$(poke 0x230030 $5);$(poke 0x230034 $6)"; }
V3_READS="0x00230000 0x00230004 0x00230008"
OV_READS=""                                          # 590b30: EAX only

: > "$OUT"
echo "# Stage 3 task 2 ball collision box leaves (FUN_00590b10 vec3+=s + FUN_00590b30 AABB overlap)" >> "$OUT"
echo "# PCode-emu ground truth. v3/A@0x230000, B@0x230020. box = [minx,miny,minz,maxx,maxy,maxz]." >> "$OUT"
echo "# 590b10: mem[v3] after += s. 590b30: EAX=1 iff strict overlap on all 3 axes." >> "$OUT"

# ---- FUN_00590b10 (this=v3@0x230000; s) ----
bank b10_pos  0x590b10 0x00230000 "0x10000"   "$(V3 100 200 300)"  "$V3_READS"
bank b10_neg  0x590b10 0x00230000 "-5"         "$(V3 0 0 0)"        "$V3_READS"
bank b10_wrap 0x590b10 0x00230000 "0x40000000" "$(V3 0x50000000 0 -0x40000000)" "$V3_READS"

# ---- FUN_00590b30 (this=A@0x230000; B@0x230020). A fixed = [0,0,0, 0x100,0x100,0x100] ----
AFIX="$(A 0 0 0 0x100 0x100 0x100)"
# overlapping corner -> 1.
bank ov_hit    0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0x50 0x50 0x50 0x150 0x150 0x150)" "$OV_READS"
# x edge touching (lo==hi, strict) -> 0.
bank ov_xedge  0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0x100 0x50 0x50 0x200 0x150 0x150)" "$OV_READS"
# x fully separated -> 0.
bank ov_xsep   0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0x200 0 0 0x300 0x100 0x100)" "$OV_READS"
# y edge touching -> 0.
bank ov_yedge  0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0 0x100 0 0x100 0x200 0x100)" "$OV_READS"
# z edge touching -> 0.
bank ov_zedge  0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0 0 0x100 0x100 0x100 0x200)" "$OV_READS"
# B fully inside A -> 1.
bank ov_inside 0x590b30 0x00230000 "0x230020" "$AFIX;$(B 0x10 0x10 0x10 0x20 0x20 0x20)" "$OV_READS"
# negative mins (signed cmp) -> 1.
bank ov_neg    0x590b30 0x00230000 "0x230020" "$AFIX;$(B -0x50 -0x50 -0x50 0x10 0x10 0x10)" "$OV_READS"

echo "=== collbox oracle -> $OUT ==="
cat "$OUT"
