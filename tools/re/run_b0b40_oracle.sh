#!/usr/bin/env bash
# Stage 3 (movement leaf): drive the REAL FUN_005b0b40 through the Ghidra PCode emulator and
# bank the returned count (EAX). Ground truth that Pm98Action._count_teammates_closer must
# reproduce bit-for-bit (app/tests/test_b0b40.gd).
#
# FUN_005b0b40(__thiscall this=player P, int param_2) is a PURE counter (writes only stack
# locals, disasm-verified). It computes a SELF metric `self = abs(P[4] + P[0x3a4])` (note the
# '+'), then walks the opponent descriptor P+0x188 = {base, count}: for each of `count` players
# (stride 0x3bc) it forms `q_metric = abs(q[4] - q[0x3a4])` (note the '-'; a NULL base yields the
# sentinel 0xc80000), and increments the result when `q_metric < param_2 + self` (signed, strict
# <). The engine calls it as FUN_005b0b40(0xfffe0000) => param_2 = -0x20000. NO RNG, NO float
# import, NO LUT -- just poke state, run, read EAX.
#
# Memory map: player P@0x230000 (ECX), opponent array Q0@0x240000 / Q1@0x2403bc / Q2@0x240778
# (stride 0x3bc), opponent descriptor OD@0x251000 ({+0:base=Q array, +4:count}). EAX is the
# default read_reg, so the returned count is captured.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b0b40_oracle.txt
SPEC=$SPECDIR/_b0b40_run.spec
ROUT=$SPECDIR/_b0b40_run.out

# Field offsets within a player (0x3bc stride): +4 = x, +0x3a4 = anchor.
#   Q0 anchor @0x2403a4 ; Q1 (@0x2403bc) anchor @0x240760 ; Q2 (@0x240778) anchor @0x240b1c.
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b0b40
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
arg     0xfffe0000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
zero    0x00251000 0x00001000
mem 0x00230188 4 0x00251000     # P+0x188 = opponent descriptor OD
mem 0x00230004 4 0x40000        # P.x (+4)
mem 0x002303a4 4 0x40000        # P.anchor (+0x3a4) -> self = abs(0x40000+0x40000) = 0x80000
mem 0x00251000 4 0x00240000     # OD base = opponent array
mem 0x00251004 4 0x3            # OD count (default 3)
mem 0x00240004 4 0x50000        # Q0.x  -> metric abs(0x50000-0x10000)=0x40000 (< 0x60000, counted)
mem 0x002403a4 4 0x10000        # Q0.anchor
mem 0x002403c0 4 0x10000        # Q1.x  -> metric abs(0x10000-0x50000)=0x40000 (counted; tests '-')
mem 0x00240760 4 0x50000        # Q1.anchor
mem 0x0024077c 4 0x80000        # Q2.x  -> metric abs(0x80000-0)=0x80000 (> 0x60000, NOT counted)
mem 0x00240b1c 4 0x0            # Q2.anchor
$1
maxsteps 200000
EOF
}

# threshold = param_2 + self = -0x20000 + 0x80000 = 0x60000 (default self).
FIX=(
"count0|mem 0x00251004 4 0x0"
"count2|mem 0x00251004 4 0x2"
"mixed3|"
"boundary|mem 0x00251004 4 0x2 ; mem 0x00240004 4 0x60000 ; mem 0x002403a4 4 0x0 ; mem 0x002403c0 4 0x5ffff ; mem 0x00240760 4 0x0"
"null_base|mem 0x00251000 4 0x0 ; mem 0x00251004 4 0x1"
"negself|mem 0x002303a4 4 0xfffc0000"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 movement leaf: FUN_005b0b40 (opponent-count) ground truth (PCode emu; pure" >> "$OUT"
echo "# counter, no float-import, no LUT; EAX = returned count). Each row: FIX <name> CALL line." >> "$OUT"
echo "# self=abs(P[4]+P[0x3a4]); per-q abs(q[4]-q[0x3a4]); count where q<param_2+self (param_2=-0x20000)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9]+')"
done
echo "=== b0b40 oracle -> $OUT ==="
cat "$OUT"
