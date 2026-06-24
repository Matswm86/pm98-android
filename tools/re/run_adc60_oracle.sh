#!/usr/bin/env bash
# Oracle for FUN_005adc60 (854 B, __fastcall this=player): the case-0x37 AI "lay-off / short-feed",
# the NEAR-TWIN of FUN_005ad970 (case 0x36). Clears ball+0x63, sets player+0x5e=0 (NOT 1). Unlike 0x36
# the set-piece SPECIAL case does NOTHING in the top block -- ONLY the non-special branch re-rolls
# touch/power, and it does so with FOUR rng draws (player+0x58 = rng*2/0x8000+6, player+0x54 =
# rng*3/0x8000+0xd, then player+0x58 = rng*4/0x8000+0xc, player+0x54 = rng*3/0x8000+0xd -- the first
# pair is OVERWRITTEN but the rng IS consumed), then biases the facing player+0x34 toward/away the
# WORST-rated teammate (one extra draw if a worst teammate exists). The tail displaces the player
# forward by polar(player+0x54*0xe0000>>4 + 0xe0000, facing) and asks for a corridor teammate, BUT the
# scan fn is re-selected by the SAME set-piece predicate: SPECIAL -> FUN_005b1100 (corridor scan, as in
# ad970); non-special -> FUN_005b31a0 (the loose-ball / open-man search, mode 0). hit -> aim
# (player+0xa0/a4/a8) = teammate pos, ball+0x4c = teammate; miss -> a blind polar throw (fallback mag
# player+0x54*0x70000>>4 + 0xa0000 + rng*0xa00/0x80, one extra draw). Ends with FUN_005ac1a0 (=
# setup_shot). Drives the REAL fn under the PCode emulator.
#
# STUBBED: FUN_005ac1a0 (setup_shot, ported+verified separately) so this measures ONLY adc60's residue;
#   FUN_005943b0 (match play-state predicate -> return 1 = play_state 0, so the set-piece predicate is
#   gated by gs+0x2ee and player+0x5c alone).
# RUN REAL (in-image leaves): FUN_005ec250 (rng), FUN_005ee0f0 (polar), and BOTH corridor families --
#   FUN_005b1100 (corridor scan) -> FUN_005b0e90 (perp dist) -> FUN_005ee500/540 (dot16/cross16) + the FP
#   perp magnitude, AND FUN_005b31a0 (loose-ball search) -> FUN_005b3c10 (zone chance roll, DRAWS rng) +
#   FUN_005b3580 (attack-dir sign match). So the non-special path's rng count includes b31a0's b3c10
#   draws -- the GD port (loose_ball_search) must reproduce them.
# SURROGATE: ftol via the 0x6233a4 IAT thunk -> the truncate-toward-zero surrogate at 0x252000.
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190). gs@0x280000
# (P+0x184): gs+0 = outer roster firstptr (0x2a0000), gs+4 = count, gs+0x2ee = set-piece flag, gs+0x30c
# = zone (b3c10 threshold select). roster1 header@0x290000 (P+0x188): +0 = inner firstptr, +4 = count;
# the inner roster is 0x2a0000 (SHARED with gs) for most fixtures, but 0x2b0000 (SEPARATE) for the
# b31a0-HIT fixture so the chosen outer candidate is NOT self-matched away to ivar9=0. teammates tm_k @
# 0x2a0000 + k*0x3bc (stride 0x3bc); separate inner cB @ 0x2b0000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/adc60_oracle.txt
SPEC=$SPECDIR/_adc60_run.spec
ROUT=$SPECDIR/_adc60_run.out
LUT=$SPECDIR/_adc60_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball, ball+0x1d4 -> match. P+0x184 -> gs, P+0x188 -> roster1 header.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x2701d4 0x260000)"
PTRS="$PTRS;$(poke 0x230184 0x280000);$(poke 0x230188 0x290000)"
# gs+0 = outer roster firstptr 0x2a0000.
PTRS="$PTRS;$(poke 0x280000 0x2a0000)"
GLOB="$(poke 0x6d3184 0x12345678)"
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x5ac1a0 0 0 SETUP"     # FUN_005ac1a0 = setup_shot (ported separately; isolate adc60 residue)
  "0x5943b0 1 0 PHASE0"    # FUN_005943b0 play-state predicate -> 1 (play_state == 0)
)

