#!/usr/bin/env bash
# Stage 3 task 2 (STATISTICAL engine, leaf oracle): drive the REAL chance/goal
# resolver FUN_0044ece0 through the Ghidra PCode emulator and bank the exact
# event it emits. Ground truth that Pm98StatMatch.resolve_chance must reproduce
# bit-for-bit (app/tests/test_statresolve_oracle.gd).
#
# FUN_0044ece0 is the heart of PM98's "instant result" / AI-vs-AI match engine
# (the PS==5 branch of the career-match runner FUN_0044ee70, lines 357-792):
#   __thiscall this=ECX=match M, arg0=side (attacking 0/1), arg1=seg, arg2=minute.
#   1. KEEPER GATE: read the DEFENDING side's keeper (player[0]). Defender base =
#      (side==0)*0x7a0 + M. If keeper is in the XI (+0x88 != 0) AND rand()%130 <
#      keeper_save_byte(+0xc0)  ->  SAVE, no event, return. (selected==0 keeper
#      can't save -> always a chance.)
#   2. SCORER ROULETTE: attacking base = side*0x7a0 + M. Sum position weights
#      DAT_006532ec[player[i].posCode(+0xc8)] over the 11 players (GK weight 0).
#      Roll rand()%total, walk players[1..10] (GK excluded) accumulating weight;
#      first player past the threshold that is AVAILABLE (booking slots +0xd4/+0xd8
#      not both set AND no pending shot +0xdc) is the scorer. Re-roll if none.
#   3. EMIT: FUN_004510b0(this=M, type=seg, minute, 0, (scorerShirt<<16)|teamId).
#      teamId = *(short*)(attacking_base + 0x7e8).
#
# Emulation wrinkles:
#   * rand() = msvcrt import via `call ds:0x6233b0`. We INJECT a faithful MSVC LCG
#     thunk (state*0x343FD + 0x269EC3; return (state>>16)&0x7FFF) at 0x257010 with
#     the seed word at 0x257000, and repoint the IAT slot -- exactly the same idiom
#     as run_playerbuild's _ftol injection. The GDScript port runs the IDENTICAL
#     LCG from the identical seed, so the rand stream (and thus scorer) matches.
#     We `trace 0x257010` to count the draws each call consumes.
#   * FUN_004510b0 (event append) calls FUN_005bbf10 to GROW the event vector. We
#     pre-size the vector ourselves (M+0xf98 -> a zeroed 0x400 buffer, M+0xf9c=0)
#     and STUB FUN_005bbf10 (cdecl/2) to a no-op, so the 16-byte record lands in
#     our buffer and we read it straight back. No heap alloc in the emu.
#
# Memory map (all reads of the position LUT @0x6532ec hit the real mapped .data):
#   match M@0x210000 (zero 0x4000)   event buf@0x258000 (zero 0x400)
#   rand seed@0x257000  rand thunk@0x257010  rand IAT slot 0x6233b0
#
# PcodeEmu PARSING GOTCHA: `mem <addr> <size> <val>` and `arg <val>` both parse the
# VALUE as HEX (hexVal), and PcodeEmu reads ONE directive per line. So every poke is
# emitted one-per-line with hex values (decimal 11 would silently become 0x11 = 17,
# which here indexes past the 19-entry weight LUT into garbage and blows up the total).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/statresolve_oracle.txt
SPEC=$SPECDIR/_statresolve_run.spec
ROUT=$SPECDIR/_statresolve_run.out

M=0x210000
SEEDADDR=0x257000
THUNK=0x257010
BUF=0x258000

# MSVC rand() LCG thunk, seed word @0x257000:
#   A1 00702500          mov  eax,[0x257000]
#   69 C0 FD430300       imul eax,eax,0x343FD
#   05 C39E2600          add  eax,0x269EC3
#   A3 00702500          mov  [0x257000],eax
#   C1 E8 10             shr  eax,16
#   25 FF7F0000          and  eax,0x7FFF
#   C3                   ret
RAND_THUNK=A10070250069C0FD43030005C39E2600A300702500C1E81025FF7F0000C3

# Readback: event count + the 16-byte record {type, minute, p4, payload}, plus the
# final seed state (to know how many draws were consumed).
READS=(
  "0x210f9c 4"   # event count (1 if a goal/event emitted, 0 if keeper saved)
  "0x258000 4"   # record[0] = type (= seg arg)
  "0x258004 4"   # record[1] = minute (+ case offset from type)
  "0x258008 4"   # record[2] = p4 (0)
  "0x25800c 4"   # record[3] = payload = (scorerShirt<<16)|teamId
  "0x257000 4"   # final LCG state
)

