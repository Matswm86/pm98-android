#!/usr/bin/env bash
# Stage 3 INTEGRATION oracle (Task #4b item 4 -- the handler cascade / set_phase(0) lever): drive the
# REAL FUN_005a4600 (engine_tick) all the way through a Family-A action handler AND its nested cascade
# leaf -- FUN_005ac1a0 (setup_shot) -> FUN_005ab5a0 (resolve_post_shot) -- run REAL under the emu (NOT
# stubbed). This is the first oracle that exercises the engine -> handler -> setup_shot -> resolve_post_shot
# composition end to end, i.e. the path that reaches set_phase(0) (FUN_005942e0(0) inside resolve_post_shot).
# It is the integration counterpart to the per-leaf oracles (run_engine_oracle / run_acc40 / run_shotsetup /
# run_postshot); test_engine_cascade.gd asserts Pm98Action.engine_tick(call_setup=true) reproduces it.
#
# UN-STUBBED vs run_engine_oracle.sh: 0x5acc40 (acc40 = goal_aim_025) and 0x5ac1a0 (setup_shot) run REAL.
# resolve_post_shot (0x5ab5a0) is reached transitively from setup_shot and runs REAL (never stubbed). The
# OTHER 6 handlers + the resolver + teammate-count + the 5 movement fns stay STUBBED (not on the acc40 path).
# resolve_post_shot's own two display/queue leaves are stubbed (TRAIL FUN_0058fda0, ENQ FUN_00594470) --
# exactly as in run_postshot_oracle.sh -- since the GD port models them as no-ops.
#
# FTOL: the FISTTP truncating thunk (run_shotsetup_oracle.sh) -- setup_shot ftols a near-boundary sqrt, so
# the fnstcw surrogate is WRONG here; resolve_post_shot's ftol never hits a boundary so the FISTTP one is
# also correct for it. Plus the hand-coded Win32 MulDiv @0x252100 (setup_shot needs it).
#
# Memory: player P@0x230000 (ECX/ESI); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); gs/P184@0x280000
# (P+0x184); play-state@0x290000 (match+0x468); target teammate@0x2a0000 (ball+0x4c); stat@0x2b0000
# (P+0x3b8). ball+0x1d4 -> match (FUN_0058f100 + the engage read it).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/engine_cascade_oracle.txt
SPEC=$SPECDIR/_engine_cascade_run.spec
ROUT=$SPECDIR/_engine_cascade_run.out
LUT=$SPECDIR/_engine_cascade_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Identity pointers: P+0x18c->match, P+0x190->ball, P+0x184->gs/P184, P+0x3b8->stat; ball+0x1d4->match;
# ball+0x4c->target teammate (so the ball reads "owned"); match+0x468->play-state.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
PTRS="$PTRS;$(poke 0x2303b8 0x2b0000);$(poke 0x2701d4 0x260000);$(poke 0x27004c 0x2a0000)"
PTRS="$PTRS;$(poke 0x260468 0x290000)"
# globals: contested-touch gate = 0 (active); RNG seed (read back to count draws); LUT sentinel.
GLOB="$(poke 0x6d31c4 0);$(poke 0x6d3184 0x12345678);$(poke 0x6d3184 0x12345678)"
# FISTTP truncating _ftol (setup_shot boundary sqrt) + hand-coded Win32 MulDiv (setup_shot).
FTOL="membts 0x00252000 83EC08DB0C248B042483C408C3
membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00
$(poke 0x6233a4 0x252000)
$(poke 0x623064 0x252100)"

# Stubbed leaves: "VA RET ARGBYTES LABEL". acc40 (0x5acc40) + setup_shot (0x5ac1a0) are NOT here -> real.
STUBS=(
  "0x5b0b40 0 4 B0B40"     # teammate count (not on acc40 path; here for safety)
  "0x5aeda0 0 0 AEDA0"     # case 8/9 resolver
  "0x5ad010 0 0 AD010"     # case 5/0x24
  "0x5ad970 0 0 AD970"     # case 0x36
  "0x5adc60 0 0 ADC60"     # case 0x37
  "0x5adfc0 0 0 ADFC0"     # case 0x19/0x1a
  "0x5ae4c0 0 0 AE4C0"     # case 0x14/0x16
  "0x5ae910 0 0 AE910"     # case 0x15
  "0x5a8680 0 0 M8680"     # settle move
  "0x5a65a0 0 4 M65a0"     # general move
  "0x5a9490 0 0 M9490"     # lean (post-switch)
  "0x5a8f20 0 4 M8f20"     # body orient (post-switch)
  "0x605ff0 0 0 atexit"    # FUN_005a7260 (ball-touch) now runs REAL (un-stubbed); atexit guards its steer
                           # box-init. These fixtures never reach 7260's body, so the output is unchanged.
  "0x58fda0 0 0 TRAIL"     # resolve_post_shot render trail (no sim residue)
  "0x594470 0 12 ENQ"      # resolve_post_shot enqueue (arg0 = event code)
)

