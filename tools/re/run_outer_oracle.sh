#!/usr/bin/env bash
# Oracle for FUN_005983f0 -- the per-FRAME outer match step (Pm98Outer.step) -- plus dedicated rows
# for its seed-relevant leaf FUN_00598340 (the PS==2 replay-cut check, Pm98Outer._replay_cut).
#
# SHELL rows (entry 0x5983f0, __fastcall ECX=match @0x230000, session ptr match+0x468 -> 0x240000):
# every callee is STUBBED except the three play-state predicates FUN_005943b0/d0/f0 (run REAL against
# session+0xfa0), so the rows pin the SHELL's own residue: the +0x1a19 entry clear, the branch select
# (stub-hit identity/order/count: KIT x2, TICK vs WAIT, DEQ arg0=1, ROSTER x2), the +0x1a1e arm when
# TICK returns 0, the score copy +0x478/+0x798 -> +0x19b0/+0x19b4, and the AL continue flag.
# TICK (0x598740) and CUT (0x598340) stub retvals are per-fixture knobs.
#
# CUT rows (entry 0x598340, run REAL incl. its ONE unbracketed FUN_005ec250 draw, seed DAT_006d3184
# poked 0x12345678): pin the gate (+0x1a2c==1 && +0x1a30==0 && +0x1a38==0), the ball-side sign
# compare (+0x1614 vs signed +/-+0x1820 by +0x1664 == +0x19a0&1), the engaged early-keep (+0x1650),
# and the draw branch (AL + post-seed).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/outer_oracle.txt
SPEC=$SPECDIR/_outer_run.spec
ROUT=$SPECDIR/_outer_run.out

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
pokeb() { printf 'mem 0x%08x 1 0x%02x\n'  "$1" $(( $2 & 0xff )); }

# Base state shared by every SHELL row: match @0x230000, session @0x240000 (match+0x468),
# score sentinels team0+0xc=+0x478=7 / team1+0xc=+0x798=3, +0x19b0/+0x19b4 poison 0x55,
# +0x1a19 poisoned 1 (must be cleared at entry).
base_pokes() {  # $1=play_state  $2=extra pokes (newline-joined, may be empty)
  poke  0x230468 0x240000
  poke  0x240fa0 "$1"
  poke  0x230478 7
  poke  0x230798 3
  poke  0x2319b0 0x55
  poke  0x2319b4 0x55
  pokeb 0x231a19 1
  [ -n "$2" ] && printf '%s\n' "$2" || true
}

# STUB list: label -> "va retval argbytes". TICK/CUT retvals substituted per fixture.
stubs() {  # $1=tick_ret  $2=cut_ret
  cat <<EOF
stub 0x5b6ee0 0 0 KIT
stub 0x451200 0 0 THUNKA
stub 0x594310 0 0 BLIT
stub 0x593ab0 0 0 WAIT
stub 0x598740 $1 0 TICK
stub 0x594570 0 4 DEQ
stub 0x594380 0 0 DISPB
stub 0x4511f0 0 0 THUNKB
stub 0x598340 $2 0 CUT
stub 0x598690 0 0 REPLAY
stub 0x44d3d0 0 4 ROSTER
EOF
}

READS_SHELL=(
  "0x00231a19 1"  # +0x1a19 must be 0 (entry clear)
  "0x00231a1e 1"  # +0x1a1e restart arm
  "0x002319b0 4"  # score copy dest team0 (0x55 = untouched, 7 = copied)
  "0x002319b4 4"  # score copy dest team1 (0x55 / 3)
  "0x0023180e 1"  # live branch writes 0
)

