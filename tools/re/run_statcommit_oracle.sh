#!/usr/bin/env bash
# Season/match stat COMMIT oracle: drive the REAL FUN_0044e440 (the accumulator the
# period-transition handlers call) through the Ghidra PCode emulator and bank every
# byte it writes into the fixture report object DAT_0066afd0.
#
# Why: FUN_0044e440 is the ONLY writer of the 0x48-byte per-player stat records that
# the STATISTICS screen (FUN_00449b50 getter @0x4fcf4c/0x4fd801) and the transfer
# price ladder (FUN_005849a0 @0x57b2e8/0x57b3a9) read. Until this is banked, the port
# has no honest source for MP / MIN / RATING / MoM / G. / SHOTS / PASSES / TAC. / S.
# See docs/re/season_stats_re.md.
#
# FUN_0044e440  __thiscall(this=ECX=match M). No stack args. Structure:
#   1. header copy: M+0x64/+0x804 possession -> F+0x18/+0x1a (u16);
#      M+0x3c/+0x40 -> F+0xb4/+0xb8;  M+0x28 -> F+0x30 (dw);
#      M+0x2c/0x30/0x34/0x38 -> F+0x34/0x35/0x36/0x37 (bytes);
#      M+0x1c/0x20/0x24 -> F+0x40/+0x48/+0x50 (dw). Then FUN_00449960(F) drops the
#      old event list (F+0x60/+0x64) and zeroes the 6 scoreline counters.
#   2. event loop over the M+0xf98 vector (0x10-byte {type,minute,p4,payload}):
#      jump table 0x44ea18 routes type 0..4 to the counter blocks; table 0x44ea2c
#      maps type -> report code (0..4 -> 1..5). p4 != 0 flips the credited side
#      (own goal). Each event is then handed to FUN_004497f0 (event-list rebuild).
#   3. per-player commit, both sides x 11: if M+0x7a0*s+0xac*p+0x88 (the PLAYER ID)
#      is nonzero, set player+0xec = 1 and push the 0x44 bytes at player+0xec..+0x12f
#      plus that id as a 0x48-byte record into FUN_00449990 (home, F+0x9c/+0xa0) or
#      FUN_00449a70 (away, F+0xa4/+0xa8) -- find-by-id-else-append, then OVERWRITE.
#      Then zero player+0xec..+0x12f. Then append assist (+0xd4/+0xd8, minutes
#      +0xe0/+0xe4) and shot (+0xdc, minute +0xe8) markers to the 0xc-stride vector
#      at F+0x94/+0x98.
#   4. tail: for every selected player, clamp byte player+0xb8 to 0x63 and store it
#      into the GLOBAL player object (table DAT_0066c158, count DAT_0066c150) at
#      playerobj+0xa8.
#
# Emulation: F is a synthetic report object at 0x220000 with pre-sized record
# buffers, so FUN_005bbf10 (the vector realloc, cdecl -> stub pops 0 arg bytes) never
# has to allocate. FUN_004497f0 (stdcall ret 8) is STUBBED: it rebuilds the fixture's
# display event list through the CRT allocator (FUN_004496c0 -> 0x605a70/0x605a76),
# which is out of scope here; the stub still logs call ORDER + count so the per-event
# dispatch stays observable, and every scoreline counter it feeds is computed inline
# by FUN_0044e440 itself BEFORE the call, so nothing measured here is stubbed away.
# PcodeEmu GOTCHA: `mem`/`arg` VALUES parse as HEX, `read_mem` size is DECIMAL, one
# directive per line.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/statcommit_oracle.txt
SPEC=$SPECDIR/_statcommit_run.spec
ROUT=$SPECDIR/_statcommit_run.out

M=0x210000          # match object
F=0x220000          # report object -> DAT_0066afd0
HOMEBUF=0x230000    # F+0x9c  record array (0x48 stride)
AWAYBUF=0x231000    # F+0xa4  record array
EVBUF=0x232000      # F+0x94  0xc-stride assist/shot vector
PTAB=0x234000       # DAT_0066c158 global player pointer table
POBJ=0x235000       # fake player objects, id -> POBJ + id*0x100
EVTS=0x236000       # M+0xf98 match event vector

