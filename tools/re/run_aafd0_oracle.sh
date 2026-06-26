#!/usr/bin/env bash
# Oracle for FUN_005aafd0 (the non-controller possession tail, the last settle leaf). Drives the REAL
# function from entry 0x5aafd0 (ECX = player p, char param_2 as a cdecl stack `arg` = 1). Banks the rng
# DRAW COUNT (trace 0x5ec250), every field write, the return EAX, and the final LCG state (0x6d3184).
# GROUND TRUTH for Pm98Movement.possession_tail_aafd0 (app/tests/test_aafd0.gd).
#
# Leaf calls run for real: FUN_005b1230 (vec3 *scalar) + FUN_005a1700 (vec3 +) for the carrier lead point,
# FUN_005ee080 (atan) + FUN_005ee0f0 (polar) via the cos/atan LUT + the _ftol round-to-zero thunk,
# FUN_005a5430 (set_position_code), and FUN_005ec250 (rand) off DAT_006d3184. FUN_00590f00 (audio) is
# avoided by m+0x180a == 0. DAT_006d31c4 == 0 so the (p+0x3b8)+0x90 telemetry counter increments.
#
# MEM MAP: p @0x230000 (ECX). p+0x190=ball @0x280000, p+0x18c=m @0x2a0000, p+0x184=gs @0x2b0000,
# ball+0x40=carrier @0x2c0000, p+0x3b8=stats @0x2d0000. Distances kept axis-aligned (exact perfect squares)
# so ftol truncation matches int(sqrt()).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/aafd0_oracle.txt
SPEC=$SPECDIR/_aafd0_run.spec
ROUT=$SPECDIR/_aafd0_run.out
LUT=$SPECDIR/_aafd0_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# _ftol thunk (round-to-zero), same bytes as the arm2/7260 oracles; IAT slot 0x6233a4 -> it.
THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Shared wiring: struct pointers, rng seed, the replay flag clear (telemetry increments), audio off.
CONST="$(poke 0x230190 0x280000);$(poke 0x23018c 0x2a0000);$(poke 0x230184 0x2b0000);$(poke 0x2303b8 0x2d0000)
$(poke 0x6d3184 0x4d2);$(poke 0x6d31c4 0);$(poke 0x2a180a 0)"

READS="read_mem 0x00230020 4
read_mem 0x00230024 4
read_mem 0x00230028 4
read_mem 0x00230080 4
read_mem 0x00230084 4
read_mem 0x00230066 2
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x002300ac 4
read_mem 0x00230060 1
read_mem 0x00230062 1
read_mem 0x002d0090 4
read_mem 0x006d3184 4"

# name|extra-pokes. p.pos zeroed; param_2 = 1 (threshold 0x38000). gs+0x31c tier, p+0x384 stat, p+0x68, p+0x390.
# bvf_*: ball+0x54==team(0) -> bVar2 false -> refpt = ball+0x174. bvt: ball+0x54!=team + carrier on-pitch open.
FIX=(
  "bvf_near|$(poke 0x280174 0x8000);$(poke 0x2b031c 1);$(poke 0x230384 50);$(poke 0x230390 50)"
  "bvf_far|$(poke 0x280174 0x30000);$(poke 0x2b031c 1);$(poke 0x230384 80);$(poke 0x230068 0x4000);$(poke 0x230390 40)"
  "bvf_bigp68|$(poke 0x280174 0x30000);$(poke 0x2b031c 1);$(poke 0x230384 40);$(poke 0x230068 0x9000);$(poke 0x230390 30)"
  "bvt|$(poke 0x280054 5);$(poke 0x280040 0x2c0000);$(poke 0x2c02bc 1);$(poke 0x2c0040 0x1e);$(poke 0x2c0004 0x10000);$(poke 0x2c0020 0x1000);$(poke 0x2b031c 1);$(poke 0x230384 60);$(poke 0x230068 0x4000);$(poke 0x230390 50)"
  "gate_ballz|$(poke 0x280174 0x8000);$(poke 0x28000c 0x3333);$(poke 0x2b031c 1);$(poke 0x230384 50)"
  "gate_caroff|$(poke 0x280174 0x8000);$(poke 0x280040 0x2c0000);$(poke 0x2c02bc 0);$(poke 0x2b031c 1);$(poke 0x230384 50)"
  "gate_engaged|$(poke 0x280174 0x8000);$(poke 0x28004c 0x230000);$(poke 0x2b031c 1);$(poke 0x230384 50)"
  "gate_heading|$(poke 0x280178 0x30000);$(poke 0x2b031c 1);$(poke 0x230384 50)"
  "gate_far|$(poke 0x280174 0x40000);$(poke 0x2b031c 1);$(poke 0x230384 50)"
)

emit_spec() {  # $1 = extra-pokes
  {
    cat <<EOF
entry   0x005aafd0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
arg     0x1
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
zero    0x002b0000 0x00001000
zero    0x002c0000 0x00001000
zero    0x002d0000 0x00001000
maxsteps 4000000
stub    0x00605ff0 0 0 atexit
trace   0x005ec250 RNG
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "${CONST//;/$'\n'}"
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
echo "# Oracle FUN_005aafd0 (non-controller possession tail). Field mutations + EAX + rng draw count read at" >> "$OUT"
echo "# RET. Row: AAFD0 <name> eax=<v> draws=<n> | <abs-addr>=<signed LE> ... . p=0x230000 ball=0x280000" >> "$OUT"
echo "# m=0x2a0000 gs=0x2b0000 carrier=0x2c0000 stats=0x2d0000; rng final = 0x6d3184." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  EAX=$(echo "$LINE" | grep -oE 'EAX=[0-9-]+' | head -1 || true); EAX=${EAX:-EAX=0}
  DRAWS=$(echo "$LINE" | grep -oE 'RNG=[0-9]+' | head -1 || true); DRAWS=${DRAWS:-RNG=0}
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  echo "AAFD0 $NAME $EAX draws=${DRAWS#RNG=} | $KV" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  $EAX  ${DRAWS}"
done
echo "=== aafd0 oracle -> $OUT ==="
cat "$OUT"
