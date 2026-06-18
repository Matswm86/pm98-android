#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE state setters): drive the REAL FUN_005a5430 (set-position-code)
# and FUN_0058eca0 (engage-target) through the Ghidra PCode emulator and bank the exact
# mutated state. Ground truth that Pm98Movement.set_position_code / set_engagement must
# reproduce bit-for-bit (app/tests/test_decideset.gd). Both functions are straight-line
# field ops -- NO sub-calls, NO RNG, NO ftol, NO LUT injection: FUN_005a5430 reads the
# real position-remap table &DAT_00665208 (.data, already mapped in the program image), so
# this oracle transitively validates the POS_REMAP_LUT extraction too.
#
#   FUN_005a5430(__thiscall player; pos_code): player+0x40 = pos_code; if pos_code !=
#     DAT_00665208[pos_code] then clear player+0x2c / +0x30.  (ret 0x4)
#   FUN_0058eca0(__thiscall player; target):   engage `target` (a player pointer / 0=null).
#     match = player+0x1d4. See test_decideset.gd / Pm98Movement.set_engagement for the body.
#
# Memory map: player P0 @0x230000, target P1 @0x2303bc (stride 0x3bc, == the movement
# oracle), match M @0x210000. POINTER fields (player+0x40/+0x44/+0x48, match+0x43c) are
# read back as ABSOLUTE addresses; the test maps addr -> index (0 -> null/-1). Values decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideset_oracle.txt
SPEC=$SPECDIR/_decideset_run.spec
ROUT=$SPECDIR/_decideset_run.out

P0=0x00230000; P1=0x002303bc; M=0x00210000

