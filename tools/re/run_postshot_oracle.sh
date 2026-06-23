#!/usr/bin/env bash
# Oracle for FUN_005ab5a0 (2880 B, __fastcall this=player): the POST-SHOT / loose-ball RESOLUTION the
# open-play engine runs after an action settles. Drives the REAL function under the Ghidra PCode
# emulator (headless: match+0x180b = 0, so every commentary/anim display call is gated OUT) and banks
# the SIM RESIDUE + enqueue order the GDScript port (Pm98Movement.resolve_post_shot) must reproduce.
#
# STUBBED (logged, no sim residue we model):
#   FUN_0058fda0 (0x58fda0) render trail (__fastcall ECX=ball, 0 args) -> noop.
#   FUN_00594470 (0x594470) enqueue (__thiscall match; code, player, flag -> RET 0xC). arg0 = code.
# RUN REAL (in-image, verified leaves): predicates FUN_005ac120/005ac0e0/0058fb50; geometry
#   FUN_005ee080(atan)/00436fb0(store)/005edfb0(muladd16)/005b1260(planar_mag)/00590ae0/00590aa0(vec);
#   FUN_005b0bb0 (pass-target test, + its leaves & the ftol thunk); engage FUN_0058eca0 + FUN_0058ed70;
#   set_phase FUN_005942e0; RNG FUN_005ec240(save)/005ec230(restore)/005ec250(draw, seed DAT_006d3184).
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190, decompile "+400");
#   P184 descriptor@0x280000 (P+0x184) = {base, count, ... , +0x2e4 keeper counter}; stat@0x2b0000
#   (P+0x3b8, +0x88 contested-touch counter); ball+0x1d4 -> match (engage reads it). Pass-block owner /
#   teammate players @0x2a0000 / 0x2c0000 when a fixture needs them.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/postshot_oracle.txt
SPEC=$SPECDIR/_postshot_run.spec
ROUT=$SPECDIR/_postshot_run.out
LUT=$SPECDIR/_postshot_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# P+0x18c -> match, P+0x190 -> ball, P+0x184 -> P184, P+0x3b8 -> stat; ball+0x1d4 -> match.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
PTRS="$PTRS;$(poke 0x2303b8 0x2b0000);$(poke 0x2701d4 0x260000)"
# globals: contested-touch gate = 0 (active); seed = a known value (read back to detect a draw).
GLOB="$(poke 0x6d31c4 0);$(poke 0x6d3184 0x12345678)"
# _ftol thunk: redirect 0x6233a4 -> hand-coded round-to-zero ftol at 0x252000 (from balladvance).
FTOL="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

STUBS=(
  "0x58fda0 0 0 TRAIL"     # render trail (no sim residue)
  "0x594470 0 12 ENQ"      # enqueue (arg0 = event code)
)

