#!/usr/bin/env bash
# Oracle for FUN_005acc40 (975 B, __fastcall this=player): case 4/0x25, the AI "aim the set-piece feed AT
# the goal" handler, frame-gated by p+0x2c==4 && p+0x30==3 and ball(p+0x190)+0x4c != 0. Aims at the
# ball+0x4c teammate's position (player+0xa0/a4/a8 = target+4/+8/+c). On a SPECIAL set-piece touch
# (gs+0x2ee && play_state==0 && p+0x5c) with the full power window (p+0x58==0x10 && p+0x54!=0), it FLAGS a
# goal-mouth redirect (p+0x5f=1, p+0x58=4) UNLESS the player itself sits in a byline-corner (FUN_005ac0e0)
# or goal-box (FUN_0058fb50) region on the side OPPOSITE its goal anchor (+0x3a4), or match+0x44c==2.
# When p+0x5f is set (here OR on entry) it BENDS the aim: aim += polar(planar_mag(aim-pos)/4,
# blended_angle), where blended_angle = atan(goal - target.pos) half-rotated toward the goal-facing axis
# (the +0x8000 side term, oriented by match+0x19a0 vs team p+0x2b8). A long feed (dist > 0x1e0000) also
# sets ball+0x62=1. Then it CLAMPS the aim into the goal AABB (match+0x1828..+0x183c) shrunk 0x4ccc per
# face, and on the special touch sets p+0x5e=(p+0x54!=0). Draws NO rng. Drives the REAL fn under the emu.
#
# STUBBED: FUN_005ac1a0 (setup_shot, ported+verified separately) so this measures ONLY acc40's residue;
#   FUN_005943b0 (match play-state predicate -> 1 = play_state 0). The commentary call FUN_00590f00 is
#   gated out by match+0x180a==0 (headless), so it is never reached -- no stub needed.
# RUN REAL (in-image leaves, all inlined in the GD port): FUN_005ee080 (atan), FUN_00436fb0 (cos/sin
#   set), FUN_005edfb0 (muladd16 -> planar_mag), FUN_005ee0f0 (polar), FUN_0058fb50 (goalbox test),
#   FUN_005ac0e0 (corner test), FUN_00590aa0 (vec set), FUN_00590ae0 (vec sub), FUN_00590ac0 (vec copy),
#   FUN_00590b10 (add scalar), FUN_005b1210 (sub scalar), FUN_00590be0 (6-int copy). No ftol path.
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); gs@0x280000
# (P+0x184); target teammate@0x2a0000 (ball+0x4c). Goal geometry on the match: +0x1820 goal line,
# +0x1828..+0x1830 box min (x,y,z), +0x1834..+0x183c box max, +0x19a0 orient (bit0), +0x44c phase-tag,
# +0x180a commentary flag (0 = headless).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/acc40_oracle.txt
SPEC=$SPECDIR/_acc40_run.spec
ROUT=$SPECDIR/_acc40_run.out
LUT=$SPECDIR/_acc40_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball, P+0x184 -> gs. ball+0x4c -> target teammate 0x2a0000.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
PTRS="$PTRS;$(poke 0x27004c 0x2a0000)"
GLOB="$(poke 0x6d3184 0x12345678)"
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x5ac1a0 0 0 SETUP"     # FUN_005ac1a0 = setup_shot (ported separately; isolate acc40 residue)
  "0x5943b0 1 0 PHASE0"    # FUN_005943b0 play-state predicate -> 1 (play_state == 0)
)

