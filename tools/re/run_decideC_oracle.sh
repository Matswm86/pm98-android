#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE slice C1): drive the REAL FUN_005a3400 through the Ghidra PCode
# emulator with a set-piece phase (match+0x448 in {3,6,7} or a default) and a NON-TAKER player
# (player != match+0x438), then bank the slice-C move-target / facing / position outputs.
# Ground truth that Pm98Movement.decide_slice_c must reproduce bit-for-bit
# (app/tests/test_decideC.gd).
#
# Slice C1 is the switch tail (disasm 0x5a37f8..0x5a44c4), non-taker cases 3/6/7 + default:
#   * DAT_006d31c4 @0x6d31c4 = 0 (real-compute branch); slices A + B run as the prefix.
#   * match+0x448 picks the case; match+0x438 -> a DISTINCT taker struct T2 @0x260000 so the
#     player is never the taker (the taker engagement/RNG/aim paths are out of C1 scope).
#   * player+0x2cc = -1 -> slice B's +0xb0 table lookup is skipped (no team-struct table needed).
#   * player+0x190 -> a ball struct B @0x250000; the facing tail reads its +0x4 vec (and case 7
#     off-pitch reads ball+0x90). The taker's team lives at T2+0x2b8.
#   * FUN_005bbf10 STUBBED (cdecl no-op). FUN_005a5430 (set_position_code), FUN_00590ae0
#     (vec3_sub) and FUN_005ee080 (atan) run FOR REAL; the cos/atan LUTs + faithful _ftol are
#     injected (same trick as run_moveleaf_oracle.sh) so the atan tail emulates without fcos.
#
# Memory map: player P0 @0x230000, match M @0x210000, team struct @0x240000 (unused, +0x2cc<0),
# ball B @0x250000, taker T2 @0x260000. Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideC_oracle.txt
SPEC=$SPECDIR/_decideC_run.spec
ROUT=$SPECDIR/_decideC_run.out
LUT=$SPECDIR/_decideC_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

# Slice-C output addresses (P0 + offset). facing +0x34/+0x64 are WORD writes into zeroed dwords.
READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"              # +4/+8/+0xc move target
  "0x00230034 4" "0x00230064 4"                             # +0x34/+0x64 facing (WORD, raw u16)
  "0x00230040 4"                                            # +0x40 position code
  "0x00230048 4"                                            # +0x48 stamina (kill-test: stays 0)
)

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
zero    0x00240000 0x00001000
zero    0x00250000 0x00001000
zero    0x00260000 0x00001000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
maxsteps 800000
stub 0x5bbf10 0 0
mem 0x006d31c4 1 0x0
mem 0x0023018c 4 0x00210000
mem 0x00230188 4 0x00240000
mem 0x00230190 4 0x00250000
mem 0x002302cc 4 0xffffffff
mem 0x00211820 4 0x100000
mem 0x00210438 4 0x00260000
EOF
    cat "$LUT"
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# LE-int32 poke of a possibly-negative decimal.
poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Fixtures: name | pokes (';'-separated). Common per-fixture knobs (abs addr):
#   player +0x2b8=0x2302b8 (team) +0x2bc=0x2302bc (on/off) ; match +0x19a0=0x2119a0 (orient)
#   +0x448=0x210448 (phase) ; taker +0x2b8=0x2602b8 ; on-pitch slots ep1 +0x1f8=0x2301f8,
#   ep2 +0x204=0x230204 ; ball +0x4=0x250004 +0x90=0x250090.
FIX=(
# case 3 same-team -> move = endpoint2 (+0x204 slots). on-pitch team0/orient0 (no mirror).
"c3_same|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 3);$(poke 0x2602b8 0);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 0x80000);$(poke 0x250008 0x10000)"
# case 3 different-team -> move = endpoint1 (+0x1f8 slots).
"c3_diff|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 3);$(poke 0x2602b8 1);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 -0x40000);$(poke 0x250008 0x20000)"
# case 6 same-team -> per-axis midpoint (ep2+ep1)/2 trunc toward zero.
"c6_same|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 6);$(poke 0x2602b8 0);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 0x30000);$(poke 0x250008 -0x10000)"
# case 6 same-team negative-odd midpoint -> exercises trunc-toward-zero (not floor).
"c6_negmid|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 6);$(poke 0x2602b8 0);$(poke 0x2301f8 3);$(poke 0x2301fc 7);$(poke 0x230200 -1);$(poke 0x230204 -8);$(poke 0x230208 -2);$(poke 0x23020c 0);$(poke 0x250004 0x10000);$(poke 0x250008 0x10000)"
# case 6 different-team -> move = endpoint1.
"c6_diff|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 6);$(poke 0x2602b8 1);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 0x80000);$(poke 0x250008 -0x10000)"
# case 7 same-team -> move = endpoint2.
"c7_same|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 7);$(poke 0x2602b8 0);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 0x70000);$(poke 0x250008 0x30000)"
# case 7 OFF-pitch (different team), ball.x(+0x90) >= 0 -> set_pos(0x20); move=ep1[gx,0,0]; x-=0x5999.
"c7_off_pos|$(poke 0x2302b8 1);$(poke 0x2302bc 0);$(poke 0x2119a0 0);$(poke 0x210448 7);$(poke 0x2602b8 0);$(poke 0x250090 0x70000);$(poke 0x250004 0x40000);$(poke 0x250008 0x20000)"
# case 7 OFF-pitch, ball.x < 0 -> move x += 0x5999.
"c7_off_neg|$(poke 0x2302b8 1);$(poke 0x2302bc 0);$(poke 0x2119a0 0);$(poke 0x210448 7);$(poke 0x2602b8 0);$(poke 0x250090 -0x10000);$(poke 0x250004 0x40000);$(poke 0x250008 0x20000)"
# case 7 on-pitch different team -> move = endpoint1.
"c7_on_diff|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 7);$(poke 0x2602b8 1);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000);$(poke 0x250004 0x70000);$(poke 0x250008 0x30000)"
# default (phase 8): switch falls through to the clean RET -> move + facing untouched (slice B).
"default|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 8);$(poke 0x2602b8 0);$(poke 0x2301f8 0x10000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x30000);$(poke 0x250004 0x70000);$(poke 0x250008 0x30000)"
)

: > "$OUT"
echo "# Stage 3 task 2 DECIDE slice C1 (FUN_005a3400 set-piece switch, NON-TAKER paths) PCode-emu" >> "$OUT"
echo "# ground truth. DAT_006d31c4=0; match+0x448=phase, match+0x438=T2(0x260000) so non-taker;" >> "$OUT"
echo "# player+0x2cc=-1 (slice-B lookup skipped); ball=0x250000; cos/atan LUT + _ftol injected." >> "$OUT"
echo "# FUN_005bbf10 stubbed; 5a5430/590ae0/5ee080 real. Each row: 'FIX <name>' + verbatim CALL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  mv=$(echo "$LINE" | grep -oE 'mem\[0x230004:4\]=[0-9-]+')  34=$(echo "$LINE" | grep -oE 'mem\[0x230034:4\]=[0-9-]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')"
done
echo "=== decideC oracle -> $OUT ==="
cat "$OUT"
