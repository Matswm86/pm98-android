#!/usr/bin/env bash
# Stage 3 task 2 (positioning leaves): drive the REAL FUN_005b04e0 (forward-zone eligibility) and
# FUN_005b0b40 (goal-side opponent count) through the Ghidra PCode emulator and bank the returned
# EAX. Ground truth for Pm98Movement.pos_forward_ok / count_goalside_opponents
# (app/tests/test_posleaf.gd). Both are leaves of the off-ball positioning pass FUN_005b73a0.
#
#   FUN_005b04e0(__thiscall player; pos3 ptr): 1 iff pos is inside the pitch box
#     [m+0x1828..+0x1834]x[+0x182c..+0x1838]x[+0x1830..+0x183c], AND abs(x) > m+0x1820-0x108000,
#     AND abs(y) < 0x1428f5, AND sign(x) != sign(player+0x3a4). Pure integer; no sub-calls.
#   FUN_005b0b40(__thiscall player; thresh): count of opponents (player+0x188 = {base,count}) with
#     abs(opp.x - opp.anchor) < thresh + abs(player.x + player.anchor). x=+0x4, anchor=+0x3a4.
# NO RNG/LUT/ftol/stubs. EAX (auto-banked on RET) is the return.
#
# Memory map: player P @0x230000, match M @0x210000 (box bounds), pos vec @0x250000 (5b04e0 arg),
# opp descriptor @0x251000 ({+0:base=0x260000, +4:count}), opponents @0x260000 / @0x2603bc.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/posleaf_oracle.txt
SPEC=$SPECDIR/_posleaf_run.spec
ROUT=$SPECDIR/_posleaf_run.out

emit_spec() {
  # $1 = entry, $2 = stack arg (hex), $3 = pokes (newline-separated)
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00250000 0x00002000
zero    0x00260000 0x00002000
mem 0x0023018c 4 0x00210000
EOF
    printf 'arg 0x%08x\n' $(( $2 & 0xffffffff ))
    printf '%s\n' "$3"
    echo "maxsteps 200000"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name, $2 entry, $3 arg, $4 pokes
  emit_spec "$2" "$3" "${4//;/$'\n'}"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9-]+')"
}

# match box bounds + line scale; player anchor (+0x3a4) positive (sign +1).
MBOX="$(poke 0x211828 -0x200000);$(poke 0x211834 0x200000);$(poke 0x21182c -0x180000);$(poke 0x211838 0x180000);$(poke 0x211830 -0x10000);$(poke 0x21183c 0x100000);$(poke 0x211820 0x140000)"
PANCHOR="$(poke 0x2303a4 0x140000)"
PV() { echo "$(poke 0x250000 $1);$(poke 0x250004 $2);$(poke 0x250008 $3)"; }   # pos vec at the arg ptr

: > "$OUT"
echo "# Stage 3 task 2 positioning leaves (FUN_005b04e0 eligibility + FUN_005b0b40 goal-side count)" >> "$OUT"
echo "# PCode-emu ground truth, EAX = return. box [-0x200000..0x200000]x[-0x180000..0x180000]x" >> "$OUT"
echo "# [-0x10000..0x100000]; line thr = 0x140000-0x108000 = 0x38000; player+0x3a4 anchor = +0x140000." >> "$OUT"

# ---- FUN_005b04e0 (pos vec is the arg @0x250000) ----
# ok: inside box, |x|>0x38000, |y|<0x1428f5, x<0 (opposite the +anchor) -> 1.
bank b04e0_ok        0x5b04e0 0x250000 "$MBOX;$PANCHOR;$(PV -0x100000 0x10000 0)"
# outside box (x > xmax) -> 0.
bank b04e0_outbox    0x5b04e0 0x250000 "$MBOX;$PANCHOR;$(PV 0x300000 0x10000 0)"
# not past the line (|x| <= 0x38000) -> 0.
bank b04e0_online    0x5b04e0 0x250000 "$MBOX;$PANCHOR;$(PV -0x10000 0x10000 0)"
# y out of band (|y| >= 0x1428f5) -> 0.
bank b04e0_ybig      0x5b04e0 0x250000 "$MBOX;$PANCHOR;$(PV -0x100000 0x1428f5 0)"
# same sign as anchor (x > 0, anchor > 0) -> 0.
bank b04e0_samesign  0x5b04e0 0x250000 "$MBOX;$PANCHOR;$(PV 0x100000 0x10000 0)"

# ---- FUN_005b0b40 (arg = thresh; player.x=+0x40000 anchor=+0x40000 -> base=0x80000) ----
# 2 opponents: Q0 d=|0x100000-0|=0x100000, Q1 d=|0x20000-0|=0x20000. descriptor count=2.
B0B40="$(poke 0x230004 0x40000);$(poke 0x2303a4 0x40000);$(poke 0x230188 0x251000);$(poke 0x251000 0x260000);$(poke 0x251004 2);$(poke 0x260004 0x100000);$(poke 0x2603a4 0);$(poke 0x2603c0 0x20000);$(poke 0x260760 0)"
# thresh 0x20000 -> lim 0xa0000: Q1(0x20000)<lim counted, Q0(0x100000) not -> 1.
bank b0b40_one   0x5b0b40 0x20000  "$B0B40"
# thresh 0x100000 -> lim 0x180000: both counted -> 2.
bank b0b40_all   0x5b0b40 0x100000 "$B0B40"
# thresh -0x80000 -> lim 0: neither d<0 -> 0.
bank b0b40_none  0x5b0b40 -0x80000 "$B0B40"

echo "=== posleaf oracle -> $OUT ==="
cat "$OUT"
