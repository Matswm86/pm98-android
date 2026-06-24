#!/usr/bin/env bash
# Oracle for FUN_005ad970 (737 B, __fastcall this=player): the case-0x36 AI "lay-off / short-feed"
# action handler. Clears ball+0x63, sets player+0x5e=1; then UNLESS the set-piece predicate holds
# (gs+0x2ee && FUN_005943b0(match) && player+0x5c) it re-rolls touch/power (player+0x58 = rng*4/0x8000
# +0xc, player+0x54 = rng*3/0x8000+0xd) and biases the facing player+0x34 toward/away from the
# WORST-rated teammate at its pitch position (self table player+0xe4[idx]). Then it casts a corridor from
# the temporarily forward-displaced player along the facing and asks FUN_005b1100 for the nearest
# teammate in it: hit -> aim (player+0xa0/a4/a8) = teammate pos, ball+0x4c = teammate; miss -> a blind
# polar throw (one extra rng draw). Ends with FUN_005ac1a0 (= setup_shot). Drives the REAL fn under the
# PCode emulator.
#
# STUBBED: FUN_005ac1a0 (setup_shot, ported+verified separately -> run_shotsetup_oracle.sh) so this
#   measures ONLY ad970's residue; FUN_005943b0 (match play-state predicate -> return 1 = play_state 0,
#   so the predicate is gated by gs+0x2ee and player+0x5c alone).
# RUN REAL (in-image leaves): FUN_005ec250 (rng, traced), FUN_005ee0f0 (polar), FUN_005b1100 (roster
#   corridor scan) -> FUN_005b0e90 (per-candidate corridor perp distance) -> FUN_005ee500 (dot16),
#   FUN_005ee540 (cross16), and the FP perp magnitude (FILD/FSQRT + ftol).
# SURROGATE: ftol via the 0x6233a4 IAT thunk (CALL 0x605fb0 -> jmp [0x6233a4]) -> the truncate-and-keep
#   surrogate at 0x252000 (FNSTCW/OR 0xc/FLDCW/FIST -- truncate toward zero, does NOT pop ST0 so the
#   caller's trailing FSTP balances). The perp distance is a sqrt(sum of squares), generally
#   non-perfect-square, so truncation matters (the shotsetup key finding).
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); ball+0x1d4 ->
#   match. gs@0x280000 (P+0x184): gs+0 = roster firstptr (0x2a0000), gs+4 = count, gs+0x2ee = set-piece
#   flag. roster1@0x290000 (P+0x188): SHARED firstptr (0x2a0000) + count -- the min-skill scan and the
#   corridor scan iterate the same players. teammates tm_k @ 0x2a0000 + k*0x3bc (stride 0x3bc).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/ad970_oracle.txt
SPEC=$SPECDIR/_ad970_run.spec
ROUT=$SPECDIR/_ad970_run.out
LUT=$SPECDIR/_ad970_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball, ball+0x1d4 -> match. P+0x184 -> gs, P+0x188 -> roster1.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x2701d4 0x260000)"
PTRS="$PTRS;$(poke 0x230184 0x280000);$(poke 0x230188 0x290000)"
# gs+0 / roster1+0 share the teammate firstptr 0x2a0000.
PTRS="$PTRS;$(poke 0x280000 0x2a0000);$(poke 0x290000 0x2a0000)"
GLOB="$(poke 0x6d3184 0x12345678)"
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x5ac1a0 0 0 SETUP"     # FUN_005ac1a0 = setup_shot (ported separately; isolate ad970 residue)
  "0x5943b0 1 0 PHASE0"    # FUN_005943b0 play-state predicate -> 1 (play_state == 0)
)

