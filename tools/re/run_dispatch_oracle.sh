#!/usr/bin/env bash
# Stage 3 task 2 (dispatcher): drive the REAL match-event dispatcher FUN_005966d0
# (and the case-1 aggregate helper FUN_00450e60) through the Ghidra PCode emulator and
# bank the exact mutated state. Ground truth that Pm98Dispatch.dispatch / _agg_decision
# must reproduce bit-for-bit (test_dispatch.gd).
#
# FUN_005966d0(__thiscall this=match, outcome) classifies a resolver outcome 1-7 into
# the events it appends via FUN_00594470 (enqueue, already locked by test_events). The
# on-screen commentary (every FUN_004e*, guarded by match+0x180b) is left OFF (=0) so it
# never runs -- exactly how the GDScript port stubs it; the FUN_005ec240/230 save/restore
# brackets around it then net-zero the RNG. The only load-bearing RNG draws are the
# conditional FUN_005ec250 in case 2 (geometry-gated) and case 6 (goal), so we seed
# DAT_006d3184=1 and read it back: an unchanged 1 == no draw, 2745024 == one draw.
#
# The queue grower FUN_005bbf10 (Win32 GlobalReAlloc) is STUBBED and the event buffer is
# pre-allocated at 0x260000 with match+0x1a24 pre-pointed there, so event N lands at
# 0x260000 + N*0x10 (same trick as run_event_oracle.sh). The cos/atan LUTs are injected
# (membts) for the case-2 fixtures, which read them via FUN_005ee080 + the cos table.
#
# Memory map: match M@0x200000 (0x2000), event buf@0x260000, team T@0x270000 (match+0x468;
# phase +0xfa0, cup flags +0x44/+0x48, +0x14, goal log +0xf98/+0xf9c, ids +0x7e8/+0xf88),
# players P@0x230000 / Q@0x240000, goal-log L@0x280000. Values banked decimal (u32 LE).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/dispatch_oracle.txt
SPEC=$SPECDIR/_dispatch_run.spec
ROUT=$SPECDIR/_dispatch_run.out
LUT=$SPECDIR/_dispatch_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8 (banked)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
eaxv() { echo "$1" | grep -oE "EAX=[0-9-]+" | head -1 | cut -d= -f2 || true; }

# --- dispatcher base spec; $1=outcome  $2=extra pokes  $3=inject_lut(1/0) -----------
emit_disp() {
  cat > "$SPEC" <<EOF
entry   0x5966d0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
arg     $1
zero    0x00200000 0x00002000
zero    0x00230000 0x00001000
zero    0x00240000 0x00001000
zero    0x00260000 0x00001000
zero    0x00270000 0x00002000
stub    0x005bbf10 0 0
stub    0x00251092 0 8         # lstrcpyA (call ebp, ebp=*0x623054) -- commentary copy, no-op stdcall(2)
mem 0x006d31c4 1 0x0
mem 0x006d3184 4 0x1            # DAT_006d3184 = RNG state seed 1
mem 0x00200454 4 0x0           # cooldown = 0 (not busy)
mem 0x00201998 4 0x0           # counter (0 -> default 0x157c)
mem 0x0020180b 1 0x0           # commentary flag OFF
mem 0x00200468 4 0x00270000    # match+0x468 -> team
mem 0x00200828 4 0x00270000    # match+0x828 -> valid ptr (case-6 unconditional deref)
mem 0x00201a24 4 0x00260000    # event buffer
mem 0x00201a28 4 0x0           # count = 0
mem 0x00201a38 4 0x0           # freeze = 0
$2
maxsteps 4000000
EOF
  if [ "${3:-0}" = "1" ]; then cat "$LUT" >> "$SPEC"; fi
  cat >> "$SPEC" <<'EOF'
read_mem 0x00201a28 4
read_mem 0x00260000 4
read_mem 0x00260004 4
read_mem 0x00260008 4
read_mem 0x0026000c 4
read_mem 0x00260010 4
read_mem 0x00260014 4
read_mem 0x00260018 4
read_mem 0x0026001c 4
read_mem 0x00260020 4
read_mem 0x00260024 4
read_mem 0x00260028 4
read_mem 0x0026002c 4
read_mem 0x006d3184 4
read_mem 0x002019d4 4
read_mem 0x00201a38 4
read_mem 0x00200448 4
read_mem 0x0020044c 4
read_mem 0x00200454 4
read_mem 0x00201a2c 4
EOF
}

