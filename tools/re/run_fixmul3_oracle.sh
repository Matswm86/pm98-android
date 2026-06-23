#!/usr/bin/env bash
# Leaf oracle for FUN_005edfd0 (cdecl a,b,c): ((a*b)>>16)*c >>16 -- chained 16.16 fixmul, the binary's
# imul/shrd 0x10 twice. Ported as Pm98Trig.fixmul3 (= mul16(mul16(a,b),c)). Pure arithmetic, no memory:
# args are cdecl stack ([ebp+8/0xc/0x10]). Fixtures cover +/+, -/+, +/-, large, and a 0x1820-style val.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/fixmul3_oracle.txt
SPEC=$SPECDIR/_fixmul3_run.spec
ROUT=$SPECDIR/_fixmul3_run.out

# name|a|b|c (decimal, may be negative)
FIX=(
  "pos|0x30000|0x8000|0xb2"
  "neg_a|-0x30000|0x8000|0xb2"
  "neg_c|0x30000|0x8000|-0xb2"
  "big|0x1428f4|0x4000|0x200"
  "unit|0x10000|0x10000|0x10000"
)

run_one() {
  cat > "$SPEC" <<EOF
entry   0x005edfd0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
maxsteps 2000
arg $1
arg $2
arg $3
read_reg EAX
EOF
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Leaf oracle FUN_005edfd0 (fixmul3): cdecl ((a*b)>>16)*c >>16. Row: FIX <name> a b c -> EAX." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME A B C <<<"$row"
  run_one "$A" "$B" "$C"
  EAX=$(grep -oE 'EAX=-?[0-9]+' "$ROUT" | head -1)
  echo "FIX $NAME $A $B $C $EAX" >> "$OUT"
done
echo "=== fixmul3 oracle -> $OUT ==="
cat "$OUT"
