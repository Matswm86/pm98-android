#!/usr/bin/env bash
# Stage 3 (movement leaf "settle"): drive the REAL FUN_005a8680 through the Ghidra PCode emulator and
# bank (a) the leaf-call SELECTION + arg0 sequence and (b) the only two fields 8680 writes itself --
# p+0x5d (windup-edge flag) and p+0x54 (possession-claim clear). GROUND TRUTH that
# Pm98Movement.settle_8680 must reproduce bit-for-bit (app/tests/test_settle.gd).
#
# FUN_005a8680(p) is PURE INTEGER -- all FPU lives in its leaves -- so NO LUT / NO ftol is needed; we
# STUB all seven leaves and read back the `CALL 0 STUB <label> .. arg0=..` trace the emulator emits:
#   B1420 = FUN_005b1420 (off-ball reposition gate)         thiscall, 0 stack args
#   M8F20 = FUN_005a8f20 (steer APPLY; arg0 = heading)       thiscall(heading)        argbytes 4
#   M8AC0 = FUN_005a8ac0 (curve-speed windup; arg0=heading)  thiscall(heading,100)    argbytes 8
#   AA4D0 = FUN_005aa4d0 (kick_setup)                        thiscall, 0 stack args
#   AA870 = FUN_005aa870(0)                                  thiscall(0)              argbytes 4
#   AAFD0 = FUN_005aafd0(1)                                  thiscall(1)              argbytes 4
#   B8CE0 = FUN_005b8ce0(1) (select_nearest; this=gs)        thiscall(1)              argbytes 4
#
# Memory map (zeroed windows): P@0x230000 (ECX) M@0x260000 (P+0x18c) BALL@0x270000 (P+0x190)
# GS@0x280000 (P+0x184) OTHER@0x2a0000 (the BALL+0x4c rival claimant). The set-piece taker is
# M+0x438==P; the ball controller is BALL+0x40==P.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/settle_oracle.txt
SPEC=$SPECDIR/_settle_run.spec
ROUT=$SPECDIR/_settle_run.out

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

STUBS=(
  "0x5b1420 1 0 B1420"     # off-ball reposition (returns bool, discarded)
  "0x5a8f20 0 4 M8F20"     # steer APPLY (arg0 = heading)
  "0x5a8ac0 0 8 M8AC0"     # curve-speed windup (arg0 = heading, arg1 = 100)
  "0x5aa4d0 0 0 AA4D0"     # kick_setup
  "0x5aa870 0 4 AA870"     # controller possession tail, arg 0
  "0x5aafd0 0 4 AAFD0"     # non-controller possession tail, arg 1
  "0x5b8ce0 0 4 B8CE0"     # select_nearest(gs, 1)
)

READS=( "0x0023005d 1" "0x00230054 4" )

