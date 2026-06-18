#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE slice C2): drive the REAL FUN_005a3400 with a set-piece phase
# (match+0x448 in {2,3,4,6,7}) and the player AS THE TAKER (player == match+0x438), then bank the
# taker move-target / facing / position / stamina outputs. Ground truth that
# Pm98Movement._decide_slice_c_taker must reproduce bit-for-bit (app/tests/test_decideCtaker.gd).
#
# Setup (player P0 @0x230000 = the taker):
#   * DAT_006d31c4=0 (real compute); slices A+B run as the prefix; player+0x2cc=-1 (slice-B
#     lookup skipped); player+0x2bc=0 (off-pitch -> slice A needs no formation slots).
#   * match+0x438 = P0 -> the taker branch. ball = player+0x190 -> B @0x250000; ball+0x40 = P0 so
#     the real FUN_0058eca0 (ball.engage(player)) finds the player already engaged and EARLY-RETURNS
#     (no ball/match mutation -> no wild writes; its non-early path is validated in test_decideset).
#   * stamina flag inputs: teaminfo (player+0x184) @0x270000 with +0x2ee ; phase0 struct
#     (match+0x468) @0x280000 with +0xfa0 (==0 -> phase0 true) ; player+0x5c.
#   * match+0x180b=0 -> case 6's gated SFX FUN_004e9630 is skipped. The case 4/5/6/7 `.data`
#     set-piece globals + case 6 RNG save/restore run for real (harmless to P0 fields).
#   * cos/atan LUTs + faithful _ftol injected (moveleaf trick) so the real atan/polar emulate.
#
# Memory: P0@0x230000, M@0x210000, ball@0x250000, teaminfo@0x270000, phase0@0x280000. Signed LE.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideCtaker_oracle.txt
SPEC=$SPECDIR/_decideCtaker_run.spec
ROUT=$SPECDIR/_decideCtaker_run.out
LUT=$SPECDIR/_decideCtaker_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"              # +4/+8/+0xc move target
  "0x00230034 4" "0x00230064 4"                             # +0x34/+0x64 facing (WORD, raw u16)
  "0x00230040 4"                                            # +0x40 position code
  "0x00230048 4"                                            # +0x48 stamina
  "0x0023002c 4" "0x00230030 4"                             # +0x2c/+0x30 (set_position_code remap-clear)
)

emit_spec() {
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
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
maxsteps 900000
stub 0x5bbf10 0 0
mem 0x006d31c4 1 0x0
mem 0x0023018c 4 0x00210000
mem 0x00230188 4 0x00240000
mem 0x00230190 4 0x00250000
mem 0x00230184 4 0x00270000
mem 0x002302cc 4 0xffffffff
mem 0x00211820 4 0x100000
mem 0x00210438 4 0x00230000
mem 0x00210468 4 0x00280000
mem 0x00250040 4 0x00230000
mem 0x0021180b 1 0x0
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

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Fixtures: name | pokes. Common knobs (abs addr):
#   player +0x2b8=0x2302b8 (team) +0x5c=0x23005c (stamina) ; match +0x19a0=0x2119a0 (orient)
#   +0x448=0x210448 (phase) ; teaminfo +0x2ee=0x2702ee ; ball pos +0x90=0x250090 +0x94=0x250094.
FIX=(
# case 2 taker, stamina flag TRUE (teaminfo+0x2ee=1, phase0=0, +0x5c=1) -> +0x48 = 0x384.
"c2_flagT|$(poke 0x2302b8 0);$(poke 0x2119a0 0);$(poke 0x210448 2);$(poke 0x2702ee 1);$(poke 0x23005c 1);$(poke 0x250090 0x200000);$(poke 0x250094 0x80000);$(poke 0x250098 0)"
# case 2 taker, stamina flag FALSE (player+0x5c=0) -> +0x48 = 0xb4.
"c2_flagF|$(poke 0x2302b8 0);$(poke 0x2119a0 0);$(poke 0x210448 2);$(poke 0x2702ee 1);$(poke 0x23005c 0);$(poke 0x250090 0x200000);$(poke 0x250094 0x80000);$(poke 0x250098 0)"
# case 3 taker: facing +0x34=(ball+0x94<1?0x4000:-0x4000); +0x64 keeps slice-B; +0x2c/+0x30 cleared (0x13 remaps).
"c3_taker|$(poke 0x2302b8 0);$(poke 0x2119a0 0);$(poke 0x210448 3);$(poke 0x2702ee 1);$(poke 0x23005c 1);$(poke 0x250090 0x180000);$(poke 0x250094 0x80000);$(poke 0x250098 0);$(poke 0x23002c 0x111);$(poke 0x230030 0x222)"
# case 4 taker: set_pos(0x1d) + double-aim -> tail; +0x2c/+0x30 cleared (0x1d remaps to 5).
"c4_taker|$(poke 0x2302b8 0);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2702ee 1);$(poke 0x23005c 1);$(poke 0x250090 0x200000);$(poke 0x250094 0x80000);$(poke 0x250098 0);$(poke 0x23002c 0x333);$(poke 0x230030 0x444)"
# case 6 taker: team1 -> facing 0x8000 (both); move = ball+0x90; SFX skipped (match+0x180b=0).
"c6_taker|$(poke 0x2302b8 1);$(poke 0x2119a0 0);$(poke 0x210448 6);$(poke 0x2702ee 1);$(poke 0x23005c 1);$(poke 0x250090 0x200000);$(poke 0x250094 0x80000);$(poke 0x250098 0x10000)"
# case 7 taker: orient1 (flips aim_x sign) + double-aim -> tail.
"c7_taker|$(poke 0x2302b8 0);$(poke 0x2119a0 1);$(poke 0x210448 7);$(poke 0x2702ee 1);$(poke 0x23005c 1);$(poke 0x250090 0x200000);$(poke 0x250094 0x80000);$(poke 0x250098 0)"
)

: > "$OUT"
echo "# Stage 3 task 2 DECIDE slice C2 (FUN_005a3400 set-piece switch, TAKER paths) PCode-emu" >> "$OUT"
echo "# ground truth. player==match+0x438 (taker); ball.engage early-returns (ball+0x40=player);" >> "$OUT"
echo "# stamina flag via teaminfo+0x2ee / phase0(match+0x468+0xfa0==0) / player+0x5c; LUT+_ftol injected." >> "$OUT"
echo "# Each row: 'FIX <name>' + the verbatim CALL line (fields by abs addr, P0=0x230000)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  mv=$(echo "$LINE" | grep -oE 'mem\[0x230004:4\]=[0-9-]+')  34=$(echo "$LINE" | grep -oE 'mem\[0x230034:4\]=[0-9-]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')  48=$(echo "$LINE" | grep -oE 'mem\[0x230048:4\]=[0-9-]+')"
done
echo "=== decideCtaker oracle -> $OUT ==="
cat "$OUT"
