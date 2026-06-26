#!/usr/bin/env bash
# Stage 3 (settle leaf): drive the REAL FUN_005b1420 through the Ghidra PCode emulator and bank
# (a) the per-player formation counter p+0x14c, (b) the leaf-call SELECTION (which of B0040/B1500/
# B1C80, or none under the set-piece freeze), and (c) the returned byte EAX. GROUND TRUTH that
# Pm98Movement.formation_gate_b1420 must reproduce bit-for-bit (app/tests/test_b1420.gd).
#
# FUN_005b1420(__thiscall this=player P) maintains p+0x14c (INC while P is the ball carrier
# BALL+0x40==P, else RESET 0), then -- unless bVar2 (GS+0x2ee flag && FUN_005943b0(M)==1 (sub-phase
# *(M+0x468)+0xfa0 == 0) && P+0x5c lock) -- dispatches EXACTLY ONE positioning leaf:
#   B0040 = FUN_005b0040  when P==GS+0x204 && BALL+0x40==0 (no carrier); returns 1
#   B1500 = FUN_005b1500  else when BALL+0x54 != P+0x2b8;               returns its byte
#   B1C80 = FUN_005b1c80  else;                                          returns its byte
# The dispatched leaves are thiscall ECX=P, 0 stack args -> STUBBED here (B0040 ret 0 [discarded, fn
# returns 1], B1500 ret 0x55, B1C80 ret 0xaa as return sentinels). FUN_005943b0 (thiscall ECX=M) is a
# 2-deref pure predicate -> EXECUTED for real (M+0x468 -> SUB; SUB+0xfa0 = sub-phase). NO RNG/LUT/ftol.
#
# Memory map (zeroed windows): P@0x230000 (ECX), M@0x260000 (P+0x18c), BALL@0x270000 (P+0x190),
# GS@0x280000 (P+0x184), SUB@0x290000 (M+0x468). read_mem p+0x14c (0x23014c); EAX = returned byte.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b1420_oracle.txt
SPEC=$SPECDIR/_b1420_run.spec
ROUT=$SPECDIR/_b1420_run.out

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

STUBS=(
  "0x5b0040 0 0 B0040"      # interception/mark (return discarded; fn returns 1)
  "0x5b1500 0x55 0 B1500"   # loose-ball reposition (return sentinel 0x55)
  "0x5b1c80 0xaa 0 B1C80"   # default reposition    (return sentinel 0xaa)
)
READS=( "0x0023014c 4" )

emit_spec() {  # $1 = newline-joined pokes
  {
    cat <<EOF
entry   0x005b1420
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
maxsteps 200000
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

# All fixtures: P+0x18c -> M, P+0x190 -> BALL, P+0x184 -> GS, M+0x468 -> SUB (for FUN_005943b0).
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000);$(poke 0x260468 0x290000)"
CARRIER="$(poke 0x270040 0x230000)"   # BALL+0x40 = P (P holds the ball -> counter INC)
ANCHOR="$(poke 0x280204 0x230000)"    # GS+0x204 = P (the formation-anchor slot)

FIX=(
# B0040: not carrier (BALL+0x40==0 -> counter reset 0), P==GS+0x204, no carrier -> b0040, return 1.
"b0040|$ANCHOR"
# B1500: carrier (counter = 5+1), GS+0x204!=P, BALL+0x54(7) != P+0x2b8(0) -> b1500, return 0x55.
"b1500_carrier|$CARRIER;$(poke 0x23014c 5);$(poke 0x270054 7)"
# B1C80: not carrier (counter 0), GS+0x204!=P, BALL+0x54(0)==P+0x2b8(0) -> b1c80, return 0xaa.
"b1c80|"
# B1C80 with carrier: counter = 9+1=10, BALL+0x54(0)==P+0x2b8(0) -> b1c80.
"b1c80_carrier|$CARRIER;$(poke 0x23014c 9)"
# FREEZE: GS+0x2ee=1, SUB+0xfa0=0 (FUN_005943b0=1), P+0x5c=1 -> bVar2 true -> NO leaf, return 1.
"freeze|$(poke 0x2802ee 1);$(poke 0x23005c 1)"
# FREEZE phase!=0: GS+0x2ee=1, SUB+0xfa0=2 (FUN_005943b0=0) -> no freeze -> dispatch b1c80.
"freeze_phase|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x290fa0 2)"
# FREEZE no-lock: GS+0x2ee=1, SUB+0xfa0=0 (5943b0=1), P+0x5c=0 -> no freeze -> dispatch b1c80.
"freeze_nolock|$(poke 0x2802ee 1)"
)

: > "$OUT"
echo "# Stage 3 settle leaf FUN_005b1420 (off-ball formation gate) PCode-emu truth. 3 dispatch leaves" >> "$OUT"
echo "# STUBBED (B0040 ret0/B1500 0x55/B1C80 0xaa); FUN_005943b0 executed for real. Each row: FIX <name>" >> "$OUT"
echo "# + STUB/RET lines. mem[0x23014c]=p+0x14c counter; EAX=return byte. P=0x230000 M=0x260000" >> "$OUT"
echo "# BALL=0x270000 GS=0x280000 SUB=0x290000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || true
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "[$NAME] $(echo "$RET" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9]+')  14c=$(echo "$RET" | grep -oE 'mem\[0x23014c:4\]=[0-9-]+')  stubs=$(grep -cE 'CALL 0 STUB' "$ROUT")"
done
echo "=== b1420 oracle -> $OUT ==="
cat "$OUT"