emit_spec() {  # $1 = newline-joined pokes
  {
    cat <<EOF
entry   0x005a8680
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00001000
maxsteps 2000000
EOF
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# All fixtures: P+0x18c -> match, P+0x190 -> ball, P+0x184 -> gs.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
TAKER="$(poke 0x260438 0x230000)"     # M+0x438 = P (set-piece taker)
CTRL="$(poke 0x270040 0x230000)"      # BALL+0x40 = P (ball controller)

FIX=(
# --- BRANCH 1: set-piece taker aim snap (action 4 -> clean tail). idx = (p4<0)+((p8>0)+((ph==4)+(ph==7)*2)*2)*2
"b1_p3_i0|$TAKER;$(poke 0x260448 3);$(poke 0x230040 4);$(poke 0x230004 0x10000);$(poke 0x230008 -0x10000);$(poke 0x230034 0x100)"
"b1_p3_i3|$TAKER;$(poke 0x260448 3);$(poke 0x230040 4);$(poke 0x230004 -0x10000);$(poke 0x230008 0x10000);$(poke 0x230034 0x7000)"
"b1_p4_i4|$TAKER;$(poke 0x260448 4);$(poke 0x230040 4);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x230034 0x5000)"
"b1_p4_i7|$TAKER;$(poke 0x260448 4);$(poke 0x230040 4);$(poke 0x230004 -1);$(poke 0x230008 0x10000);$(poke 0x230034 0x9000)"
"b1_p7_i8|$TAKER;$(poke 0x260448 7);$(poke 0x230040 4);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x230034 0x2000)"
"b1_p7_i11|$TAKER;$(poke 0x260448 7);$(poke 0x230040 4);$(poke 0x230004 -1);$(poke 0x230008 1);$(poke 0x230034 0xc000)"
"b1_p5|$TAKER;$(poke 0x260448 5);$(poke 0x230040 4);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x230034 0x3456)"
"b1_gsadj|$TAKER;$(poke 0x260448 3);$(poke 0x230040 4);$(poke 0x230004 0x10000);$(poke 0x230008 -0x10000);$(poke 0x230034 0x100);$(poke 0x280210 1)"
# --- BRANCH 2: open-play action 0..3 in open play (phase 0).
"b2_fall|$(poke 0x230040 2);$(poke 0x260448 0);$(poke 0x230034 0x2222)"
"b2_call8ac0|$(poke 0x230040 1);$(poke 0x260448 0);$(poke 0x230034 0x2222);$(poke 0x280213 1);$(poke 0x26181c 0x2000)"
"b2_skip_action|$(poke 0x230040 5);$(poke 0x260448 0);$(poke 0x230034 0x1111)"
"b2_skip_phase|$(poke 0x230040 2);$(poke 0x260448 1);$(poke 0x230034 0x1111)"
# --- TOP RESET: p+0x2bc set AND phase 0 -> B1420, then branch-2 2a-fall.
"reset_b1420|$(poke 0x230040 2);$(poke 0x260448 0);$(poke 0x2302bc 1);$(poke 0x230034 0x4321)"
# --- TAIL ARMS: action 0x16 (>3 -> no steer; passes the tail gate). phase 1 (no top reset).
"tail_aa4d0|$(poke 0x230040 0x16);$(poke 0x260448 1);$CTRL;$(poke 0x280214 1)"
"tail_aa870|$(poke 0x230040 0x16);$(poke 0x260448 1);$CTRL;$(poke 0x280215 1)"
"tail_aafd0|$(poke 0x230040 0x16);$(poke 0x260448 1);$(poke 0x280214 1)"
"tail_b8ce0|$(poke 0x230040 0x16);$(poke 0x260448 1);$(poke 0x230054 5)"
"tail_b8ce0_team|$(poke 0x230040 0x16);$(poke 0x260448 1);$(poke 0x230054 5);$(poke 0x27004c 0x2a0000);$(poke 0x2302b8 10);$(poke 0x2a02b8 20)"
"tail_b8ce0_same|$(poke 0x230040 0x16);$(poke 0x260448 1);$(poke 0x230054 5);$(poke 0x27004c 0x2a0000);$(poke 0x2302b8 10);$(poke 0x2a02b8 10)"
)

: > "$OUT"
echo "# Stage 3 movement leaf FUN_005a8680 (settle) PCode-emu truth. PURE INTEGER -> 7 leaves STUBBED;" >> "$OUT"
echo "# each row: FIX <name> + verbatim STUB/RET lines. STUB shows leaf selection + arg0; mem[0x23005d]=p+0x5d," >> "$OUT"
echo "# mem[0x230054]=p+0x54. P=0x230000 M=0x260000 BALL=0x270000 GS=0x280000 OTHER=0x2a0000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || true
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "[$NAME] $(echo "$RET" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  5d=$(echo "$RET" | grep -oE 'mem\[0x23005d:1\]=[0-9-]+')  54=$(echo "$RET" | grep -oE 'mem\[0x230054:4\]=[0-9-]+')  stubs=$(grep -cE 'CALL 0 STUB' "$ROUT")"
done
echo "=== settle oracle -> $OUT ==="
cat "$OUT"
