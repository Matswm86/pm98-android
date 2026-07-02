#!/usr/bin/env bash
# Oracle for the two restart-DECIDE entity methods FUN_00593b70 dispatches per restart:
#   FUN_0058e120 (ball vtable+4 @0x639084): release carrier/owner, zero vel, +0x1d8 flag
#     from session+0x14 / DAT_00674e7c==8, kickoff (match+0x448==2) zeroes the spot
#     +0x90/94/98, pos snaps to the spot, +0x58 = -2.
#   FUN_005a2140 (keeper vtable+4 @0x63920c): zero slide vel, +0x2dc anim re-stamp from
#     match+0x1a5c and the +0x3bc index, pos zero, FUN_005a5430(0x42), then park at the
#     goal: idx1 y=-(m+0x1824)-0x10000 x=(m+0x1820)/2; idx2 y=+(m+0x1824)+0x10000 x=-/2.
# GROUND TRUTH for Pm98Movement.ball_restart_decide / keeper_restart_decide
# (app/tests/test_restartdecide.gd).
#
# Memory: ball B@0x220000 keeper K@0x230000 match M@0x210000 session S@0x260000.
# B+0x1d4 -> M, K+0x18c -> M, M+0x468 -> S. DAT_006d31c4=0 (live).
# FUN_005bbf10 (GlobalAlloc wrapper, emu-uncallable) stubbed no-op as in the collbuilder
# oracle -- the two ring-clear lines are alloc-side and excluded from the readback claims.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/restartdecide_oracle.txt
SPEC=$SPECDIR/_restartdecide_run.spec
ROUT=$SPECDIR/_restartdecide_run.out

B=0x220000 ; K=0x230000 ; M=0x210000 ; S=0x260000

BALL_READS=(
  "0x220004 4" "0x220008 4" "0x22000c 4"                      # pos
  "0x220020 4" "0x220024 4" "0x220028 4"                      # vel
  "0x220040 4" "0x220044 4" "0x220048 4" "0x22004c 4" "0x220050 4"
  "0x220058 4" "0x22005c 4" "0x2201e0 4"
  "0x220061 1" "0x220063 1" "0x220064 1" "0x2201d8 1"
  "0x220090 4" "0x220094 4" "0x220098 4"
)
KEEP_READS=(
  "0x230004 4" "0x230008 4" "0x23000c 4"                      # pos
  "0x2302dc 4" "0x2303c0 4" "0x2303c4 4" "0x2303b4 4"
  "0x230040 4" "0x23002c 4" "0x230030 4"                      # pos code + 5a5430 side effects
)

emit_spec() {
  # $1 = entry  $2 = ECX  $3 = pokes  $4 = reads array name
  local -n reads_ref=$4
  cat > "$SPEC" <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $2
zero    0x00210000 0x00003000
zero    0x00220000 0x00001000
zero    0x00230000 0x00001000
zero    0x00260000 0x00001000
stub    0x005bbf10 0 0
mem 0x006d31c4 1 0x0
mem 0x002201d4 4 $M
mem 0x0023018c 4 $M
mem 0x00210468 4 $S
$3
EOF
  { echo "maxsteps 2000000"; for r in "${reads_ref[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1
}

# Ball pre-state common: dirty owner/vel/pos/flags so every clear is observable.
BALL_DIRTY="mem 0x220004 4 0x111111 ; mem 0x220008 4 0x222222 ; mem 0x22000c 4 0x33333 ; mem 0x220020 4 0x4444 ; mem 0x220024 4 0x5555 ; mem 0x220028 4 0x6666 ; mem 0x220040 4 0x230000 ; mem 0x220044 4 0x230000 ; mem 0x220048 4 0x230000 ; mem 0x22004c 4 0x230000 ; mem 0x220050 4 0x7 ; mem 0x220058 4 0x1 ; mem 0x22005c 4 0x9 ; mem 0x220061 1 0x1 ; mem 0x220063 1 0x1 ; mem 0x220064 1 0x1 ; mem 0x2201d8 1 0x1 ; mem 0x220090 4 0x123400 ; mem 0x220094 4 0x56780 ; mem 0x220098 4 0x9ab0"

FIX_BALL=(
"kickoff_s14z|0x58e120|$B|$BALL_DIRTY ; mem 0x210448 4 0x2 ; mem 0x260014 4 0x0 ; mem 0x674e7c 4 0x1"
"kickoff_s14set|0x58e120|$B|$BALL_DIRTY ; mem 0x210448 4 0x2 ; mem 0x260014 4 0x1 ; mem 0x674e7c 4 0x1"
"kickoff_mode8|0x58e120|$B|$BALL_DIRTY ; mem 0x210448 4 0x2 ; mem 0x260014 4 0x1 ; mem 0x674e7c 4 0x8"
"phase0_spot|0x58e120|$B|$BALL_DIRTY ; mem 0x210448 4 0x0 ; mem 0x260014 4 0x0 ; mem 0x674e7c 4 0x1"
)

KEEP_BASE="mem 0x211a5c 4 0x30 ; mem 0x211820 4 0x2a0001 ; mem 0x211824 4 0x150000 ; mem 0x2303c0 4 0x999 ; mem 0x2303c4 4 0x888 ; mem 0x230004 4 0x1111 ; mem 0x230008 4 0x2222 ; mem 0x23000c 4 0x3333 ; mem 0x23002c 4 0x5 ; mem 0x230030 4 0x6"

FIX_KEEP=(
"idx1|0x5a2140|$K|$KEEP_BASE ; mem 0x2303bc 4 0x1"
"idx2|0x5a2140|$K|$KEEP_BASE ; mem 0x2303bc 4 0x2"
"idx1_a5c|0x5a2140|$K|$KEEP_BASE ; mem 0x2303bc 4 0x1 ; mem 0x211a5c 4 0x1234"
)

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

: > "$OUT"
echo "# restart-decide ground truth (PCode emu, live DAT_006d31c4=0; 5bbf10 stubbed)." >> "$OUT"
echo "# Each row: BALL|KEEP <name> + verbatim CALL line (mem[addr:w]=val, ball@0x220000," >> "$OUT"
echo "# keeper@0x230000). Ball reads: pos/vel/owner block/+0x58/+0x5c/+0x1e0/bytes/spot;" >> "$OUT"
echo "# keeper reads: pos, +0x2dc/+0x3c0/+0x3c4/+0x3b4, +0x40/+0x2c/+0x30." >> "$OUT"
for row in "${FIX_BALL[@]}"; do
  IFS='|' read -r NAME ENTRY ECX POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$ENTRY" "$ECX" "$POKES" BALL_READS
  S_LINE=$(run_emu)
  echo "BALL $NAME $S_LINE" >> "$OUT"
  echo "[ball:$NAME] $(echo "$S_LINE" | grep -oE 'CALL 0 (RET|HALT)' || echo '?')"
done
for row in "${FIX_KEEP[@]}"; do
  IFS='|' read -r NAME ENTRY ECX POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$ENTRY" "$ECX" "$POKES" KEEP_READS
  S_LINE=$(run_emu)
  echo "KEEP $NAME $S_LINE" >> "$OUT"
  echo "[keep:$NAME] $(echo "$S_LINE" | grep -oE 'CALL 0 (RET|HALT)' || echo '?')"
done
echo "=== restartdecide oracle -> $OUT ==="
cat "$OUT"