HOME_CLUB=0x28      # 40
AWAY_CLUB=0x11      # 17

# ---- side/player helpers -----------------------------------------------------
# side base = M + 0x7a0*s ; player base = side + 0xac*p
pbase() { printf '0x%x' $(( 0x210000 + $1*0x7a0 + $2*0xac )); }

# Fill one side: player ids (arg2 = space-separated 11 ids, 0 = not selected) and a
# unique sentinel dword in every slot of the 0x44-byte commit block +0xec..+0x12f,
# so the banked record proves the field-by-field provenance.
build_side() {
  local s=$1; shift
  local ids=("$@")
  local p k b v
  for p in $(seq 0 10); do
    b=$(pbase "$s" "$p")
    printf 'mem 0x%x 2 0x%x\n' $((b+0x88)) "${ids[$p]}"     # player id (selection key)
    printf 'mem 0x%x 1 0x%x\n' $((b+0xb8)) $(( s==0 && p==0 ? 0xff : 0x40 + s*0x20 + p ))
    for k in $(seq 0 16); do                                 # +0xec .. +0x12c, 17 dwords
      v=$(( 0x10000*(s+1) + 0x100*(p+1) + 4*k ))
      printf 'mem 0x%x 4 0x%x\n' $((b+0xec+4*k)) $v
    done
  done
}

# Global player table: id -> POBJ + id*0x100 for every id we use.
build_ptab() {
  local id
  for id in "$@"; do
    [ "$id" = 0 ] && continue
    printf 'mem 0x%x 4 0x%x\n' $((PTAB+4*id)) $((POBJ+id*0x100))
  done
}

# A match event record at index $5: type minute p4 team shirt
evt() {
  local idx=$1 type=$2 min=$3 p4=$4 team=$5 shirt=$6
  local b=$(( EVTS + idx*0x10 ))
  printf 'mem 0x%x 4 0x%x;;mem 0x%x 4 0x%x;;mem 0x%x 4 0x%x;;mem 0x%x 4 0x%x' \
    $b "$type" $((b+4)) "$min" $((b+8)) "$p4" $((b+12)) $(( (shirt<<16) | team ))
}

# ---- capture set -------------------------------------------------------------
R0=$(( 0x230000 ))            # home record 0
R1=$(( 0x230000 + 0x48 ))     # home record 1
RL=$(( 0x230000 + 10*0x48 ))  # home record 10
A0=$(( 0x231000 ))            # away record 0
E0=$(( 0x232000 ))            # 0xc-vector record 0
E1=$(( 0x232000 + 0xc ))
E2=$(( 0x232000 + 0x18 ))
E3=$(( 0x232000 + 0x24 ))

