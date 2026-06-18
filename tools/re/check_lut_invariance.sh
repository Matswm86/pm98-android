#!/usr/bin/env bash
# Stage 2 proof: the resolver FUN_005aeda0's RNG draw stream + final RNG state are
# INVARIANT to the trig LUT (DAT_006d31c8). The LUT lives in .bss (zero at emulation
# start); decoding/seeding it would be needed only if geometry changed the draws.
# This runs the baseline decision-tree fixture twice -- once with a zero LUT, once
# with a reconstructed cos table (LUT[k]=round(65536*cos(2*pi*k/4096)), the exact
# form FUN_005ee0f0 indexes) -- and asserts the draw stream + final state match.
# If they match, the decision tree can be ported faithfully WITHOUT the LUT (the
# real sin/cos coordinates are Stage 3 movement work). Exit 0 = invariant.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
BASE="$SPECDIR/_lut_zero.spec"
SEED="$SPECDIR/_lut_seed.spec"

# Baseline fixture (all branch inputs 0), zero LUT.
sed -e 's/__PANG__/0x0/' -e 's/__TANG__/0x0/' -e 's/__POS__/0x0/' \
    -e 's/__ENGAGED__/0x0/' -e 's/__SKILL__/0x0/' -e 's/__HDR__/0x0/' \
    "$SPECDIR/resolver_tree.tmpl" > "$BASE"

# Same fixture + a seeded cos LUT (16 KB membts at 0x6d31c8).
python3 - "$BASE" "$SEED" <<'PY'
import math, sys
src, dst = sys.argv[1], sys.argv[2]
lut = bytearray()
for k in range(4096):
    lut += (round(65536*math.cos(2*math.pi*k/4096)) & 0xffffffff).to_bytes(4, 'little')
text = open(src).read().replace(
    "mem 0x006d3184 4 0x1",
    "mem 0x006d3184 4 0x1\nmembts  0x006d31c8 " + lut.hex() + "   # reconstructed cos LUT")
open(dst, 'w').write(text)
PY

run() { "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
          -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$1" "$2" \
          >/dev/null 2>&1 || true; }
stream() { grep -oE 'TRACE rng #[0-9]+ step=[0-9]+ EAX=[0-9]+' "$1" | grep -oE 'EAX=[0-9]+' \
             | cut -d= -f2 | paste -sd, -; }
state()  { grep -E 'CALL 0 (RET|HALT)' "$1" | grep -oE 'mem\[0x6d3184:4\]=[0-9]+' | cut -d= -f2; }

run "$BASE" "$SPECDIR/_lut_zero.out"
run "$SEED" "$SPECDIR/_lut_seed.out"
ZD=$(stream "$SPECDIR/_lut_zero.out"); ZS=$(state "$SPECDIR/_lut_zero.out")
SD=$(stream "$SPECDIR/_lut_seed.out"); SS=$(state "$SPECDIR/_lut_seed.out")
echo "zero-LUT : draws=$ZD state=$ZS"
echo "seeded   : draws=$SD state=$SS"
if [[ "$ZD" == "$SD" && "$ZS" == "$SS" ]]; then
  echo "PASS: draw stream + final RNG state are LUT-invariant."
else
  echo "FAIL: LUT changes the draw stream -- the LUT MUST be seeded for the port."; exit 1
fi
