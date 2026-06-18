#!/usr/bin/env bash
# Stage 3: drive the REAL ball-physics scoring predicates (FUN_0058ede0 goal-area,
# FUN_0058f100 trajectory-copy, FUN_0058fbe0 post/bar) through the PCode emulator on
# constructed ball+match fixtures, and capture the exact mutated state. This is the
# ground truth the GDScript port (Pm98Predicates) must reproduce bit-for-bit
# (test_predicates.gd). No LUT needed for these three (only FUN_0058f140 reads it).
#
# Memory: ball B@0x220000, match M@0x200000, src vec@0x240000. Fixtures set
# match+0x180a=0 (skip sound) + ball+0x50=0 (skip the keeper stat) so the binary
# runs the pure geometry/bit/clamp path. EAX = the predicate's return.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/predicate_oracle.txt
SPEC=$SPECDIR/_pred_run.spec
ROUT=$SPECDIR/_pred_run.out

# emit_spec ENTRY X Y Z VX VY VZ LINE POST POSS SIDE F63 B462 SX SY SZ
emit_spec() {
  cat > "$SPEC" <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00220000
zero    0x00200000 0x00002000
zero    0x00220000 0x00001000
zero    0x00240000 0x00000100
mem 0x00220004 4 $2          # ball x
mem 0x00220008 4 $3          # ball y
mem 0x0022000c 4 $4          # ball z
mem 0x00220020 4 $5          # ball vx
mem 0x00220024 4 $6          # ball vy
mem 0x00220028 4 $7          # ball vz
mem 0x00220040 4 0x00240000  # ball+0x40 -> src trajectory vector
mem 0x0022004c 4 0x0         # ball+0x4c = 0
mem 0x00220050 4 0x0         # ball+0x50 = 0 (keeper stat no-op)
mem 0x00220054 4 ${11}       # ball+0x54 side flag
mem 0x00220063 1 ${12}       # ball+0x63 armed byte
mem 0x002201d4 4 0x00200000  # ball+0x1d4 -> match
mem 0x00200462 1 ${13}       # match+0x462 initial band byte
mem 0x00201820 4 $8          # match+0x1820 goal line
mem 0x00201824 4 $9          # match+0x1824 post pos
mem 0x002019a0 4 ${10}       # match+0x19a0 possession flag
mem 0x00200448 4 0x0         # match+0x448 = 0 (not paused)
mem 0x0020180a 1 0x0         # match+0x180a = 0 (skip sound)
mem 0x00240004 4 ${14}       # src+4
mem 0x00240008 4 ${15}       # src+8
mem 0x0024000c 4 ${16}       # src+0xc
maxsteps 500000
read_mem 0x00200462 1        # match+0x462 after
read_mem 0x00220008 4        # ball y after
read_mem 0x0022000c 4        # ball z after
read_mem 0x00220020 4        # ball vx after
read_mem 0x00220024 4        # ball vy after
read_mem 0x00220028 4        # ball vz after
read_mem 0x00220090 4        # ball +0x90 (deflect/traj x)
read_mem 0x00220094 4        # ball +0x94
read_mem 0x00220098 4        # ball +0x98
EOF
}

# name           ENTRY      X          Y         Z         VX      VY       VZ       LINE       POST      POSS SIDE F63 B462 SX     SY     SZ
MATRIX=(
  "ede0_out      0x58ede0   0x0        0x0       0x0       0x0     0x0      0x0      0x100000   0x0       0x0  0x0  0x0 0x0  0x0    0x0    0x0"
  "ede0_low      0x58ede0   0x108000   0x1000    0x1000    0x0     0x0      0x0      0x100000   0x0       0x0  0x0  0x0 0x0  0x0    0x0    0x0"
  "ede0_zclamp   0x58ede0   0x108000   0x1000    0x25000   0x2000  0x0      0x5000   0x100000   0x0       0x0  0x0  0x0 0x0  0x0    0x0    0x0"
  "ede0_yclamp   0x58ede0   0x108000   0x38000   0x1000    0x2000  0x4000   0x0      0x100000   0x0       0x0  0x0  0x0 0x0  0x0    0x0    0x0"
  "ede0_win1     0x58ede0   -0x108000  0x1000    0x22000   0x0     0x0      0x0      0x100000   0x0       0x0  0x0  0x0 0x0  0x0    0x0    0x0"
  "f100_copy     0x58f100   0x0        0x0       0x0       0x0     0x0      0x0      0x0        0x0       0x0  0x0  0x1 0x0  0x111  0x222  0x333"
  "f100_noarm    0x58f100   0x0        0x0       0x0       0x0     0x0      0x0      0x0        0x0       0x0  0x0  0x0 0x0  0x111  0x222  0x333"
  "fbe0_out      0x58fbe0   0x0        0x0       0x0       0x0     0x0      0x0      0x100000   0x40000   0x0  0x1  0x0 0x0  0x0    0x0    0x0"
  "fbe0_zcol     0x58fbe0   0x180000   0x10000   0x28000   0x1000  0x2000   -0x3000  0x100000   0x40000   0x0  0x1  0x0 0x0  0x0    0x0    0x0"
  "fbe0_ycol     0x58fbe0   0x180000   0x3a000   0x10000   0x1000  0x3000   0x1000   0x100000   0x40000   0x0  0x1  0x0 0x0  0x0    0x0    0x0"
)

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
: > "$OUT"
echo "# Stage 3 predicate ground truth (oracle = PCode emu). cols decimal (32-bit unsigned)." >> "$OUT"
echo "# name | ret | b462 | y | z | vx | vy | vz | ox | oy | oz | RET?" >> "$OUT"
for row in "${MATRIX[@]}"; do
  read -r NAME ENTRY X Y Z VX VY VZ LINE POST POSS SIDE F63 B462 SX SY SZ <<<"$row"
  emit_spec "$ENTRY" "$X" "$Y" "$Z" "$VX" "$VY" "$VZ" "$LINE" "$POST" "$POSS" "$SIDE" "$F63" "$B462" "$SX" "$SY" "$SZ"
  : > "$ROUT"   # clear: a spec-parse failure must not leak the previous fixture's result
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  EAX=$(echo "$S" | grep -oE 'EAX=[0-9-]+' | cut -d= -f2 || true)
  printf '%-13s | %-3s | %-3s | %-10s | %-10s | %-10s | %-10s | %-10s | %-10s | %-10s | %-10s | %s\n' \
    "$NAME" "$((EAX & 0xff))" "$(mval "$S" 0x200462)" \
    "$(mval "$S" 0x220008)" "$(mval "$S" 0x22000c)" \
    "$(mval "$S" 0x220020)" "$(mval "$S" 0x220024)" "$(mval "$S" 0x220028)" \
    "$(mval "$S" 0x220090)" "$(mval "$S" 0x220094)" "$(mval "$S" 0x220098)" "${RET:-?}" >> "$OUT"
  echo "[$NAME] ret=$((EAX & 0xff)) b462=$(mval "$S" 0x200462) $RET"
done
echo "=== predicate oracle -> $OUT ==="
cat "$OUT"
