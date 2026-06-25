#!/usr/bin/env bash
# Stage 3 (ball-touch decision, slice 2a): drive the REAL FUN_005a7260 through the Ghidra PCode emulator
# into its EXECUTE-KICK block (L515-666) and bank the post-call field mutations that
# Pm98Movement.ball_touch_7260's kick sub-arm 1 must reproduce bit-for-bit (app/tests/test_7260kick.gd).
#
# This slice ports ONLY the FIRST execute-kick sub-arm (L544-605): the primary shot/pass STRIKE that
# advances the action code, zeroes ball velocity, records the ball-anim target (ball+0x9c/a0/a4), engages
# the ball to the player (FUN_0058eca0) and resets the engage-copy + turnover guards. Sub-arms 2/3
# (the weaker-pass and near-miss arms, L606-666) and the dribble-grid block (L242-514) stay DEFERRED;
# the fixtures here always FIRE sub-arm 1 so the binary never falls through to them.
#
# Gate to enter the kick block: same-side (FUN_0058fb50 box + sign(P.x)==sign(P+0x3a4)) AND not-carrier
# (ball+0x40 != P) AND m+0x448==0 AND (m+0x461 & 0x20)==0 AND action in {0x35,0x31,0x26,0x2a,0x32,0x27,
# 0x2b} AND P+0x2c==5. p+0x44 selects the marker grid row (lazy-init DAT_00674280/438 + static
# DAT_00665538/665510). RNG seed DAT_006d3184=0 so FUN_005ec250's first draw (38) -> roll (38*1000>>15)=1
# clears the MulDiv threshold and the strike fires deterministically.
#
# SURROGATES: _ftol @0x252000 (IAT 0x6233a4) + hand-coded Win32 MulDiv @0x252100 (IAT 0x623064, the kick
# block's MulDiv(power*4+400, 0x9999-ballspeed, 0x4c96) threshold). The event queue is FROZEN
# (m+0x1a38=1) so FUN_00594470 early-returns (no GlobalReAlloc fault); the enqueue is locked separately
# in test_events.gd. Audio/commentary leaves are gated off (m+0x180b/0x180c=0). RNG save/restore
# (5ec240/5ec230) brackets are net-neutral and skipped in the port.
#
# Memory map (zeroed windows): P@0x230000 M@0x210000 ball@0x240000 GS@0x250000 OTHER@0x260000 STAT@0x270000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260kick_oracle.txt
SPEC=$SPECDIR/_7260kick_run.spec
ROUT=$SPECDIR/_7260kick_run.out
LUT=$SPECDIR/_7260kick_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

P=0x00230000; M=0x00210000; BALL=0x00240000; GS=0x00250000; OTHER=0x00260000; STAT=0x00270000

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# Banked fields: P action/team-tags + STAT shot counter + ball engage/strike state + m turnover.
# Plus grid/static cross-checks (GRID1[2]@0x674298, GRID2[2]@0x674450, DAT_00665538[2], DAT_00665510[2]).
READS="
read_mem 0x00230040 4
read_mem 0x00230054 4
read_mem 0x00230058 4
read_mem 0x00270094 4
read_mem 0x00210461 1
read_mem 0x00240004 4
read_mem 0x00240008 4
read_mem 0x0024000c 4
read_mem 0x00240040 4
read_mem 0x00240044 4
read_mem 0x00240048 4
read_mem 0x00240054 4
read_mem 0x00240080 4
read_mem 0x0024004c 4
read_mem 0x00240063 1
read_mem 0x00240068 4
read_mem 0x0024006c 4
read_mem 0x00240070 4
read_mem 0x00240020 4
read_mem 0x00240024 4
read_mem 0x00240028 4
read_mem 0x0024009c 4
read_mem 0x002400a0 4
read_mem 0x002400a4 4
read_mem 0x00210458 4
read_mem 0x00674298 4
read_mem 0x0067429c 4
read_mem 0x006742a0 4
read_mem 0x00674450 4
read_mem 0x00674454 4
read_mem 0x00674458 4
read_mem 0x00665540 4
read_mem 0x00665518 4
read_mem 0x006d3184 4
"