READS=(
  "0x00270063 1"  # ball+0x63 = 0
  "0x0023005e 1"  # player+0x5e = 1
  "0x00230058 4"  # player+0x58 (touch, recomputed)
  "0x00230054 4"  # player+0x54 (power, recomputed in non-special)
  "0x00230034 2"  # player+0x34 (facing, biased)
  "0x002300a0 4"  # player+0xa0 aim.x
  "0x002300a4 4"  # player+0xa4 aim.y
  "0x002300a8 4"  # player+0xa8 aim.z
  "0x0027004c 4"  # ball+0x4c (hit teammate ptr, else unchanged)
  "0x00230004 4"  # player+0x4  (displaced then restored)
  "0x00230008 4"  # player+0x8
  "0x0023000c 4"  # player+0xc
  "0x006d3184 4"  # RNG seed
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005ad970
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00002000
maxsteps 6000000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    echo "trace 0x005ec250 RNG"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Common base: guard (P+0x2c=0x13, P+0x30=0); facing 0; touch/power seeds; non-special (P+0x5c=0).
# gs+4 / roster1+4 = 2 teammates. tm0 @0x2a0000 idx=1 (+0x2b8=0,+0x2c4=1), tm1 @0x2a03bc idx=2.
# self per-position skill table: P+0xe4[1]=0x100000 (tm0, the WORST), P+0xe4[2]=0x200000 (tm1).
# self bias short P+0xb8[1] (@0x2300ba) = 0 -> JLE -> the +0x222 facing bias. teammates active (+0x2bc=1).
# tm0 placed forward on +x at 0x2fa000 (in the corridor for the BASE mag), tm1 off to the side (y huge).
BASE="$(poke 0x23002c 0x13);$(poke 0x230030 0);$(poke 0x230034 0)"
BASE="$BASE;$(poke 0x230054 0xd);$(poke 0x230058 0x10);$(poke 0x23005c 0)"
BASE="$BASE;$(poke 0x280004 2);$(poke 0x290004 2);$(poke 0x2802ee 0)"
BASE="$BASE;$(poke 0x2a02bc 1);$(poke 0x2a02b8 0);$(poke 0x2a02c4 1)"
BASE="$BASE;$(poke 0x2a0004 0x2fa000);$(poke 0x2a0008 0);$(poke 0x2a000c 0)"
BASE="$BASE;$(poke 0x2a0678 1);$(poke 0x2a0674 0);$(poke 0x2a0680 2)"          # tm1 +0x2bc/+0x2b8/+0x2c4
BASE="$BASE;$(poke 0x2a03c0 0x100000);$(poke 0x2a03c4 0x500000);$(poke 0x2a03c8 0)"  # tm1 pos +4/+8/+c
BASE="$BASE;$(poke 0x2300e8 0x100000);$(poke 0x2300ec 0x200000);$(poke 0x2300ba 0)"

FIX=(
  # nonspecial_hit: P+0x5c=0 -> rng p58/p54 + worst-teammate facing bias (+0x222) + corridor hit (tm0).
  "nonspecial_hit|"

  # special_hit: gs+0x2ee=1 + P+0x5c=1 -> special (p58=p58/2+8, no rng/bias) + corridor hit. 0 rng draws.
  "special_hit|$(poke 0x2802ee 1);$(poke 0x23005c 1)"

  # nonspecial_miss: teammates moved off-axis (y=0x900000) -> corridor miss -> blind polar (4 rng draws).
  "nonspecial_miss|$(poke 0x2a0008 0x900000);$(poke 0x2a03c4 0x900000)"

  # special_miss: special + off-axis teammates -> fallback (1 rng draw).
  "special_miss|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2a0008 0x900000);$(poke 0x2a03c4 0x900000)"

  # bias_gt0: worst-teammate bias short P+0xb8[1] = 5 (>0) -> the -0x222 facing bias branch.
  "bias_gt0|$(poke 0x2300ba 5)"

  # no_teammate: empty rosters (count 0) -> no worst teammate (skip bias), corridor miss -> fallback (3).
  "no_teammate|$(poke 0x280004 0);$(poke 0x290004 0)"

  # two_corridor: tm1 ALSO forward but at larger perp than tm0 -> min-perp picks tm0 (verifies selection).
  "two_corridor|$(poke 0x2a03c0 0x2c0000);$(poke 0x2a03c4 0x40000)"
)

: > "$OUT"
echo "# Oracle FUN_005ad970 (case 0x36 AI lay-off). this=player. FUN_005ac1a0/005943b0 stubbed." >> "$OUT"
echo "# reads: ball+0x63/4c, player+0x5e/54/58/34/aim(a0/a4/a8)/pos(4/8/c), seed. corridor leaf runs REAL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== ad970 oracle -> $OUT ==="
cat "$OUT"