emit_agg() {
  # FUN_00450e60(__fastcall ecx=team). $1 = extra pokes (team + goal log).
  cat > "$SPEC" <<EOF
entry   0x450e60
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00270000
zero    0x00270000 0x00002000
zero    0x00280000 0x00001000
$1
maxsteps 1000000
EOF
}

# Dispatcher fixtures: name | outcome | LUT | pokes
DISP=(
"busy|6|0|mem 0x00200454 4 0x99"
"sub_corner|4|0|mem 0x00200440 4 0x00230000 ; mem 0x002302b8 4 0x11 ; mem 0x002302c0 4 0x22 ; mem 0x0020046c 4 0x00240000 ; mem 0x002402b8 4 0x33 ; mem 0x002402c0 4 0x44 ; mem 0x0020045c 4 0x0"
"phase_ko|1|0|mem 0x002019a0 4 0x0"
"phase_ht|1|0|mem 0x002019a0 4 0x2"
"phase_et_end|1|0|mem 0x002019a0 4 0x4"
"phase_ft_replay|1|0|mem 0x002019a0 4 0x1 ; mem 0x00270044 4 0x1"
"phase_ft_2leg|1|0|mem 0x002019a0 4 0x1 ; mem 0x00270048 4 0x1"
"phase_ft_done|1|0|mem 0x002019a0 4 0x1"
"buildup_nodraw|2|1|mem 0x0020165c 4 0x0 ; mem 0x00201630 4 0x30000 ; mem 0x00201634 4 0x40000"
"buildup_draw|2|1|mem 0x0020165c 4 0x1 ; mem 0x00201630 4 0x30000 ; mem 0x00201634 4 0x40000"
"buildup_sub|2|1|mem 0x00200440 4 0x00230000 ; mem 0x002302b8 4 0x11 ; mem 0x002302c0 4 0x22 ; mem 0x0020165c 4 0x1 ; mem 0x00201630 4 0x30000 ; mem 0x00201634 4 0x40000"
"restart|3|0|mem 0x002019a0 4 0x0"
"restart_et|3|0|mem 0x002019a0 4 0x4"
"corner|4|0|mem 0x0020045c 4 0x0 ; mem 0x0020046c 4 0x00240000 ; mem 0x002402b8 4 0x55 ; mem 0x002402c0 4 0x66"
"foul_normal|5|0|mem 0x00200460 1 0x0 ; mem 0x00200461 1 0x0 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0x77 ; mem 0x002302c0 4 0x88"
"foul_yellow|5|0|mem 0x00200460 1 0x0 ; mem 0x00200461 1 0x2 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0x77 ; mem 0x002302c0 4 0x88"
"foul_2yellow|5|0|mem 0x00200460 1 0x0 ; mem 0x00200461 1 0x4 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0x77 ; mem 0x002302c0 4 0x88"
"foul_red|5|0|mem 0x00200460 1 0x0 ; mem 0x00200461 1 0x6 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0x77 ; mem 0x002302c0 4 0x88"
"offside|5|0|mem 0x00200460 1 0x1 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0x77 ; mem 0x002302c0 4 0x88"
"goal|6|0|mem 0x00200444 4 0x00230000 ; mem 0x002302b8 4 0x1 ; mem 0x002302c0 4 0x99 ; mem 0x0020045c 4 0x0 ; mem 0x002019a0 4 0x0 ; mem 0x00200461 1 0x0 ; mem 0x00200462 1 0x0"
"goal_draw|6|0|mem 0x00200444 4 0x00230000 ; mem 0x002302b8 4 0x1 ; mem 0x002302c0 4 0x99 ; mem 0x0020045c 4 0x0 ; mem 0x002019a0 4 0x0 ; mem 0x00200461 1 0x20 ; mem 0x00200462 1 0x0"
"owngoal|6|0|mem 0x00200444 4 0x00230000 ; mem 0x002302b8 4 0x0 ; mem 0x002302c0 4 0x99 ; mem 0x0020045c 4 0x0 ; mem 0x002019a0 4 0x0 ; mem 0x00200461 1 0x20 ; mem 0x00200462 1 0x0"
"pen_nocard|7|0|mem 0x00200461 1 0x0 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0xaa ; mem 0x002302c0 4 0xbb"
"pen_yellow|7|0|mem 0x00200461 1 0x2 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0xaa ; mem 0x002302c0 4 0xbb"
"pen_red|7|0|mem 0x00200461 1 0x6 ; mem 0x0020043c 4 0x00230000 ; mem 0x002302b8 4 0xaa ; mem 0x002302c0 4 0xbb"
)

