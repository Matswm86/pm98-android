#!/usr/bin/env bash
# Oracle for FUN_005ac1a0 (2713 B, __fastcall this=player): the SHOT / TRAJECTORY SETUP the open-play
# engine runs to launch the ball (case-0x13 etc.). Computes a skill-jittered horizontal reach, a launch
# pitch (local_28) and a horizontal direction (local_20), then writes the predicted landing spot
# (ball+0x84/88/8c) and the launch velocity (ball+0x20/24/28), bumps ball+0x70 to >=4 and clears
# player+0x54/0x58. Drives the REAL function under the Ghidra PCode emulator and banks the residue the
# GDScript port (Pm98Movement.setup_shot) must reproduce.
#
# STUBBED: FUN_005ab5a0 (0x5ab5a0) the post-shot resolution -- already ported + oracle-verified
#   separately (run_postshot_oracle.sh), so we cut it here to isolate THIS function's writes.
# RUN REAL (in-image leaves): FUN_0058f100 (the early ball-engage copy guard), FUN_00590c10 (AABB
#   contains), FUN_005ec250 (RNG, seed DAT_006d3184 -- read back to count draws), FUN_005ee080 (atan
#   LUT), FUN_005edfa0/b0/d0/90 (16.16 fixmath), FUN_005ee0f0 (polar->cartesian, cos LUT).
# SURROGATES: _ftol @0x252000 (CALL 0x605fb0 = JMP [0x6233a4]) + a hand-coded Win32 MulDiv @0x252100
#   (the IAT import 0x623064 is uncallable in-emu; round half away from zero, -1 if denom==0, preserves
#   EBX -- the caller keeps the MulDiv ptr in EBX).
# CRITICAL ftol NOTE: this function's _ftol lands on a non-integer sqrt (tof = sqrt(vterm/l14)*2^16), so
#   the ROUNDING MODE matters. MSVC _ftol TRUNCATES toward zero, but Ghidra's PCode FPU IGNORES the
#   round-to-zero control word the classic `fnstcw/or ah,0x0C/fldcw/fist` surrogate sets -- its FIST
#   rounds to NEAREST, which gave tof one too high on .8-fraction values (e.g. 23141.84 -> 23142). The
#   surrogate here is `sub esp,8 / fisttp [esp] / mov eax,[esp] / add esp,8 / ret`: FISTTP truncates
#   UNCONDITIONALLY (ignores the CW) and pops -- exactly MSVC _ftol. (The older balladvance/postshot
#   ftol surrogate happens to agree only because those callers never ftol a near-boundary fraction.)
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); ball+0x1d4 ->
#   match (FUN_0058f100 reads it). owner @0x2a0000 when a fixture needs ball owned (only tested != 0).
#   cos LUT @0x6d31c8 + atan LUT @0x6d71c8 injected; seed DAT_006d3184; double 65536.0 @0x639268 (image).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/shotsetup_oracle.txt
SPEC=$SPECDIR/_shotsetup_run.spec
ROUT=$SPECDIR/_shotsetup_run.out
LUT=$SPECDIR/_shotsetup_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball; ball+0x1d4 -> match (FUN_0058f100).
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x2701d4 0x260000)"
# seed (read back to detect/count rng draws).
GLOB="$(poke 0x6d3184 0x12345678)"
# _ftol thunk redirect (round-to-zero ftol from balladvance) + hand-coded Win32 MulDiv.
#   MulDiv @0x252100: push ebx; ecx=c; if 0 ret -1; eax=a; if c<0 neg a,c; imul [b]; ebx=c>>1;
#   sign(prod)? sub/add half (64-bit); idiv ecx; pop ebx; ret 0xC.
FTOL="membts 0x00252000 83EC08DB0C248B042483C408C3
membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00
$(poke 0x6233a4 0x252000)
$(poke 0x623064 0x252100)"

STUBS=(
  "0x5ab5a0 0 0 RESOLVE"   # FUN_005ab5a0 post-shot resolution (ported separately)
)

