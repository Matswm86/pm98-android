#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE slice C3): drive the REAL FUN_005a3400 through the Ghidra PCode
# emulator for the NON-TAKER set-piece cases 2 / 4 / 5 (cases 3/6/7 = slice C1, all takers = C2),
# then bank the move-target / facing / position outputs that Pm98Movement.decide_slice_c must
# reproduce bit-for-bit (app/tests/test_decideC3.gd).
#
# Cases (player != match+0x438, non-taker):
#   * case 2 (disasm 0x5a3953..0x5a3a2a): clamp endpoint1 into minmax(v, L), v=[goal_target_x,
#     -Yscale,-1.0] L=[0,+Yscale,+1000.0] (Yscale = match+0x1824), then clamp_min_sep(ball,0x90000).
#   * cases 4/5 same-team (0x5a3d12..0x5a3fe9): move=endpoint2 + conditional override from the
#     set-piece position table @0x674330 (indexed by player+0x2c8); on-pitch -> clamp_min_sep 0xa8000.
#   * cases 4/5 diff-team off-pitch (0x5a3fee..0x5a4073): set_pos(0x20), move=endpoint1 + wing offsets.
#   * cases 4/5 diff-team on-pitch (0x5a4078..0x5a40a9): move=endpoint1, clamp_min_sep 0xa8000.
#
#   DAT_006d31c4 @0x6d31c4 = 0 (real-compute); slices A + B run as the prefix. match+0x438 ->
#   a DISTINCT taker T2 @0x260000 (its team at T2+0x2b8 sets same/different). player+0x2cc = -1
#   (slice-B +0xb0 lookup skipped). The cases-4/5 one-time table init runs: DAT_006742ec @0x6742ec
#   cleared so the inline writes @0x674330 land, and FUN_00605ff0 STUBBED (faithful: it never
#   touches the table). FUN_005bbf10 STUBBED. FUN_005a5430/590aa0/5b12c0/590ae0/5ee080/5ee2d0/5a44f0
#   run FOR REAL; cos/atan LUTs + faithful _ftol injected (clamp_min_sep + the atan tail).
#
# Memory map: player P0 @0x230000, match M @0x210000, team @0x240000 (unused), ball B @0x250000,
# taker T2 @0x260000, set-piece table @0x674330. Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideC3_oracle.txt
SPEC=$SPECDIR/_decideC3_run.spec
ROUT=$SPECDIR/_decideC3_run.out
LUT=$SPECDIR/_decideC3_lut.txt

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
zero    0x00674000 0x00001000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
maxsteps 800000
stub 0x5bbf10 0 0
stub 0x605ff0 0 0
mem 0x006742ec 1 0x0
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
pokeb() { printf 'mem 0x%08x 1 0x%02x' "$1" $(( $2 & 0xff )); }

# Per-fixture knobs (abs addr): player +0x2b8 team, +0x2bc on/off, +0x2c8 squad-pos, +0x2d6 flag;
# match +0x19a0 orient, +0x448 phase, +0x1824 Yscale, +0x19cc phase-5 sub-flag; taker +0x2b8 team;
# on-pitch slots ep1 +0x1f8, ep2 +0x204; ball +0x4 (facing), +0x90/+0x94/+0x98 (pos, far -> min-sep no-op).
# Common: ball facing vec +0x4=[0x70000,0x30000,0]; ball.pos far (0x500000) so clamp_min_sep is a no-op.
B4="$(poke 0x250004 0x70000);$(poke 0x250008 0x30000);$(poke 0x25000c 0)"
BPOS_FAR="$(poke 0x250090 0x500000);$(poke 0x250098 0)"
SLOTS_ON="$(poke 0x2301f8 0x80000);$(poke 0x2301fc 0x20000);$(poke 0x230200 0x10000);$(poke 0x230204 0x40000);$(poke 0x230208 0x50000);$(poke 0x23020c 0x60000)"

