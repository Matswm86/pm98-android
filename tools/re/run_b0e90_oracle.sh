#!/usr/bin/env bash
# Leaf oracle for FUN_005b0e90 (__thiscall, RET 0x10): the perpendicular distance from a player to a
# dribble-LANE SEGMENT. Drives the REAL function under the Ghidra PCode emulator and banks EAX (the
# distance, or 0xc80000 = 13107200 when the player is off the lane). GROUND TRUTH that
# Pm98Movement._lane_perp_dist must reproduce bit-for-bit (app/tests/test_b1070.gd).
#
# this(ECX) = pl (the OTHER player; reads pl+4/8/0xc = pl.pos). 4 stack args:
#   a1 = p_pos vec3 ptr (lane origin), a2 = angle, a3 = halfmag (lane length), a4 = radius.
# Algorithm: unit = polar(0x10000, angle); mid = polar(round0(halfmag/2), angle); endpoint = p_pos+mid;
# bbox half-extent = round0(halfmag/2)+radius about endpoint -> miss => 0xc80000. D = pl.pos - p_pos;
# proj = dot16(unit, D) ; proj<0 or proj>halfmag => 0xc80000 ; else perp = ftol(sqrt(|cross16(unit,D)|^2)).
# All geometry leaves run REAL: 5ee0f0 (polar), 5ee500 (dot16), 5ee540 (cross16) + the FP magnitude
# (FILD/FSQRT + _ftol via the 0x6233a4 thunk -> hand-coded round-to-zero ftol at 0x252000). Trig LUT injected.
#
# Memory: pl @0x230000 (ECX), p_pos vec @0x240000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b0e90_oracle.txt
SPEC=$SPECDIR/_b0e90_run.spec
ROUT=$SPECDIR/_b0e90_run.out
LUT=$SPECDIR/_b0e90_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }
a32()  { printf '0x%08x' $(( $1 & 0xffffffff )); }   # 32-bit arg literal (handles negatives)

# _ftol thunk: redirect import slot 0x6233a4 -> hand-coded round-to-zero ftol at 0x252000.
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# name|angle|halfmag|radius|PX PY PZ|plx ply plz   (P_pos at 0x240000, pl.pos at 0x230004..c)
FIX=(
  # bbox MISS: pl.y past the endpoint box (0x70000 >= 0x40000/2... half-extent 0x60000) -> 13107200.
  "boxmiss|0|0x80000|0x20000|0 0 0|0x40000 0x70000 0"
  # ON lane midpoint: perp ~0, proj 0x40000 in [0,0x80000].
  "online|0|0x80000|0x20000|0 0 0|0x40000 0 0"
  # PERP offset 0x20000 at midpoint -> perp == 0x20000 (131072).
  "perp|0|0x80000|0x20000|0 0 0|0x40000 0x20000 0"
  # BEHIND origin (proj<0) but inside bbox -> 13107200.
  "behind|0|0x80000|0x20000|0 0 0|-0x10000 0 0"
  # BEYOND lane end (proj>halfmag) but inside bbox -> 13107200.
  "beyond|0|0x80000|0x20000|0 0 0|0x90000 0 0"
  # DIAG angle + nonzero origin + perp offset: exercises the rotated cross/sqrt + translation.
  "diag|0x2000|0x80000|0x20000|0x10000 0x10000 0|0x50000 0x48000 0"
)
# NOTE: every fixture's perpendicular magnitude must be INTEGER-valued. Ghidra pcode does not model
# the x87 control word, so the membts _ftol's `fldcw` truncate-mode is a no-op and the emulator's
# `fist` rounds-to-NEAREST -- whereas the real MSVC _ftol truncates toward zero. They diverge only at
# a non-integer magnitude (e.g. a pure-z offset 0x18000 with the LUT's unit.y residual yields
# 98304.93: real game/GDScript truncate to 98304, the emulator rounds to 98305). Same constraint as
# Pm98Trig._dist3 ("perfect-square distances"). Keep cross-product magnitudes exact.

emit_spec() {  # $1=angle $2=halfmag $3=radius $4="PX PY PZ" $5="plx ply plz"
  read -r PX PY PZ <<<"$4"
  read -r LX LY LZ <<<"$5"
  {
    cat <<EOF
entry   0x005b0e90
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00240000 0x00000100
maxsteps 400000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    echo "arg 0x240000"                 # a1 = p_pos ptr
    echo "arg $(a32 "$1")"              # a2 = angle
    echo "arg $(a32 "$2")"              # a3 = halfmag
    echo "arg $(a32 "$3")"             # a4 = radius
    poke 0x240000 "$PX"; echo; poke 0x240004 "$PY"; echo; poke 0x240008 "$PZ"; echo
    poke 0x230004 "$LX"; echo; poke 0x230008 "$LY"; echo; poke 0x23000c "$LZ"; echo
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Leaf oracle FUN_005b0e90 (lane perpendicular distance). this=pl; args (p_pos@0x240000, angle, halfmag, radius)." >> "$OUT"
echo "# Row: B0E90 <name> <steps> EAX=<dist>  (13107200 == 0xc80000 == off-lane sentinel)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ANG HM RAD PP PL <<<"$row"
  emit_spec "$ANG" "$HM" "$RAD" "$PP" "$PL"
  run_emu
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  EAX=$(echo "$RET" | grep -oE 'EAX=[0-9-]+' | head -1)
  STEPS=$(echo "$RET" | grep -oE '(RET|HALT) steps=[0-9]+')
  echo "B0E90 $NAME $STEPS $EAX" >> "$OUT"
done
echo "=== b0e90 oracle -> $OUT ==="
cat "$OUT"
