#!/usr/bin/env bash
# Stage 3 INTEGRATION oracle (handoff item 1 -- the KICK tail + the pass-block roster scan): drive the
# REAL FUN_005a4600 (engine_tick) through a Family-A KICK action handler -- FUN_005ae4c0 (kick_resolve,
# case 0x14/0x16) -- and on into FUN_005ab5a0 (resolve_post_shot), both run REAL under the emu. This is
# the integration counterpart to run_engine_cascade_oracle.sh (which drives the acc40 -> setup_shot tail):
# here the handler chains STRAIGHT to resolve_post_shot (no setup_shot), threading the gs[0] roster the
# binary reads at **(int**)(player+0x184). Two fixtures:
#   kick_tail     -- match+0x438 == player -> resolve_post_shot short-circuits to the tail (set_phase(0),
#                    engage), proving the engine -> kick_handler -> resolve_post_shot DIRECT composition.
#   kick_passblock -- match+0x438 != player, match+0x448 == 0, sign(anchor) != sign(ball+0x20): the ONLY
#                    path that runs the pass-target scan over the THREADED roster. A single teammate at the
#                    shooter's position (scale 0) makes FUN_005b0bb0 hit the capsule -> mark_pass_receiver
#                    fires (traced: PASS). This exercises the new gs.get(0,[]) / _ref(p,0x184).get(0,[])
#                    threading wired into kick_resolve in 0a7156f -- the explicit "NOT YET oracle-exercised"
#                    gap from the handler-cascade handoff.
#
# UN-STUBBED vs run_engine_cascade_oracle.sh: 0x5ae4c0 (kick_resolve) runs REAL; resolve_post_shot
# (0x5ab5a0) is reached transitively and runs REAL (+ its real leaves: FUN_005b0bb0 pass-target test,
# the engage FUN_0058eca0/0058ed70, set_phase FUN_005942e0, the predicates/geometry). STUBBED: the OTHER
# 6 handlers + setup_shot + resolver + teammate-count FUN_005b0b40 + the 5 movement fns + resolve's TRAIL
# (FUN_0058fda0) / ENQ (FUN_00594470) + the kick's EFFECT (FUN_00590f00) / AUDIO (FUN_004e9940).
#
# FTOL: the FISTTP truncating thunk (run_ae4c0/shotsetup). The kick ball-SPEED sqrt is a perfect square
# (vel (3,4,0)<<16 -> mag 0x50000) so the ftol is unambiguous; resolve's pass-capsule perp is 0 (teammate
# at the shooter) so its ftol is exact too. No Win32 MulDiv import is needed (kick + this resolve path use
# inline magic-number IMULs only).
#
# Memory: player P@0x230000 (ECX); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); gs/P184@0x280000
# (P+0x184); stat@0x2b0000 (P+0x3b8); teammate0@0x2a0000 (the kick tm0 AND the pass-scan receiver, +0x190
# ->ball, +0x18c->match); kick tm-array@0x290000 ([0x290000]=teammate0). ball+0x1d4 -> match. P184 roster:
# P184+0 = base = teammate0, P184+4 = count = 1 (mirrors run_postshot_oracle.sh passteam_keeper).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/engine_kick_oracle.txt
SPEC=$SPECDIR/_engine_kick_run.spec
ROUT=$SPECDIR/_engine_kick_run.out
LUT=$SPECDIR/_engine_kick_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Identity pointers: P+0x18c->match, P+0x190->ball, P+0x184->gs/P184, P+0x3b8->stat; ball+0x1d4->match;
# P+0x188->kick tm-array, [tm-array]->teammate0; teammate0 +0x190->ball, +0x18c->match.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
PTRS="$PTRS;$(poke 0x2303b8 0x2b0000);$(poke 0x2701d4 0x260000)"
PTRS="$PTRS;$(poke 0x230188 0x290000);$(poke 0x290000 0x2a0000)"
PTRS="$PTRS;$(poke 0x2a0190 0x270000);$(poke 0x2a018c 0x260000)"
# globals: contested-touch gate = 0 (active); RNG seed (read back to count draws); LUT sentinel.
GLOB="$(poke 0x6d31c4 0);$(poke 0x6d3184 0x12345678)"
# FISTTP truncating _ftol (kick ball-speed sqrt + resolve perp).
FTOL="membts 0x00252000 83EC08DB0C248B042483C408C3
$(poke 0x6233a4 0x252000)"

