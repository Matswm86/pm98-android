#!/usr/bin/env bash
# Stage 3 task 2 (STATISTICAL engine, END-TO-END oracle): drive the REAL career-match
# runner FUN_0044ee70 (the PS==5 statistical / instant-result branch, lines 357-792)
# through the Ghidra PCode emulator for a full LEAGUE fixture and bank the COMPLETE
# event queue + final score + rand draw count + final LCG state. This is the ground
# truth Pm98StatMatch.simulate() must reproduce bit-for-bit
# (app/tests/test_statmatch_oracle.gd).
#
# HOW THE FULL FUNCTION IS RUN. We enter at the real function entry 0x44ee70 and let
# the preamble (lines 42-50) run, then SKIP the entire positional/UI block (lines
# 51-356) by zeroing the global gate DAT_00652a10 -- so control falls straight into
# the statistical engine at line 357. The engine then runs for real: the chance-count
# rand loops, the validated resolver FUN_0044ece0 (goals), the buildup markers
# FUN_0044ec00/ea40, and the stats accumulator FUN_00450510, all emitting into the
# event vector via FUN_004510b0.
#
# STUBS (all UI / no-rand helpers; none touch the scoreline or the rand stream):
#   FUN_0044d5f0 (preamble display)         FUN_0044d0d0/d190/d250/d310/d520 (segment
#   transitions)   FUN_00450e60 (full-time gate, ret 0 -> unused for league)
#   FUN_005bbf10 (event-vector grow; the buffer is pre-sized so records land in it).
# FAKE VTABLE: the buildup markers do a virtual UI call `(*DAT_0066b1e0)->slot(arg)`.
#   DAT_0066c150 := 0 forces the arg-0 path; DAT_0066b1e0 -> a fake object whose
#   vtable slots +0x114/+0x118/+0x11c point at VSTUB (a __thiscall(1) stub). The
#   markers still set their +0xd4/+0xd8/+0xdc fields (which the resolver reads), so
#   scorer availability is faithful.
# DAT_0066afd0 -> a zeroed scratch page so the preamble's *(DAT_0066afd0+0xb4) reads
#   don't fault.
#
# rand() = injected MSVC-LCG thunk + IAT repoint (same as the leaf oracles). LEAGUE =
# extra-time flag M+0x44 == 0 AND penalties flag M+0x48 == 0 (both left zero), so the
# match is H1 + H2 only -- ET / penalties are cup-only and not part of this oracle.
# PcodeEmu GOTCHA: `mem`/`arg` VALUES parse as HEX, one directive per line.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/statmatch_oracle.txt
SPEC=$SPECDIR/_statmatch_run.spec
ROUT=$SPECDIR/_statmatch_run.out

M=0x210000
SEEDADDR=0x257000
THUNK=0x257010
BUF=0x258000
SCRATCH=0x256000      # DAT_0066afd0 target (zeroed)
FOBJ=0x256800
FVT=0x256900
VSTUB=0x259000
RAND_THUNK=A10070250069C0FD43030005C39E2600A300702500C1E81025FF7F0000C3

s0=$(( 0x210000 ))
s1=$(( 0x210000 + 0x7a0 ))
NREC=16               # event records to read back (a league match never reaches this)

# Build one XI at side base $1, team id $2, strength $3 (hex), keeper save $4, pass $5.
build_xi() {
  local sbase=$1 tid=$2 str=$3 ks=$4 pass=$5
  local POS=(1 2 3 5 7 9 11 13 16 9 12)
  for i in $(seq 0 10); do
    local base=$(( sbase + i*0xac ))
    printf 'mem 0x%x 2 0x%x\n' $((base+0x88)) $((i+1))
    printf 'mem 0x%x 4 0x%x\n' $((base+0xc8)) ${POS[$i]}
    printf 'mem 0x%x 1 0x%x\n' $((base+0xbf)) $str
    printf 'mem 0x%x 1 0x%x\n' $((base+0xc2)) $pass
  done
  printf 'mem 0x%x 2 0x%x\n' $((sbase+0x7e8)) $tid
  printf 'mem 0x%x 1 0x%x\n' $((sbase+0xc0)) $ks
  printf 'mem 0x%x 1 0x32\n' $((sbase+0xbb))           # team shape byte
}