READS=(
  "0x2200a0 4"  "0x2200a8 4"  "0x220098 4"          # home count / away count / evvec count
  "$(printf 0x%x $((R0+0x00))) 4" "$(printf 0x%x $((R0+0x04))) 4"
  "$(printf 0x%x $((R0+0x08))) 4" "$(printf 0x%x $((R0+0x0c))) 4"
  "$(printf 0x%x $((R0+0x10))) 4" "$(printf 0x%x $((R0+0x14))) 4"
  "$(printf 0x%x $((R0+0x18))) 4" "$(printf 0x%x $((R0+0x1c))) 4"
  "$(printf 0x%x $((R0+0x20))) 4" "$(printf 0x%x $((R0+0x24))) 4"
  "$(printf 0x%x $((R0+0x28))) 4" "$(printf 0x%x $((R0+0x2c))) 4"
  "$(printf 0x%x $((R0+0x30))) 4" "$(printf 0x%x $((R0+0x34))) 4"
  "$(printf 0x%x $((R0+0x38))) 4" "$(printf 0x%x $((R0+0x3c))) 4"
  "$(printf 0x%x $((R0+0x40))) 4" "$(printf 0x%x $((R0+0x44))) 2"
  "$(printf 0x%x $((R0+0x46))) 2"
  "$(printf 0x%x $((R1+0x00))) 4" "$(printf 0x%x $((R1+0x10))) 4"
  "$(printf 0x%x $((R1+0x44))) 2"
  "$(printf 0x%x $((RL+0x00))) 4" "$(printf 0x%x $((RL+0x44))) 2"
  "$(printf 0x%x $((A0+0x00))) 4" "$(printf 0x%x $((A0+0x18))) 4"
  "$(printf 0x%x $((A0+0x44))) 2"
  "0x22003c 1" "0x22003d 1" "0x22004c 1" "0x22004d 1" "0x220054 1" "0x220055 1"
  "0x220018 2" "0x22001a 2"
  "0x220030 4" "0x220034 1" "0x220035 1" "0x220036 1" "0x220037 1"
  "0x220040 4" "0x220048 4" "0x220050 4" "0x2200b4 4" "0x2200b8 4"
  "0x2100ec 4" "0x210104 4" "0x21012c 4"          # side0 p0 block after commit
  "0x2101d0 4"                                     # side0 p1 +0x124 (0xac+0xec+0x38)
  "$(printf 0x%x $((POBJ+1*0x100+0xa8))) 1"        # id 1  condition write-back (clamp)
  "$(printf 0x%x $((POBJ+2*0x100+0xa8))) 1"        # id 2
  "$(printf 0x%x $((POBJ+21*0x100+0xa8))) 1"       # id 21
  "$(printf 0x%x $((E0+0x00))) 4" "$(printf 0x%x $((E0+0x04))) 4"
  "$(printf 0x%x $((E0+0x08))) 4"
  "$(printf 0x%x $((E1+0x00))) 4" "$(printf 0x%x $((E1+0x04))) 4"
  "$(printf 0x%x $((E1+0x08))) 4"
  "$(printf 0x%x $((E2+0x00))) 4" "$(printf 0x%x $((E2+0x04))) 4"
  "$(printf 0x%x $((E2+0x08))) 4"
  "$(printf 0x%x $((E3+0x00))) 4" "$(printf 0x%x $((E3+0x04))) 4"
  "$(printf 0x%x $((E3+0x08))) 4"
)

emit_spec() {
  # $1 nevents  $2 event pokes  $3 extra pokes  $4 home ids  $5 away ids
  local -a hids aids
  read -r -a hids <<<"$4"
  read -r -a aids <<<"$5"
  cat > "$SPEC" <<EOF
entry   0x44e440
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
zero    0x00210000 0x00004000
zero    0x00220000 0x00001000
zero    0x00230000 0x00001000
zero    0x00231000 0x00001000
zero    0x00232000 0x00001000
zero    0x00234000 0x00001000
zero    0x00235000 0x00004000
zero    0x00236000 0x00001000
mem     0x0066afd0 4 $F
mem     0x0066c150 4 0x20
mem     0x0066c158 4 $PTAB
mem     0x00220038 2 $HOME_CLUB
mem     0x0022003a 2 $AWAY_CLUB
mem     0x0022009c 4 $HOMEBUF
mem     0x002200a4 4 $AWAYBUF
mem     0x00220094 4 $EVBUF
mem     0x00210f98 4 $EVTS
mem     0x00210f9c 4 $1
mem     0x00210064 2 0x39
mem     0x00210804 2 0x27
mem     0x002107e8 2 $HOME_CLUB
mem     0x00210f88 2 $AWAY_CLUB
mem     0x0021001c 4 0x1111
mem     0x00210020 4 0x2222
mem     0x00210024 4 0x3333
mem     0x00210028 4 0x4444
mem     0x0021002c 1 0x55
mem     0x00210030 1 0x66
mem     0x00210034 1 0x77
mem     0x00210038 1 0x88
mem     0x0021003c 4 0x9999
mem     0x00210040 4 0xaaaa
$(build_side 0 "${hids[@]}")
$(build_side 1 "${aids[@]}")
$(build_ptab "${hids[@]}" "${aids[@]}")
$2
$3
EOF
  {
    echo "maxsteps 20000000"
    echo "stub 0x5bbf10 0 0 vecrealloc"
    echo "stub 0x4497f0 0 8 evtappend"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } >> "$SPEC"
}