# 0x5ae4c0 (kick_resolve) + 0x5ab5a0 (resolve_post_shot) are NOT here -> run REAL.
STUBS=(
  "0x5b0b40 0 4 B0B40"     # teammate count (prologue + mark_pass_receiver's count_goalside_opponents)
  "0x5aeda0 0 0 AEDA0"     # case 8/9 resolver
  "0x5acc40 0 0 ACC40"     # case 4/0x25 goal_aim
  "0x5ad010 0 0 AD010"     # case 5/0x24
  "0x5ad970 0 0 AD970"     # case 0x36
  "0x5adc60 0 0 ADC60"     # case 0x37
  "0x5adfc0 0 0 ADFC0"     # case 0x19/0x1a kick (off-path)
  "0x5ae910 0 0 AE910"     # case 0x15 kick (off-path)
  "0x5ac1a0 0 0 SETUP"     # setup_shot (not on the kick path)
  "0x5a8680 0 0 M8680"     # settle move
  "0x5a65a0 0 4 M65a0"     # general move
  "0x5a9490 0 0 M9490"     # lean (post-switch)
  "0x5a7260 0 0 M7260"     # locomotion (post-switch)
  "0x5a8f20 0 4 M8f20"     # body orient (post-switch)
  "0x58fda0 0 0 TRAIL"     # resolve_post_shot render trail (no sim residue)
  "0x594470 0 12 ENQ"      # resolve_post_shot enqueue (arg0 = event code)
  "0x590f00 0 0 EFFECT"    # kick crowd/commentary effect (no tracked field, no rng)
  "0x4e9940 0 4 AUDIO"     # kick audio (gated OFF by match+0x180b=0, never reached)
)

READS=(
  # --- engine_tick skeleton residue ---
  "0x002302d7 1" "0x002302d8 1"
  "0x0023002c 4" "0x00230030 4" "0x00230040 4" "0x00230048 4"
  "0x00230050 4" "0x0023006c 4" "0x00230088 4"
  # --- kick_resolve residue ---
  "0x00270020 4" "0x00270024 4" "0x00270028 4"
  "0x00230054 4" "0x00230058 4" "0x0027004c 4" "0x00270070 4"
  "0x00260462 4" "0x00270064 4"
  # --- resolve_post_shot residue (engage + set_phase(0) + counters) ---
  "0x00270050 4" "0x00270040 4" "0x00270044 4" "0x00270048 4" "0x00270054 4" "0x00270080 4"
  "0x00260438 4" "0x0026043c 4" "0x00260458 4" "0x00260460 1" "0x00260448 4" "0x0026044c 4"
  "0x002b0088 4" "0x002802e4 4"
  # --- rng seed (2 kick draws; resolve draws 0 on tail + pass-hit) ---
  "0x006d3184 4"
)