READS=(
  "0x00270084 4"  # ball+0x84  landing.x = ball.x + polar(mag_land, horiz).x
  "0x00270088 4"  # ball+0x88  landing.y
  "0x0027008c 4"  # ball+0x8c  landing.z (out.z=0 -> ball.z)
  "0x00270020 4"  # ball+0x20  vel.x
  "0x00270024 4"  # ball+0x24  vel.y
  "0x00270028 4"  # ball+0x28  vel.z (sin*tof, or 0 in the bVar2 branch)
  "0x00270070 4"  # ball+0x70  = max(4, ball+0x70)
  "0x00230054 4"  # player+0x54 = 0 (always cleared)
  "0x00230058 4"  # player+0x58 = 0
  "0x00270090 4"  # ball+0x90  = engaged+4 (only the FUN_0058f100 skip path copies it)
  "0x00270094 4"  # ball+0x94
  "0x00270098 4"  # ball+0x98
  "0x006d3184 4"  # RNG seed   = advanced once per FUN_005ec250 draw
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005ac1a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x002a0000 0x00001000
maxsteps 2000000
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

# Common base: shooter controls the ball (ball+0x40 = player -> guard short-circuits, body runs).
# aim target (P+0xa0/a4/a8) forward of the ball at origin (P+4/8/c = 0); anchor negative (sign != aim.x).
# goalx = 0x300000; goal AABB (match+0x1828..183c) left ZERO so the aim point is never "in goal" by
# default (aim_goal / bVar3 false); P+0x2bc = 1 so the late goalbox bump is skipped by default.
BASE="$(poke 0x230040 2);$(poke 0x2300a0 0x200000);$(poke 0x2300a4 0x40000);$(poke 0x2300a8 0)"
BASE="$BASE;$(poke 0x2303a4 -1);$(poke 0x2302bc 1)"
BASE="$BASE;$(poke 0x2303a0 70);$(poke 0x230394 80);$(poke 0x230054 5);$(poke 0x230058 6)"
BASE="$BASE;$(poke 0x230070 8000);$(poke 0x270070 100);$(poke 0x261820 0x300000)"
BASE="$BASE;$(poke 0x270040 0x230000)"   # ball+0x40 = player (guard short-circuits)

# name|extra-pokes (BASE + PTRS + GLOB appended).
FIX=(
  # cvar0_owned: cVar4=0 (P+0x5e=0), ball owned (ball+0x4c=owner). cVar4==0 velocity path; owned skill +0x394.
  "cvar0_owned|$(poke 0x23005e 0);$(poke 0x27004c 0x2a0000)"

  # bVar2_true: cVar4=0 + aim CLOSE to ball (small reach) so reach < rng*10+0xf0000 -> bVar2 true ->
  # local_28 = 0x271c (fixed pitch), velocity = polar(mul16(cos,2*tof)) with ball+0x28 = 0.
  "bVar2_true|$(poke 0x23005e 0);$(poke 0x27004c 0x2a0000);$(poke 0x2300a0 0x60000);$(poke 0x2300a4 0)"

  # cvar1_owned: cVar4=1 (P+0x5e=1), ball owned. The else velocity branch (ball+0x28 = mul16(sin,tof)).
  "cvar1_owned|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000)"

  # unowned: ball+0x4c=0 -> unowned skill +0x3a0, different spread factors (0x9999/0x160c/0x889/0xf555).
  "unowned|$(poke 0x23005e 1);$(poke 0x27004c 0)"

  # cvar0_unowned: cVar4=0 + unowned (covers cVar4==0 && unowned sVar23=0 arm + bVar3 spread half).
  "cvar0_unowned|$(poke 0x23005e 0);$(poke 0x27004c 0)"

  # action13: action=0x13 (set-piece) -> local_20 cap 0x140000, local_24 reach branch 0x140000.
  "action13|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x230040 0x13)"

  # action37: action=0x37 -> same cap but the late +0x222 bump is suppressed (action != 0x37 gate).
  "action37|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x230040 0x37)"

  # phase44c6: match+0x44c=6 -> iVar21 /= 3.
  "phase44c6|$(poke 0x23005e 0);$(poke 0x27004c 0x2a0000);$(poke 0x26044c 6)"

  # phase44c4: match+0x44c=4 -> local_20 cap forced 0x500000 (first block early branch).
  "phase44c4|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x26044c 4)"

  # aim_goal: aim point INSIDE the goal AABB on the opposite side from the anchor -> aim_goal/bVar3 true,
  # cap 0x500000. AABB encloses aim (0x200000,0x40000,0): minx<=0x200000<=maxx etc.; goalx 0x300000 so
  # |aim.x|=0x200000 > goalx-0x108000=0x1f8000; |aim.y|=0x40000 < 0x1428f5; sign(aim.x)+ != anchor-.
  # (cVar4=1 + owned + reach<cap -> NOT-C else branch with half=0x20000, the only fixture that hits it.)
  "aim_goal|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x261828 0x100000);$(poke 0x26182c 0);$(poke 0x261830 -0x100000);$(poke 0x261834 0x280000);$(poke 0x261838 0x100000);$(poke 0x26183c 0x100000)"

  # late2bc: P+0x2bc=0 + player pos at goalbox (own side, sign(px)==anchor) + cVar4=1 + action!=0x37 ->
  # the +0x222 local_28 bump. player pos (px=-0x200000 same sign as anchor=-1), inside AABB, |px|>goalx-0x108000.
  "late2bc|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x2302bc 0);$(poke 0x230004 -0x200000);$(poke 0x230008 0x40000);$(poke 0x23000c 0);$(poke 0x261828 -0x280000);$(poke 0x26182c 0);$(poke 0x261830 -0x100000);$(poke 0x261834 -0x100000);$(poke 0x261838 0x100000);$(poke 0x26183c 0x100000)"

  # clamp70: ball+0x70=2 -> bumped to 4.
  "clamp70|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x270070 2)"

  # touch_lt4: player+0x54/0x58 below 4 -> local_24(touch) floored to 4.
  "touch_lt4|$(poke 0x23005e 0);$(poke 0x27004c 0x2a0000);$(poke 0x230054 1);$(poke 0x230058 2)"

  # skip: ball+0x40 != player AND ball+0x63 != 0 -> FUN_0058f100 returns nonzero -> jump to end. With
  # match+0x448=0 it also copies ball+0x90/94/98 = engaged+4/8/c. engaged @0x2a0000 with +4/8/c set.
  "skip|$(poke 0x23005e 1);$(poke 0x27004c 0x2a0000);$(poke 0x270040 0x2a0000);$(poke 0x270063 1);$(poke 0x260448 0);$(poke 0x2a0004 0x111);$(poke 0x2a0008 0x222);$(poke 0x2a000c 0x333)"
)

: > "$OUT"
echo "# Oracle FUN_005ac1a0 (shot/trajectory setup). this=player. FUN_005ab5a0 STUBbed (ported sep)." >> "$OUT"
echo "# reads: landing ball+0x84/88/8c, vel ball+0x20/24/28, ball+0x70, player+0x54/58, ball+0x90/94/98, seed." >> "$OUT"
echo "# rng draws = (seed advanced); each draw multiplies seed by 0x343fd. tracehits RNG = draw count." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$BASE;$POKES;$PTRS;$GLOB"   # BASE first so per-fixture pokes override it
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== shotsetup oracle -> $OUT ==="
cat "$OUT"
