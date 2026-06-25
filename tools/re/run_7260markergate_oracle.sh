#!/usr/bin/env bash
# Oracle for FUN_005a7260 marker-grid ENTRY GATES (0x5a7d9e..0x5a7e23), slice 2b-iii-a. After the
# FUN_005b05a0 pull-in call the binary decides whether to RUN the ~470-insn marker-grid dribble search
# (fall through to 0x5a7e23) or SKIP to the tail re-engage block (jump to 0x5a8457). We drive the REAL
# FUN_005a7260 ENTERED MID-FUNCTION at 0x5a7d9e (right after the b05a0 call) with ESI=p, EBP=p+4 -- the
# faithful register state on the je-into-marker-block path (ebp = lea [esi+4] at 0x5a73dd, never
# clobbered before the 0x5a76f8.. je's into 0x5a7d4d). The two gates, in binary order:
#   (1) PROXIMITY -- ball.pos (ball+4) within per-axis |Δ| < 0x230000 of p.pos (EBP) on ALL 3 axes.
#   (2) POSSESSION early-out (only when FUN_005b8c90 says we hold the ball: gs[0x138]+0x1664 == gs+8):
#       proceed iff carrier ball+0x40 == 0 AND ball+0x44 == p; else tail.
# OBSERVATION: trace GRID@0x5a7e23 + TAIL@0x5a8457. The search, when it finds no marker, ALSO falls to
# 0x5a8457, so TAIL is NOT a clean discriminator -- the gate outcome is "did GRID(0x5a7e23) fire?".
# No LUT/ftol/RNG/stubs: the only call before either trace target is FUN_005b8c90 (pure int compare on
# our gs/m memory). After the trace fires the run executes real code until maxsteps -> HALT; the
# tracehits map is banked regardless. GROUND TRUTH for Pm98Movement._marker_gate_proceed
# (app/tests/test_7260markergate.gd).
#
# Memory: p @0x230000 (ECX/ESI, EBP=0x230004), ball @0x280000, gs @0x290000, m @0x2a0000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260markergate_oracle.txt
SPEC=$SPECDIR/_7260markergate_run.spec
ROUT=$SPECDIR/_7260markergate_run.out

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Constant wiring (every fixture): p+0x184=gs, p+0x190=ball, gs+0x138=m.
CONST="$(poke 0x230184 0x290000);$(poke 0x230190 0x280000);$(poke 0x290138 0x2a0000)"

emit_spec() {  # $1 = fixture pokes
  {
    cat <<EOF
entry   0x005a7d9e
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ESI 0x00230000
reg     EBP 0x00230004
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00002000
maxsteps 30000
trace   0x005a7e23 GRID
trace   0x005a8457 TAIL
EOF
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${1//;/$'\n'}"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# name|pokes  (p.pos zeroed; ball.pos / possession V,W / carrier / ball+0x44 per fixture).
# In-possession when gs+8 (0x290008) == m+0x1664 (0x2a1664); both default 0 -> in possession.
FIX=(
  # near + NOT in possession (gs+8=1 != m+0x1664=0) -> run search (GRID).
  "near_loose|$(poke 0x290008 1)"
  # proximity FAIL on x (Δx = 0x230000, the >= boundary) -> tail.
  "far_x|$(poke 0x280004 0x230000)"
  # proximity FAIL on y, NEGATIVE delta (abs = 0x230000) -> tail (exercises the cdq/xor/sub abs).
  "far_y_neg|$(poke 0x280008 -0x230000)"
  # proximity FAIL on z -> tail.
  "far_z|$(poke 0x28000c 0x230000)"
  # near boundary (Δx = 0x22ffff, just inside) + not in possession -> GRID.
  "near_boundary|$(poke 0x280004 0x22ffff);$(poke 0x290008 1)"
  # near + in possession (both 0) + carrier ball+0x40 != 0 -> tail.
  "poss_carrier|$(poke 0x280040 0x999)"
  # near + in possession + loose (carrier 0) + ball+0x44 == p (0x230000) -> GRID.
  "poss_loose_match44|$(poke 0x280044 0x230000)"
  # near + in possession + loose + ball+0x44 != p -> tail.
  "poss_loose_nomatch44|$(poke 0x280044 0x111)"
)

: > "$OUT"
echo "# Oracle FUN_005a7260 marker-grid ENTRY GATES (0x5a7d9e..0x5a7e23). Entered mid-fn at 0x5a7d9e" >> "$OUT"
echo "# (ESI=p, EBP=p+4). trace GRID@0x5a7e23 (run search) vs TAIL@0x5a8457 (skip). proceed = GRID fired." >> "$OUT"
echo "# Row: MGATE <name> proceed=<0|1> | <CALL summary with tracehits=...>." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  if echo "$LINE" | grep -q 'GRID='; then PROCEED=1; else PROCEED=0; fi
  echo "MGATE $NAME proceed=$PROCEED | $(echo "$LINE" | grep -oE 'tracehits=\{[^}]*\}')" >> "$OUT"
  echo "[$NAME] proceed=$PROCEED  $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  $(echo "$LINE" | grep -oE 'tracehits=\{[^}]*\}')"
done
echo "=== 7260 marker-gate oracle -> $OUT ==="
cat "$OUT"
