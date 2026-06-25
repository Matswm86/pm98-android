#!/usr/bin/env bash
# Leaf oracle for FUN_005b1070 (__thiscall, RET 0xc) + the FUN_005b0fd0 min-loop it tail-calls: the
# lane-CLEARANCE query (closest OTHER active player's perpendicular distance to the p->target lane).
# Drives the REAL function under the Ghidra PCode emulator and banks EAX. GROUND TRUTH that
# Pm98Movement._lane_clearance (-> _lane_min_dist -> _lane_perp_dist) must reproduce (test_b1070.gd).
#
# this(ECX) = p. 3 stack args: a1 = gs, a2 = target(ball) vec3 ptr, a3 = radius. b1070 computes
# angle = atan(target - p.pos), halfmag = planar_mag(target - p.pos), then FUN_005b0fd0(p, gs, angle,
# halfmag, radius): MIN over players[i] (gs+0 base, gs+4 count, stride 0x3bc) of FUN_005b0e90, skipping
# inactive (pl+0x2bc==0) and p itself. All geometry leaves real (5ee080/5b1260/5ee0f0/5ee500/5ee540 +
# _ftol via 0x6233a4 -> 0x252000). Trig LUT injected. Off-lane sentinel = 0xc80000 = 13107200.
#
# Memory: p @0x230000 (ECX, p.pos +4/8/c, active +0x2bc), gs @0x250000 (+0 base, +4 count),
# target @0x240000, player array @0x270000 (stride 0x3bc). skipself fixture overlaps base=p=0x230000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b1070_oracle.txt
SPEC=$SPECDIR/_b1070_run.spec
ROUT=$SPECDIR/_b1070_run.out
LUT=$SPECDIR/_b1070_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Player record helpers (base + i*0x3bc). P0BASE varies (separate 0x270000, or overlap p 0x230000).
# pl: +4/8/c pos, +0x2bc active. p.pos = (0,0,0); target = (0x80000,0,0) -> lane +x, len ~0x80000.
PP="$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0)"          # p.pos
TGT="$(poke 0x240000 0x80000);$(poke 0x240004 0);$(poke 0x240008 0)"   # target (ball) pos

# name|count|arraybase|pokes
FIX=(
  # both players inactive (pl+0x2bc==0) -> all skipped -> sentinel.
  "none|2|0x270000|$(poke 0x270004 0x40000);$(poke 0x270008 0x20000);$(poke 0x2702bc 0);$(poke 0x2703c0 0x40000);$(poke 0x270678 0)"
  # one active player at perp 0x20000 off the midpoint -> ~130672.
  "one|2|0x270000|$(poke 0x270004 0x40000);$(poke 0x270008 0x20000);$(poke 0x2702bc 1);$(poke 0x2703c0 0x40000);$(poke 0x2703c4 0x20000);$(poke 0x270678 0)"
  # two active: p0 perp 0x20000, p1 perp 0x10000 -> MIN = the smaller (p1).
  "min2|2|0x270000|$(poke 0x270004 0x40000);$(poke 0x270008 0x20000);$(poke 0x2702bc 1);$(poke 0x2703c0 0x40000);$(poke 0x2703c4 0x10000);$(poke 0x270678 1)"
  # one active but OFF lane (y past bbox) -> sentinel.
  "offlane|1|0x270000|$(poke 0x270004 0x40000);$(poke 0x270008 0x70000);$(poke 0x2702bc 1)"
  # SELF-SKIP: array base == p (0x230000); p0 == p (active, at lane origin) MUST be skipped; p1 active
  # at perp 0x20000. If skip failed, min would be ~0 (p at origin); correct result == p1 ~130672.
  "skipself|2|0x230000|$(poke 0x2302bc 1);$(poke 0x2303c0 0x40000);$(poke 0x2303c4 0x20000);$(poke 0x230678 1)"
)

emit_spec() {  # $1=count $2=arraybase $3=pokes
  {
    cat <<EOF
entry   0x005b1070
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00240000 0x00000100
zero    0x00250000 0x00000100
zero    0x00270000 0x00001000
maxsteps 400000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    echo "arg 0x250000"                 # a1 = gs
    echo "arg 0x240000"                 # a2 = target ptr
    echo "arg 0x20000"                  # a3 = radius
    poke 0x250000 "$2"; echo            # gs+0 = player array base
    poke 0x250004 "$1"; echo            # gs+4 = count
    printf '%s\n' "${PP//;/$'\n'}"
    printf '%s\n' "${TGT//;/$'\n'}"
    printf '%s\n' "${3//;/$'\n'}"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Leaf oracle FUN_005b1070 + FUN_005b0fd0 (lane clearance = min OTHER-player perp dist)." >> "$OUT"
echo "# Row: B1070 <name> <steps> EAX=<mindist>  (13107200 == off-lane / none-active sentinel)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME CNT BASE POKES <<<"$row"
  emit_spec "$CNT" "$BASE" "$POKES"
  run_emu
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  EAX=$(echo "$RET" | grep -oE 'EAX=[0-9-]+' | head -1)
  STEPS=$(echo "$RET" | grep -oE '(RET|HALT) steps=[0-9]+')
  echo "B1070 $NAME $STEPS $EAX" >> "$OUT"
done
echo "=== b1070 oracle -> $OUT ==="
cat "$OUT"
