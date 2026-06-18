#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE slice A): drive the REAL FUN_005a3400 prologue+bbox through the
# Ghidra PCode emulator and bank the 13 slice-A output fields. Ground truth that
# Pm98Movement.decide_slice_a must reproduce bit-for-bit (app/tests/test_decideA.gd).
#
# FUN_005a3400 is the per-player DECIDE (4293 bytes); slice A is its first ~100 instructions
# (goal-X anchor +0x3a4, the two target endpoints +0x1e0/+0x1ec, and the movement bbox
# +0x210..+0x224). Slice A is pure integer (mirror/compose/min-max sort) -- NO RNG/LUT/ftol --
# but the rest of the function (slices B/C) is RNG+LUT heavy. So this oracle runs the WHOLE
# real function down the REPLAY path (DAT_006d31c4 != 0): slice A executes IDENTICALLY, then
# the function takes the simple replay-copy tail and RETURNs cleanly, never touching the
# slice-A outputs (+0x1e0..+0x224, +0x3a4 are all written before the gate and not overwritten;
# the 0x51-dword replay copy writes player+0x40..+0x184 only). No callee stubs, no LUT.
#
# Memory map: player P0 @0x230000, match M @0x210000, FUN_005ed870 +0x38 buffer @0x252000,
# replay +0x3b0 buffer @0x254000. DAT_006d31c4 @0x6d31c4 = 1 (replay). Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideA_oracle.txt
SPEC=$SPECDIR/_decideA_run.spec
ROUT=$SPECDIR/_decideA_run.out

# 13 slice-A output addresses (P0 + offset).
READS="0x002303a4 0x002301e0 0x002301e4 0x002301e8 0x002301ec 0x002301f0 0x002301f4 \
0x00230210 0x00230214 0x00230218 0x0023021c 0x00230220 0x00230224"

emit_spec() {
  # $1 = per-fixture pokes (newline-separated)
  {
    cat <<EOF
entry   0x005a3400
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00001000
zero    0x00252000 0x00000040
zero    0x00254000 0x00000400
maxsteps 400000
mem 0x006d31c4 1 0x1
mem 0x00230038 4 0x00252000
mem 0x002303b0 4 0x00254000
mem 0x0023005c 4 0x0
mem 0x0023018c 4 0x00210000
mem 0x00210438 4 0x0
EOF
    printf '%s\n' "$1"
    for r in $READS; do echo "read_mem $r 4"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | head -1 | cut -d= -f2 || true; }
retof() { echo "$1" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true; }

bank() {
  local name=$1 pokes=$2 line
  emit_spec "$pokes"
  run_emu
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  printf 'FIX %s a3a4=%s e0=%s e4=%s e8=%s ec=%s f0=%s f4=%s b10=%s b14=%s b18=%s b1c=%s b20=%s b24=%s\n' \
    "$name" \
    "$(mval "$line" 0x2303a4)" \
    "$(mval "$line" 0x2301e0)" "$(mval "$line" 0x2301e4)" "$(mval "$line" 0x2301e8)" \
    "$(mval "$line" 0x2301ec)" "$(mval "$line" 0x2301f0)" "$(mval "$line" 0x2301f4)" \
    "$(mval "$line" 0x230210)" "$(mval "$line" 0x230214)" "$(mval "$line" 0x230218)" \
    "$(mval "$line" 0x23021c)" "$(mval "$line" 0x230220)" "$(mval "$line" 0x230224)" >> "$OUT"
  echo "[$name] $(retof "$line") a3a4=$(mval "$line" 0x2303a4) b10=$(mval "$line" 0x230210) b1c=$(mval "$line" 0x23021c)"
}

: > "$OUT"
echo "# Stage 3 task 2 DECIDE slice A (FUN_005a3400 prologue+bbox) PCode-emu ground truth" >> "$OUT"
echo "# (replay path, clean RET). Row: FIX <name> + 13 slice-A fields. signed LE decimal." >> "$OUT"
echo "# a3a4=+0x3a4 goalX | e0..e8=+0x1e0 endpoint A | ec..f4=+0x1ec endpoint B" >> "$OUT"
echo "# b10..b18=+0x210 bbox-min | b1c..b24=+0x21c bbox-max" >> "$OUT"

# Common on-pitch formation slots (used only by the on-* fixtures).
ONPITCH_VECS="mem 0x002301f8 4 0x60000
mem 0x002301fc 4 0xFFFD0000
mem 0x00230200 4 0x10000
mem 0x00230204 4 0xFFFE0000
mem 0x00230208 4 0x40000
mem 0x0023020c 4 0x0
mem 0x00230228 4 0x50000
mem 0x0023022c 4 0x20000
mem 0x00230230 4 0xFFFF0000
mem 0x00230234 4 0x70000"

# off-pitch (player+0x2bc = 0): explicit default box, two sign branches + the x-swap.
bank off_u9_0 "mem 0x002302bc 4 0x0
mem 0x002302b8 4 0x0
mem 0x00211820 4 0x100000
mem 0x002119a0 4 0x0"                                 # (0&1)^0 = 0 ; no swap
bank off_u9_1 "mem 0x002302bc 4 0x0
mem 0x002302b8 4 0x0
mem 0x00211820 4 0x100000
mem 0x002119a0 4 0x1"                                 # (1&1)^0 = 1 ; swap fires
bank off_team1 "mem 0x002302bc 4 0x0
mem 0x002302b8 4 0x1
mem 0x00211820 4 0xC0000
mem 0x002119a0 4 0x1"                                 # (1&1)^1 = 0

# on-pitch (player+0x2bc != 0): mirror endpoints + sorted box from the formation slots.
bank on_noflip "mem 0x002302bc 4 0x1
mem 0x002302b8 4 0x0
mem 0x00211820 4 0x100000
mem 0x002119a0 4 0x0
$ONPITCH_VECS"                                        # (0&1)^0 = 0 ; no mirror flip
bank on_flip "mem 0x002302bc 4 0x1
mem 0x002302b8 4 0x0
mem 0x00211820 4 0x100000
mem 0x002119a0 4 0x1
$ONPITCH_VECS"                                        # (1&1)^0 = 1 ; flip x,y
bank on_flip_team1 "mem 0x002302bc 4 0x1
mem 0x002302b8 4 0x1
mem 0x00211820 4 0xC0000
mem 0x002119a0 4 0x0
$ONPITCH_VECS"                                        # (0&1)^1 = 1 ; flip x,y

echo "=== decideA oracle -> $OUT ==="
cat "$OUT"