emit_spec() {  # $1 = pokes (newline-joined)
  {
    cat <<EOF
entry   0x005a4600
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x002a0000 0x00001000
zero    0x002b0000 0x00001000
maxsteps 8000000
EOF
    cat "$LUT"
    printf '%s\n' "$FTOL"
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    echo "trace 0x005ec250 RNG"
    echo "trace 0x005b0bb0 PASS"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Common base: reach case 0x14 with the kick guard satisfied. action 0x14, frame guard p+0x2c=8 /
# p+0x30=3 (->0 after tick_action with +0x48 locked), +0x48 nonzero (timer lock -> tick_action keeps
# +0x2c/+0x40), +0x88=0 (skip the 16-tick stamina block). p+4=0 + anchor +0x3a4=0x100000 -> matching
# signs -> prologue flag block skipped (no B0B40 call). Player at origin; aim p+0xa0/a4=0 (scale 0).
FRAME="$(poke 0x230040 0x14);$(poke 0x23002c 8);$(poke 0x230030 3);$(poke 0x230048 5);$(poke 0x230088 0)"
FRAME="$FRAME;$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 0x100000);$(poke 0x2302bc 1)"
FRAME="$FRAME;$(poke 0x2300a0 0);$(poke 0x2300a4 0)"

# kick_resolve inputs: ball owned-self guard passed by ball+0x63=0; p+0x7c==ball+0x80 (both 0). Ball
# velocity (3,4,0)<<16 -> speed 0x50000 (perfect square). touch p+0x54=10; accuracy p+0x39c=50; power
# p+0x388=50; skill word p+0xb8=0x7fff (min goalpost-angle path); facing p+0x34=0; tm0 skill idx 0.
KICK="$(poke 0x270063 0);$(poke 0x270020 0x30000);$(poke 0x270024 0x40000);$(poke 0x270028 0)"
KICK="$KICK;$(poke 0x270070 100);$(poke 0x230054 10);$(poke 0x23039c 50);$(poke 0x230388 50)"
KICK="$KICK;$(poke 0x2300b8 0x7fff);$(poke 0x230034 0);$(poke 0x2a02b8 0);$(poke 0x2a02c4 0)"
KICK="$KICK;$(poke 0x261820 0x300000);$(poke 0x2619a0 0)"

# resolve common: match+0x448=0 (open play), match+0x460=0 (no stale taker), match+0x44c=3 (nonzero ->
# set_phase(0) drives it to 0, an observable proof the phase write fired).
RESCOM="$(poke 0x260448 0);$(poke 0x260460 0);$(poke 0x26044c 3)"

: > "$OUT"
echo "# Stage 3 INTEGRATION: FUN_005a4600 (engine_tick) -> kick_resolve (FUN_005ae4c0, case 0x14) ->" >> "$OUT"
echo "#   resolve_post_shot (FUN_005ab5a0), both REAL. set_phase(0) reached. PASS = FUN_005b0bb0 fired." >> "$OUT"
echo "#   reads: engine skeleton + kick velocity + full resolve residue + rng seed (2 draws)." >> "$OUT"

# --- kick_tail: match+0x438 == player -> resolve short-circuits, no roster scan -----------------------
TAIL="$(poke 0x260438 0x230000);$(poke 0x2302b8 0)"
POKES="$FRAME;$KICK;$RESCOM;$TAIL;$PTRS;$GLOB"
emit_spec "${POKES//;/$'\n'}"
run_emu
echo "## FIX kick_tail" >> "$OUT"
grep -E 'CALL 0 (STUB|RET|HALT)|PASS' "$ROUT" >> "$OUT" || true

# --- kick_passblock: match+0x438 != player; side_neg (p+0x2b8=1) -> goalx negated -> ball+0x20 < 0 ----
# sign(anchor=+) != sign(ball+0x20=-) -> the pass-target scan runs. P184 roster = {base=teammate0, count=1};
# teammate0 at the shooter (origin), scale 0 -> FUN_005b0bb0 hits the capsule -> PASS trace fires.
PASSB="$(poke 0x260438 0);$(poke 0x2302b8 1);$(poke 0x280000 0x2a0000);$(poke 0x280004 1)"
POKES="$FRAME;$KICK;$RESCOM;$PASSB;$PTRS;$GLOB"
emit_spec "${POKES//;/$'\n'}"
run_emu
echo "## FIX kick_passblock" >> "$OUT"
grep -E 'CALL 0 (STUB|RET|HALT)|PASS' "$ROUT" >> "$OUT" || true

echo "=== engine kick oracle -> $OUT ==="
cat "$OUT"
