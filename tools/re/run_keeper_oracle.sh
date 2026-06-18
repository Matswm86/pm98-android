#!/usr/bin/env bash
# Stage 3 task 3 (4th predicate): drive the REAL keeper-reach save predicate
# FUN_0058f140 through the Ghidra PCode emulator and capture the exact mutated
# state. Unlike the other three predicates this one READS the arctan LUT
# (DAT_006d71c8) via FUN_005ee080 (atan_angle), so we inject the EXACT trig LUTs
# into emulator memory first (tools/re/emit_lut_membts.py -> membts), exactly the
# task-2 movement-oracle trick. This is the ground truth Pm98Predicates.keeper_save
# must reproduce bit-for-bit (test_predicates.gd).
#
# Memory map: match M@0x200000, ball B@0x220000, keeper K@0x230000, the keeper
# stat-struct C@0x250000 (keeper+0x3b8 -> C; FUN_005909f0 bumps C+0x80 on a save).
# The keeper's own match-context (keeper+0x18c) is set to M (one match in play).
# match+0x462 = 0 so FUN_005909f0 only bumps the save counter and does NOT enqueue
# a 0x15/0x16 commentary event (that event path = FUN_00594470 = driver task 2).
# DAT_006d31c4 = 0 (in-sim). EAX low byte = the predicate's bool return (bVar12).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/keeper_oracle.txt
SPEC=$SPECDIR/_keeper_run.spec
ROUT=$SPECDIR/_keeper_run.out
LUT=$SPECDIR/_lut_membts.txt

# Bank the LUT-injection membts lines once (cos@0x6d31c8 + atan@0x6d71c8).
python3 tools/re/emit_lut_membts.py > "$LUT"

# Fixed keeper goal-box (match+0x1828..+0x183c) + goal line (match+0x1820).
LINE=0x100000
BMINX=0xF0000;  BMINY=-0x30000; BMINZ=0x0
BMAXX=0x110000; BMAXY=0x30000;  BMAXZ=0x20000

# emit_spec  X Y Z  F61  KEEPER  KX KY KZ  K2B8 K3A4  POSS
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x58f140
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00220000
zero    0x00200000 0x00002000
zero    0x00220000 0x00001000
zero    0x00230000 0x00000400
zero    0x00250000 0x00000100
mem 0x006d31c4 1 0x0          # DAT_006d31c4 = 0 (in-sim)
mem 0x00220004 4 $1           # ball x
mem 0x00220008 4 $2           # ball y
mem 0x0022000c 4 $3           # ball z
mem 0x0022004c 4 0x0          # ball+0x4c = 0 (enter keeper block)
mem 0x00220050 4 $5           # ball+0x50 = keeper ptr (or 0)
mem 0x00220061 1 $4           # ball+0x61 latch byte
mem 0x002201d4 4 0x00200000   # ball+0x1d4 -> match
mem 0x00200462 1 0x0          # match+0x462 band byte (0 -> no event enqueue)
mem 0x00201820 4 $LINE        # match+0x1820 goal line
mem 0x00201828 4 $BMINX       # match+0x1828 box min x
mem 0x0020182c 4 $BMINY       # match+0x182c box min y
mem 0x00201830 4 $BMINZ       # match+0x1830 box min z
mem 0x00201834 4 $BMAXX       # match+0x1834 box max x
mem 0x00201838 4 $BMAXY       # match+0x1838 box max y
mem 0x0020183c 4 $BMAXZ       # match+0x183c box max z
mem 0x002019a0 4 ${11}        # match+0x19a0 possession
mem 0x00230004 4 $6           # keeper x
mem 0x00230008 4 $7           # keeper y
mem 0x0023000c 4 $8           # keeper z
mem 0x00230034 4 0x0          # keeper+0x34 (cancels in diff)
mem 0x0023018c 4 0x00200000   # keeper+0x18c -> kmatch = M
mem 0x002302b8 4 $9           # keeper+0x2b8 side flag
mem 0x002303a4 4 ${10}        # keeper+0x3a4 x-extent
mem 0x002303b8 4 0x00250000   # keeper+0x3b8 -> stat struct C
EOF
  cat "$LUT" >> "$SPEC"
  cat >> "$SPEC" <<EOF
maxsteps 2000000
read_mem 0x00220061 1         # ball+0x61 latch after
read_mem 0x00220050 4         # ball+0x50 keeper ptr after (0 if cleared)
read_mem 0x00220090 4         # ball+0x90 deflect x
read_mem 0x00220094 4         # ball+0x94 deflect y
read_mem 0x00220098 4         # ball+0x98 deflect z
read_mem 0x00250080 4         # keeper save counter (1 = save fired)
EOF
}

# name        X          Y          Z         F61  KEEPER      KX         KY        KZ   K2B8 K3A4  POSS
MATRIX=(
  "inside     0x100000   0x0        0x10000   0x1  0x00230000  0x100000   0x0       0x0  0x0  0x0   0x0"
  "reach      0x100000   0x35000    0x10000   0x1  0x00230000  0x100000   0x0       0x0  0x0  0x0   0x0"
  "save       0x140000   -0x10000   0x10000   0x1  0x00230000  0xC0000    0x10000   0x0  0x0  0x0   0x0"
  "nofire     0x100000   0x3b000    0x10000   0x1  0x00230000  0x100000   0x0       0x0  0x0  0x0   0x0"
  "noarm      0x100000   0x3b000    0x10000   0x0  0x00230000  0x100000   0x0       0x0  0x0  0x0   0x0"
  "nokeep     0x100000   0x3b000    0x10000   0x1  0x0         0x0        0x0       0x0  0x0  0x0   0x0"
  "clampn     0x100000   -0x3b000   0x10000   0x1  0x0         0x0        0x0       0x0  0x0  0x0   0x0"
)

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
: > "$OUT"
echo "# Stage 3 keeper-save ground truth (oracle = PCode emu, LUT injected). cols decimal (32-bit unsigned)." >> "$OUT"
echo "# name | ret | f61 | k50 | ox | oy | oz | save | RET?" >> "$OUT"
for row in "${MATRIX[@]}"; do
  read -r NAME X Y Z F61 KEEPER KX KY KZ K2B8 K3A4 POSS <<<"$row"
  emit_spec "$X" "$Y" "$Z" "$F61" "$KEEPER" "$KX" "$KY" "$KZ" "$K2B8" "$K3A4" "$POSS"
  : > "$ROUT"   # clear: a spec-parse failure must not leak the previous fixture's result
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  EAX=$(echo "$S" | grep -oE 'EAX=[0-9-]+' | cut -d= -f2 || true)
  printf '%-10s | %-3s | %-3s | %-10s | %-10s | %-10s | %-3s | %-4s | %s\n' \
    "$NAME" "$((EAX & 0xff))" "$(mval "$S" 0x220061)" "$(mval "$S" 0x220050)" \
    "$(mval "$S" 0x220090)" "$(mval "$S" 0x220094)" "$(mval "$S" 0x220098)" \
    "$(mval "$S" 0x250080)" "${RET:-?}" >> "$OUT"
  echo "[$NAME] ret=$((EAX & 0xff)) f61=$(mval "$S" 0x220061) k50=$(mval "$S" 0x220050) save=$(mval "$S" 0x250080) $RET"
done
echo "=== keeper-save oracle -> $OUT ==="
cat "$OUT"
