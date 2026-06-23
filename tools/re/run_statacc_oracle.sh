#!/usr/bin/env bash
# Stage 3 task 2 (STATISTICAL engine, leaf oracle): drive the REAL per-segment
# player-stats accumulator FUN_00450510 through the Ghidra PCode emulator and bank
# (a) the exact number of rand() draws it consumes, (b) the final LCG state, and
# (c) a sample of the per-player stat fields it writes. The Pm98StatMatch port of
# this function MUST reproduce the DRAW COUNT + FINAL STATE bit-for-bit, because
# FUN_00450510 sits between the two halves of FUN_0044ee70 and any drift in its
# rand consumption desyncs the whole second-half scorer stream.
#
# FUN_00450510  __thiscall(this=ECX=match M, duration, p3, p4). Call sites in the
# orchestration are FUN_00450510(0x2d,0,0) (a 45-min half) and (0xf,0,0) (15-min ET).
#   * Bumps team possession at M+0x64 / M+0x804 by rand()*(dur/8)>>15 + dur/40.
#   * Loops over players accumulating "minutes simulated" until >= duration, each
#     iteration a rand()%200 vs the strength byte (+0xbf, halved when role +0xcc==0).
#     STRENGTH BYTES MUST BE NONZERO or the loop never terminates.
#   * Per selected player: rolls passes(+0x108)/tackles(+0x10c)/dribbles(+0x110)/
#     rating(+0x114) from rand() scaled by the pass seed (+0xc2), plus role-2/3
#     "key pass" (+0x104) draws; then a re-roll loop that rolls a per-player counter
#     up to that player's EVENT count (+0xfc, = FUN_00450d20 over the event vector),
#     and a bounded (<=1000) convergence loop with more conditional draws.
#   * So the draw count is HEAVILY data-dependent (strength, role, pass seed, and
#     the events already in M+0xf98). The fixtures vary all of these.
#
# Emulation: same injected MSVC-LCG rand thunk + IAT repoint as the resolver oracle;
# FUN_00450d20 (event counter) runs for real against a pre-filled event vector;
# FUN_005bbf10 is never reached here. M@0x210000, rand seed@0x257000, thunk@0x257010.
# PcodeEmu GOTCHA: `mem`/`arg` VALUES parse as HEX, one directive per line.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/statacc_oracle.txt
SPEC=$SPECDIR/_statacc_run.spec
ROUT=$SPECDIR/_statacc_run.out

M=0x210000
SEEDADDR=0x257000
THUNK=0x257010
BUF=0x258000
RAND_THUNK=A10070250069C0FD43030005C39E2600A300702500C1E81025FF7F0000C3

s0=$(( 0x210000 ))
s1=$(( 0x210000 + 0x7a0 ))

# Build one XI at side base $1: shirts 1..11 (+0x88), pos codes (+0xc8), strength
# (+0xbf, hex), pass/tackle seed (+0xc2, hex). Roles (+0xcc) stay 0 unless EXTRA sets.
build_xi() {
  local sbase=$1 str=$2 pass=$3
  local POS=(1 2 3 5 7 9 11 13 16 9 12)
  for i in $(seq 0 10); do
    local base=$(( sbase + i*0xac ))
    printf 'mem 0x%x 2 0x%x\n' $((base+0x88)) $((i+1))      # shirt 1..11 (selected)
    printf 'mem 0x%x 4 0x%x\n' $((base+0xc8)) ${POS[$i]}    # position code
    printf 'mem 0x%x 1 0x%x\n' $((base+0xbf)) $str          # strength byte
    printf 'mem 0x%x 1 0x%x\n' $((base+0xc2)) $pass         # pass/tackle seed
  done
}

# Capture: per-player stats for side0 p1 / side1 p1, possession, plus team rating
# accumulators. (offsets: +0x104 keypass +0x108 pass +0x10c tackle +0x110 dribble
# +0x114 rating +0x11c bookings +0x120 shot +0x124).
P0=$(( s0 + 1*0xac ))   # side0 player1
P1=$(( s1 + 1*0xac ))   # side1 player1
READS=(
  "0x210064 4"   # team0 possession
  "0x210804 4"   # team1 possession
  "$(printf 0x%x $((P0+0x104))) 4"
  "$(printf 0x%x $((P0+0x108))) 4"
  "$(printf 0x%x $((P0+0x10c))) 4"
  "$(printf 0x%x $((P0+0x110))) 4"
  "$(printf 0x%x $((P0+0x114))) 4"
  "$(printf 0x%x $((P1+0x108))) 4"
  "$(printf 0x%x $((P1+0x114))) 4"
  "0x257000 4"   # final LCG state
)

