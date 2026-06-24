#!/usr/bin/env bash
# Oracle for FUN_005adfc0 (1131 B, __fastcall this=player): one of the 3 "kick resolution" action
# handlers (case 0x19/0x1a). Launches the ball toward the goal mouth: it computes the launch SPEED from
# the ball's current velocity magnitude + a touch term, picks an aim yaw between the two goalposts
# (jittered by the player's accuracy +0x39c), a launch pitch (jittered by power +0x388), rotates the
# {speed,0,0} vector by pitch (about Y) then yaw (about Z), and writes it as the ball velocity
# (ball+0x20/24/28). Then resets player+0x54/58, ball+0x4c, bumps ball+0x70>=4, sets match+0x462|=0x20
# and calls FUN_005ab5a0 (post-shot resolution). Drives the REAL fn under the PCode emulator.
#
# STUBBED: FUN_005ab5a0 (post-shot, ported+verified separately -> run_postshot_oracle.sh), FUN_00590f00
#   (crowd/commentary effect, no tracked field / no rng), FUN_004e9940 (audio, gated off via match+0x180b=0).
# RUN REAL (in-image leaves): FUN_0058f100 (early ball-engage guard, this=ball), FUN_0058fb50 /
#   FUN_005ae430 (goalbox AABB reads -- pure), FUN_005ec240/FUN_005ec230 (rng seed get/set; the audio
#   wrapper is rng-neutral), FUN_005ec250 (rng, traced), FUN_005ee080 (atan LUT), FUN_005ee6e0 (rotate
#   about Y), FUN_005ee670 (rotate about Z), FUN_005edfb0 (16.16 muladd), FUN_00590aa0 (vec3 set),
#   FUN_00590ae0 (vec3 sub).
# SURROGATE: _ftol @0x252000 = `sub esp,8 / fisttp [esp] / mov eax,[esp] / add esp,8 / ret`. The ftol
#   here lands on the BALL-SPEED sqrt (sqrt(vx^2+vy^2+vz^2)), a non-perfect-square in the nonsq fixture,
#   so FISTTP (truncate-toward-zero, ignores the CW) is REQUIRED -- the classic FIST surrogate rounds to
#   nearest under Ghidra's PCode FPU (the shotsetup key finding). No MulDiv import is used (all the
#   /3 /24 /32 /100 divisions are inline magic-number IMULs).
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); ball+0x1d4 ->
#   match (FUN_0058f100 reads it). teammate array: P+0x188 -> 0x290000, [0x290000]=0x2a0000 (teammate0).
#   cos LUT @0x6d31c8 + atan LUT @0x6d71c8 injected; seed DAT_006d3184.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/adfc0_oracle.txt
SPEC=$SPECDIR/_adfc0_run.spec
ROUT=$SPECDIR/_adfc0_run.out
LUT=$SPECDIR/_adfc0_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball; ball+0x1d4 -> match; P+0x188 -> tm-array; [tm-array]=teammate0.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x2701d4 0x260000)"
PTRS="$PTRS;$(poke 0x230188 0x290000);$(poke 0x290000 0x2a0000)"
GLOB="$(poke 0x6d3184 0x12345678)"
FTOL="membts 0x00252000 83EC08DB0C248B042483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x5ab5a0 0 0 RESOLVE"   # post-shot resolution (ported separately)
  "0x590f00 0 0 EFFECT"    # crowd/commentary effect (no tracked field, no rng)
  "0x4e9940 0 4 AUDIO"     # audio __thiscall(this,arg) -- gated OFF by match+0x180b=0 (never reached)
)

