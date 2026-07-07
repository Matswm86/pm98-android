#!/usr/bin/env bash
# DECIDE slice-C CASE 2 (kickoff) NON-TAKER ground truth via the Ghidra PCode emulator.
# The decideC oracle (run_decideC_oracle.sh) covers cases 3/6/7 + default but NOT case 2, so the
# port's _slice_c_case2_nontaker (the kickoff receiver bbox-blend) was never validated against the
# real FUN_005a3400. This drives the REAL function at match+0x448 == 2 for a NON-TAKER player and
# banks the move target -- the authoritative answer for where the real game places the kickoff
# receiver (slot-8). Same map/stubs as run_decideC_oracle.sh, plus real x/y-scale for the box.
#
# Memory map: player P0 @0x230000, match M @0x210000, team @0x240000, ball B @0x250000, taker T2
# @0x260000. Real Villa-Bolton scale: x(+0x1820)=3768320, y(+0x1824)=2359296, orient(+0x19a0)=0.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideC2_oracle.txt
SPEC=$SPECDIR/_decideC2_run.spec
ROUT=$SPECDIR/_decideC2_run.out
LUT=$SPECDIR/_decideC2_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"              # +4/+8/+0xc move target (the answer)
  "0x002301e0 4" "0x002301e4 4" "0x002301e8 4"              # +0x1e0 endpoint1 (slice-A mirror of startA)
  "0x00230040 4"                                            # +0x40 position code
)

emit_spec() {
  {
    cat <<EOF
entry   0x005a3400
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00001000
zero    0x00240000 0x00001000
zero    0x00250000 0x00001000
zero    0x00260000 0x00001000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
maxsteps 800000
stub 0x5bbf10 0 0
mem 0x006d31c4 1 0x0
mem 0x0023018c 4 0x00210000
mem 0x00230188 4 0x00240000
mem 0x00230190 4 0x00250000
mem 0x002302cc 4 0xffffffff
mem 0x00211820 4 0x398000
mem 0x00211824 4 0x240000
mem 0x00210438 4 0x00260000
EOF
    cat "$LUT"
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# common non-taker case-2 knobs: player team0 on-pitch (0x2bc nonzero), taker team differs.
# startB / roam / roam2 must be set so slice-A's box build (0059a0e0/005b11f0/005b12c0) runs.
COMMON="$(poke 0x2302b8 0);$(poke 0x2119a0 0);$(poke 0x210448 2);$(poke 0x2602b8 1)"
ROAM="$(poke 0x230204 3211366);$(poke 0x230208 -560034);$(poke 0x23020c 0);$(poke 0x230228 -616204);$(poke 0x23022c -1310720);$(poke 0x230230 3768319);$(poke 0x230234 1310720)"

FIX=(
# slot-8 REAL: startA(0x1f8)=(-201452,-607696,0), on-pitch(0x2bc=8), ball at center (0x90=0).
"slot8_real|$COMMON;$(poke 0x2302bc 8);$(poke 0x2301f8 -201452);$(poke 0x2301fc -607696);$(poke 0x230200 0);$ROAM"
# probe A: ep1 far BELOW the box in x (-9000000) -> if clamp active, x pinned to box min (=goalx -3768320).
"probe_xlo|$COMMON;$(poke 0x2302bc 8);$(poke 0x2301f8 -9000000);$(poke 0x2301fc -607696);$(poke 0x230200 0);$ROAM"
# probe B: ep1 far ABOVE box in x (+9000000) -> if clamp active, x pinned to box max (=0).
"probe_xhi|$COMMON;$(poke 0x2302bc 8);$(poke 0x2301f8 9000000);$(poke 0x2301fc -607696);$(poke 0x230200 0);$ROAM"
# probe C: ep1 y beyond +yscale (+9000000) -> clamp to +yscale (2359296).
"probe_yhi|$COMMON;$(poke 0x2302bc 8);$(poke 0x2301f8 -201452);$(poke 0x2301fc 9000000);$(poke 0x230200 0);$ROAM"
)

: > "$OUT"
echo "# DECIDE slice-C CASE 2 (kickoff) NON-TAKER PCode-emu ground truth. phase=2, non-taker." >> "$OUT"
echo "# xscale=3768320 yscale=2359296 orient=0 team0 on-pitch. mv=+0x4/8/c ep1=+0x1e0/4/8." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  mv4=$(echo "$LINE" | grep -oE 'mem\[0x230004:4\]=[0-9-]+' | cut -d= -f2)
  mv8=$(echo "$LINE" | grep -oE 'mem\[0x230008:4\]=[0-9-]+' | cut -d= -f2)
  e0=$(echo "$LINE" | grep -oE 'mem\[0x2301e0:4\]=[0-9-]+' | cut -d= -f2)
  e4=$(echo "$LINE" | grep -oE 'mem\[0x2301e4:4\]=[0-9-]+' | cut -d= -f2)
  echo "[$NAME] move=(${mv4:-?},${mv8:-?})  ep1=(${e0:-?},${e4:-?})"
done
echo "=== decideC2 oracle -> $OUT ==="
cat "$OUT"