run_emu() {
  # analyzeHeadless occasionally comes back with an empty result (project lock churn
  # from the previous invocation); retry rather than die mid-sweep.
  local try
  for try in 1 2 3; do
    : > "$ROUT"
    "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
      -scriptPath tools/re/ghidra_scripts \
      -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
    grep -qE 'CALL 0 (RET|HALT)' "$ROUT" && return 0
    echo "  (retry $try: empty emulator result)" >&2
    sleep 5
  done
  return 0
}
mval() { local v; v=$(echo "$1" | grep -oE "mem\[$2:[0-9]+\]=[0-9-]+" | head -1 | cut -d= -f2 || true); echo "${v:-0}"; }

HOME_IDS="1 2 3 4 5 6 7 8 9 10 11"
AWAY_IDS="21 22 23 24 25 26 27 28 29 30 31"

# fixture C events: home goal / home own-goal / away ET1 goal / type-4 home / away ET2
EV_C="$(evt 0 0 27 0 $HOME_CLUB 6);;$(evt 1 1 12 1 $HOME_CLUB 9);;$(evt 2 2 5 0 $AWAY_CLUB 4);;$(evt 3 4 33 0 $HOME_CLUB 2);;$(evt 4 3 8 0 $AWAY_CLUB 7)"

# fixture D markers: side0 p0 two assists + a shot; side1 p0 a shot only
P00=$(pbase 0 0); P10=$(pbase 1 0)
EX_D="mem $(printf 0x%x $((P00+0xd4))) 4 0x1;;mem $(printf 0x%x $((P00+0xe0))) 4 0xc"
EX_D="$EX_D;;mem $(printf 0x%x $((P00+0xd8))) 4 0x1;;mem $(printf 0x%x $((P00+0xe4))) 4 0x1e"
EX_D="$EX_D;;mem $(printf 0x%x $((P00+0xdc))) 4 0x1;;mem $(printf 0x%x $((P00+0xe8))) 4 0x2a"
EX_D="$EX_D;;mem $(printf 0x%x $((P10+0xdc))) 4 0x1;;mem $(printf 0x%x $((P10+0xe8))) 4 0x11"

# name | nevents | eventpokes | extrapokes | home ids | away ids
FIX=(
  "A_clean|0x0|||$HOME_IDS|$AWAY_IDS"
  "B_partial|0x0|||1 2 0 0 5 6 7 8 9 10 11|21 22 23 24 25 26 27 28 29 30 0"
  "C_events|0x5|$EV_C||$HOME_IDS|$AWAY_IDS"
  "D_markers|0x0||$EX_D|$HOME_IDS|$AWAY_IDS"
  "E_duppid|0x0|||1 2 3 4 5 6 7 3 9 10 11|$AWAY_IDS"
)

: > "$OUT"
{
  echo "# FUN_0044e440 stat-COMMIT ground truth (PCode emu; PcodeEmu.java)."
  echo "# M=$M report F=$F(DAT_0066afd0) home recs=$HOMEBUF away recs=$AWAYBUF evvec=$EVBUF"
  echo "# Player commit block = player+0xec..+0x12f seeded with sentinel dwords"
  echo "#   value(side s, player p, dword k) = 0x10000*(s+1) + 0x100*(p+1) + 4*k"
  echo "# so record+K == 0x10000*(s+1)+0x100*(p+1)+K proves a straight field copy."
  echo "# FUN_005bbf10 + FUN_004497f0 stubbed (see header); stubhits show call counts."
} >> "$OUT"

