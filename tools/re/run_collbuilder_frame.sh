#!/usr/bin/env bash
# Companion to run_collbuilder_oracle.sh: dump the phase-0 FRAME of FUN_005946f0 -- the
# stack-resident source quad tables the constant-fold (0x5946f0..0x595259) builds and the
# phase 1-4 loops interpolate. Sentinel = 0x595259 (the first push of the first FUN_005bbf10
# call = the phase-0/phase-1 boundary), so the emu HALTs there and we dump the whole frame.
# Indexed by ESP-offset so it maps 1:1 to the disasm's `mov [esp+off],reg` writes -- this is
# the ground truth for the Pm98CollBuilder phase-0 port (validated in test_collbuilder.gd).
#
# Frame base: entry esp = sp0-4 = 0x307ffc; after `sub esp,0x60c` + push ebx/ebp/esi ->
# body esp = 0x3079e4. We dump 0x3079e0 .. 0x308010 and the test reads [esp+off] = base+off.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/collbuilder_frame.txt
SPEC=$SPECDIR/_collbuilder_frame.spec
ROUT=$SPECDIR/_collbuilder_frame.out

M=0x00500000
SA=0x00600000; SB=0x00680000; SC=0x00700000; SD=0x00720000
EBASE=0x003079e4                      # body esp (frame base); [esp+off] = EBASE+off
FB=0x003079e0; FWORDS=396             # dump window start + word count (covers 0..~0x630)

pk() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

{
  echo "entry   0x5946f0"
  echo "ret     0x595259"             # phase-0/1 boundary
  echo "stack   0x00300000 0x00010000 0x00308000"
  echo "reg     ECX $M"
  echo "maxsteps 5000000"
  echo "zero    $M 0x00008000"
  echo "zero    $SA 0x00040000"; echo "zero    $SB 0x00020000"
  echo "zero    $SC 0x00010000"; echo "zero    $SD 0x00010000"
  pk $((M+0x27c8)) $((SA)); pk $((M+0x17f4)) $((SB)); pk $((M+0x27d0)) $((SC)); pk $((M+0x2ba4)) $((SD))
  # SAME goal dims as run_collbuilder_oracle.sh
  pk $((M+0x194c)) 0x20000; pk $((M+0x1950)) 0x30000; pk $((M+0x1954)) 0x40000
  pk $((M+0x1958)) 0x18000; pk $((M+0x195c)) 0x28000; pk $((M+0x1960)) 0x12000
  pk $((M+0x1964)) 0x1c000; pk $((M+0x1968)) 0x22000; pk $((M+0x196c)) 0x14000
  pk $((M+0x1970)) 0x8000;  pk $((M+0x1974)) 0x10000; pk $((M+0x1978)) 0xc000
  pk $((M+0x197c)) 0x6000;  pk $((M+0x1820)) 0x90000; pk $((M+0x1988)) 0x0
  pk $((M+0x1a1b)) 0x0101;  pk $((M+0x1a4c)) 0x5000;  pk $((M+0x27cc)) 0x0
  for ((i=0; i<FWORDS; i++)); do printf 'read_mem 0x%08x 4\n' $(( FB + i*4 )); done
  echo "stub    0x5bbf10 0 0"
} > "$SPEC"

: > "$ROUT"
"$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
  -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
L=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)

{
  echo "# phase-0 frame of FUN_005946f0 (sentinel 0x595259). EBASE=$EBASE; columns = [esp+off]."
  echo "# RUN: $(echo "$L" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
  echo "EBASE $EBASE"
  for ((i=0; i<FWORDS; i++)); do
    a=$(( FB + i*4 )); off=$(( a - EBASE ))
    v=$(echo "$L" | grep -oE "mem\[$(printf 0x%x $a):4\]=[0-9-]+" | head -1 | cut -d= -f2)
    printf 'F 0x%x %s\n' "$off" "${v:-NA}"
  done
} > "$OUT"
echo "=== collbuilder frame -> $OUT ==="; sed -n '1,3p' "$OUT"
echo "spot esp+0x48c (decompile local_180 region):"; grep -E '^F 0x48c |^F 0x180 ' "$OUT"