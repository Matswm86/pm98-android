#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE slice B): drive the REAL FUN_005a3400 real-compute head through the
# Ghidra PCode emulator and bank the slice-B output fields. Ground truth that
# Pm98Movement.decide_slice_b must reproduce bit-for-bit (app/tests/test_decideB.gd).
#
# Slice B is the DAT_006d31c4==0 head (disasm 0x5a374d..0x5a37f8): clear the per-tick movement
# scratch, set the s16 facing, look up the formation-position value +0xb0 from the team
# struct's +0x13c table (indexed by player+0x2cc), and stamp the position code via FUN_005a5430.
# Unlike slice A (which used the replay path for a clean RET), slice B IS the gated body, so:
#   * DAT_006d31c4 @0x6d31c4 = 0 (take the real-compute branch at 0x5a374d).
#   * match+0x448 = 8 -> the switch `cmp eax,0x7; ja 0x5a44ba` falls to the DEFAULT exit
#     (a clean RET at 0x5a44ba) immediately AFTER slice B, so slice C never runs -- no LUT,
#     no RNG, no extra field writes. The default exit does NOT rewrite facing.
#   * FUN_005bbf10 (the +0x3b0/+0x38 queue-grow GlobalReAlloc, called by both slice B's head
#     and the leading FUN_005ed870 no-op path) is STUBBED (cdecl no-op). FUN_005a5430
#     (set_position_code) runs FOR REAL -- it reads the static .data LUT &DAT_00665208 from the
#     mapped image (pos_code 0 or 0x1e, neither remaps -> +0x2c/+0x30 left untouched).
#   * slice A still executes as the prefix (its pure helpers 5a4510/59a0e0/5b11f0/5b12c0 are
#     HALT-free, proven by run_decideA_oracle.sh); it writes only +0x1e0..+0x224 / +0x3a4,
#     which slice B neither reads nor reports, so the slice-B readback is purely slice B.
#
# Memory map: player P0 @0x230000, match M @0x210000, team/formation struct T @0x240000
# (its +0x13c int32 table is the source for +0xb0). Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideB_oracle.txt
SPEC=$SPECDIR/_decideB_run.spec
ROUT=$SPECDIR/_decideB_run.out

# Slice-B output addresses (P0 + offset). +0x61 is a BYTE; facing +0x34/+0x64 are WORD writes
# into zeroed dwords (so a 4-byte read yields 0x8000 / 0). Everything else is a dword store.
READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"              # +4/+8/+0xc move target = 0
  "0x00230020 4" "0x00230024 4" "0x00230028 4"              # +0x20/+0x24/+0x28 scratch = 0
  "0x0023002c 4" "0x00230030 4"                             # +0x2c/+0x30 NOT written (kill-test)
  "0x00230034 4" "0x00230064 4"                             # +0x34/+0x64 facing (WORD)
  "0x00230040 4"                                            # +0x40 position code (set_position_code)
  "0x00230048 4"                                            # +0x48 = 0
  "0x00230054 4" "0x00230058 4"                             # +0x54/+0x58 velocity = 0
  "0x00230061 1"                                            # +0x61 reach byte (set, never cleared)
  "0x00230068 4" "0x0023006c 4"                             # +0x68/+0x6c = 0
  "0x00230090 4"                                            # +0x90 = 0
  "0x002300b0 4"                                            # +0xb0 formation-position value
  "0x002303b4 4"                                            # +0x3b4 = 0
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
maxsteps 400000
stub    0x5bbf10 0 0
mem 0x006d31c4 1 0x0
mem 0x0023018c 4 0x00210000
mem 0x00230188 4 0x00240000
mem 0x00210448 4 0x8
mem 0x00211820 4 0x100000
EOF
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

# Fixtures: name | pokes (';'-separated, appended after the base).
# P0 field abs addrs: +0x2b8=0x2302b8 +0x2bc=0x2302bc +0x2cc=0x2302cc +0x61=0x230061
#   +0x2c=0x23002c +0x30=0x230030 ; match +0x19a0=0x2119a0 ; T table +0x13c+idx*4 @ 0x24013c+idx*4.
FIX=(
# home, orient 0 -> facing 0 ; on-pitch (pos 0) ; idx 3 -> table[3]=0x50000 (+0x61 set).
"home_on_v|mem 0x002302b8 4 0x0 ; mem 0x002302bc 4 0x1 ; mem 0x002302cc 4 0x3 ; mem 0x002119a0 4 0x0 ; mem 0x00240148 4 0x50000"
# orient 1, team 0 -> facing 0x8000 ; on-pitch ; idx 0 -> table[0]=0 ; +0x61 seeded 7 -> stays 7.
"away_on_zero|mem 0x002302b8 4 0x0 ; mem 0x002302bc 4 0x1 ; mem 0x002302cc 4 0x0 ; mem 0x002119a0 4 0x1 ; mem 0x0024013c 4 0x0 ; mem 0x00230061 1 0x7"
# team 1, orient 1 -> facing 0 ; OFF-pitch (pos 0x1e) ; idx 5 -> table[5]=0x123 (+0x61 set) ;
#   +0x2c/+0x30 seeded -> must survive (slice B never writes them; no remap-clear at pos 0x1e).
"off_pitch|mem 0x002302b8 4 0x1 ; mem 0x002302bc 4 0x0 ; mem 0x002302cc 4 0x5 ; mem 0x002119a0 4 0x1 ; mem 0x00240150 4 0x123 ; mem 0x0023002c 4 0x111 ; mem 0x00230030 4 0x222"
# team 1, orient 0 -> facing 0x8000 ; on-pitch ; idx -1 -> no lookup, +0xb0=0 ; +0x61 seeded 3 -> stays 3.
"neg_idx|mem 0x002302b8 4 0x1 ; mem 0x002302bc 4 0x1 ; mem 0x002302cc 4 0xffffffff ; mem 0x002119a0 4 0x0 ; mem 0x00230061 1 0x3"
# team 1, orient 0 -> facing 0x8000 ; on-pitch ; idx 2 -> table[2]=0x7fff0000 (high bit, +0x61 set).
"away_t1_big|mem 0x002302b8 4 0x1 ; mem 0x002302bc 4 0x1 ; mem 0x002302cc 4 0x2 ; mem 0x002119a0 4 0x0 ; mem 0x00240144 4 0x7fff0000"
)

: > "$OUT"
echo "# Stage 3 task 2 DECIDE slice B (FUN_005a3400 field reset+facing+position) PCode-emu" >> "$OUT"
echo "# ground truth. DAT_006d31c4=0 (real compute); match+0x448=8 -> switch default clean RET;" >> "$OUT"
echo "# FUN_005bbf10 stubbed, FUN_005a5430 real. Each row: 'FIX <name>' + the verbatim CALL line." >> "$OUT"
echo "# Fields by abs addr (P0=0x230000): +0x61 byte=reach latch; +0x34/+0x64=facing (0x8000/0)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  b0=$(echo "$LINE" | grep -oE 'mem\[0x2300b0:4\]=[0-9-]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')  34=$(echo "$LINE" | grep -oE 'mem\[0x230034:4\]=[0-9-]+')"
done
echo "=== decideB oracle -> $OUT ==="
cat "$OUT"
