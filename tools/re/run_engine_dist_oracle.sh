#!/usr/bin/env bash
# Stage 3 INTEGRATION oracle (case-0x13 GATE): drive the REAL FUN_005a4600 (engine_tick) through the
# case-0x13 (keeper-distribution / kick windup) bVar17-TRUE arm -- the kick-aim teammate search + ball
# launch INSIDE FUN_005a4600 -- and on into its nested leaf FUN_005ac1a0 (setup_shot) -> FUN_005ab5a0
# (resolve_post_shot), all REAL under the emu. This gates the previously TRANSCRIPTION-ONLY case-0x13
# pre-block (the +0xa0/a4/a8 aim + ball+4/8/c launch vector) AND the setup_shot wiring in
# Pm98Action._case_distribution. test_engine_dist.gd asserts Pm98Action.engine_tick reproduces it.
#
# Companion to run_engine_cascade_oracle.sh (which gates the SAME setup_shot leaf via the acc40/case-4
# path); this reaches it via case 0x13 instead, exercising FUN_005a4600's own teammate-search block that
# the cascade never runs.
#
# UN-STUBBED vs run_engine_oracle.sh: 0x5ac1a0 (setup_shot) runs REAL; resolve_post_shot (0x5ab5a0) is
# reached transitively + REAL. acc40 (case 4) is NOT on the case-0x13 path -> stays stubbed. The other
# handlers + resolver + teammate-count + 3 movement fns stay STUBBED; 7260 is skipped (p+0x2bc=1) and 8f20
# runs REAL but is INERT (facing +0x34 = 0 -> 0 turn delta, no carrier ball-advance). resolve_post_shot's
# display/queue leaves are stubbed (TRAIL FUN_0058fda0, ENQ FUN_00594470) -- modelled as no-ops in the port.
#
# FTOL: the FISTTP truncating thunk (setup_shot ftols a near-boundary sqrt) + the hand-coded Win32 MulDiv
# @0x252100 -- same as run_engine_cascade_oracle.sh / run_shotsetup_oracle.sh.
#
# Memory: player P@0x230000 (ECX/ESI); match@0x260000 (P+0x18c); ball@0x270000 (P+0x190); gs/P184@0x280000
# (P+0x184); play-state@0x290000 (match+0x468); stat@0x2b0000 (P+0x3b8); teammate@0x2a0000 (the gs roster
# entry the case-0x13 search picks -> ball+0x4c). gs+0 (0x280000) -> descriptor [players_base, count] @0x280010.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/engine_dist_oracle.txt
SPEC=$SPECDIR/_engine_dist_run.spec
ROUT=$SPECDIR/_engine_dist_run.out
LUT=$SPECDIR/_engine_dist_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# Identity pointers: P+0x18c->match, P+0x190->ball, P+0x184->gs, P+0x3b8->stat; ball+0x1d4->match;
# match+0x468->play-state. ball+0x4c is NOT pre-poked -- the case-0x13 block sets it to the found teammate.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"
PTRS="$PTRS;$(poke 0x2303b8 0x2b0000);$(poke 0x2701d4 0x260000);$(poke 0x260468 0x290000)"
# gs roster descriptor: **(P+0x184) = *(gs) = players_base @0x2a0000; (*(P+0x184))[1] = *(gs+4) = count.
GSBASE="$(poke 0x280000 0x2a0000);$(poke 0x280004 1)"
# the one eligible teammate @0x2a0000: q+0x2bc(700) != 0; pos q+4/8/c.
TEAM="$(poke 0x2a02bc 1);$(poke 0x2a0004 0x1000000);$(poke 0x2a0008 0x80000);$(poke 0x2a000c 0)"
# globals: contested-touch gate = 0 (active); RNG seed (read back to count draws).
GLOB="$(poke 0x6d31c4 0);$(poke 0x6d3184 0x12345678)"
# FISTTP truncating _ftol (setup_shot boundary sqrt) + hand-coded Win32 MulDiv (setup_shot).
FTOL="membts 0x00252000 83EC08DB0C248B042483C408C3
membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00
$(poke 0x6233a4 0x252000)
$(poke 0x623064 0x252100)"

