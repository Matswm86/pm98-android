#!/usr/bin/env bash
# Oracle for FUN_005b0a60 -- the lean's Slice-B carrier-busy predicate (decompile fn_005b0a60). __fastcall,
# ECX = carrier; pure switch on carrier.action (+0x40) against the action timer (+0x2c); returns bool in AL.
# Leaf-pure (no calls / no FPU), so the spec needs only entry/ret/stack + the carrier struct. GROUND TRUTH
# for Pm98Movement._carrier_busy_b0a60 (app/tests/test_9490sliceB.gd). carrier @ 0x230000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b0a60_oracle.txt
SPEC=$SPECDIR/_b0a60_run.spec
ROUT=$SPECDIR/_b0a60_run.out

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# name|action|timer  -- boundary pairs around every switch arm, plus a default-case miss.
FIX=(
  "d_busy|0xd|1"      "d_idle|0xd|0"
  "x13_busy|0x13|4"   "x13_idle|0x13|5"
  "x1f|0x1f|0"        "x21|0x21|0"        "x2f|0x2f|0"
  "x28_busy|0x28|4"   "x28_idle|0x28|3"
  "x29_busy|0x29|9"   "x2c_idle|0x2c|3"   "x2d_busy|0x2d|4"
  "x2e_busy|0x2e|2"   "x2e_idle|0x2e|1"
  "x30_busy|0x30|7"   "x30_idle|0x30|6"   "x33_busy|0x33|7"  "x34_idle|0x34|6"
  "x36_busy|0x36|0x13" "x36_idle|0x36|0x14"
  "x37_busy|0x37|5"   "x37_idle|0x37|6"
  "default|0x99|0"
)

emit_spec() {  # $1=action  $2=timer
  cat > "$SPEC" <<EOF
entry   0x005b0a60
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
maxsteps 100000
$(poke 0x230040 "$1")
$(poke 0x23002c "$2")
read_reg EAX
EOF
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005b0a60 (carrier-busy predicate). Row: B0A60 <name> | AL=<0|1> (EAX & 0xff)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ACT TMR <<<"$row"
  emit_spec "$ACT" "$TMR"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  EAX=$(echo "$LINE" | grep -oE 'EAX=[0-9-]+' | head -1 | cut -d= -f2 || true)
  AL=$(( (EAX & 0xff) != 0 ? 1 : 0 ))
  echo "B0A60 $NAME | AL=$AL" >> "$OUT"
  echo "[$NAME] act=$ACT t=$TMR -> AL=$AL ($(echo "$LINE" | grep -oE 'RET steps=[0-9]+' || echo HALT))"
done
echo "=== b0a60 oracle -> $OUT ==="
cat "$OUT"