# emit_spec ACTION PX PY P3A4 IDX POWER ANIMX ANIMY ANIMZ [FACING]
emit_spec() {
  local action=$1 px=$2 py=$3 p3a4=$4 idx=$5 power=$6 ax=$7 ay=$8 az=$9 facing=${10:-0x2000}
  {
    echo "entry   0x5a7260"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P"                       # __fastcall: p in ECX
    # _ftol thunk (round-to-zero) + hand-coded Win32 MulDiv (IAT imports uncallable in-emu).
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00"
    echo "mem 0x006233a4 4 0x00252000"          # _ftol thunk ptr
    echo "mem 0x00623064 4 0x00252100"          # MulDiv thunk ptr
    echo "stub 0x00605ff0 0 0 atexit"           # lazy-init steer box-init atexit fault guard
    echo "maxsteps 8000000"
    cat "$LUT"
    echo "zero    0x00230000 0x00000400"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00240000 0x00000400"
    echo "zero    0x00250000 0x00000400"
    echo "zero    0x00260000 0x00000400"
    echo "zero    0x00270000 0x00000400"
    echo "zero    0x00674000 0x00001000"        # lazy-init marker grids (BSS-zero so lazy-init runs)
    poke 0x006d3184 0                           # RNG seed = 0 (first draw 38 -> roll 1)
    poke 0x006d31c4 0                           # playback flag 0 (live -> stat counter fires)
    poke 0x00230184 $GS
    poke 0x0023018c $M
    poke 0x00230190 $BALL
    poke 0x002401d4 $M                           # ball+0x1d4 -> m (engage turnover counter)
    poke 0x002303b8 $STAT                        # p+0x3b8 -> stat struct (+0x94 shot counter)
    poke 0x00230040 "$action"
    poke 0x0023002c 5                            # p+0x2c == 5 (kick-block gate)
    poke 0x00230044 "$idx"                       # p+0x44 marker index
    poke 0x0023038c "$power"                     # p+0x38c power stat
    poke 0x00230004 "$px"
    poke 0x00230008 "$py"
    poke 0x0023000c 0
    poke 0x002303a4 "$p3a4"                      # sign(p.x)==sign(p+0x3a4) -> same-side
    poke 0x002302b8 1                            # team
    poke 0x00230034 "$facing"                    # facing
    poke 0x00230054 7                            # -> 0 (engage zeroes target+0x54)
    poke 0x00230058 7                            # -> 0
    poke 0x00240040 $OTHER                       # ball+0x40 carrier = OTHER (not-carrier)
    poke 0x00240054 5                            # ball+0x54 old team (!= p team -> engage bumps m+0x458)
    poke 0x0024004c 0
    poke 0x00240050 0                            # keeper null (keeper_event no-op)
    poke 0x00240063 0
    poke 0x00240068 0
    poke 0x0024006c 0
    poke 0x00240070 0
    poke 0x00240020 0; poke 0x00240024 0; poke 0x00240028 0
    poke 0x00240004 0x1111; poke 0x00240008 0x2222; poke 0x0024000c 0x3333   # ball.pos (sub-arm2: += p.vel)
    poke 0x00230020 0x100;  poke 0x00230024 0x200;  poke 0x00230028 0x300     # p.vel (sub-arm2 ball.pos drag)
    poke 0x00240114 "$ax"                        # ball anim x at (DAT_00665538[idx]+0x12)*0xc (idx=2 -> 0x114)
    poke 0x00240118 "$ay"
    poke 0x0024011c "$az"
    poke 0x00210448 0
    poke 0x00210461 0
    poke 0x00210460 0
    poke 0x00210458 0
    poke 0x00211a38 1                            # freeze event queue (enqueue early-returns)
    poke 0x0021180b 0; poke 0x0021180c 0
    poke 0x002119a0 0
    poke 0x00211820 0
    poke 0x00211970 0x7f000000
    poke 0x00211978 0x7f000000
    poke 0x00211828 -0x10000000; poke 0x0021182c -0x10000000; poke 0x00211830 -0x10000000
    poke 0x00211834 0x10000000;  poke 0x00211838 0x10000000;  poke 0x0021183c 0x10000000
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {
  local name=$1 line kv
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  echo "FIX $name | $kv" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 ball-touch slice-2a (FUN_005a7260 execute-kick sub-arm 1, L544-605) PCode-emu ground truth." >> "$OUT"
echo "# Row: FIX <name> | <abs-addr>=<u LE> ... . P=0x230000 ball=0x240000 m=0x210000 stat=0x270000." >> "$OUT"

#         ACTION PX      PY      P3A4  IDX POWER ANIMX   ANIMY   ANIMZ
# Sub-arm 1 (primary strike): gate-1 z-error 0 (anim_z == GRID1[2].2) -> fires.
emit_spec 0x26   0x1000  0x2000  0x500 2   100   0x4333  0x2000  0x1cccc;  run_emu; bank kick26
emit_spec 0x31   0x1000  0x2000  0x500 2   100   0x4333  0x2000  0x1cccc;  run_emu; bank kick31
# Sub-arm 2 (weaker pass): anim_z = 0x1cccc+25000 -> z-error 25000 fails gate-1 (<22282) but passes
# gate-2 (<29491); planar 0 (anim_x-p.x == GRID1[2].0-GRID2[2].0). Settles the polar/rotate ball.vel
# slot-overlap (the in-place FUN_005ee6e0 about Y) + FUN_0058ed80 ownership transfer + ball.pos += p.vel.
emit_spec 0x26   0x1000  0x2000  0x500 2   100   0x4333  0x2000  142964;   run_emu; bank pass26
# Sub-arm 2 independent point: power 150 (radius), facing 0x1000 (aim), anim_x 0x5000 (Dx 16384, must
# NOT affect ball.vel) -- confirms the polar/rotate formula generalizes (not curve-fit to pass26).
emit_spec 0x26   0x1000  0x2000  0x500 2   150   0x5000  0x2000  157964  0x1000;  run_emu; bank pass2b
# Sub-arm 3 (near-miss): power 50 so z-error 20000 fails gate-1 (<11141) AND gate-2 (<14745) but passes
# gate-3 (<29491); only sets m+0x461 |= 0x20.
emit_spec 0x26   0x1000  0x2000  0x500 2   50    0x4333  0x2000  137964;   run_emu; bank near26

echo "=== 7260kick oracle -> $OUT ==="
cat "$OUT"