READS=(
  "0x00270050 4"  # ball+0x50  = player (always)
  "0x00270064 1"  # ball+0x64  = |px+anchor| > 0x1e0000 (always)
  "0x00270040 4"  # ball+0x40  = 0 after engage+ed70
  "0x00270044 4"  # ball+0x44  = player (engage)
  "0x00270048 4"  # ball+0x48  = player (engage)
  "0x0027004c 4"  # ball+0x4c  = 0 (engage)
  "0x00270054 4"  # ball+0x54  = player team (engage)
  "0x00270080 4"  # ball+0x80  = engage counter
  "0x00230054 4"  # player+0x54 = 0 (engage zeroes target)
  "0x00230058 4"  # player+0x58 = 0 (engage zeroes target)
  "0x0026043c 4"  # match+0x43c = pass receiver / cleared
  "0x00260460 1"  # match+0x460 = set-piece cooldown / cleared
  "0x00260438 4"  # match+0x438 = controlled (cleared if == player)
  "0x00260458 4"  # match+0x458 = team-switch counter (engage)
  "0x002b0088 4"  # stat+0x88   = contested-touch counter
  "0x002802e4 4"  # P184+0x2e4  = keeper counter
  "0x006d3184 4"  # RNG seed    = unchanged unless a FUN_005ec250 draw fired
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005ab5a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00001000
zero    0x002b0000 0x00001000
zero    0x002c0000 0x00001000
maxsteps 800000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# name|pokes  (PTRS + GLOB appended to every fixture).
FIX=(
  # tail_438: action 0x13 skips the first block; player == match+0x438 -> straight to the tail. Ball
  # owned-by-self (4c!=0) so the contested-touch stat inc fires; px=0x200000 -> ball+0x64 = 1.
  "tail_438|$(poke 0x230040 0x13);$(poke 0x260438 0x230000);$(poke 0x27004c 0x230000);$(poke 0x230004 0x200000);$(poke 0x2303a4 0)"

  # enq10: action 2; FUN_005ac120(player_pos) true (|px|>goalx-0x160000, |py|>0x1428f5, sign px!=anchor);
  # FUN_005ac0e0(bvec) true; planar_mag(bvec - player_pos) > 0xa0000; match+0x44c != 4 -> enqueue(0x10).
  # match+0x438 = player so it then jumps to the tail.
  "enq10|$(poke 0x230040 2);$(poke 0x261820 0x200000);$(poke 0x230004 0x100000);$(poke 0x230008 0x200000);$(poke 0x2303a4 -1);$(poke 0x2700cc 0x400000);$(poke 0x2700d0 0x200000);$(poke 0x26044c 0);$(poke 0x260438 0x230000)"

  # enq10_skip44c: same as enq10 but match+0x44c == 4 -> enqueue SUPPRESSED.
  "enq10_skip|$(poke 0x230040 2);$(poke 0x261820 0x200000);$(poke 0x230004 0x100000);$(poke 0x230008 0x200000);$(poke 0x2303a4 -1);$(poke 0x2700cc 0x400000);$(poke 0x2700d0 0x200000);$(poke 0x26044c 4);$(poke 0x260438 0x230000)"

  # passhit: pass-target block. action 2 but FUN_005ac120 false (px=0) so the first block is skipped.
  # match+0x448=0 and sign(anchor) != sign(ball+0x20). Ball owned by an owner player @0x2a0000 whose
  # own +0x190->ball, +0x18c->match: FUN_005b0bb0(this=owner) hits immediately (owner owns ball) ->
  # bVar2 -> tail. match+0x43c should become the owner; cooldown set by |owner.x - player.x|.
  "passhit|$(poke 0x230040 2);$(poke 0x230004 0);$(poke 0x2303a4 -1);$(poke 0x270020 0x100000);$(poke 0x27004c 0x2a0000);$(poke 0x2a0190 0x270000);$(poke 0x2a018c 0x260000);$(poke 0x260448 0)"

  # keeper_inc: ball unowned (4c=0). pass-block skipped (match+0x448=1). player at origin, goalx oriented
  # +, facing 0 aligned with the goal direction so atan-vs-facing < 0x3554 -> the keeper counter
  # P184+0x2e4 increments. |anchor+px| large enough to pass the 0x98001 gate; DAT_00674e78 = 0.
  "keeper_inc|$(poke 0x230040 2);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x2300a0 0);$(poke 0x2300a4 0);$(poke 0x261820 0x100000);$(poke 0x230034 0);$(poke 0x2303a4 0x100000);$(poke 0x260448 1);$(poke 0x27004c 0)"

  # keeper_noinc: same as keeper_inc but facing (player+0x34 = 0x4000) is > 0x3554 off the goal angle ->
  # the first atan gate jumps to the tail, so P184+0x2e4 stays 0. Verifies the facing gate.
  "keeper_noinc|$(poke 0x230040 2);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x2300a0 0);$(poke 0x2300a4 0);$(poke 0x261820 0x100000);$(poke 0x230034 0x4000);$(poke 0x2303a4 0x100000);$(poke 0x260448 1);$(poke 0x27004c 0)"

  # passteam_keeper: ball unowned but the pass-block IS entered (match+0x448=0, sign(anchor)!=sign(ball+0x20)).
  # P184 = {base=teammate@0x2c0000, count=1}; the team-loop runs FUN_005b0bb0(this=teammate, tgt=player_pos)
  # which hits the capsule (everything at origin, scale 0) -> bVar2 -> early tail, so the keeper +0x2e4
  # does NOT fire even though facing would align. Distinguishes pass-block-hit from keeper.
  "passteam_keeper|$(poke 0x230040 2);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x2300a0 0);$(poke 0x2300a4 0);$(poke 0x261820 0x100000);$(poke 0x230034 0);$(poke 0x2303a4 0x100000);$(poke 0x260448 0);$(poke 0x270020 -1);$(poke 0x27004c 0);$(poke 0x280000 0x2c0000);$(poke 0x280004 1);$(poke 0x2c0190 0x270000);$(poke 0x2c018c 0x260000)"

  # enq0e: ball+0x48 = an OPPOSING player (team 1 != player team 0) so L154 takes the else -> the 0xe
  # branch. Pass-block skipped (448=1). FUN_005ac0e0(player_pos) true AND sign(px)==sign(anchor) so the
  # gate passes; player+0xa0 = 0 keeps the |a0|>0xeffff exit off -> enqueue(0xe). FUN_005ac120 is false
  # (sign px == anchor) so the first block does NOT also enqueue 0x10.
  "enq0e|$(poke 0x230040 2);$(poke 0x261820 0x200000);$(poke 0x230004 0x100000);$(poke 0x230008 0x200000);$(poke 0x2303a4 1);$(poke 0x2300a0 0);$(poke 0x260448 1);$(poke 0x27004c 0x2a0000);$(poke 0x270048 0x2c0000);$(poke 0x2c02b8 1);$(poke 0x27000c 0)"

  # classify_draw: ball OWNED (4c!=0), pass-block skipped (448=1), ball+0x48=0 -> the owned-ball
  # classification ladder. Velocities/distances steer to the innermost 004ea9f0 branch where the
  # commentary roll FUN_005ec250 fires -> the seed (DAT_006d3184) advances exactly once.
  "classify_draw|$(poke 0x230040 2);$(poke 0x230004 -1);$(poke 0x230008 0);$(poke 0x2300a0 0);$(poke 0x2300a4 0);$(poke 0x261820 0x200000);$(poke 0x2303a4 1);$(poke 0x260448 1);$(poke 0x27004c 0x2a0000);$(poke 0x270048 0)"
)

: > "$OUT"
echo "# Oracle FUN_005ab5a0 (post-shot resolution). this=player; headless (match+0x180b=0)." >> "$OUT"
echo "# STUBs: TRAIL=FUN_0058fda0, ENQ=FUN_00594470 (arg0=code). Rest real. seed=DAT_006d3184." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$POKES;$PTRS;$GLOB"
  emit_spec "${POKES//;/$'\n'}"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || true
done
echo "=== postshot oracle -> $OUT ==="
cat "$OUT"
