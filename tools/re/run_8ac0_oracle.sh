#!/usr/bin/env bash
# Stage 3 (settle leaf "windup"): drive the REAL FUN_005a8ac0 through the Ghidra PCode emulator and
# bank the only field it writes itself -- p+0x6c (the curve/windup speed param) -- plus the heading it
# forwards to its tail-call FUN_005a8f20. GROUND TRUTH that Pm98Movement.windup_8ac0 reproduces
# bit-for-bit (app/tests/test_8ac0.gd).
#
# FUN_005a8ac0(this=p, heading, strength) is PURE INTEGER -- its only FPU is the tail-call to
# FUN_005a8f20 (steer APPLY, already oracle-GREEN via run_steering_oracle.sh). We STUB 0x5a8f20
# (M8F20) so NO LUT / NO ftol is needed; the stub trace `CALL 0 STUB M8F20 .. arg0=` confirms the
# heading passthrough, and read_mem p+0x6c banks the curve write.
#   p+0x6c = 0                                              when phase in {2,3,4,5,7} AND
#                                                           (M+0x461 & 0x40)==0 OR team-mismatch  [PARK]
#   p+0x6c = ((p+0x70 * p+0x3ac)/15000 * strength)/100 + p+0x3a8                                  [FORMULA]
#   strength is first cut to strength*0x4b/100 when p IS the ball controller (ball+0x40 == p).
#
# Memory map (zeroed windows, reusing the settle layout): P@0x230000 (ECX) M@0x260000 (P+0x18c)
# BALL@0x270000 (P+0x190) OTHER@0x2a0000 (the M+0x444 team-id holder for the mismatch fixture).
# Links: M+0x444 -> OTHER (team holder, +0x2b8); BALL+0x40 -> P (when p is the controller).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/8ac0_oracle.txt
SPEC=$SPECDIR/_8ac0_run.spec
ROUT=$SPECDIR/_8ac0_run.out

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

emit_spec() {  # $1 = newline-joined pokes ; $2 = heading ; $3 = strength
  {
    cat <<EOF
entry   0x005a8ac0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x002a0000 0x00001000
stub 0x5a8f20 0 4 M8F20
maxsteps 2000000
EOF
    printf '%s\n' "$1"
    printf 'arg 0x%x\n' "$2"          # arg0 = heading  (param_2 -> forwarded to 8f20)
    printf 'arg 0x%x\n' "$3"          # arg1 = strength (param_3)
    echo "read_mem 0x0023006c 4"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Shared links + the curve-formula inputs (p+0x70=15000, p+0x3ac=0x10000, p+0x3a8=0x111 unless noted).
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000)"
FORMULA="$(poke 0x230070 15000);$(poke 0x2303ac 0x10000);$(poke 0x2303a8 0x111)"
CTRL="$(poke 0x270040 0x230000)"      # BALL+0x40 = P (p IS the ball controller -> 75% strength cut)
TEAMP="$(poke 0x260444 0x2a0000)"     # M+0x444 -> OTHER (team-id holder)

# row: NAME|HEADING|STRENGTH|extra-pokes
FIX=(
"formula        |0x2222|100|"                                                   # phase 0 -> formula, no scale
"formula_str80  |0x1234|80|"                                                    # different strength
"formula_scale  |0x2222|100|$CTRL"                                              # p is controller -> 75%
"park_flagclear |0x3000|100|$(poke 0x260448 3)"                                 # phase 3, M+0x461&0x40==0 -> park
"park_mismatch  |0x4000|100|$(poke 0x260448 4);$(poke 0x260461 0x40);$TEAMP;$(poke 0x2302b8 10);$(poke 0x2a02b8 20)"  # flag set + team mismatch -> park
"noscale_match  |0x5000|100|$(poke 0x260448 5);$(poke 0x260461 0x40);$TEAMP;$(poke 0x2302b8 10);$(poke 0x2a02b8 10)"  # flag set + team match -> NOT park -> formula
"phase1_formula |0x6000|100|$(poke 0x260448 1)"                                 # phase 1 not in set -> formula
)

: > "$OUT"
echo "# Stage 3 settle leaf FUN_005a8ac0 (windup) PCode-emu truth. PURE INTEGER; tail-call 8f20 STUBBED." >> "$OUT"
echo "# Row: FIX <name> | 6c=<p+0x6c LE int32> | m8f20_arg0=<heading forwarded>. P=0x230000 M=0x260000" >> "$OUT"
echo "# BALL=0x270000 OTHER=0x2a0000. Formula inputs p+0x70=15000 p+0x3ac=0x10000 p+0x3a8=0x111." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME HEADING STRENGTH POKES <<<"$row"
  NAME=$(echo "$NAME" | xargs)   # trim
  POKES="$FORMULA;$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES" "$HEADING" "$STRENGTH"
  run_emu
  SIXC=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 | grep -oE 'mem\[0x23006c:4\]=[0-9-]+' | head -1)
  ARG0=$(grep -E 'CALL 0 STUB M8F20' "$ROUT" | head -1 | grep -oE 'arg0=[0-9-]+' | head -1)
  echo "FIX $NAME | $SIXC | m8f20_$ARG0" >> "$OUT"
  echo "[$NAME] $(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  $SIXC  m8f20_$ARG0"
done
echo "=== 8ac0 oracle -> $OUT ==="
cat "$OUT"