FIX=(
# case 2 non-taker, team0/orient0 (no mirror), Yscale 0x40000: x clamps to hi=0, y/z in range.
"c2_nontaker|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 2);$(poke 0x2602b8 0);$(poke 0x211824 0x40000);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 2 non-taker, mirror (orient1): gx positive, ep1 mirrored (negated x,y).
"c2_mirror|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 1);$(poke 0x210448 2);$(poke 0x2602b8 0);$(poke 0x211824 0x40000);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 -0x20000)"
# case 4 same-team, on-pitch, pos8 (entry [0xc0000,-0x8000,0]) -> override fires; ball.y>0 -> -entry.y.
"c4_same_override|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 8);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 same-team override, mirror (orient1) + ball.y<0 -> no y-neg, x mirrored.
"c4_same_mirror|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 1);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 8);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 -0x10000)"
# case 5 same-team, pos8 nonzero, match+0x19cc=0 -> phase-5 guard SKIPS override -> move=endpoint2.
"c5_phase5_guard|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 5);$(poke 0x2602b8 0);$(poke 0x2302c8 8);$(poke 0x2119cc 0);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 5 same-team, pos8, match+0x19cc!=0 -> guard inactive -> override fires.
"c5_phase5_on|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 5);$(poke 0x2602b8 0);$(poke 0x2302c8 8);$(poke 0x2119cc 1);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 same-team, pos0 (all-zero entry) -> override SKIPPED -> move=endpoint2.
"c4_same_allzero|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 0);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 same-team, pos5 (nonzero [0xb0000,0,0]) + player+0x2d6=0 -> gate3 false -> SKIP override.
"c4_same_pos5guard|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 5);$(pokeb 0x2302d6 0);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 same-team, pos5 + player+0x2d6=1 -> gate3 true -> override fires.
"c4_same_pos5d6|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 5);$(pokeb 0x2302d6 1);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 same-team OFF-pitch, pos8 -> override fires (uses table); NO min-sep (off-pitch).
"c4_same_off|$(poke 0x2302b8 0);$(poke 0x2302bc 0);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 0);$(poke 0x2302c8 8);$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 DIFFERENT team, OFF-pitch -> set_pos(0x20); move=ep1[gx,0,0] + (+0x4ccc, ball.y>=0->-0x20000).
"c4_diff_off|$(poke 0x2302b8 0);$(poke 0x2302bc 0);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 1);$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
# case 4 DIFFERENT team, OFF-pitch, ball.y<0 -> +0x20000; mirror (orient1) -> x offset -0x4ccc.
"c4_diff_off_neg|$(poke 0x2302b8 0);$(poke 0x2302bc 0);$(poke 0x2119a0 1);$(poke 0x210448 4);$(poke 0x2602b8 1);$B4;$BPOS_FAR;$(poke 0x250094 -0x10000)"
# case 4 DIFFERENT team, ON-pitch -> move=endpoint1, clamp_min_sep 0xa8000 (no-op, ball far).
"c4_diff_on|$(poke 0x2302b8 0);$(poke 0x2302bc 1);$(poke 0x2119a0 0);$(poke 0x210448 4);$(poke 0x2602b8 1);$SLOTS_ON;$B4;$BPOS_FAR;$(poke 0x250094 0x10000)"
)

: > "$OUT"
echo "# Stage 3 task 2 DECIDE slice C3 (FUN_005a3400 set-piece switch, NON-TAKER cases 2/4/5) PCode-emu" >> "$OUT"
echo "# ground truth. DAT_006d31c4=0; match+0x448=phase, match+0x438=T2(0x260000); player+0x2cc=-1;" >> "$OUT"
echo "# table-init flag 0x6742ec cleared, FUN_00605ff0 + FUN_005bbf10 stubbed; cos/atan LUT + _ftol injected." >> "$OUT"
echo "# 5a5430/590aa0/5b12c0/590ae0/5ee080/5ee2d0/5a44f0 real. Each row: 'FIX <name>' + verbatim CALL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  mv=$(echo "$LINE" | grep -oE 'mem\[0x230004:4\]=[0-9-]+')  34=$(echo "$LINE" | grep -oE 'mem\[0x230034:4\]=[0-9-]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')"
done
echo "=== decideC3 oracle -> $OUT ==="
cat "$OUT"