# Aggregate fixtures (FUN_00450e60): name | pokes. Goal log L@0x280000, 16-byte records
# [type, _, sideflag, teamid]; team home id @+0x7e8, away id @+0xf88.
AGG=(
"agg_draw0|mem 0x00270048 4 0x0"
"agg_leaf1|mem 0x00270048 4 0x0 ; mem 0x00270f98 4 0x00280000 ; mem 0x00270f9c 4 0x1 ; mem 0x002707e8 4 0x7 ; mem 0x00270f88 4 0x9 ; mem 0x00280000 4 0x7 ; mem 0x00280008 4 0x0 ; mem 0x0028000c 4 0x7"
"agg_2leg1|mem 0x00270048 4 0x1 ; mem 0x0027002c 4 0xff ; mem 0x00270030 4 0xff ; mem 0x00270f98 4 0x00280000 ; mem 0x00270f9c 4 0x2 ; mem 0x002707e8 4 0x7 ; mem 0x00270f88 4 0x9 ; mem 0x00280000 4 0x7 ; mem 0x00280008 4 0x0 ; mem 0x0028000c 4 0x7 ; mem 0x00280010 4 0x7 ; mem 0x00280018 4 0x0 ; mem 0x0028001c 4 0x7"
"agg_2leg2|mem 0x00270048 4 0x1 ; mem 0x0027002c 4 0xff ; mem 0x00270030 4 0xff ; mem 0x00270f98 4 0x00280000 ; mem 0x00270f9c 4 0x2 ; mem 0x002707e8 4 0x7 ; mem 0x00270f88 4 0x9 ; mem 0x00280000 4 0x7 ; mem 0x00280008 4 0x0 ; mem 0x0028000c 4 0x9 ; mem 0x00280010 4 0x7 ; mem 0x00280018 4 0x0 ; mem 0x0028001c 4 0x9"
)

: > "$OUT"
echo "# Stage 3 task 2 dispatcher ground truth (oracle = PCode emu; realloc stubbed, LUT injected for case 2, commentary OFF)." >> "$OUT"
echo "# D name | count | e0:c,x,y,d | e1:c,x,y,d | e2:c,x,y,d | rng | d4 | frz | p448 | p44c | cd | a2c | RET" >> "$OUT"
for row in "${DISP[@]}"; do
  IFS='|' read -r NAME OUTC LUTF POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_disp "$OUTC" "$POKES" "$LUTF"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'D %-15s | %s | %s,%s,%s,%s | %s,%s,%s,%s | %s,%s,%s,%s | %s | %s | %s | %s | %s | %s | %s | %s\n' \
    "$NAME" "$(mval "$S" 0x201a28)" \
    "$(mval "$S" 0x260000)" "$(mval "$S" 0x260004)" "$(mval "$S" 0x260008)" "$(mval "$S" 0x26000c)" \
    "$(mval "$S" 0x260010)" "$(mval "$S" 0x260014)" "$(mval "$S" 0x260018)" "$(mval "$S" 0x26001c)" \
    "$(mval "$S" 0x260020)" "$(mval "$S" 0x260024)" "$(mval "$S" 0x260028)" "$(mval "$S" 0x26002c)" \
    "$(mval "$S" 0x6d3184)" "$(mval "$S" 0x2019d4)" "$(mval "$S" 0x201a38)" \
    "$(mval "$S" 0x200448)" "$(mval "$S" 0x20044c)" "$(mval "$S" 0x200454)" "$(mval "$S" 0x201a2c)" "${RET:-?}" >> "$OUT"
  echo "[D $NAME] count=$(mval "$S" 0x201a28) e0=$(mval "$S" 0x260000) rng=$(mval "$S" 0x6d3184) frz=$(mval "$S" 0x201a38) $RET"
done
echo "# A name | result(EAX) | RET" >> "$OUT"
for row in "${AGG[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_agg "$POKES"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'A %-15s | %s | %s\n' "$NAME" "$(eaxv "$S")" "${RET:-?}" >> "$OUT"
  echo "[A $NAME] result=$(eaxv "$S") $RET"
done
echo "=== dispatcher oracle -> $OUT ==="
cat "$OUT"
