#!/usr/bin/env bash
# Oracle for the FUN_005a7260 marker TAIL (0x5a8457..0x5a85ac, slice 2b-iii-e). Same mid-function drive as
# the marker-APPLY oracle (build -> scan -> apply), but we DO NOT stub 0x5a8457: we let the tail run for
# real (carrier check + two L-inf proximity gates) and let it call the arm-2 active tail FUN_005aa870(1)
# for real. We stub the SHARED epilogue 0x5a85a2 instead -- at that point esp is back at the as-if-called
# position ([esp] = retSentinel), so the stub pops it and returns cleanly without unwinding a mid-fn frame.
#
# Every fixture is a NOHIT scan (best-idx stays -1, apply no-op, local_159 == 0); the read-back m+0x461
# confirms applied=0. gate ref point = polar(0x4ccc, facing) + p.pos vs ball+0x138/13c/140. work[3].z
# (== ball+0x140) only pushes markers 0/1 FURTHER from their z-gate, so a large value preserves nohit; the
# gate-2 recovery uses p.vel.z (p+0x28), which the scan never reads. The handoff target FUN_005aa870 runs
# for real (its own oracle is run_arm2tail_oracle.sh); p+0x80 == 1 (and set_position_code -> p+0x40 == 5)
# is the "arm-2 ran" discriminator. GROUND TRUTH for Pm98Movement._marker_tail (app/tests/test_7260markertail.gd).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260markertail_oracle.txt
SPEC=$SPECDIR/_7260markertail_run.spec
ROUT=$SPECDIR/_7260markertail_run.out
LUT=$SPECDIR/_7260markertail_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

THUNKS="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring (== marker-apply oracle) PLUS the arm-2 tail deps: p+0x188 -> teamstruct -> ctx (slot/team
# 0 => sVar11 = p[0xb8] = 0), RNG seed DAT_006d3184 = 0. p.pos / facing default 0 (poked per fixture).
CONST="$(poke 0x23018c 0x2a0000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x2303b8 0x2c0000);$(poke 0x2801d4 0x2a0000);$(poke 0x2a1a38 1)
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 1)
$(poke 0x230188 0x2b0000);$(poke 0x2b0000 0x2d0000);$(poke 0x2d02b8 0);$(poke 0x2d02c4 0)
$(poke 0x6d31c4 0);$(poke 0x6d3184 0)"

# KICK_GRID1 / KICK_GRID2 lazy-init restore (== marker-apply oracle).
gv() { local base=$1; shift; local i=0 a; for a in "$@"; do echo "$(poke $(( base + i )) "$a")"; i=$(( i + 4 )); done; }
GRID1_INIT="$(gv 0x674280 \
  0x1b333 0 0x4000   0x9999 0 0x10000   0x9999 0 0x1cccc \
  0x21999 0x3555 0x3333   0x21999 0x3555 0xf333   0x21999 0x3555 0x1b333 \
  0x21999 -0x3555 0x3333  0x21999 -0x3555 0xf333  0x21999 -0x3555 0x1b333 | tr '\n' ';')"
GRID2_INIT="$(gv 0x674438 \
  0x14ccc 0 0   0x6666 0 0   0x6666 0 0 \
  0x18ccc 0x3555 0   0x18ccc 0x3555 0   0x18ccc 0x3555 0 \
  0x18ccc -0x3555 0  0x18ccc -0x3555 0  0x18ccc -0x3555 0 | tr '\n' ';')"

# Pass-0 best-state seed (== marker-apply oracle SEED_WORK): the pass-0 entry seeds the rest itself.
SEED_WORK="$(poke 0x308050 0);$(poke 0x308054 0);$(poke 0x308058 0)"

# Read back: m+0x461 (applied discriminator), then the arm-2 tail mutations.
READS="read_mem 0x002a0461 1
read_mem 0x00230048 4
read_mem 0x00230040 4
read_mem 0x00230080 4
read_mem 0x00230084 4
read_mem 0x002300a0 4
read_mem 0x002300a4 4
read_mem 0x002300a8 4
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x00230066 2
read_mem 0x0023005e 1
read_mem 0x006d3184 4"

# name|extra-pokes.  All NOHIT scans (no traj marker pokes). Arm-2 deps: facing p+0x34, vel p+0x20/24/28,
# base100 p+0x3a0, on-pitch p+0x2bc=1, ball.vel ball+0x20/24/28.  g1pass: all-zero -> gate1 passes.
# g2pass: ball+0x140 (work[3].z) large fails gate1.z, p.vel.z recovers gate2.  g2fail: same but p.vel.z=0.
# foreign/samecarrier: ball+0x40 -> carrier @0x2e0000 with team 1 (foreign) / 0 (same).
ARM2="$(poke 0x2303a0 50);$(poke 0x2302bc 1);$(poke 0x280020 0x6000);$(poke 0x280024 0x1000);$(poke 0x280028 -0x400)"
FIX=(
  "g1pass|$SEED_WORK;$(poke 0x230034 0x1000);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);$ARM2"
  "g2pass|$SEED_WORK;$(poke 0x280140 0x40000);$(poke 0x230028 0x40000);$(poke 0x230034 0);$(poke 0x230020 0x2000);$(poke 0x230024 -0x2000);$ARM2"
  "g2fail|$SEED_WORK;$(poke 0x280140 0x40000);$(poke 0x230028 0);$(poke 0x230034 0);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$ARM2"
  "foreign|$SEED_WORK;$(poke 0x280040 0x2e0000);$(poke 0x2e02b8 1);$(poke 0x230034 0x1000);$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);$ARM2"
  "samecarrier|$SEED_WORK;$(poke 0x280040 0x2e0000);$(poke 0x2e02b8 0);$(poke 0x230034 0x1000);$(poke 0x230020 0x4000);$ARM2"
)

emit_spec() {  # $1=extra-pokes
  {
    cat <<EOF
entry   0x005a7e23
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ESI 0x00230000
reg     ECX 0x00280000
zero    0x00230000 0x00001000
zero    0x00280000 0x00002000
zero    0x002a0000 0x00002000
zero    0x002b0000 0x00001000
zero    0x002c0000 0x00001000
zero    0x002d0000 0x00001000
zero    0x002e0000 0x00001000
zero    0x00674000 0x00002000
maxsteps 2000000
stub    0x00605ff0 0 0 atexit
stub    0x005a85a2 0 0 EPI
EOF
    cat "$LUT"
    printf '%s\n' "$THUNKS"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${GRID1_INIT//;/$'\n'}"
    printf '%s\n' "${GRID2_INIT//;/$'\n'}"
    printf '%s\n' "${1//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a7260 marker TAIL (0x5a8457..0x5a85ac). Mutations read back at the epilogue 0x5a85a2." >> "$OUT"
echo "# Row: TAIL <name> arm2=<0|1> applied=<0|1> | <abs-addr>=<signed LE> ... . p=0x230000 ball=0x280000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  if echo "$KV" | grep -q '0x230080=1 '; then ARM2RAN=1; else ARM2RAN=0; fi
  if echo "$KV" | grep -q '0x2a0461=0 '; then APPLIED=0; else APPLIED=1; fi
  echo "TAIL $NAME arm2=$ARM2RAN applied=$APPLIED | $KV" >> "$OUT"
  echo "[$NAME] arm2=$ARM2RAN applied=$APPLIED $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== 7260 marker-tail oracle -> $OUT ==="
cat "$OUT"