READS=( "0x210f9c 4" )                                  # event count
for i in $(seq 0 $((NREC-1))); do
  b=$(( 0x258000 + i*0x10 ))
  READS+=( "$(printf 0x%x $b) 4" "$(printf 0x%x $((b+4))) 4" \
           "$(printf 0x%x $((b+8))) 4" "$(printf 0x%x $((b+12))) 4" )
done
READS+=( "0x257000 4" )                                 # final LCG state

emit_spec() {
  # $1 seed  $2 str0  $3 str1  $4 keeper  $5 pass
  cat > "$SPEC" <<EOF
entry   0x44ee70
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
zero    0x00210000 0x00004000
zero    0x00256000 0x00004000
zero    0x00257000 0x00001000
zero    0x00258000 0x00000400
membts  $THUNK $RAND_THUNK
mem     $SEEDADDR 4 $1
mem     0x006233b0 4 $THUNK
mem     0x00210f98 4 $BUF
mem     0x00210f9c 4 0x0
mem     0x00652a10 4 0x0
mem     0x0066afd0 4 $SCRATCH
mem     0x0066c150 4 0x0
mem     0x0066b1e0 4 $FOBJ
mem     $FOBJ 4 $FVT
mem     $(printf 0x%x $((FVT+0x114))) 4 $VSTUB
mem     $(printf 0x%x $((FVT+0x118))) 4 $VSTUB
mem     $(printf 0x%x $((FVT+0x11c))) 4 $VSTUB
$(build_xi $s0 0x0007 $2 $4 $5)
$(build_xi $s1 0x0013 $3 $4 $5)
mem     0x00210044 4 0x0
mem     0x00210048 4 0x0
stub    0x0044d5f0 0 0
stub    0x0044d0d0 0 0
stub    0x0044d190 0 0
stub    0x0044d250 0 0
stub    0x0044d310 0 0
stub    0x0044d520 0 0
stub    0x00450e60 0 0
stub    0x005bbf10 0 0
stub    $VSTUB 0 4
EOF
  { echo "maxsteps 80000000"; echo "trace $THUNK rand";
    for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

# Fixtures: name | seed | str0 | str1 | keeper | pass
FIX=(
  "league_A|0x12345678|0x46|0x32|0x28|0x40"
  "league_B|0x0abcdef1|0x3c|0x3c|0x28|0x40"
  "league_C|0x00112233|0x50|0x28|0x20|0x44"
  "league_D|0x7eeeeee1|0x32|0x46|0x30|0x38"
)

: > "$OUT"
echo "# Stage 3 task 2 STATISTICAL end-to-end: FUN_0044ee70 PS==5 league fixture ground truth" >> "$OUT"
echo "# (PCode emu; preamble skipped via DAT_00652a10=0; UI helpers stubbed; M=$M)." >> "$OUT"
echo "# Each fixture: RET | draws | count | finalstate | then one 'EV i type minute payload' per event." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME SEED S0 S1 KEEP PASS <<<"$row"
  emit_spec "$SEED" "$S0" "$S1" "$KEEP" "$PASS"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  DRAWS=$(echo "$S" | grep -oE 'tracehits=\{rand=[0-9]+\}' | grep -oE '[0-9]+' || echo 0)
  CNT=$(mval "$S" 0x210f9c)
  STATE=$(mval "$S" 0x257000)
  echo "FIX $NAME seed=$SEED $RET draws=$DRAWS count=$CNT finalstate=$STATE" >> "$OUT"
  declare -A score=()
  for i in $(seq 0 $((NREC-1))); do
    [ "$i" -ge "${CNT:-0}" ] && break
    b=$(( 0x258000 + i*0x10 ))
    T=$(mval "$S" $(printf 0x%x $b)); MIN=$(mval "$S" $(printf 0x%x $((b+4)))); PAY=$(mval "$S" $(printf 0x%x $((b+12))))
    printf '  EV %d type=%s minute=%s payload=0x%x\n' "$i" "$T" "$MIN" "$PAY" >> "$OUT"
    tid=$(( PAY & 0xffff )); score[$tid]=$(( ${score[$tid]:-0} + 1 ))
  done
  echo "  SCORE 7=${score[7]:-0} 19=${score[19]:-0}" >> "$OUT"
  echo "[$NAME] $RET draws=$DRAWS count=$CNT state=$STATE score(7-19)=${score[7]:-0}-${score[19]:-0}"
done
echo "=== statmatch end-to-end oracle -> $OUT ==="
cat "$OUT"