READS=(
  "0x00270063 1"  # ball+0x63 = 0
  "0x0023005e 1"  # player+0x5e = 0 (NOT 1 -- the 0x36 difference)
  "0x00230058 4"  # player+0x58 (touch, reroll #3 in non-special; unchanged in special)
  "0x00230054 4"  # player+0x54 (power, reroll #4 in non-special; unchanged in special)
  "0x00230034 2"  # player+0x34 (facing, biased in non-special)
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
entry   0x005adc60
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00002000
zero    0x002b0000 0x00001000
maxsteps 8000000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    echo "trace 0x005ec250 RNG"
    echo "trace 0x005b3c10 B3C10"
    echo "trace 0x005b31a0 B31A0"
    echo "trace 0x005b1100 B1100"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Common base: guard (P+0x2c=6, P+0x30=0); facing 0; touch/power seeds; non-special (gs+0x2ee=0, P+0x5c=0).
# gs+4 / roster1+4 = 2 teammates; roster1 firstptr SHARED = 0x2a0000. tm0 @0x2a0000 idx=1, tm1 @0x2a03bc
# idx=2 (both active +0x2bc=1). self per-position skill table: P+0xe4[1]=0x100000 (tm0, the WORST),
# P+0xe4[2]=0x200000 (tm1). self bias short P+0xb8[1] (@0x2300ba) = 0 -> the +0x222 facing bias. tm0
# forward on +x at 0x2fa000 (in the corridor for the BASE mag); tm1 off to the side.
BASE="$(poke 0x23002c 6);$(poke 0x230030 0);$(poke 0x230034 0)"
BASE="$BASE;$(poke 0x230054 0xd);$(poke 0x230058 0x10);$(poke 0x23005c 0)"
BASE="$BASE;$(poke 0x280004 2);$(poke 0x290000 0x2a0000);$(poke 0x290004 2);$(poke 0x2802ee 0)"
BASE="$BASE;$(poke 0x2a02bc 1);$(poke 0x2a02b8 0);$(poke 0x2a02c4 1)"
BASE="$BASE;$(poke 0x2a0004 0x2fa000);$(poke 0x2a0008 0);$(poke 0x2a000c 0)"
BASE="$BASE;$(poke 0x2a0678 1);$(poke 0x2a0674 0);$(poke 0x2a0680 2)"          # tm1 +0x2bc/+0x2b8/+0x2c4
BASE="$BASE;$(poke 0x2a03c0 0x100000);$(poke 0x2a03c4 0x500000);$(poke 0x2a03c8 0)"  # tm1 pos +4/+8/+c
BASE="$BASE;$(poke 0x2300e8 0x100000);$(poke 0x2300ec 0x200000);$(poke 0x2300ba 0)"

FIX=(
  # nonspecial_miss: non-special -> 4 rerolls + worst-teammate bias (+0x222); tail uses b31a0 over the
  # SHARED roster -> every outer candidate is its own inner candidate (h=0 -> ivar9=0 -> score 0) so
  # b31a0 returns 0 -> miss -> blind polar fallback (1 more draw). player near goal -> no b3c10.
  "nonspecial_miss|"

  # special_hit: gs+0x2ee=1 + P+0x5c=1 -> special (no top-block rng) + tail uses b1100 -> corridor hit
  # (tm0 forward). 0 rng draws. p58/p54 unchanged (0x10/0xd).
  "special_hit|$(poke 0x2802ee 1);$(poke 0x23005c 1)"

  # special_miss: special + off-axis teammates -> b1100 miss -> fallback (1 rng draw).
  "special_miss|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2a0008 0x900000);$(poke 0x2a03c4 0x900000)"

  # nonspecial_hit: SEPARATE inner roster (0x2b0000, one cB idx=3 with huge skill so it is skipped in
  # the inner scan) -> the outer candidate cA (tm0, idx1) keeps ivar9=0x7c72 -> high score -> b31a0
  # HIT. aim = cA pos, ball+0x4c = cA. draws: 4 rerolls + bias (worst=cB) = 5; b31a0 no b3c10.
  "nonspecial_hit|$(poke 0x290000 0x2b0000);$(poke 0x290004 1);$(poke 0x2b02b8 0);$(poke 0x2b02c4 3);$(poke 0x2b02bc 1);$(poke 0x2300f0 0xc80000);$(poke 0x2300be 0)"

  # bias_gt0: worst-teammate bias short P+0xb8[1] = 5 (>0) -> the -0x222 facing bias branch. (shared
  # roster -> b31a0 miss -> fallback.)
  "bias_gt0|$(poke 0x2300ba 5)"

  # no_teammate: empty rosters (count 0) -> no worst teammate (skip bias, 4 draws), b31a0 over empty ->
  # 0 -> fallback (1 draw) = 5 total.
  "no_teammate|$(poke 0x280004 0);$(poke 0x290004 0)"

  # chance_gate: player FAR from its goal (P+0x4=0x400000) -> the b31a0 distance gate fails for both
  # teammates -> FUN_005b3c10 fires (zone=0 -> threshold 100/1000) -> extra rng draws. Verifies the
  # b3c10 rng consumption + the seed parity through b31a0.
  "chance_gate|$(poke 0x230004 0x400000)"
)

: > "$OUT"
echo "# Oracle FUN_005adc60 (case 0x37 AI lay-off, near-twin of 0x36). this=player. setup_shot/005943b0 stubbed." >> "$OUT"
echo "# reads: ball+0x63/4c, player+0x5e(=0)/54/58/34/aim(a0/a4/a8)/pos(4/8/c), seed. b1100 + b31a0(+b3c10/b3580) run REAL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== adc60 oracle -> $OUT ==="
cat "$OUT"
