#!/usr/bin/env bash
# Oracle for FUN_005ad010 (2391 B, __fastcall this=player): case 5/0x24, THE MONSTER feed/blind-aim handler.
# Frame guard P+0x2c==3 && P+0x30==3. Clears ball(P+0x190)+0x4c, then:
#  (1) POWER-BUMP preamble (only P+0x54>=0xe && P+0x5e==0): if heading_diff to [opp_goalx,0,0] s16-abs <
#      0x4000 and |anchor+x| > 0x1e0000, P+0x54 += min((|anchor+x|-0x1e0000)/0x80000, 5). No rng.
#  (2) special = gs(P+0x184)+0x2ee && play_state0(FUN_005943b0) && P+0x5c. special -> P+0x5e=(P+0x58!=0);
#      else a power roll: DRAW A, P+0x5e = ((A*1000)/0x8000 < (|anchor+x|*500)/0x3c0000); if set DRAW B,
#      P+0x58 = shot_rng_scale(B, (|anchor+x|*10)/0x3c0000)+4.
#  (3) BIG branch on P+0x2bc (p700): ==0 && restart_box_ok(FUN_0059a120, player pos) -> P+0x5e=1, special
#      P+0x58=p58/2+8 (0 rng) else reroll P+0x58=scale(rng,4)+0xc, P+0x54=scale(rng,2)+0xe (2 rng) +
#      worst-teammate facing bias (+1 rng; SIGN word>=0 -> +0x222, word<0 -> -0x222), then displace by
#      polar(p54*0x120000/16+0x120000, facing) + corridor FUN_005b1100(0x1e0000,0xa0000); HIT -> aim +
#      ball+0x4c; MISS -> blind polar (+1 rng). p700!=0/box-fail -> match+0x44c==4: reroll unless special
#      (P+0x58=scale(rng,6)+0xc, P+0x54=scale(rng,3)+0xd, 2 rng); if P+0x58!=0 displace polar(p54*0x190000/
#      16+0xf0000) + corridor(0x460000,0x80000), MISS -> 2nd corridor(0x460000,0xf0000) on RESTORED pos.
#      44c!=4 -> unless special, 44c==5: 19cc==0 corridor(0x190000,0xf0000); 19cc!=0 P+0x5e=1 + P+0x58=
#      scale(rng,8)+4 (1 rng).
#  (4) TAIL (P+0x5e && ball+0x4c==0): p700==0 goalbox-on-anchor-side early-out; else aim -= pos, scale by
#      (0x10000 - p58*0x8000/16) (FUN_005ee1c0), and if heading(scaled aim) within 0x2000 of heading(opp
#      goal) blend polar(|anchor+x|, atan(scaled)) and halve; aim += pos.
#  (5) FUN_005ac1a0 (setup_shot) + match+0x462 |= 0x80.
#
# STUBBED: FUN_005ac1a0 (setup_shot, ported separately -> isolate ad010 residue); FUN_005943b0 (play-state
#   predicate -> 1 = play_state 0). Commentary FUN_00590f00 gated out headless by match+0x180a==0.
# RUN REAL: FUN_005b1100 (corridor scan, deterministic), FUN_0059a120 (restart_box_ok), FUN_0058fb50
#   (goalbox), FUN_005a44f0 (opp goal-x), FUN_005aac00 (heading diff), FUN_005ee080 (atan), FUN_005ee0f0
#   (polar), FUN_005ee1c0 (vec3 scale), FUN_00590aa0 (vec set), FUN_005ec250 (rng -- the seed under test).
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); gs@0x280000
# (P+0x184): gs+0 = roster firstptr (0x2a0000), gs+4 = count, gs+0x2ee = set-piece flag; roster1
# header@0x290000 (P+0x188): +0 firstptr (0x2a0000 SHARED), +4 count. teammate tm0 @0x2a0000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/ad010_oracle.txt
SPEC=$SPECDIR/_ad010_run.spec
ROUT=$SPECDIR/_ad010_run.out
LUT=$SPECDIR/_ad010_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball, ball+0x1d4 -> match. P+0x184 -> gs, P+0x188 -> roster1 header.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x2701d4 0x260000)"
PTRS="$PTRS;$(poke 0x230184 0x280000);$(poke 0x230188 0x290000)"
PTRS="$PTRS;$(poke 0x280000 0x2a0000);$(poke 0x290000 0x2a0000)"   # gs+0 + roster1+0 = firstptr (shared)
GLOB="$(poke 0x6d3184 0x12345678)"
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x5ac1a0 0 0 SETUP"     # FUN_005ac1a0 = setup_shot (ported separately; isolate ad010 residue)
  "0x5943b0 1 0 PHASE0"    # FUN_005943b0 play-state predicate -> 1 (play_state == 0)
)

