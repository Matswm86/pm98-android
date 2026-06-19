#!/usr/bin/env bash
# Stage 3 task 2 (match-driver leaves): drive three small leaves of the per-tick driver
# FUN_00598740 through the Ghidra PCode emulator and bank their effects. Ground truth for
# Pm98Movement.within_box / set_phase / vec3_copy (app/tests/test_driverleaf.gd).
#
#   FUN_005a1820(__thiscall p1; p2, lx, ly, lz): 1 iff abs(p1.x-p2.x)<lx & abs(.y)<ly & abs(.z)<lz
#     (STRICT). Goalkeeper-distribution region test. EAX = return.
#   FUN_005942e0(__thiscall match; phase): match+0x448 = phase unless already 8; mirror to +0x44c
#     unless phase==1. Reads back +0x448/+0x44c.
#   FUN_00590ac0(__thiscall dst; src): copy 3 dwords src -> dst. Reads back dst[0..2].
# All pure integer, no sub-calls / RNG / LUT / ftol / stubs.
#
# Memory map: vecs/dst @0x230000 (p1/dst), @0x230010 (p2/src), match @0x210000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/driverleaf_oracle.txt
SPEC=$SPECDIR/_driverleaf_run.spec
ROUT=$SPECDIR/_driverleaf_run.out

emit_spec() {
  # $1 entry, $2 ECX(this), $3 args(space-sep hex/dec), $4 pokes(';'->nl), $5 reads(space-sep "addr")
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $2
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
EOF
    for a in $3; do printf 'arg 0x%08x\n' $(( a & 0xffffffff )); done
    printf '%s\n' "${4//;/$'\n'}"
    for r in $5; do echo "read_mem $r 4"; done
    echo "maxsteps 100000"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name $2 entry $3 ecx $4 args $5 pokes $6 reads
  emit_spec "$2" "$3" "$4" "$5" "$6"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+( EAX=[0-9-]+)?')"
}

V1() { echo "$(poke 0x230000 $1);$(poke 0x230004 $2);$(poke 0x230008 $3)"; }   # p1/dst @0x230000
V2() { echo "$(poke 0x230010 $1);$(poke 0x230014 $2);$(poke 0x230018 $3)"; }   # p2/src @0x230010
A1820_READS=""                                              # 5a1820: EAX only
PHASE_READS="0x00210448 0x0021044c"
COPY_READS="0x00230000 0x00230004 0x00230008"

: > "$OUT"
echo "# Stage 3 task 2 match-driver leaves (FUN_005a1820 within-box + FUN_005942e0 set-phase +" >> "$OUT"
echo "# FUN_00590ac0 vec3-copy) PCode-emu ground truth. 5a1820: EAX=return. p1/dst@0x230000, p2/src" >> "$OUT"
echo "# @0x230010, match@0x210000. Each row: FIX <name> + verbatim CALL (EAX and/or mem[...])." >> "$OUT"

# ---- FUN_005a1820 (this=p1@0x230000; p2@0x230010, lx, ly, lz) ----
# within: |0-0x10000|<0x20000 on all axes -> 1.
bank a1820_within 0x5a1820 0x00230000 "0x230010 0x20000 0x20000 0x20000" "$(V1 0 0 0);$(V2 0x10000 0x10000 0x10000)" "$A1820_READS"
# negative diff still within (abs) -> 1.
bank a1820_negok  0x5a1820 0x00230000 "0x230010 0x20000 0x20000 0x20000" "$(V1 0x10000 0x10000 0x10000);$(V2 0 0 0)" "$A1820_READS"
# x diff == lx (strict <) -> 0.
bank a1820_xfail  0x5a1820 0x00230000 "0x230010 0x20000 0x20000 0x20000" "$(V1 0 0 0);$(V2 0x20000 0x10000 0x10000)" "$A1820_READS"
# y out -> 0.
bank a1820_yfail  0x5a1820 0x00230000 "0x230010 0x20000 0x20000 0x20000" "$(V1 0 0 0);$(V2 0x10000 0x30000 0x10000)" "$A1820_READS"
# z out -> 0.
bank a1820_zfail  0x5a1820 0x00230000 "0x230010 0x20000 0x20000 0x20000" "$(V1 0 0 0);$(V2 0x10000 0x10000 0x30000)" "$A1820_READS"

# ---- FUN_005942e0 (this=match@0x210000; phase) ; +0x44c pre-seeded 0x7777 sentinel ----
# phase 6 (not 1, not locked): +0x448=6, +0x44c=6.
bank phase_set    0x5942e0 0x00210000 "6" "$(poke 0x210448 0);$(poke 0x21044c 0x7777)" "$PHASE_READS"
# phase 1: +0x448=1, +0x44c stays sentinel.
bank phase_one    0x5942e0 0x00210000 "1" "$(poke 0x210448 0);$(poke 0x21044c 0x7777)" "$PHASE_READS"
# already locked (+0x448==8): no change (both stay).
bank phase_locked 0x5942e0 0x00210000 "6" "$(poke 0x210448 8);$(poke 0x21044c 0x7777)" "$PHASE_READS"

# ---- FUN_00590ac0 (this=dst@0x230000; src@0x230010) ----
bank copy_vec     0x590ac0 0x00230000 "0x230010" "$(V2 0x12340000 0x56780000 0x9abc0000)" "$COPY_READS"

echo "=== driverleaf oracle -> $OUT ==="
cat "$OUT"