# emit_spec ENTRY "argdec" "POKE_LINES" "READ_ADDR:SIZE ..."
emit_spec() {
  local entry=$1 args=$2 pokes=$3 reads=$4
  {
    echo "entry   $entry"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P0"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00230000 0x00001000"
    echo "maxsteps 200000"
    [ -n "$pokes" ] && printf '%s\n' "$pokes"
    for a in $args; do printf 'arg 0x%08x\n' $(( a & 0xffffffff )); done
    for r in $reads; do
      local addr=${r%%:*}; local sz=${r##*:}
      echo "read_mem $addr $sz"
    done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# grab the value of mem[<addr>:<size>] from the single CALL result line
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | head -1 | cut -d= -f2 || true; }
retof() { echo "$1" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true; }

: > "$OUT"
echo "# Stage 3 task 2 DECIDE state setters (FUN_005a5430 / FUN_0058eca0) PCode-emu ground" >> "$OUT"
echo "# truth. Pointer fields (p40/p44/p48/m43c) are ABSOLUTE addresses; test maps -> index" >> "$OUT"
echo "# (P0=2293760 P1=2294716 ; null=0). Other fields raw signed LE decimal." >> "$OUT"
echo "# 5a5430 row: FIX <name> fn=5a5430 p40=<code> p2c=<v> p30=<v>" >> "$OUT"
echo "# 58eca0 row: FIX <name> fn=58eca0 p40=<a> p44=<a> p48=<a> p4c=<v> p54=<v> p80=<v> t54=<v> t58=<v> m458=<v> m460=<v> m43c=<a>" >> "$OUT"

# =========================== FUN_005a5430 (set-position-code) ===========================
# Preset +0x2c=0x1111 / +0x30=0x2222 so the "no clear" path is distinguishable from "clear".
# Reads: P0+0x40 (0x230040), P0+0x2c (0x23002c), P0+0x30 (0x230030).
POS_READS="0x00230040:4 0x0023002c:4 0x00230030:4"
bank_pos() {
  local name=$1 code=$2 line
  emit_spec 0x005a5430 "$code" "mem 0x0023002c 4 0x1111
mem 0x00230030 4 0x2222" "$POS_READS"
  run_emu
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  printf 'FIX %s fn=5a5430 p40=%s p2c=%s p30=%s\n' \
    "$name" "$(mval "$line" 0x230040)" "$(mval "$line" 0x23002c)" "$(mval "$line" 0x230030)" >> "$OUT"
  echo "[$name] $(retof "$line") p40=$(mval "$line" 0x230040) p2c=$(mval "$line" 0x23002c) p30=$(mval "$line" 0x230030)"
}
bank_pos pos_keep0   0        # LUT[0]=0   == 0    -> keep
bank_pos pos_remap4  4        # LUT[4]=0   != 4    -> CLEAR
bank_pos pos_remap19 19       # LUT[19]=0  != 19   -> CLEAR
bank_pos pos_keep30  30       # LUT[30]=30 == 30   -> keep
bank_pos pos_remap29 29       # LUT[29]=5  != 29   -> CLEAR
bank_pos pos_keep12  12       # LUT[12]=12 == 12   -> keep

# ============================== FUN_0058eca0 (engage-target) ==============================
# Reads: P0 +0x40/+0x44/+0x48/+0x4c/+0x54/+0x80 ; P1 +0x54(0x230410)/+0x58(0x230414) ;
#        M +0x458(0x210458)/+0x460(0x210460)/+0x43c(0x21043c).
ENG_READS="0x00230040:4 0x00230044:4 0x00230048:4 0x0023004c:4 0x00230054:4 0x00230080:4 0x00230410:4 0x00230414:4 0x00210458:4 0x00210460:4 0x0021043c:4"
bank_eng() {
  local name=$1 target=$2 pokes=$3 line
  emit_spec 0x0058eca0 "$target" "$pokes" "$ENG_READS"
  run_emu
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  printf 'FIX %s fn=58eca0 p40=%s p44=%s p48=%s p4c=%s p54=%s p80=%s t54=%s t58=%s m458=%s m460=%s m43c=%s\n' \
    "$name" \
    "$(mval "$line" 0x230040)" "$(mval "$line" 0x230044)" "$(mval "$line" 0x230048)" \
    "$(mval "$line" 0x23004c)" "$(mval "$line" 0x230054)" "$(mval "$line" 0x230080)" \
    "$(mval "$line" 0x230410)" "$(mval "$line" 0x230414)" \
    "$(mval "$line" 0x210458)" "$(mval "$line" 0x210460)" "$(mval "$line" 0x21043c)" >> "$OUT"
  echo "[$name] $(retof "$line") p40=$(mval "$line" 0x230040) m458=$(mval "$line" 0x210458) m43c=$(mval "$line" 0x21043c)"
}

# Common preset for the "engage happens" fixtures: P0+0x1d4 -> match; P0+0x40 = null(0, differs
# from target); P0+0x54 = 99 (team tag, != target team 7); P0+0x4c=0x3333; P0+0x80 = 5;
# P1+0x2b8(team)=7 (addr 0x230674); P1+0x54/+0x58 = 0xAAAA/0xBBBB; M+0x458 = 10; M+0x460 = 1.
# m43c set per-fixture. target = P1 = 0x002303bc.
ENG_BASE="mem 0x002301d4 4 0x00210000
mem 0x00230040 4 0x0
mem 0x00230054 4 0x63
mem 0x0023004c 4 0x3333
mem 0x00230080 4 0x5
mem 0x00230674 4 0x7
mem 0x00230410 4 0xAAAA
mem 0x00230414 4 0xBBBB
mem 0x00210458 4 0xA
mem 0x00210460 4 0x1
mem 0x00210448 4 0x0"

# engage_new: phase 0, taker (m43c) = P0 (a DIFFERENT ptr) -> stale-taker clear fires.
bank_eng engage_new 0x002303bc "$ENG_BASE
mem 0x0021043c 4 0x00230000"
# engage_sameteam: P0+0x54 already == target team 7 -> m458 NOT incremented (stays 10).
bank_eng engage_sameteam 0x002303bc "$ENG_BASE
mem 0x00230054 4 0x7
mem 0x0021043c 4 0x00230000"
# engage_takereq: m43c == target -> stale-taker NOT cleared (m460 stays 1, m43c stays target).
bank_eng engage_takereq 0x002303bc "$ENG_BASE
mem 0x0021043c 4 0x002303bc"
# engage_phase: match+0x448 != 0 (not open play) -> stale-taker NOT cleared.
bank_eng engage_phase 0x002303bc "$ENG_BASE
mem 0x00210448 4 0x2
mem 0x0021043c 4 0x00230000"
# engage_same: P0+0x40 already == target -> whole body skipped (pure no-op).
bank_eng engage_same 0x002303bc "mem 0x002301d4 4 0x00210000
mem 0x00230040 4 0x002303bc
mem 0x00230044 4 0x002303bc
mem 0x00230048 4 0x002303bc
mem 0x00230054 4 0x63
mem 0x0023004c 4 0x3333
mem 0x00230080 4 0x5
mem 0x00230674 4 0x7
mem 0x00230410 4 0xAAAA
mem 0x00230414 4 0xBBBB
mem 0x00210458 4 0xA
mem 0x00210460 4 0x1
mem 0x00210448 4 0x0
mem 0x0021043c 4 0x00230000"
# engage_null: target = 0 (null). P0+0x40 = a real target (differs) -> +0x40/+0x4c set, rest
# of the body skipped (p44/p48 keep preset, t54/t58/counter/m* unchanged).
bank_eng engage_null 0x0 "mem 0x002301d4 4 0x00210000
mem 0x00230040 4 0x002303bc
mem 0x00230044 4 0x002303bc
mem 0x00230048 4 0x002303bc
mem 0x00230054 4 0x63
mem 0x0023004c 4 0x3333
mem 0x00230080 4 0x5
mem 0x00230674 4 0x7
mem 0x00230410 4 0xAAAA
mem 0x00230414 4 0xBBBB
mem 0x00210458 4 0xA
mem 0x00210460 4 0x1
mem 0x00210448 4 0x0
mem 0x0021043c 4 0x00230000"

echo "=== decideset oracle -> $OUT ==="
cat "$OUT"
