#!/usr/bin/env bash
# Leaf oracle for FUN_005b0bb0 (__thiscall, RET 0x10): the AI "is teammate X a valid pass/lay-off
# target" test. Drives the REAL function under the Ghidra PCode emulator and banks its outcome:
#   EAX (return bool = BL), match+0x43c (pass-receiver = player on hit), match+0x460 (set-piece
#   cooldown byte 0x5a/0x3c/0x1e/0xf by distance tier).
#
# this(ECX)=player; 4 stack args = (param_2 = candidate target vec3 ptr, param_3 = pass angle,
# param_4 = scale, param_5 = dist threshold). The corrected `this` is the PLAYER BASE (Ghidra's
# FUN_005ab5a0 decompile mis-renders the call as piVar1=player+4; the body uses [EDI+4]/[EDI+0x3a4]/
# [EDI+0x190]/[EDI+0x18c] = player offsets, confirmed by objdump _passtest_5b0bb0.asm).
#
# Only FUN_005b0b40 (teammate count) is STUBBED (fixture-controlled retval). All geometry leaves run
# REAL: FUN_00590aa0/590ae0 (vec set/sub), FUN_005ee080 (atan), FUN_005ee0f0 (polar), FUN_005ee500
# (dot16), FUN_005ee540 (cross16), and the FP magnitude (FILD/FSQRT + _ftol via the 0x6233a4 thunk,
# redirected to the hand-coded ftol at 0x252000 as in run_balladvance_oracle.sh). Trig LUT injected.
#
# Memory: player @0x230000 (ECX), match @0x260000 (P+0x18c), ball @0x270000 (P+0x190), tgt @0x2a0000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/passtest_oracle.txt
SPEC=$SPECDIR/_passtest_run.spec
ROUT=$SPECDIR/_passtest_run.out
LUT=$SPECDIR/_passtest_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball. (P+0x184 gs unused by this leaf.)
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000)"
# _ftol thunk: redirect 0x6233a4 -> hand-coded round-to-zero ftol at 0x252000 (from balladvance).
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# name|count|angle|scale|dist|pokes  (count = FUN_005b0b40 stub retval; angle/scale/dist = cdecl args)
FIX=(
  # owner: ball.owner==player -> immediate true. px-tgt0 = 0x200000 > 0x1e0000 -> cooldown 0x5a.
  "owner|0|0|0|0x7fffffff|$(poke 0x27004c 0x230000);$(poke 0x230004 0x200000)"
  # toomany: stub count=2 (>=2) -> early false, no writes.
  "toomany|2|0|0|0x7fffffff|$(poke 0x230004 0x100000)"
  # farself: |px+anchor| = 0x200000 >= dist 0x100000 -> false.
  "farself|0|0|0|0x100000|$(poke 0x230004 0x200000)"
  # facing_reject: not owned, +0x68>0x776, |atan(goal)-facing|>0x4e39 -> false (runs 590aa0/590ae0/5ee080).
  "facereject|0|0|0|0x7fffffff|$(poke 0x230068 0x800);$(poke 0x2602b8 0);$(poke 0x261820 0x300000);$(poke 0x230034 0x6000)"
  # prox_fail: not owned, +0x68<0x777 (skip facing), tgt far -> AABB miss -> false (runs polar_vec).
  "proxfail|0|0|0x80000|0x7fffffff|$(poke 0x27004c 0);$(poke 0x2a0000 0x300000)"
  # prox_pass_true: tgt == player.pos -> D=0, perp=0 <= thr_base -> true. px-tgt0=0 -> cooldown 0xf.
  "proxtrue|0|0|0x80000|0x7fffffff|$(poke 0x230004 0x100000);$(poke 0x2a0000 0x100000)"
  # prox_pass_false: tgt offset in y by 0x60000 -> perp 0x60000 > thr_base 0x30000 -> false (FP branch).
  "proxfalse|0|0|0x80000|0x7fffffff|$(poke 0x230004 0x100000);$(poke 0x2a0000 0x100000);$(poke 0x2a0004 0x60000)"
)

emit_spec() {  # $1=count $2=angle $3=scale $4=dist $5=pokes
  {
    cat <<EOF
entry   0x005b0bb0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x002a0000 0x00000100
maxsteps 400000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    echo "stub 0x5b0b40 $1 4 B0B40"
    echo "arg 0x2a0000"
    echo "arg $2"
    echo "arg $3"
    echo "arg $4"
    printf '%s\n' "${5//;/$'\n'}"
    printf '%s\n' "${PTRS//;/$'\n'}"
    echo "read_mem 0x0026043c 4"
    echo "read_mem 0x00260460 1"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Leaf oracle FUN_005b0bb0 (pass-target test). this=player; args (tgt@0x2a0000, angle, scale, dist)." >> "$OUT"
echo "# Row: PT <name> EAX=<ret> 43c=<receiver> 460=<cooldown>. FUN_005b0b40 stubbed (count); rest real." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME CNT ANG SCL DST POKES <<<"$row"
  emit_spec "$CNT" "$ANG" "$SCL" "$DST" "$POKES"
  run_emu
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  EAX=$(echo "$RET" | grep -oE 'EAX=[0-9-]+' | head -1)
  M43C=$(echo "$RET" | grep -oE 'mem\[0x26043c:4\]=[0-9-]+')
  M460=$(echo "$RET" | grep -oE 'mem\[0x260460:1\]=[0-9-]+')
  STEPS=$(echo "$RET" | grep -oE '(RET|HALT) steps=[0-9]+')
  echo "PT $NAME $STEPS $EAX $M43C $M460" >> "$OUT"
done
echo "=== passtest oracle -> $OUT ==="
cat "$OUT"