READS=(
  "0x00270062 1"  # ball+0x62 (long-feed flag)
  "0x0023005e 1"  # player+0x5e (= power!=0 on the special touch)
  "0x0023005f 1"  # player+0x5f (redirect flag, set here or pre-set)
  "0x00230058 4"  # player+0x58 (-> 4 when the redirect fires)
  "0x002300a0 4"  # player+0xa0 aim.x (aimed + bent + clamped)
  "0x002300a4 4"  # player+0xa4 aim.y
  "0x002300a8 4"  # player+0xa8 aim.z
  "0x006d3184 4"  # RNG seed (acc40 draws 0 -> unchanged)
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005acc40
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00001000
maxsteps 8000000
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

# Common base: guard (p+0x2c=4, p+0x30=3); target teammate pos @0x2a0000 (+4/+8/+c); goal geometry on the
# match. goalx 0x2000000, box min [0x1000000,-0x800000,-0x100000], max [0x3000000,0x800000,0x100000];
# orient 0, team 0 (orient==1-team is false -> no goalx negate); match+0x44c=0 (!=2); +0x180a=0 (headless).
BASE="$(poke 0x23002c 4);$(poke 0x230030 3);$(poke 0x2302b8 0)"
BASE="$BASE;$(poke 0x2a0004 0x1000000);$(poke 0x2a0008 0x80000);$(poke 0x2a000c 0)"
BASE="$BASE;$(poke 0x261820 0x2000000);$(poke 0x2619a0 0);$(poke 0x26044c 0);$(poke 0x26180a 0)"
BASE="$BASE;$(poke 0x261828 0x1000000);$(poke 0x26182c 0xff800000);$(poke 0x261830 0xfff00000)"
BASE="$BASE;$(poke 0x261834 0x3000000);$(poke 0x261838 0x800000);$(poke 0x26183c 0x100000)"
# self touch/power window + special inputs (overridden per fixture).
BASE="$BASE;$(poke 0x230054 0xd);$(poke 0x230058 0x10);$(poke 0x23005c 0);$(poke 0x2802ee 0)"

FIX=(
  # redirect_special: special touch (gs+0x2ee=1, p+0x5c=1), p+0x58=0x10, p+0x54!=0; player at midfield
  # (p+4=0 -> |x| fails corner+goalbox) -> redirect fires (p+0x5f=1, p+0x58=4) -> aim bent + clamped.
  # anchor +0x3a4=0x100000 (sign +). NB gs+0x2ee lives on the gs struct @0x280000+0x2ee.
  "redirect_special|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"

  # special_in_corner: player sits in a byline corner on the side OPPOSITE its anchor -> redirect SKIPPED
  # (p+0x5f stays 0). p+4=0x2000000 (|x|>goalx-0x160000), p+8=0x200000 (|y|>0x1428f5); anchor -0x100000
  # (sign -, opposite). aim = target.pos, clamped; special -> p+0x5e=1.
  "special_in_corner|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2303a4 0xfff00000);$(poke 0x230004 0x2000000);$(poke 0x230008 0x200000)"

  # not_special: gs+0x2ee=0 -> special false -> redirect block skipped, p+0x5f stays 0, no bend; aim =
  # target.pos, clamped. p+0x5e untouched. (BASE already has gs+0x2ee=0, p+0x5c=0.)
  "not_special|$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"

  # preset_5f_nonspecial: p+0x5f=1 on ENTRY but NOT special -> redirect block skipped, yet the bend STILL
  # runs (p+0x5f!=0). Decouples the geometry path from the special predicate.
  "preset_5f_nonspecial|$(poke 0x23005f 1);$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"

  # blocked_44c2: special + full window + midfield (would redirect) BUT match+0x44c=2 -> redirect SKIPPED.
  "blocked_44c2|$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x26044c 2);$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"

  # long_feed: preset p+0x5f=1, target FAR (0x5000000) from the player (p+4=0) -> planar_mag > 0x1e0000 ->
  # ball+0x62=1 + a large bent aim (then clamped into the box).
  "long_feed|$(poke 0x23005f 1);$(poke 0x2a0004 0x5000000);$(poke 0x2a0008 0);$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"

  # neg_orient: orient bit0=1 with team 0 -> orient==(1-team) -> goalx NEGATED; also flips the +0x8000
  # side term in the angle blend. special redirect path.
  "neg_orient|$(poke 0x2619a0 1);$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0)"
)

: > "$OUT"
echo "# Oracle FUN_005acc40 (case 4/0x25 AI goal-aim feed). this=player. setup_shot/005943b0 stubbed; commentary headless." >> "$OUT"
echo "# reads: ball+0x62, player+0x5e/5f/58, aim a0/a4/a8, seed (0 draws). All vec + atan + polar leaves run REAL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== acc40 oracle -> $OUT ==="
cat "$OUT"
