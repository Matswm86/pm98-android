#!/usr/bin/env bash
# Stage 3 task 2 (STATISTICAL engine): bank the REAL full-time / tie-resolution gate
# FUN_00450e60 (@0x450e60, no rand()) through the Ghidra PCode emulator, so the
# GDScript port Pm98StatMatch.ft_gate() can be validated bit-exact
# (app/tests/test_ftgate_oracle.gd).
#
# The gate returns a byte: 0 = still level (play on / replay), 1 = side 0 through,
# 2 = side 1 through. It reads the match struct's leg-carry fields and decision flags
# (+0x20/0x24/0x28/0x2c/0x30/0x34/0x38/0x44/0x48) and calls four REAL leaf score
# readers over the +0xf98 event vector:
#   FUN_00450d60 -> side0 score   FUN_00450db0 -> side1 score
#   FUN_00450e00 -> side0 pens    FUN_00450e30 -> side1 pens
# We do NOT stub those four; they run for real over a synthetic event queue we build,
# so the whole gate is exercised end-to-end on its own bytes. No rand() is involved.
#
# Event record = 16 bytes [i32 type, i32 minute, i32 p4, i32 payload]; (short)payload
# = team id. type==4 = penalty event. teamId(side0)=+0x7e8, teamId(side1)=+0xf88.
# PcodeEmu GOTCHA: `mem` VALUES parse as HEX, one directive per line; return in EAX.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/ftgate_oracle.txt
SPEC=$SPECDIR/_ftgate_run.spec
ROUT=$SPECDIR/_ftgate_run.out

M=0x210000
BUF=0x258000
TID0=0x0007
TID1=0x0013

# Append event records to the spec. $1 = comma list of "type:p4:tid" triples.
emit_events() {
  local list=$1 i=0
  IFS=',' read -ra recs <<<"$list"
  for r in "${recs[@]}"; do
    [ -z "$r" ] && continue
    IFS=':' read -r t p4 tid <<<"$r"
    local b=$(( BUF + i*0x10 ))
    printf 'mem 0x%x 4 0x%x\n' $((b))     "$t"
    printf 'mem 0x%x 4 0x%x\n' $((b+4))   0x0
    printf 'mem 0x%x 4 0x%x\n' $((b+8))   "$p4"
    printf 'mem 0x%x 4 0x%x\n' $((b+12))  $(( (0x9 << 16) | tid ))
    i=$((i+1))
  done
  printf 'mem 0x%x 4 0x%x\n' $((M+0xf9c)) "$i"   # event count
}

# Build a synthetic event queue producing exactly S0 normal goals, S1 normal goals,
# P0 side0 pens, P1 side1 pens. $1=S0 $2=S1 $3=P0 $4=P1
build_queue() {
  local s0=$1 s1=$2 p0=$3 p1=$4 list="" k
  for ((k=0;k<s0;k++)); do list+="2:0:$((TID0)),"; done
  for ((k=0;k<s1;k++)); do list+="2:0:$((TID1)),"; done
  for ((k=0;k<p0;k++)); do list+="4:0:$((TID0)),"; done
  for ((k=0;k<p1;k++)); do list+="4:0:$((TID1)),"; done
  emit_events "$list"
}

# $1 seed-unused  fields via env: F20 F24 F28 A B C D F44 F48 / S0 S1 P0 P1
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x450e60
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $M
zero    0x00210000 0x00004000
zero    0x00258000 0x00001000
mem     0x002107e8 2 $TID0
mem     0x00210f88 2 $TID1
mem     0x00210f98 4 $BUF
mem     $(printf 0x%x $((M+0x20))) 4 0x$F20
mem     $(printf 0x%x $((M+0x24))) 4 0x$F24
mem     $(printf 0x%x $((M+0x28))) 4 0x$F28
mem     $(printf 0x%x $((M+0x2c))) 4 0x$A
mem     $(printf 0x%x $((M+0x30))) 4 0x$B
mem     $(printf 0x%x $((M+0x34))) 4 0x$C
mem     $(printf 0x%x $((M+0x38))) 4 0x$D
mem     $(printf 0x%x $((M+0x44))) 4 0x$F44
mem     $(printf 0x%x $((M+0x48))) 4 0x$F48
EOF
  build_queue "$S0" "$S1" "$P0" "$P1" >> "$SPEC"
  { echo "maxsteps 2000000"; echo "read_reg EAX"; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Fixtures: name | F20 F24 F28 A B C D F44 F48 | S0 S1 P0 P1
# A/B/C/D and flags are HEX (0xff = sentinel "no carry / single leg").
FIX=(
  # --- single match, pens on (A==ff & B==ff branch) ---
  "single_s0win|0 0 0 ff ff ff ff 0 1|2 1 0 0"
  "single_s1win|0 0 0 ff ff ff ff 0 1|1 2 0 0"
  "single_level_noaway|0 0 0 ff ff ff ff 0 1|1 1 0 0"
  "single_level_pen_s0|0 1 0 ff ff ff ff 0 1|1 1 3 2"
  "single_level_pen_s1|0 1 0 ff ff ff ff 0 1|1 1 2 3"
  "single_level_pen_tie|0 1 0 ff ff ff ff 0 1|1 1 2 2"
  # --- no pens (F48==0) -> simple this-match winner ---
  "nopen_s0win|0 0 0 ff ff ff ff 0 0|2 0 0 0"
  "nopen_s1win|0 0 0 ff ff ff ff 0 0|0 2 0 0"
  "nopen_level|0 0 0 ff ff ff ff 0 0|1 1 0 0"
  # --- two-legged, F28 aggregate branch (F44==0 so top-if skipped) ---
  "agg_f28_s1ahead|0 0 1 1 0 ff ff 0 1|0 2 0 0"
  "agg_f28_s0ahead|0 0 1 2 0 ff ff 0 1|1 0 0 0"
  "agg_f28_level_pen_s0|0 1 1 1 1 ff ff 0 1|1 1 2 1"
  # --- bottom path (F28==0, carry present), away-goals + agg ---
  "bot_level_draw|0 0 0 1 1 ff ff 0 1|1 1 0 0"
  "bot_away_s1|0 0 0 0 1 ff ff 0 1|2 1 0 0"
  "bot_agg_s0|0 0 0 0 0 ff ff 0 1|3 1 0 0"
)

: > "$OUT"
echo "# Stage 3 task 2 STATISTICAL: FUN_00450e60 full-time/tie gate ground truth (PCode emu, no rand)." >> "$OUT"
echo "# fields F20 F24 F28 A B C D F44 F48 (hex) | scores S0 S1 P0 P1 -> RET (0 level / 1 side0 / 2 side1)" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME FIELDS SCORES <<<"$row"
  read -r F20 F24 F28 A B C D F44 F48 <<<"$FIELDS"
  read -r S0 S1 P0 P1 <<<"$SCORES"
  export F20 F24 F28 A B C D F44 F48 S0 S1 P0 P1
  emit_spec
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  EAX=$(echo "$LINE" | grep -oE 'EAX=[0-9-]+' | cut -d= -f2)
  RET=$(( (EAX) & 0xff ))
  printf 'FIX %-22s F=[%s] S=[%s] -> RET=%s\n' "$NAME" "$FIELDS" "$SCORES" "$RET" >> "$OUT"
  echo "[$NAME] EAX=$EAX RET=$RET"
done
echo "=== ftgate oracle -> $OUT ==="
cat "$OUT"