# Build one XI at side base $1 with team id $2: shirts 1..11 at +0x88, position
# codes at +0xc8. posCodes span the weight LUT (GK slot=1->w0; striker slots 9->w35).
#   players 0..10 posCode = 1 2 3 5 7 9 11 13 16 9 12
#   weights (players 1..10, GK excluded) = 3 3 7 12 35 12 18 18 35 15  (total 158)
# NOTE: PcodeEmu reads ONE directive per line and parses the `mem` VALUE as HEX
# (hexVal), so emit one poke per line with hex-encoded values (decimal 11 != 0x11).
build_xi() {
  local sbase=$1 tid=$2
  local POS=(1 2 3 5 7 9 11 13 16 9 12)
  for i in $(seq 0 10); do
    local base=$(( sbase + i*0xac ))
    printf 'mem 0x%x 2 0x%x\n' $((base+0x88)) $((i+1))      # shirt 1..11 (selected)
    printf 'mem 0x%x 4 0x%x\n' $((base+0xc8)) ${POS[$i]}    # position code
  done
  printf 'mem 0x%x 2 0x%x\n' $((sbase+0x7e8)) $tid          # team id
}

emit_spec() {
  # $1 seed  $2 side  $3 seg  $4 minute  $5 keeper_rating  $6 extra pokes
  # Defender = (side==0)*0x7a0 + M, player[0]. Set BOTH keepers' save byte (+0xc0)
  # to the fixture value; only the defender's is consulted.
  local s0=$(( 0x210000 ))
  local s1=$(( 0x210000 + 0x7a0 ))
  cat > "$SPEC" <<EOF
entry   0x44ece0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
arg     $2
arg     $3
arg     $4
zero    0x00210000 0x00004000
zero    0x00257000 0x00001000
zero    0x00258000 0x00000400
membts  $THUNK $RAND_THUNK
mem     $SEEDADDR 4 $1
mem     0x006233b0 4 $THUNK
stub    0x005bbf10 0 0
mem     0x00210f98 4 $BUF
mem     0x00210f9c 4 0x0
$(build_xi $s0 0x0007)
$(build_xi $s1 0x0013)
mem     $(printf 0x%x $((s0+0xc0))) 1 $5
mem     $(printf 0x%x $((s1+0xc0))) 1 $5
$6
EOF
  { echo "maxsteps 4000000"; echo "trace $THUNK rand";
    for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

# Fixtures: name | seed | side | seg | minute(HEX) | keeper | extra
# IMPORTANT: PcodeEmu parses `arg`/`mem` VALUES as HEX, so the minute column is hex
# (0x14 = decimal 20). The GDScript test mirrors the DECIMAL equivalents.
# Small seeds give small first draws (always under the save threshold); the goal
# fixtures use larger seeds so the keeper gate passes and the scorer roulette runs.
# seg 0..3 exercise FUN_004510b0's per-period minute offset (case1+0x2d/2+0x5a/3+0x69).
# Defender keeper +0x88: side0 attacks -> s1 GK @0x210828; gk_out clears it (no save).
FIX=(
  "goal_seg0_sh5|0x00001007|0|0|0x07|0x28|"
  "goal_seg1_sh9|0x00001015|0|1|0x14|0x28|"
  "goal_seg2_sh11|0x0000101c|0|2|0x21|0x28|"
  "goal_seg3_sh7|0x0000103f|0|3|0x0b|0x28|"
  "save_keep40|0x00000001|0|0|0x07|0x28|"
  "lowkeep_goal6|0x0000100e|0|0|0x05|0x03|"
  "side1_goal_sh5|0x00001007|1|0|0x16|0x28|"
  "gkout_goal_sh2|0x00000003|0|0|0x09|0x28|mem 0x00210828 2 0x0"
)

: > "$OUT"
echo "# Stage 3 task 2 STATISTICAL leaf: chance/goal resolver FUN_0044ece0 ground truth" >> "$OUT"
echo "# (PCode emu; injected MSVC-LCG rand @0x257010; FUN_005bbf10 stubbed; M=$M)." >> "$OUT"
echo "# cols: name | RET draws | count type minute p4 payload finalstate" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME SEED SIDE SEG MIN KEEP EXTRA <<<"$row"
  emit_spec "$SEED" "$SIDE" "$SEG" "$MIN" "$KEEP" "$EXTRA"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  DRAWS=$(echo "$S" | grep -oE 'tracehits=\{rand=[0-9]+\}' | grep -oE '[0-9]+' || echo 0)
  vals=""
  for r in "${READS[@]}"; do a=${r%% *}; vals+="$(mval "$S" "$a") "; done
  printf 'FIX %-14s %-4s draws=%-2s | %s\n' "$NAME" "${RET:-?}" "${DRAWS:-?}" "$vals" >> "$OUT"
  echo "[$NAME] ${RET:-?} draws=${DRAWS:-?} cnt=$(mval "$S" 0x210f9c) payload=$(mval "$S" 0x25800c)"
done
echo "=== statresolve oracle -> $OUT ==="
cat "$OUT"
