#!/usr/bin/env bash
# Stage 3 task 2 (event-queue layer): drive the REAL match-event-queue functions
# through the Ghidra PCode emulator and bank the exact mutated state. This is the
# ground truth Pm98Events.enqueue / keeper_event must reproduce bit-for-bit
# (test_events.gd). Two entries:
#   * FUN_00594470 (enqueue, __thiscall this=match): append [code, player+0x2b8,
#     player+0x2c0, 0x168] at match+0x1a24, bump count match+0x1a28, maintain the
#     0x1a30 timer + 0x1a2c max-flag bookkeeping (gated by the match phase via
#     match+0x468 -> +0xfa0 read by FUN_005943d0/b0). Driven directly with cdecl-
#     style stack args (code, player, flag) + ECX=match.
#   * FUN_005909f0 (keeper_event, __thiscall this=ball): bump the keeper save stat
#     (*(keeper+0x3b8)+0x80, or +0x7c when save_flag!=0) then enqueue a 0x15/0x16
#     event when match+0x462 warrants. Driven with ECX=ball + the char save_flag arg.
#
# Neither reads the trig LUT, so (unlike run_keeper_oracle.sh) NO LUT injection.
# The queue grower FUN_005bbf10 calls Win32 GlobalReAlloc, which the emulator can't
# run, so we STUB it (EAX=0, cdecl: pop nothing) and pre-allocate the event buffer
# at 0x260000, pre-pointing match+0x1a24 there. With count starting at 0 the first
# event lands at buf + (0+1)*0x10 - 0x10 = 0x260000 exactly.
#
# Memory map: match M@0x200000, event buffer @0x260000, team T@0x270000 (phase at
# +0xfa0). keeper_event adds: ball B@0x220000, keeper K@0x230000, stat C@0x250000.
# DAT_006d31c4 = 0 (in-sim). Values banked decimal (32-bit unsigned LE).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/event_oracle.txt
SPEC=$SPECDIR/_event_run.spec
ROUT=$SPECDIR/_event_run.out

