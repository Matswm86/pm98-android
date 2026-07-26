#!/usr/bin/env bash
# Validate MANAGER_HACK.EXE (3-forwards patch) against the REAL bytes in the Ghidra
# PCode emulator, using the same harness shape as tools/re/run_statmatch_oracle.sh.
#
# Two questions, both answered by running FUN_0044ee70's PS==5 league path:
#   1. REGRESSION — with an XI that has NO ATT-role players (exactly the banked stock
#      fixtures, roles all 0), MANAGER_HACK.EXE must produce the SAME draws / event
#      count / final LCG state / score as MANAGER.EXE. The patch must be inert.
#   2. EFFECT — with 3 ATT-role players (+0xcc == 3) on side 0, the hacked binary must
#      give side 0 >= 3 goals per half (>= 6) while the stock binary does not.
#
# Usage: run_hack_oracle.sh            (runs both programs, prints a table)
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPEC=tools/hack/_hack_run.spec
ROUT=tools/hack/_hack_run.out

M=0x210000
SEEDADDR=0x257000
THUNK=0x257010
BUF=0x258000
SCRATCH=0x256000
FOBJ=0x256800
FVT=0x256900
VSTUB=0x259000
RAND_THUNK=A10070250069C0FD43030005C39E2600A300702500C1E81025FF7F0000C3
s0=$(( 0x210000 ))
s1=$(( 0x210000 + 0x7a0 ))
NREC=48

# $1 side base  $2 team id  $3 strength  $4 keeper save  $5 pass  $6 how many ATT roles
build_xi() {
  local sbase=$1 tid=$2 str=$3 ks=$4 pass=$5 natt=${6:-0}
  local POS=(1 2 3 5 7 9 11 13 16 9 12)
  for i in $(seq 0 10); do
    local base=$(( sbase + i*0xac ))
    printf 'mem 0x%x 2 0x%x\n' $((base+0x88)) $((i+1))
    printf 'mem 0x%x 4 0x%x\n' $((base+0xc8)) ${POS[$i]}
    printf 'mem 0x%x 1 0x%x\n' $((base+0xbf)) $str
    printf 'mem 0x%x 1 0x%x\n' $((base+0xc2)) $pass
    # ROLE (+0xcc): 3 = ATT. Fill from the last outfield slot backwards.
    if [ "$natt" -gt 0 ] && [ "$i" -ge $((11 - natt)) ]; then
      printf 'mem 0x%x 4 0x3\n' $((base+0xcc))
    fi
  done
  printf 'mem 0x%x 2 0x%x\n' $((sbase+0x7e8)) $tid
  printf 'mem 0x%x 1 0x%x\n' $((sbase+0xc0)) $ks
  printf 'mem 0x%x 1 0x32\n' $((sbase+0xbb))
}

READS=( "0x210f9c 4" )
for i in $(seq 0 $((NREC-1))); do
  b=$(( 0x258000 + i*0x10 ))
  READS+=( "$(printf 0x%x $b) 4" "$(printf 0x%x $((b+4))) 4" \
           "$(printf 0x%x $((b+8))) 4" "$(printf 0x%x $((b+12))) 4" )
done
READS+=( "0x257000 4" )

# $1 seed  $2 str0  $3 str1  $4 keeper  $5 pass  $6 natt(side0)
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x44ee70
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
zero    0x00210000 0x00004000
zero    0x00256000 0x00004000
zero    0x00257000 0x00001000
zero    0x00258000 0x00000800
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
$(build_xi $s0 0x0007 $2 $4 $5 $6)
$(build_xi $s1 0x0013 $3 $4 $5 0)
mem     0x00210044 4 0x0
mem     0x00210048 4 0x0
stub    0x0044d5f0 0 0
stub    0x0044d0d0 0 0
stub    0x0044d190 0 0
stub    0x0044d250 0 0
stub    0x0044d310 0 0
stub    0x0044d520 0 0
stub    0x00450e60 0 0
stub    0x00606220 0 0
stub    0x005bbf10 0 0
stub    $VSTUB 0 4
EOF
  { echo "maxsteps 80000000"; echo "trace $THUNK rand";
    for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {  # $1 = program name in the ghidra project
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process "$1" -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\[$2:[0-9]+\]=[0-9-]+" | cut -d= -f2 || true; }

# name | seed | str0 | str1 | keeper | pass | natt(side0)
FIX=(
  "regress_A|0x12345678|0x46|0x32|0x28|0x40|0"
  "regress_B|0x0abcdef1|0x3c|0x3c|0x28|0x40|0"
  "regress_C|0x00112233|0x50|0x28|0x20|0x44|0"
  "regress_D|0x7eeeeee1|0x32|0x46|0x30|0x38|0"
  "att3_A|0x12345678|0x46|0x32|0x28|0x40|3"
  "att3_B|0x0abcdef1|0x3c|0x3c|0x28|0x40|3"
  "att3_C|0x00112233|0x50|0x28|0x20|0x44|3"
  "att3_D|0x7eeeeee1|0x32|0x46|0x30|0x38|3"
)

printf '%-11s %-16s %-8s %-6s %-12s %s\n' FIXTURE PROGRAM draws count finalstate "score(us-them)"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME SEED S0 S1 KEEP PASS NATT <<<"$row"
  emit_spec "$SEED" "$S0" "$S1" "$KEEP" "$PASS" "$NATT"
  for PROG in MANAGER.EXE MANAGER_HACK.EXE; do
    run_emu "$PROG"
    S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
    DRAWS=$(echo "$S" | grep -oE 'tracehits=\{rand=[0-9]+\}' | grep -oE '[0-9]+' || echo 0)
    CNT=$(mval "$S" 0x210f9c); STATE=$(mval "$S" 0x257000)
    declare -A score=(); score=()
    for i in $(seq 0 $((NREC-1))); do
      [ "$i" -ge "${CNT:-0}" ] && break
      b=$(( 0x258000 + i*0x10 ))
      T=$(mval "$S" $(printf 0x%x $b)); PAY=$(mval "$S" $(printf 0x%x $((b+12))))
      [ "$T" = "4" ] && continue
      tid=$(( PAY & 0xffff )); score[$tid]=$(( ${score[$tid]:-0} + 1 ))
    done
    printf '%-11s %-16s %-8s %-6s %-12s %s-%s\n' \
      "$NAME" "$PROG" "$DRAWS" "$CNT" "$STATE" "${score[7]:-0}" "${score[19]:-0}"
  done
done
