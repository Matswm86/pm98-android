#!/usr/bin/env bash
# H2-restart in-place rebuild evidence: pin the WRITE-SET of the per-player builder
# FUN_005a2830 (the FUN_005b6ba0 kickoff-reset callee). The binary re-runs this ctor
# on the SAME player memory at every restart rung (restart_handler L96-102 5b6ba0 x2),
# so fields it does NOT write retain their previous-half values. The GDScript port
# rebuilds player Dicts from scratch, which silently zeroes unwritten fields -- this
# oracle decides which fields the in-place H2 rebuild must PRESERVE vs RESET.
#
# Method: two identical runs of the playerbuild fixture (outfield slot 5, BASE_REC of
# run_playerbuild_oracle.sh), differing ONLY in the pre-fill of P (0x3bc bytes):
# run A = 0x00-fill, run B = 0xAA-fill. Readback = every dword of P (0x00..0x3bc)
# plus byte-granular 0x2c..0x78 (the engine action-state window). Classification:
#   A==B            -> WRITTEN by the ctor (value is input-derived, fill-independent)
#   A==0, B==0xAA.. -> NOT written (in-place rebuild must keep the old value)
#   else            -> PARTIAL/fill-dependent (flag for manual disasm read)
# Same emulation wrinkles as run_playerbuild_oracle.sh (_ftol/lstr/sprintf stubs).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/playerbuild_writeset.txt
SPEC=$SPECDIR/_playerbuild_ws.spec
ROUT=$SPECDIR/_playerbuild_ws.out

P=0x230000 ; M=0x210000 ; R=0x240000

AA=$(printf 'aa%.0s' $(seq 956))   # 0x3bc bytes of 0xAA

BASE_REC="mem 0x240034 1 0x32 ; mem 0x240035 1 0x28 ; mem 0x240036 1 0x5a ; mem 0x240037 1 0x0a ; mem 0x240038 1 0x40 ; mem 0x24003c 1 0x3c ; mem 0x24003d 1 0x46 ; mem 0x24003e 1 0x50 ; mem 0x24003f 1 0x4b ; mem 0x240040 1 0x55 ; mem 0x240041 1 0x3a ; mem 0x240042 1 0x2d ; mem 0x240044 1 0x03 ; mem 0x24002c 1 0x02 ; mem 0x240030 1 0x01 ; mem 0x240098 1 0x01 ; mem 0x240008 4 0x11112222 ; mem 0x240018 4 0x33334444"

emit_spec() {
  # $1 = P pre-fill membts line ("" for zero-fill)
  cat > "$SPEC" <<EOF
entry   0x5a2830
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $P
arg     0
arg     5
arg     $M
arg     $R
zero    0x00210000 0x00003000
zero    0x00230000 0x00001000
zero    0x00240000 0x00000400
zero    0x00255000 0x00004000
$1
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x00623054 4 0x00254000
mem 0x00623040 4 0x00254010
mem 0x006233cc 4 0x00254020
stub 0x00254000 0 8
stub 0x00254010 0 4
stub 0x00254020 0 0
stub 0x005ec1d0 0 0
stub 0x005c9f60 0 8
stub 0x005d4ac0 0 4
mem 0x00674628 1 0x1
mem 0x00212550 4 0x00255000
mem 0x0021046c 4 $P
mem 0x00210758 1 0x1
mem 0x00210788 4 0x2
mem 0x00240004 4 0x0000270f
EOF
  POKES=${BASE_REC//;/$'\n'}
  echo "$POKES" >> "$SPEC"
  {
    echo "maxsteps 8000000"
    for ((o=0; o<0x3bc; o+=4)); do printf 'read_mem 0x%x 4\n' $((0x230000+o)); done
    for ((o=0x2c; o<0x78; o++)); do printf 'read_mem 0x%x 1\n' $((0x230000+o)); done
  } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1
}

emit_spec ""
LINE_A=$(run_emu)
emit_spec "membts $P $AA"
LINE_B=$(run_emu)

python3 - "$LINE_A" "$LINE_B" > "$OUT" <<'EOF'
import re, sys
a_line, b_line = sys.argv[1], sys.argv[2]
def parse(line):
    d = {}
    for m in re.finditer(r"mem\[0x([0-9a-f]+):([0-9]+)\]=(-?[0-9]+)", line):
        d[(int(m.group(1),16), int(m.group(2)))] = int(m.group(3))
    return d
A, B = parse(a_line), parse(b_line)
ret_a = "RET" in a_line; ret_b = "RET" in b_line
print(f"# FUN_005a2830 write-set (P=0x230000, outfield slot 5, team 0). runA(zero) ret={ret_a} runB(0xAA) ret={ret_b}")
print("# off  size  runA        runB        verdict")
AAV = {4: 0xAAAAAAAA, 1: 0xAA}
for (addr, size) in sorted(A):
    off = addr - 0x230000
    va, vb = A.get((addr,size)), B.get((addr,size))
    ua = va & (0xFFFFFFFF if size==4 else 0xFF) if va is not None else None
    ub = vb & (0xFFFFFFFF if size==4 else 0xFF) if vb is not None else None
    if ua == ub:
        verdict = "WRITTEN"
    elif ua == 0 and ub == AAV[size]:
        verdict = "UNTOUCHED"
    else:
        verdict = "PARTIAL/FILL-DEP"
    print(f"0x{off:03x} {size}  {ua:>10} {ub:>10}  {verdict}")
EOF
echo "=== writeset -> $OUT ==="
grep -cE "WRITTEN|UNTOUCHED|PARTIAL" "$OUT" || true
grep "UNTOUCHED\|PARTIAL" "$OUT" | head -60