run_emu() {
  : > "$ROUT"   # clear: a spec-parse failure must not leak the previous fixture
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

# ---- FUN_00594470 (enqueue) direct -----------------------------------------
# emit_enq  CODE  PLAYER  FLAG  PHASE  PX PY  FREEZE
emit_enq() {
  cat > "$SPEC" <<EOF
entry   0x594470
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
arg     $1                    # param_2 = event code
arg     $2                    # param_3 = player ptr (0 = no player)
arg     $3                    # param_4 = flag/priority
zero    0x00200000 0x00002000
zero    0x00230000 0x00000400
zero    0x00260000 0x00001000
zero    0x00270000 0x00001000
stub    0x005bbf10 0 0        # FUN_005bbf10 (GlobalReAlloc) -> no-op; buffer pre-set
mem 0x006d31c4 1 0x0          # DAT_006d31c4 = 0 (in-sim)
mem 0x00201a24 4 0x00260000   # match+0x1a24 = event buffer
mem 0x00201a28 4 0x0          # match+0x1a28 = count = 0
mem 0x00201a38 4 $7           # match+0x1a38 freeze flag
mem 0x00200468 4 0x00270000   # match+0x468 -> team
mem 0x00270fa0 4 $4           # team+0xfa0 = phase
mem 0x002302b8 4 $5           # player+0x2b8 = display x
mem 0x002302c0 4 $6           # player+0x2c0 = display y
maxsteps 2000000
read_mem 0x00201a28 4         # count after
read_mem 0x00260000 4         # event[0] code
read_mem 0x00260004 4         # event[1] x
read_mem 0x00260008 4         # event[2] y
read_mem 0x0026000c 4         # event[3] delay
read_mem 0x00201a2c 4         # 0x1a2c max-flag
read_mem 0x00201a30 4         # 0x1a30 timer
EOF
}

# ---- FUN_005909f0 (keeper_event) direct ------------------------------------
# emit_kev  SAVEFLAG  BITS  PHASE  KX KY
emit_kev() {
  cat > "$SPEC" <<EOF
entry   0x5909f0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00220000
arg     $1                    # param_2 = save_flag (char)
zero    0x00200000 0x00002000
zero    0x00220000 0x00001000
zero    0x00230000 0x00000400
zero    0x00250000 0x00000100
zero    0x00260000 0x00001000
zero    0x00270000 0x00001000
stub    0x005bbf10 0 0
mem 0x006d31c4 1 0x0          # DAT_006d31c4 = 0
mem 0x0022004c 4 0x0          # ball+0x4c = 0 (enter the body)
mem 0x00220050 4 0x00230000   # ball+0x50 -> keeper
mem 0x002201d4 4 0x00200000   # ball+0x1d4 -> match
mem 0x002303b8 4 0x00250000   # keeper+0x3b8 -> stat struct
mem 0x002302b8 4 $4           # keeper+0x2b8 = display x
mem 0x002302c0 4 $5           # keeper+0x2c0 = display y
mem 0x00200462 1 $2           # match+0x462 band bits
mem 0x00201a24 4 0x00260000   # match+0x1a24 = event buffer
mem 0x00201a28 4 0x0          # match+0x1a28 = count = 0
mem 0x00201a38 4 0x0          # match+0x1a38 freeze = 0
mem 0x00200468 4 0x00270000   # match+0x468 -> team
mem 0x00270fa0 4 $3           # team+0xfa0 = phase
maxsteps 2000000
read_mem 0x00250080 4         # stat+0x80 save counter
read_mem 0x0025007c 4         # stat+0x7c conceded counter
read_mem 0x00201a28 4         # count after
read_mem 0x00260000 4         # event[0] code
read_mem 0x00260004 4         # event[1] x
read_mem 0x00260008 4         # event[2] y
read_mem 0x0026000c 4         # event[3] delay
read_mem 0x00201a2c 4         # 0x1a2c max-flag
read_mem 0x00201a30 4         # 0x1a30 timer
EOF
}

# name        CODE    PLAYER      FLAG  PHASE  PX      PY      FREEZE
ENQ_MATRIX=(
  "basic      0x10    0x00230000  0x0   0x1    0x111   0x222   0x0"
  "noplayer   0x10    0x0         0x0   0x1    0x0     0x0     0x0"
  "flag1      0x10    0x00230000  0x1   0x1    0x5     0x6     0x0"
  "phase4skip 0x1     0x0         0x1   0x4    0x0     0x0     0x0"
  "phase4upd  0x2     0x0         0x3   0x4    0x0     0x0     0x0"
  "frozen     0x10    0x00230000  0x0   0x1    0x111   0x222   0x1"
)
# name        SAVEFLAG  BITS   PHASE  KX      KY
KEV_MATRIX=(
  "save_b40   0x0       0x40   0x1    0x777   0x888"
  "save_b20   0x0       0x20   0x1    0x777   0x888"
  "save_nobit 0x0       0x0    0x1    0x777   0x888"
  "conceded   0x1       0x40   0x1    0x777   0x888"
  "save_b80   0x0       0x80   0x1    0x777   0x888"
)

: > "$OUT"
echo "# Stage 3 task 2 event-queue ground truth (oracle = PCode emu, realloc stubbed)." >> "$OUT"
echo "# == enqueue FUN_00594470 == name | count | code | x | y | delay | a2c | a30 | RET?" >> "$OUT"
for row in "${ENQ_MATRIX[@]}"; do
  read -r NAME CODE PLAYER FLAG PHASE PX PY FREEZE <<<"$row"
  emit_enq "$CODE" "$PLAYER" "$FLAG" "$PHASE" "$PX" "$PY" "$FREEZE"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'E %-10s | %-3s | %-4s | %-6s | %-6s | %-4s | %-4s | %-4s | %s\n' \
    "$NAME" "$(mval "$S" 0x201a28)" "$(mval "$S" 0x260000)" "$(mval "$S" 0x260004)" \
    "$(mval "$S" 0x260008)" "$(mval "$S" 0x26000c)" "$(mval "$S" 0x201a2c)" \
    "$(mval "$S" 0x201a30)" "${RET:-?}" >> "$OUT"
  echo "[E $NAME] count=$(mval "$S" 0x201a28) code=$(mval "$S" 0x260000) a2c=$(mval "$S" 0x201a2c) a30=$(mval "$S" 0x201a30) $RET"
done
echo "# == keeper_event FUN_005909f0 == name | s80 | s7c | count | code | x | y | delay | a2c | a30 | RET?" >> "$OUT"
for row in "${KEV_MATRIX[@]}"; do
  read -r NAME SAVEFLAG BITS PHASE KX KY <<<"$row"
  emit_kev "$SAVEFLAG" "$BITS" "$PHASE" "$KX" "$KY"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'K %-10s | %-3s | %-3s | %-3s | %-4s | %-6s | %-6s | %-4s | %-4s | %-4s | %s\n' \
    "$NAME" "$(mval "$S" 0x250080)" "$(mval "$S" 0x25007c)" "$(mval "$S" 0x201a28)" \
    "$(mval "$S" 0x260000)" "$(mval "$S" 0x260004)" "$(mval "$S" 0x260008)" \
    "$(mval "$S" 0x26000c)" "$(mval "$S" 0x201a2c)" "$(mval "$S" 0x201a30)" "${RET:-?}" >> "$OUT"
  echo "[K $NAME] s80=$(mval "$S" 0x250080) s7c=$(mval "$S" 0x25007c) count=$(mval "$S" 0x201a28) code=$(mval "$S" 0x260000) $RET"
done
echo "=== event-queue oracle -> $OUT ==="
cat "$OUT"