# Stubbed leaves: "VA RET ARGBYTES LABEL". setup_shot (0x5ac1a0) is NOT here -> real.
STUBS=(
  "0x5b0b40 0 4 B0B40"     # teammate count (not called: same-sign prologue)
  "0x5aeda0 0 0 AEDA0"     # case 8/9 resolver
  "0x5acc40 0 0 ACC40"     # case 4/0x25 (acc40 -- not on the case-0x13 path)
  "0x5ad010 0 0 AD010"     # case 5/0x24
  "0x5ad970 0 0 AD970"     # case 0x36
  "0x5adc60 0 0 ADC60"     # case 0x37
  "0x5adfc0 0 0 ADFC0"     # case 0x19/0x1a
  "0x5ae4c0 0 0 AE4C0"     # case 0x14/0x16
  "0x5ae910 0 0 AE910"     # case 0x15
  "0x5a8680 0 0 M8680"     # settle move
  # FUN_005a65a0 un-stubbed (s12): the FULL move_dispatch port runs REAL, so its velocity-block rng
  # draws land in the banked 0x6d3184 state; only b1420's b1500/b1c80 role leaves stay stubbed ret 1.
  "0x5b1500 1 0 B1500"
  "0x5b1c80 1 0 B1C80"
  "0x5a9490 0 0 M9490"     # lean (post-switch)
  "0x605ff0 0 0 atexit"    # 8f20 box-init fault guard (inert: facing 0)
  "0x58fda0 0 0 TRAIL"     # resolve_post_shot render trail (no sim residue)
  "0x594470 0 12 ENQ"      # resolve_post_shot enqueue (arg0 = event code)
)

READS=(
  # --- engine_tick skeleton residue ---
  "0x002302d7 1" "0x002302d8 1"
  "0x0023002c 4" "0x00230030 4" "0x00230040 4" "0x00230048 4"
  "0x00230050 4" "0x0023006c 4" "0x00230088 4"
  # --- case-0x13 pre-block residue (aim + ball launch vector + b+0x4c teammate) ---
  "0x002300a0 4" "0x002300a4 4" "0x002300a8 4" "0x002300b4 4"
  "0x00270004 4" "0x00270008 4" "0x0027000c 4" "0x0027004c 4"
  # --- setup_shot residue (landing + velocity + ball+0x70 + cleared touch) ---
  "0x00270084 4" "0x00270088 4" "0x0027008c 4"
  "0x00270020 4" "0x00270024 4" "0x00270028 4"
  "0x00270070 4" "0x00230054 4" "0x00230058 4"
  # --- resolve_post_shot residue (engage + set_phase(0) + counters) ---
  "0x00270050 4" "0x00270064 1" "0x00270040 4" "0x00270044 4" "0x00270048 4"
  "0x00270054 4" "0x00270080 4"
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

# --- case 0x13 fixture ------------------------------------------------------------------------------
# engine prologue: action 0x13; frame guard p+0x2c=5 / p+0x30=3 (->0 after tick_action with +0x48 locked)
# => bVar17 TRUE; +0x48 nonzero (lock -> tick_action keeps +0x2c/+0x40, decrements +0x48); +0x88=0 (skip
# the 16-tick stamina block). p+4=0 + anchor+0x3a4=0x100000 -> same signs -> prologue flag skipped (no B0B40).
# +0x58=6 = kick power (case-0x13 aim scale) AND setup_shot touch. facing +0x34=0 (8f20 inert). p+0x2bc=1
# (7260 skipped; on-pitch). cvar4 p+0x5e=0.
FRAME="$(poke 0x230040 0x13);$(poke 0x23002c 5);$(poke 0x230030 3);$(poke 0x230048 5);$(poke 0x230088 0)"
FRAME="$FRAME;$(poke 0x2303a4 0x100000);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0)"
FRAME="$FRAME;$(poke 0x2302bc 1);$(poke 0x230058 6);$(poke 0x230034 0);$(poke 0x23005e 0)"

# setup_shot inputs: ball+0x4c set by case-0x13 -> owned -> skill +0x394; touch p+0x54/58; rating p+0x70;
# ball+0x70 base; ball+0x40=0 + ball+0x63=0 -> entry guard passes, body runs.
SETUP="$(poke 0x230394 80);$(poke 0x2303a0 70);$(poke 0x230070 8000);$(poke 0x270070 100)"
SETUP="$SETUP;$(poke 0x230054 5);$(poke 0x270040 0);$(poke 0x270063 0)"

# resolve_post_shot: match+0x438=P -> straight to the tail (skips pass/keeper/classify, 0 draws); engage
# then runs (ball+0x40=0 != P) and set_phase(0) fires. match+0x460=0; match+0x448=0 (open play).
RESOLVE="$(poke 0x260438 0x230000);$(poke 0x260460 0);$(poke 0x260448 0)"

: > "$OUT"
echo "# Stage 3 INTEGRATION (case-0x13 GATE): FUN_005a4600 (engine_tick) case 0x13 bVar17-true ->" >> "$OUT"
echo "#   teammate search + ball launch -> setup_shot (FUN_005ac1a0) -> resolve_post_shot (FUN_005ab5a0), all REAL." >> "$OUT"
echo "#   STUBS: 8 handlers + resolver + teammate-count + 3 movement fns + TRAIL/ENQ (8f20 REAL/inert, 7260 skipped)." >> "$OUT"
POKES="$FRAME;$SETUP;$RESOLVE;$PTRS;$GSBASE;$TEAM;$GLOB"
emit_spec "${POKES//;/$'\n'}"
run_emu
echo "## FIX dist_case13" >> "$OUT"
grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || true
echo "=== engine dist oracle -> $OUT ==="
cat "$OUT"