for row in "${FIX[@]}"; do
  IFS='|' read -r NAME NEV EVP EXP HIDS AIDS <<<"$row"
  EVP="${EVP//;;/$'\n'}"
  EXP="${EXP//;;/$'\n'}"
  emit_spec "$NEV" "$EVP" "$EXP" "$HIDS" "$AIDS"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  HITS=$(echo "$S" | grep -oE 'stubhits=\{[^}]*\}' || echo "stubhits={}")
  {
    echo
    echo "=== FIX $NAME  ${RET:-?}  $HITS"
    printf '  counts        home=%s away=%s evvec=%s\n' \
      "$(mval "$S" 0x2200a0)" "$(mval "$S" 0x2200a8)" "$(mval "$S" 0x220098)"
    printf '  home rec0     '
    for k in 00 04 08 0c 10 14 18 1c 20 24 28 2c 30 34 38 3c 40; do
      printf '+0x%s=%s ' "$k" "$(printf '0x%x' $(mval "$S" $(printf 0x%x $((R0+0x$k)))))"
    done
    printf '\n  home rec0     +0x44(pid)=%s +0x46(pad)=%s\n' \
      "$(mval "$S" $(printf 0x%x $((R0+0x44))))" "$(mval "$S" $(printf 0x%x $((R0+0x46))))"
    printf '  home rec1     +0x00=%s +0x10=0x%x pid=%s\n' \
      "$(mval "$S" $(printf 0x%x $((R1+0x00))))" \
      "$(mval "$S" $(printf 0x%x $((R1+0x10))))" \
      "$(mval "$S" $(printf 0x%x $((R1+0x44))))"
    printf '  home rec10    +0x00=%s pid=%s\n' \
      "$(mval "$S" $(printf 0x%x $((RL+0x00))))" "$(mval "$S" $(printf 0x%x $((RL+0x44))))"
    printf '  away rec0     +0x00=%s +0x18=0x%x pid=%s\n' \
      "$(mval "$S" $(printf 0x%x $((A0+0x00))))" \
      "$(mval "$S" $(printf 0x%x $((A0+0x18))))" \
      "$(mval "$S" $(printf 0x%x $((A0+0x44))))"
    printf '  scoreline     +0x3c=%s +0x3d=%s +0x4c=%s +0x4d=%s +0x54=%s +0x55=%s\n' \
      "$(mval "$S" 0x22003c)" "$(mval "$S" 0x22003d)" "$(mval "$S" 0x22004c)" \
      "$(mval "$S" 0x22004d)" "$(mval "$S" 0x220054)" "$(mval "$S" 0x220055)"
    printf '  header        +0x18=%s +0x1a=%s +0x30=0x%x +0x34=%s +0x35=%s +0x36=%s +0x37=%s\n' \
      "$(mval "$S" 0x220018)" "$(mval "$S" 0x22001a)" "$(mval "$S" 0x220030)" \
      "$(mval "$S" 0x220034)" "$(mval "$S" 0x220035)" "$(mval "$S" 0x220036)" \
      "$(mval "$S" 0x220037)"
    printf '  header        +0x40=0x%x +0x48=0x%x +0x50=0x%x +0xb4=0x%x +0xb8=0x%x\n' \
      "$(mval "$S" 0x220040)" "$(mval "$S" 0x220048)" "$(mval "$S" 0x220050)" \
      "$(mval "$S" 0x2200b4)" "$(mval "$S" 0x2200b8)"
    printf '  block reset   s0p0+0xec=%s +0x104=%s +0x12c=%s | s0p1+0x124=%s\n' \
      "$(mval "$S" 0x2100ec)" "$(mval "$S" 0x210104)" "$(mval "$S" 0x21012c)" \
      "$(mval "$S" 0x2101d0)"
    printf '  cond +0xa8    id1=%s id2=%s id21=%s\n' \
      "$(mval "$S" $(printf 0x%x $((POBJ+0x100+0xa8))))" \
      "$(mval "$S" $(printf 0x%x $((POBJ+0x200+0xa8))))" \
      "$(mval "$S" $(printf 0x%x $((POBJ+21*0x100+0xa8))))"
    for e in "$E0 0" "$E1 1" "$E2 2" "$E3 3"; do
      set -- $e
      printf '  evvec rec%s    kind=%s val=0x%x pid=%s\n' "$2" \
        "$(mval "$S" $(printf 0x%x $(($1+0))))" \
        "$(mval "$S" $(printf 0x%x $(($1+4))))" \
        "$(mval "$S" $(printf 0x%x $(($1+8))))"
    done
  } >> "$OUT"
  echo "[$NAME] ${RET:-?} home=$(mval "$S" 0x2200a0) away=$(mval "$S" 0x2200a8) $HITS"
done
echo "=== statcommit oracle -> $OUT ==="
cat "$OUT"