emit_shell_spec() {  # $1=play_state  $2=tick_ret  $3=cut_ret  $4=extra pokes
  {
    cat <<EOF
entry   0x005983f0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00006000
zero    0x00240000 0x00001000
maxsteps 300000
EOF
    base_pokes "$1" "$4"
    stubs "$2" "$3"
    for r in "${READS_SHELL[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

READS_CUT=(
  "0x006d3184 4"  # seed after (draw count via tracehits)
)

emit_cut_spec() {  # $1=extra pokes
  {
    cat <<EOF
entry   0x00598340
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00006000
maxsteps 100000
EOF
    poke 0x6d3184 0x12345678
    printf '%s\n' "$1"
    echo "trace 0x005ec250 RNG"
    for r in "${READS_CUT[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {  # $1=row name -- append the emu result line
  LINE=$(grep -E '^CALL 0 (RET|HALT)' "$ROUT" | head -1 || echo "NO-RESULT")
  echo "## FIX $1" >> "$OUT"
  echo "$LINE" >> "$OUT"
  # stub-call order matters for the branch-select checks -- bank it too.
  grep -E '^CALL 0 STUB' "$ROUT" | sed 's/^/#ORDER /' >> "$OUT" || true
  echo "[$1] $(echo "$LINE" | grep -oE 'EAX=[0-9-]+' || echo "$LINE")"
}

: > "$OUT"
echo "# Oracle FUN_005983f0 (outer step shell; predicates REAL, all other callees stubbed)" >> "$OUT"
echo "# + FUN_00598340 rows (REAL, seed 0x12345678 @DAT_006d3184). AL = EAX & 0xff." >> "$OUT"

# ---- SHELL rows ----
# live_cont: PS=1, TICK ret 1, code 0 -> fast path. Expect AL=1, +0x1a1e=0, scores untouched,
#            stub order KIT,KIT,TICK only (no DEQ/ROSTER/CUT).
emit_shell_spec 1 1 0 ""
run_emu; bank live_cont

# live_segend: TICK ret 0 -> +0x1a1e=1, DEQ(arg0=1) + ROSTER x2 fire, AL=1.
emit_shell_spec 1 0 0 ""
run_emu; bank live_segend

# live_fulltime: TICK ret 1, +0x1a38 pre-set 10 -> AL=0, DEQ fires, no ROSTER (+0x1a1e=0).
emit_shell_spec 1 1 0 "$(poke 0x231a38 10)"
run_emu; bank live_fulltime

# live_ps2_keep: PS=2 -> CUT runs (stub ret 1) -> replay path (+0x1a38=6 pre-set: REPLAY fires),
#                score copy 7/3, AL=0.
emit_shell_spec 2 1 1 "$(poke 0x231a38 6)"
run_emu; bank live_ps2_keep

# live_ps2_skip: PS=2, CUT ret 0, +0x1a1e stays 0 -> fast path, AL=1, scores untouched.
emit_shell_spec 2 1 0 ""
run_emu; bank live_ps2_skip

# live_ps2_1a2c2: PS=2, TICK ret 0 (arms +0x1a1e), CUT ret 0, +0x1a2c=2 -> the LAB_505 replay
#                 path WITHOUT the REPLAY-player gate (code 0 not in {6,3} and 1a2c!=1): score
#                 copy 7/3, flush, AL=0, ROSTER x2 (+0x1a1e=1). REALIZABLE against the real
#                 FUN_00598340 (gate +0x1a2c==1 fails -> ret 0), unlike live_ps2_keep -- this is
#                 the row test_outer.gd locks the port's replay path against.
emit_shell_spec 2 0 0 "$(poke 0x231a2c 2)"
run_emu; bank live_ps2_1a2c2

# pause_latch: PS=0 -> pause branch; +0x1a1f=1 breaks the wait loop after ONE WAIT frame.
#              Expect WAIT x1, score copy 7/3, DEQ(1), AL=1.
emit_shell_spec 0 1 0 "$(pokeb 0x231a1f 1)"
run_emu; bank pause_latch

# pause_code10: PS=0, +0x1a38=10 breaks the loop; AL=0.
emit_shell_spec 0 1 0 "$(poke 0x231a38 10)"
run_emu; bank pause_code10

# pause_viewing: PS=2 + set-piece latch +0x1a20=1 (pause trigger); viewing=true breaks after
#                one WAIT; AL=1.
emit_shell_spec 2 1 0 "$(pokeb 0x231a20 1)"
run_emu; bank pause_viewing

# pause_event: PS=0, +0x1a2c=2 (priority event, code 0 not in {3,4,5}) breaks the loop; AL=1.
emit_shell_spec 0 1 0 "$(poke 0x231a2c 2)"
run_emu; bank pause_event

# ---- CUT rows (entry 0x598340, REAL) ----
# gate fields: +0x1a2c=1, +0x1a30=0, +0x1a38=0. Geometry: +0x1820=0x300000 (goal x),
# +0x1664 vs +0x19a0&1 decides the sign flip; +0x1614 = ball.x.
CUTBASE="$(poke 0x231a2c 1)
$(poke 0x231820 0x300000)"

# cut_gate_off: +0x1a2c=0 -> AL=0, no draw.
emit_cut_spec "$(poke 0x231820 0x300000)"
run_emu; bank cut_gate_off

# cut_sidemiss: +0x1664=1, +0x19a0=0 -> 1 != 0&1 -> goalx stays +; ball.x negative -> sx!=sg -> AL=0, no draw.
emit_cut_spec "$CUTBASE
$(poke 0x231664 1)
$(poke 0x231614 -0x10000)"
run_emu; bank cut_sidemiss

# cut_engaged: same side (+0x1664=0 == +0x19a0&1=0 -> goalx NEGATED -> ball.x negative matches);
#              +0x1650 nonzero -> AL=1, no draw.
emit_cut_spec "$CUTBASE
$(poke 0x231664 0)
$(poke 0x231614 -0x10000)
$(poke 0x231650 1)"
run_emu; bank cut_engaged

# cut_draw: same side, NOT engaged -> exactly 1 seed draw decides; bank AL + post-seed.
emit_cut_spec "$CUTBASE
$(poke 0x231664 0)
$(poke 0x231614 -0x10000)"
run_emu; bank cut_draw

echo "=== outer oracle -> $OUT ==="
cat "$OUT"
