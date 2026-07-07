#!/usr/bin/env bash
# Phase-6 keeper GOAL-KICK / THROW distribution: drive the REAL FUN_005aad30 (path A, ~20% short kick)
# and FUN_005aae40 (path B, ~80% default) through the Ghidra PCode emulator and bank every player+ball
# field they write, so the port (_dist_kick_aad30 / _dist_kick_aae40 in Pm98Movement.gd) can be locked
# bit-for-bit. These are the leaves that clear the M5 phase-6 stall (keeper holds the ball forever).
#
# ECX = the keeper player at 0x230000. Its ball ptr (+0x190) -> 0x240000, match ptr (+0x18c) -> 0x250000,
# own-team ctx (+0x184) -> 0x260000 with count(+4)=0 so aae40 takes the blind-throw branch (no teammate
# array to fabricate). Both callees are self-contained: FUN_005ee0f0 (polar) reads only the injected cos
# LUT @0x6d31c8, FUN_005a5430 (set-position) reads the binary-resident DAT_00665208 remap table. No _ftol.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/distkick_oracle.txt
SPEC=$SPECDIR/_distkick_run.spec
ROUT=$SPECDIR/_distkick_run.out
LUT=$SPECDIR/_distkick_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"          # cos@0x6d31c8 (+atan, unused here)

P()  { printf '0x%08x' $(( 0x00230000 + $1 )); }
BB() { printf '0x%08x' $(( 0x00240000 + $1 )); }
MM() { printf '0x%08x' $(( 0x00250000 + $1 )); }
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# READS: player writes, then ball writes, then the match +0x19dc power reset.
PREADS=(0x40 0x2c 0x30 0x48 0x84 0x80 0x94 0x98 0x9c 0x66 0xa0 0xa4 0xa8 0xb4 0x6c)
BREADS=(0x68 0x6c 0x9c 0xa0 0xa4 0x4c)
READS=()
for off in "${PREADS[@]}"; do READS+=("$(P $off) 4"); done
for off in "${BREADS[@]}"; do READS+=("$(BB $off) 4"); done
READS+=("$(MM 0x19dc) 4")

emit_spec() {   # $1 = entry VA, $2 = fixture pokes (newline-joined)
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00002000
zero    0x00240000 0x00001000
zero    0x00250000 0x00002000
zero    0x00260000 0x00001000
mem     0x00230190 4 0x00240000
mem     0x0023018c 4 0x00250000
mem     0x00230184 4 0x00260000
mem     0x00260000 4 0x00270000
mem     0x00260004 4 0x00000000
mem     0x006d31c4 1 0x0
maxsteps 2000000
EOF
    cat "$LUT"
    printf '%s\n' "$2"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# fixture: player x,y,z  facing  ball x,y
fixt() {
  echo "$(poke "$(P 0x4)" "$1");$(poke "$(P 0x8)" "$2");$(poke "$(P 0xc)" "$3");$(poke "$(P 0x34)" "$4");$(poke "$(BB 0x4)" "$5");$(poke "$(BB 0x8)" "$6")"
}

FIX=(
  "aad30_a|0x005aad30|$(fixt 0 0 0            0x2000  0x1000 0x2000)"
  "aad30_b|0x005aad30|$(fixt 0x30000 -0x10000 0  0x6000  0x28000 -0x8000)"
  "aae40_a|0x005aae40|$(fixt 0 0 0            0x2000  0x1000 0x2000)"
  "aae40_b|0x005aae40|$(fixt 0x30000 -0x10000 0  0x6000  0x28000 -0x8000)"
)

: > "$OUT"
echo "# FUN_005aad30 (path A) + FUN_005aae40 (path B, blind-throw with count=0) PCode-emu truth." >> "$OUT"
echo "# order: P[0x40 2c 30 48 84 80 94 98 9c 66 a0 a4 a8 b4 6c] B[0x68 6c 9c a0 a4 4c] M[0x19dc]" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ENTRY POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$ENTRY" "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  vals=""
  for r in "${READS[@]}"; do
    a=${r%% *}
    an=$(printf '0x%x' "$a")            # emu echoes addresses unpadded (mem[0x230040:4])
    v=$(printf '%s\n' "$LINE" | grep -oE "mem\[$an:4\]=[0-9-]+" | tail -1 | grep -oE '[0-9-]+$' || true)
    vals="$vals ${v:-NA}"
  done
  echo "FIX $NAME$vals" >> "$OUT"
done
echo "=== distkick oracle -> $OUT ==="
cat "$OUT"
