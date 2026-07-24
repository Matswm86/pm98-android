#!/usr/bin/env bash
# MAN OF THE MATCH selector oracle: drive the REAL FUN_0044a370 through the Ghidra PCode
# emulator over crafted report-record arrays and bank the pid it writes into
# DAT_0066afd0+0xac.
#
# Why: FUN_0044a370 is the ONLY writer of DAT_0066afd0+0xac, the MoM pid. The STATISTICS
# MoM column is record+0x0c, stamped from that pid by FUN_0044d520 (@0x44d531) and again
# by the season fold-back (FUN_00448b60 @0x448f21). Until this is banked the port's MoM
# column has no honest source. See docs/re/statistics_row_widget_re.md.
#
# FUN_0044a370  __thiscall(this = ECX = the report object F). No stack args.
#   1. F+0xac = 0, then FUN_00448a00(F) -> a match-result code kept for the tie-break.
#   2. walk the HOME array (F+0x9c, count F+0xa0) then the AWAY array (F+0xa4, F+0xa8),
#      stride 0x48. A record is skipped outright when rec+0x38 != 0 (@0x44a40c),
#      rec+0x30 >= 2 (two yellows, @0x44a448) or rec+0x34 != 0 (a red, @0x44a455).
#   3. per record, score = ((A+B+C+D) >> 2) + 10*min(rec+0x10, 10) with the same four
#      ratios the row widget's RATING uses: A = 100*(+0x08)/((+0x08)+(+0x04)),
#      B = shots, C = passes, D = tackles -- each 100*n/(n+d), 0 when n+d == 0.
#   4. the surviving best record's rec+0x44 is stored to F+0xac.
#
# Emulation: F is a synthetic report object at 0x220000 with pre-sized record buffers.
# FUN_00448a00 (the result code) is STUBBED so the tie-break input is a controlled
# variable -- fixtures F/G run the same tie with return 0 and return 1. F+0x64 is left
# at 0 in every fixture, so the event-list tie-break loop (@0x44a7f6, FUN_00449660)
# never iterates; that path is NOT covered here and stays an open gap.
# PcodeEmu GOTCHA: `mem` VALUES parse as HEX, `read_mem` size is DECIMAL, one directive
# per line.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/moms_oracle.txt
SPEC=$SPECDIR/_moms_run.spec
ROUT=$SPECDIR/_moms_run.out

F=0x220000          # report object -> DAT_0066afd0
HOMEBUF=0x230000    # F+0x9c
AWAYBUF=0x231000    # F+0xa4

# One record: side(0/1) idx min involve goals shon shoff pon poff ton toff yel red f38 pid
rec() {
  local side=$1 idx=$2 min=$3 inv=$4 goals=$5 shon=$6 shoff=$7 pon=$8 poff=$9
  local ton=${10} toff=${11} yel=${12} red=${13} f38=${14} pid=${15}
  local b=$(( (side == 0 ? 0x230000 : 0x231000) + idx * 0x48 ))
  printf 'mem 0x%x 4 0x%x;;' $((b+0x04)) "$min"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x08)) "$inv"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x10)) "$goals"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x14)) "$shon"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x18)) "$shoff"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x1c)) "$pon"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x20)) "$poff"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x24)) "$ton"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x28)) "$toff"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x30)) "$yel"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x34)) "$red"
  printf 'mem 0x%x 4 0x%x;;' $((b+0x38)) "$f38"
  printf 'mem 0x%x 2 0x%x' $((b+0x44)) "$pid"
}

emit_spec() {
  # $1 home count  $2 away count  $3 record pokes  $4 FUN_00448a00 return
  cat > "$SPEC" <<EOF
entry   0x44a370
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $F
zero    0x00220000 0x00001000
zero    0x00230000 0x00001000
zero    0x00231000 0x00001000
mem     0x0066afd0 4 $F
mem     0x0022009c 4 $HOMEBUF
mem     0x002200a0 4 $1
mem     0x002200a4 4 $AWAYBUF
mem     0x002200a8 4 $2
mem     0x00220064 2 0x0
$3
EOF
  {
    echo "maxsteps 20000000"
    echo "stub 0x448a00 $4 0 resultcode"
    echo "stub 0x449660 0 8 eventget"
    echo "read_mem 0x2200ac 2"
  } >> "$SPEC"
}