emit_spec() {
  # $1 seed  $2 dur(hex)  $3 str0  $4 str1  $5 pass  $6 nevents  $7 extra-pokes
  cat > "$SPEC" <<EOF
entry   0x450510
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
arg     $2
arg     0
arg     0
zero    0x00210000 0x00004000
zero    0x00257000 0x00001000
zero    0x00258000 0x00000400
membts  $THUNK $RAND_THUNK
mem     $SEEDADDR 4 $1
mem     0x006233b0 4 $THUNK
mem     0x00210f98 4 $BUF
mem     0x00210f9c 4 $6
$(build_xi $s0 $3 $5)
$(build_xi $s1 $4 $5)
$7
EOF
  { echo "maxsteps 20000000"; echo "trace $THUNK rand";
    for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

# A goal event for shirt $1 on team $2 at minute $3, written at record index $4.
# Pokes are joined with ';;' (expanded to newlines after the FIX-table read, which
# would otherwise truncate a multi-line field at the first newline).
goal_rec() {
  local shirt=$1 team=$2 min=$3 idx=$4
  local b=$(( 0x258000 + idx*0x10 ))
  printf 'mem 0x%x 4 0x0;;mem 0x%x 4 0x%x;;mem 0x%x 4 0x0;;mem 0x%x 4 0x%x' \
    $b $((b+4)) $min $((b+8)) $((b+12)) $(( (shirt<<16) | team ))
}

# Fixtures: name | seed | dur | str0 | str1 | pass | nevents | extra
# A: clean half, no events, no roles/markers. B: same + 3 goal events (re-roll loop).
# C: two role-2 players side1 + a shot marker (+0xdc). D: ET duration 0xf.
EXTRA_C="mem $(printf 0x%x $((s1+1*0xac+0xcc))) 4 0x2;;mem $(printf 0x%x $((s1+9*0xac+0xcc))) 4 0x2;;mem $(printf 0x%x $((s0+5*0xac+0xdc))) 4 0x1;;mem $(printf 0x%x $((s0+5*0xac+0xe8))) 4 0x14"
EVENTS_B="$(goal_rec 6 0x7 27 0);;$(goal_rec 9 0x7 37 1);;$(goal_rec 9 0x13 4 2)"

FIX=(
  "A_clean|0x12345678|0x2d|0x46|0x32|0x40|0x0|"
  "B_events|0x12345678|0x2d|0x46|0x32|0x40|0x3|$EVENTS_B"
  "C_roles|0x0b2050f3|0x2d|0x50|0x3c|0x55|0x0|$EXTRA_C"
  "D_et|0x0009abcd|0xf|0x40|0x40|0x30|0x0|"
)

: > "$OUT"
echo "# Stage 3 task 2 STATISTICAL leaf: per-segment stats accumulator FUN_00450510 ground truth" >> "$OUT"
echo "# (PCode emu; injected MSVC-LCG rand @0x257010; FUN_00450d20 runs real; M=$M)." >> "$OUT"
echo "# cols: name | RET | draws | poss0 poss1 p0.kp p0.pass p0.tkl p0.drb p0.rate p1.pass p1.rate finalstate" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME SEED DUR S0 S1 PASS NEV EXTRA <<<"$row"
  EXTRA="${EXTRA//;;/$'\n'}"                 # expand ';;' joiners back to newlines
  emit_spec "$SEED" "$DUR" "$S0" "$S1" "$PASS" "$NEV" "$EXTRA"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  DRAWS=$(echo "$S" | grep -oE 'tracehits=\{rand=[0-9]+\}' | grep -oE '[0-9]+' || echo 0)
  vals=""
  for r in "${READS[@]}"; do a=${r%% *}; vals+="$(mval "$S" "$a") "; done
  printf 'FIX %-10s %-4s draws=%-4s | %s\n' "$NAME" "${RET:-?}" "${DRAWS:-?}" "$vals" >> "$OUT"
  echo "[$NAME] ${RET:-?} draws=${DRAWS:-?} finalstate=$(mval "$S" 0x257000)"
done
echo "=== statacc oracle -> $OUT ==="
cat "$OUT"
