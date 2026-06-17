#!/usr/bin/env bash
# Stage 1b: sweep ATTR through the REAL resolver (PCode-emulated) and dump the
# binary's own finishing-gate threshold for each, to validate the GDScript port.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
TMPL=$SPECDIR/resolver_gate.tmpl
OUT=$SPECDIR/gate_oracle_table.txt
: > "$OUT"
echo "# ATTR  gate_draw(EAX@5aeee2)  permil(EAX@5aeeff)  threshold(EDX@5aeeff)" >> "$OUT"
for ATTR in "$@"; do
  HEX=$(printf '0x%x' "$ATTR")
  sed "s/__ATTR__/$HEX/" "$TMPL" > "$SPECDIR/_gate_run.spec"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPECDIR/_gate_run.spec" "$SPECDIR/_gate_run.out" \
    >/dev/null 2>&1 || true
  DRAW=$(grep -oE 'rng_ret #1 step=[0-9]+ EAX=[0-9]+' "$SPECDIR/_gate_run.out" | grep -oE 'EAX=[0-9]+' | head -1 | cut -d= -f2)
  CMPLINE=$(grep 'gate_cmp #1' "$SPECDIR/_gate_run.out" | head -1)
  PERMIL=$(echo "$CMPLINE" | grep -oE 'EAX=[0-9]+' | cut -d= -f2)
  THRESH=$(echo "$CMPLINE" | grep -oE 'EDX=[0-9]+' | cut -d= -f2)
  printf '%-6s %-22s %-18s %s\n' "$ATTR" "${DRAW:-NA}" "${PERMIL:-NA}" "${THRESH:-NA}" >> "$OUT"
  echo "ATTR=$ATTR draw=${DRAW:-NA} permil=${PERMIL:-NA} threshold=${THRESH:-NA}"
done
echo "=== oracle table -> $OUT ==="
cat "$OUT"