READS=(
  "0x00270020 4"  # ball+0x20  launch vel.x  (rotated {speed,0,0})
  "0x00270024 4"  # ball+0x24  launch vel.y
  "0x00270028 4"  # ball+0x28  launch vel.z
  "0x00230054 4"  # player+0x54 = 0
  "0x00230058 4"  # player+0x58 = 0
  "0x0027004c 4"  # ball+0x4c  = 0
  "0x00270070 4"  # ball+0x70  = max(.,4)
  "0x00260462 4"  # match+0x462 |= 0x20  (low byte)
  "0x006d3184 4"  # RNG seed (2 draws: spread A accuracy + spread B power)
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005adfc0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00001000
maxsteps 4000000
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

# Common base: guard (P+0x2c=4, P+0x30=3); P+0x7c == ball+0x80; ball+0x63=0 (no bail). Player at origin,
# facing 0. goal x = match+0x1820 = 0x300000 (no side-negate by default: P+0x2b8=0, match+0x19a0=0 ->
# 1-team=1 != 0 -> no NEG). teammate0 skill index 0 (tm0+0x2b8=0, tm0+0x2c4=0); P+0xb8 (the s16 skill at
# idx 0) = 0x7fff so sVar2 >= sVar6 -> the MIN goalpost-angle path. accuracy P+0x39c=50, power P+0x388=50.
# ball velocity (3-4-0 scaled) -> perfect-square magnitude 0x50000 so the ftol is unambiguous by default.
BASE="$(poke 0x23002c 4);$(poke 0x230030 3);$(poke 0x23007c 1);$(poke 0x270080 1)"
BASE="$BASE;$(poke 0x270063 0);$(poke 0x230034 0)"
BASE="$BASE;$(poke 0x261820 0x300000);$(poke 0x2302b8 0);$(poke 0x2619a0 0)"
BASE="$BASE;$(poke 0x2300b8 0x7fff);$(poke 0x2a02b8 0);$(poke 0x2a02c4 0)"
BASE="$BASE;$(poke 0x23039c 50);$(poke 0x230388 50);$(poke 0x230054 10)"
BASE="$BASE;$(poke 0x270020 0x30000);$(poke 0x270024 0x40000);$(poke 0x270028 0)"
BASE="$BASE;$(poke 0x270070 100)"

FIX=(
  # base: min goalpost-angle path (sVar2 high), perfect-square ball speed 0x50000.
  "base|"

  # maxpath: sVar2 = -32768 (< sVar6) -> the MAX goalpost-angle path.
  "maxpath|$(poke 0x2300b8 0x8000)"

  # nonsq_speed: ball vel (1,1,0)<<16 -> mag = sqrt(2)<<16 (non-integer) -> exercises FISTTP truncation.
  "nonsq_speed|$(poke 0x270020 0x10000);$(poke 0x270024 0x10000);$(poke 0x270028 0)"

  # touch_lt5: P+0x54 = 2 (< 5) -> floored to 4 in the iVar3 speed term.
  "touch_lt5|$(poke 0x230054 2)"

  # lowacc: accuracy 0 + power 0 -> the spread terms (iVar15=((100-0)*0x1555)/100) take max magnitude.
  "lowacc|$(poke 0x23039c 0);$(poke 0x230388 0)"

  # side_neg: P+0x2b8 = 1 so 1-team = 0 == (match+0x19a0 & 1)=0 -> goalx NEGATED (aim other goal).
  "side_neg|$(poke 0x2302b8 1)"

  # clamp70: ball+0x70 = 2 -> bumped to 4.
  "clamp70|$(poke 0x270070 2)"

  # facing: P+0x34 = 0x2000 (eighth turn) -> sVar6/7/8 all shift; verifies the facing subtraction.
  "facing|$(poke 0x230034 0x2000)"
)

: > "$OUT"
echo "# Oracle FUN_005adfc0 (kick resolution, case 0x19/0x1a). this=player. FUN_005ab5a0/590f00/4e9940 stubbed." >> "$OUT"
echo "# reads: ball vel +0x20/24/28, player+0x54/58, ball+0x4c/70, match+0x462, seed (2 rng draws)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== adfc0 oracle -> $OUT ==="
cat "$OUT"