run_emu() {
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

# ---- fixtures ---------------------------------------------------------------
# score = ((A+B+C+D)>>2) + 10*min(goals,10); A uses (+0x08 over +0x08 + +0x04).
# H0 pid 11: inv 50 min 50 -> A=50; shots 1/1 -> B=50; passes 1/1 -> C=50; tac 1/1 -> D=50
#            goals 0 -> score 50
# H1 pid 12: same ratios, goals 1                          -> score 60
# H2 pid 13: same ratios, goals 2                          -> score 70
# A0 pid 21: same ratios, goals 3                          -> score 80
A_max="$(rec 0 0 50 50 0 1 1 1 1 1 1 0 0 0 11);;$(rec 0 1 50 50 1 1 1 1 1 1 1 0 0 0 12);;$(rec 0 2 50 50 2 1 1 1 1 1 1 0 0 0 13);;$(rec 1 0 50 50 3 1 1 1 1 1 1 0 0 0 21)"

# B: the away record is the top scorer but is gated out by rec+0x38.
B_gate38="$(rec 0 0 50 50 2 1 1 1 1 1 1 0 0 0 13);;$(rec 1 0 50 50 3 1 1 1 1 1 1 0 0 1 21)"

# C: top scorer carries two yellows (rec+0x30 >= 2).
C_yellow="$(rec 0 0 50 50 2 1 1 1 1 1 1 0 0 0 13);;$(rec 1 0 50 50 3 1 1 1 1 1 1 2 0 0 21)"

# D: top scorer carries a red (rec+0x34 != 0).
D_red="$(rec 0 0 50 50 2 1 1 1 1 1 1 0 0 0 13);;$(rec 1 0 50 50 3 1 1 1 1 1 1 0 1 0 21)"

# E: two HOME records with an identical score -- who wins a same-array tie.
E_tie_home="$(rec 0 0 50 50 1 1 1 1 1 1 1 0 0 0 11);;$(rec 0 1 50 50 1 1 1 1 1 1 1 0 0 0 12)"

# F/G: a HOME record ties an AWAY record; the only difference is the stubbed
# FUN_00448a00 result code (0 vs 1).
FG_tie_cross="$(rec 0 0 50 50 1 1 1 1 1 1 1 0 0 0 11);;$(rec 1 0 50 50 1 1 1 1 1 1 1 0 0 0 21)"

# H: no records at all -- F+0xac must stay 0 (nobody is MoM).
# I: goals above the min(.,10) cap -- 10 and 40 goals must score the same, so the
#    first (pid 11) wins on the first-record rule rather than on goal count.
I_goalcap="$(rec 0 0 50 50 10 1 1 1 1 1 1 0 0 0 11);;$(rec 0 1 50 50 40 1 1 1 1 1 1 0 0 0 12)"

# name | home count | away count | pokes | resultcode
FIX=(
  "A_max|0x3|0x1|$A_max|0"
  "B_gate38|0x1|0x1|$B_gate38|0"
  "C_yellow|0x1|0x1|$C_yellow|0"
  "D_red|0x1|0x1|$D_red|0"
  "E_tie_home|0x2|0x0|$E_tie_home|0"
  "F_tie_cross_r0|0x1|0x1|$FG_tie_cross|0"
  "G_tie_cross_r1|0x1|0x1|$FG_tie_cross|1"
  "H_empty|0x0|0x0||0"
  "I_goalcap|0x2|0x0|$I_goalcap|0"
)

: > "$OUT"
{
  echo "# FUN_0044a370 MAN OF THE MATCH ground truth (PCode emu; PcodeEmu.java)."
  echo "# report F=$F(DAT_0066afd0) home recs=$HOMEBUF away recs=$AWAYBUF"
  echo "# Every record carries ratios A=B=C=D=50, so score == 50 + 10*min(goals,10)."
  echo "# FUN_00448a00 (result code) + FUN_00449660 (event list) stubbed; F+0x64 = 0 so"
  echo "# the event-count tie-break loop never iterates."
  echo "# 'mom' is the u16 at F+0xac -- the winning record's rec+0x44."
} >> "$OUT"

for row in "${FIX[@]}"; do
  IFS='|' read -r NAME HC AC POKES RC <<<"$row"
  POKES="${POKES//;;/$'\n'}"
  emit_spec "$HC" "$AC" "$POKES" "$RC"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  HITS=$(echo "$S" | grep -oE 'stubhits=\{[^}]*\}' || echo "stubhits={}")
  {
    echo
    echo "=== FIX $NAME  ${RET:-?}  $HITS"
    printf '  home=%s away=%s resultcode=%s  mom=%s\n' \
      "$HC" "$AC" "$RC" "$(mval "$S" 0x2200ac)"
  } >> "$OUT"
  echo "[$NAME] ${RET:-?} mom=$(mval "$S" 0x2200ac) $HITS"
done
echo "=== MoM oracle -> $OUT ==="
cat "$OUT"