READS=(
  # --- engine_tick skeleton residue ---
  "0x002302d7 1" "0x002302d8 1"
  "0x0023002c 4" "0x00230030 4" "0x00230040 4" "0x00230048 4"
  "0x00230050 4" "0x0023006c 4" "0x00230088 4"
  # --- acc40 (goal_aim_025) residue ---
  "0x00270062 1" "0x0023005e 1" "0x0023005f 1"
  "0x002300a0 4" "0x002300a4 4" "0x002300a8 4"
  # --- setup_shot residue ---
  "0x00270084 4" "0x00270088 4" "0x0027008c 4"
  "0x00270020 4" "0x00270024 4" "0x00270028 4"
  "0x00270070 4" "0x00230054 4" "0x00230058 4"
  # --- resolve_post_shot residue (engage + set_phase(0)) ---
  "0x00270050 4" "0x00270064 1" "0x00270040 4" "0x00270044 4" "0x00270048 4"
  "0x0027004c 4" "0x00270054 4" "0x00270080 4"
  "0x00260438 4" "0x0026043c 4" "0x00260458 4" "0x00260460 1" "0x00260448 4"
  "0x002b0088 4" "0x002802e4 4"
  # --- rng seed ---
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
zero    0x00674000 0x00001000
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

# --- acc40 cascade fixture ---------------------------------------------------------------------------
# engine prologue: action 4, frame guard p+0x2c=4 / p+0x30=2 (tick_action raises to 3 with +0x48 locked),
# +0x48 nonzero (action-timer lock -> tick_action keeps +0x2c/+0x40), +0x88=0 (skip the 16-tick stamina
# block). p+4=0 + anchor+0x3a4=0x100000 -> matching signs -> prologue flag block skipped (no B0B40 call).
FRAME="$(poke 0x230040 4);$(poke 0x23002c 4);$(poke 0x230030 2);$(poke 0x230048 5);$(poke 0x230088 0)"
FRAME="$FRAME;$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2302bc 1)"

# acc40 (goal_aim_025), NON-special path: gs+0x2ee=0 / p+0x5c=0 -> aim = target.pos, clamped, no bend.
ACC40="$(poke 0x2a0004 0x1000000);$(poke 0x2a0008 0x80000);$(poke 0x2a000c 0);$(poke 0x2a0034 0)"
ACC40="$ACC40;$(poke 0x261820 0x2000000);$(poke 0x2619a0 0);$(poke 0x26044c 0);$(poke 0x26180a 0)"
ACC40="$ACC40;$(poke 0x261828 0x1000000);$(poke 0x26182c 0xff800000);$(poke 0x261830 0xfff00000)"
ACC40="$ACC40;$(poke 0x261834 0x3000000);$(poke 0x261838 0x800000);$(poke 0x26183c 0x100000)"
ACC40="$ACC40;$(poke 0x2802ee 0);$(poke 0x23005c 0);$(poke 0x2302b8 0)"

# setup_shot inputs: ball owned (ball+0x4c=target) -> skill +0x394; cvar4=0 (p+0x5e=0); touch p+0x54/58;
# p+0x70 rating; ball+0x70 base; ball+0x40=0 + ball+0x63=0 -> entry guard passes, body runs.
SETUP="$(poke 0x230394 80);$(poke 0x2303a0 70);$(poke 0x230070 8000);$(poke 0x270070 100)"
SETUP="$SETUP;$(poke 0x230054 5);$(poke 0x230058 6);$(poke 0x23005e 0);$(poke 0x270040 0);$(poke 0x270063 0)"

# resolve_post_shot: match+0x438=P -> straight to the tail (skips the pass/keeper/classify blocks, 0 draws);
# the engage then runs (ball+0x40=0 != P) and set_phase(0) fires. match+0x460=0 so the stale-taker clear
# is skipped. stat+0x88 increments (ball owned). contested gate 0x6d31c4=0 (in GLOB).
RESOLVE="$(poke 0x260438 0x230000);$(poke 0x260460 0);$(poke 0x260448 0)"

: > "$OUT"
echo "# Stage 3 INTEGRATION: FUN_005a4600 (engine_tick) -> acc40 (FUN_005acc40) -> setup_shot (FUN_005ac1a0)" >> "$OUT"
echo "#   -> resolve_post_shot (FUN_005ab5a0), all REAL. set_phase(0) reached. STUBS: 6 handlers + resolver +" >> "$OUT"
echo "#   teammate-count + 5 movement fns + TRAIL/ENQ. reads: full cascade residue + rng seed (0x6d3184)." >> "$OUT"
POKES="$FRAME;$ACC40;$SETUP;$RESOLVE;$PTRS;$GLOB"
emit_spec "${POKES//;/$'\n'}"
run_emu
echo "## FIX acc40_cascade" >> "$OUT"
grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || true
echo "=== engine cascade oracle -> $OUT ==="
cat "$OUT"