READS=(
  "0x0027004c 4"  # ball+0x4c (hit teammate ptr, else 0)
  "0x0023005e 1"  # player+0x5e (the feed flag)
  "0x00230058 4"  # player+0x58 (touch)
  "0x00230054 4"  # player+0x54 (power, preamble-boosted / rerolled)
  "0x00230034 2"  # player+0x34 (facing, biased)
  "0x002300a0 4"  # player+0xa0 aim.x
  "0x002300a4 4"  # player+0xa4 aim.y
  "0x002300a8 4"  # player+0xa8 aim.z
  "0x00230004 4"  # player+0x4 pos.x (displaced then restored)
  "0x00230008 4"  # player+0x8 pos.y
  "0x0023000c 4"  # player+0xc pos.z
  "0x00260462 1"  # match+0x462 (|= 0x80 tail)
  "0x006d3184 4"  # RNG seed
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005ad010
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00002000
maxsteps 8000000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    echo "trace 0x005ec250 RNG"
    echo "trace 0x005b1100 B1100"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Common base: guard (P+0x2c=3, P+0x30=3); facing 0; power/touch/special seeds. p700 (P+0x2bc) = 0 ->
# restart_box_ok path by default; anchor +0x100000, team 0, pos.x 0x2000000 (in the goal box, |x| past
# goalx-0x108000, sign matches anchor -> restart_box_ok TRUE). gs/roster1 = 1 teammate tm0 @0x2a0000,
# OFF the facing corridor by default (tm0+8 = 0x900000 -> every corridor scan MISSES) so the default
# fixtures take the blind-throw / tail re-aim paths; HIT fixtures override tm0 onto the +x ray.
BASE="$(poke 0x23002c 3);$(poke 0x230030 3);$(poke 0x230034 0)"
BASE="$BASE;$(poke 0x230054 0xd);$(poke 0x230058 0x10);$(poke 0x23005c 0);$(poke 0x23005e 0)"
BASE="$BASE;$(poke 0x2303a4 0x100000);$(poke 0x2302b8 0);$(poke 0x2302bc 0)"
BASE="$BASE;$(poke 0x230004 0x2000000);$(poke 0x230008 0);$(poke 0x23000c 0)"
BASE="$BASE;$(poke 0x280004 1);$(poke 0x290004 1);$(poke 0x2802ee 0)"
BASE="$BASE;$(poke 0x2a02bc 1);$(poke 0x2a02b8 0);$(poke 0x2a02c4 1)"
BASE="$BASE;$(poke 0x2a0004 0x2000000);$(poke 0x2a0008 0x900000);$(poke 0x2a000c 0)"   # tm0 OFF-axis
BASE="$BASE;$(poke 0x2300e8 0x100000);$(poke 0x2300ba 0)"      # self skill[idx1] + bias short[idx1]
BASE="$BASE;$(poke 0x261820 0x2000000);$(poke 0x2619a0 0);$(poke 0x26044c 0);$(poke 0x26180a 0);$(poke 0x2619cc 0)"
BASE="$BASE;$(poke 0x261828 0x1000000);$(poke 0x26182c 0xff800000);$(poke 0x261830 0xfff00000)"
BASE="$BASE;$(poke 0x261834 0x3000000);$(poke 0x261838 0x800000);$(poke 0x26183c 0x100000)"

FIX=(
  # p0_nonspec_miss: p700==0 + restart_box_ok, non-special. step2 (DRAW A + DRAW B) + reroll p58/p54 (2)
  # + worst-teammate bias (+0x222, +1) ; tm0 off corridor -> MISS -> blind polar (+1). 6 rng draws.
  "p0_nonspec_miss|"

  # p0_special_hit: special (gs+0x2ee=1, P+0x5c=1). p700==0 special -> P+0x58=p58/2+8 = 0x10. p54 NOT
  # rerolled (0xd) so mag = 0xd*0x120000/16 + 0x120000 = 0x20a000; tm0 placed at self+disp+0xa0000 =
  # 0x22aa000 on +x -> corridor HIT (aim = tm0, ball+0x4c = tm0). 0 rng draws.
  "p0_special_hit|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2a0004 0x22aa000);$(poke 0x2a0008 0)"

  # p0_special_miss: special, tm0 off -> corridor MISS -> blind polar (1 draw) -> tail re-aim.
  "p0_special_miss|$(poke 0x2802ee 1);$(poke 0x23005c 1)"

  # p0_nonspec_biasneg: non-special p700==0, worst-teammate bias short < 0 (P+0xba = -5) -> the -0x222
  # branch. tm0 off -> miss -> blind + tail. (Exercises the opposite bias sign vs feed_layoff_036.)
  "p0_nonspec_biasneg|$(poke 0x2300ba 0xfffb)"

  # 44c4_nonspec_miss: p700!=0 (P+0x2bc=1), 44c==4, non-special. step2 + reroll p58/p54 (2). tm0 off ->
  # cast1 MISS -> cast2 MISS -> tail re-aim.
  "44c4_nonspec_miss|$(poke 0x2302bc 1);$(poke 0x26044c 4)"

  # 44c4_special_hit: p700!=0, 44c==4, special -> no reroll, p58 = 0x10 != 0 -> displace by polar(0xd*
  # 0x190000/16 + 0xf0000 = 0x233000); tm0 at self+disp+0x80000 = 0x22b3000 -> cast1 HIT. 0 rng draws.
  "44c4_special_hit|$(poke 0x2302bc 1);$(poke 0x26044c 4);$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2a0004 0x22b3000);$(poke 0x2a0008 0)"

  # 44c4_p58zero_skip: p700!=0, 44c==4, special with P+0x58=0 -> step2 special sets P+0x5e=(0!=0)=0; the
  # 44c==4 block skips the displace (p58==0); tail skipped (P+0x5e==0). aim stays 0. 0 rng draws.
  "44c4_p58zero_skip|$(poke 0x2302bc 1);$(poke 0x26044c 4);$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x230058 0)"

  # 44c5_19cc0_miss: p700!=0, 44c==5, 19cc==0, non-special -> corridor(0x190000,0xf0000) on the un-
  # displaced pos; tm0 off -> MISS. P+0x5e = step2 roll. step2 draws only.
  "44c5_19cc0_miss|$(poke 0x2302bc 1);$(poke 0x26044c 5)"

  # 44c5_19cc1: p700!=0, 44c==5, 19cc!=0, non-special -> P+0x5e=1, P+0x58 = scale(rng,8)+4 (1 draw after
  # step2) -> tail re-aim.
  "44c5_19cc1|$(poke 0x2302bc 1);$(poke 0x26044c 5);$(poke 0x2619cc 1)"

  # 44c_other: p700!=0, 44c==0 (neither 4 nor 5), non-special -> nothing in the branch. P+0x5e=step2.
  # Falls straight to the tail (runs only if step2 set P+0x5e=1). step2 draws only.
  "44c_other|$(poke 0x2302bc 1);$(poke 0x26044c 0)"

  # preamble_boost: P+0x54=0x20 (>=0xe) + P+0x5e=0 -> the boost preamble fires (heading 0 to opp goal,
  # |anchor+x|=0x2100000 > 0x1e0000 -> +5 -> p54=0x25); then p700==0 non-special miss -> blind + tail.
  "preamble_boost|$(poke 0x230054 0x20)"

  # preamble_special: P+0x54=0x20 + special, p700==0 HIT path (tm0 on +x). The boost makes p54=0x25 so
  # the displacement mag = 0x25*0x120000/16 + 0x120000 = 0x4a4000; tm0 at self+disp+0xa0000 = 0x25a4000.
  # special2 -> P+0x58=p58/2+8=0x10. 0 rng draws.
  "preamble_special|$(poke 0x230054 0x20);$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2a0004 0x25a4000);$(poke 0x2a0008 0)"
)

: > "$OUT"
echo "# Oracle FUN_005ad010 (case 5/0x24 MONSTER feed/blind-aim). this=player. setup_shot/005943b0 stubbed; commentary headless." >> "$OUT"
echo "# reads: ball+0x4c, player+0x5e/58/54/34/aim(a0/a4/a8)/pos(4/8/c), match+0x462, seed. corridor/restart_box/goalbox/opp-goalx run REAL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== ad010 oracle -> $OUT ==="
cat "$OUT"
