#!/usr/bin/env bash
# Stage 3 task 2 (movement, slice 5b): drive the REAL phase-based active-player selector
# FUN_005b8f20 -- the TWO branches deferred from slice 5a -- through the Ghidra PCode
# emulator and bank the chosen active + queue + bookkeeping state. Ground truth that
# Pm98Movement.select_active (_select_phase2 / _select_phase57) must reproduce bit-for-bit
# (app/tests/test_selectactive5b.gd).
#
#   * phase 2 -> active = the on-pitch player with the highest LUT[player+0x2c8], where the
#     LUT is the STATIC .rdata table at &DAT_006392c8 (read straight from the loaded image;
#     `mov ecx,[ecx*4+0x6392c8]`). The compare is `<=` so a TIE keeps the LATER player.
#   * phase 5/7 -> a persistent set-piece queue at ctx+0x208 (buffer) / ctx+0x20c (count).
#     Empty queue -> BUILD (append every player), a verbatim cached-LHS selection pass,
#     a +0x2ed flag, a maybe-truncate-to-1, a maybe-zero-+0x8c; then EVERY call POPS the
#     front. key = player+0x3a0 (+ +0x388 if phase 7), signed; off-pitch sinks.
#
# Win32 in the build/pop path is neutralised: the GlobalReAlloc grower FUN_005bbf10 is
# STUBBED (cdecl no-op; the buffer ptr ctx+0x208 is pre-pointed at 0x270000 so appends land
# there), and the IAT memmove `call ds:0x6233d4` (5b9376) is repointed to a FAITHFUL injected
# memmove at 0x252100 (forward copy; preserves esi/edi/ebx -- the caller re-reads esi=&ctx+0x208
# right after). The faithful _ftol @0x252000 is kept from slice 5a but never fires here (no
# float path), and NO cos/atan LUT is needed.
#
# Memory map: ctx S@0x200000, match M@0x210000, players P0@0x230000 / P1@0x2303bc /
# P2@0x230778 / P3@0x230b34 (stride 0x3bc), teaminfo T@0x250000, injected _ftol@0x252000,
# injected memmove@0x252100, phase struct @0x260000 (M+0x468 -> it, +0xfa0 = sub-phase),
# queue buffer @0x270000. Active ptr (= EAX = ctx+0x168) + queue + flags read by abs addr.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/selectactive5b_oracle.txt
SPEC=$SPECDIR/_selectactive5b_run.spec
ROUT=$SPECDIR/_selectactive5b_run.out

# x86 machine code (raw bytes) injected below image base, IAT slots repointed at them.
#   _ftol  @0x252000 : MSVC float->long truncate-toward-zero (RC=11), non-popping fist.
FTOL=83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
#   memmove@0x252100 : cdecl void* memmove(dst,src,n) forward byte copy, esi/edi preserved:
#     push edi; push esi; mov edi,[esp+0xc]; mov esi,[esp+0x10]; mov ecx,[esp+0x14];
#     mov eax,edi; cld; rep movsb; pop esi; pop edi; ret
MEMMOVE=57568B7C240C8B7424108B4C241489F8FCF3A45E5FC3

# Readback: active ptr; queue count; flag byte; each +0x5c; each +0x8c; buffer[0..3].
READS=(
  "0x200168 4"                                              # active ptr (== EAX = ctx+0x168)
  "0x20020c 4"                                              # ctx+0x20c queue count
  "0x2002ed 1"                                              # ctx+0x2ed flag out
  "0x23005c 1" "0x230418 1" "0x2307d4 1" "0x230b90 1"       # P0/P1/P2/P3 +0x5c
  "0x23008c 4" "0x230448 4" "0x230804 4" "0x230bc0 4"       # P0/P1/P2/P3 +0x8c
  "0x270000 4" "0x270004 4" "0x270008 4" "0x27000c 4"       # queue buffer[0..3] (player ptrs)
)

emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b8f20
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00200000
zero    0x00200000 0x00002000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00250000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
stub    0x5bbf10 0 0
mem 0x006d31c4 1 0x0
membts 0x00252000 $FTOL
mem 0x006233a4 4 0x00252000
membts 0x00252100 $MEMMOVE
mem 0x006233d4 4 0x00252100
mem 0x00200000 4 0x00230000     # ctx+0 player base
mem 0x00200004 4 0x4            # ctx+4 count
mem 0x00200008 4 0x0            # ctx+8 team
mem 0x00200138 4 0x00210000     # ctx+0x138 match
mem 0x00200168 4 0x0            # ctx+0x168 active = none
mem 0x00200208 4 0x00270000     # ctx+0x208 queue buffer ptr
mem 0x0020020c 4 0x0            # ctx+0x20c queue count = 0 (build) unless overridden
mem 0x00210438 4 0x0            # match+0x438 forced player = none
mem 0x00210448 4 0x0            # match+0x448 phase
mem 0x002119a0 4 0x0            # match+0x19a0 mode
mem 0x00210468 4 0x00260000     # match+0x468 -> phase struct
mem 0x00260fa0 4 0x0            # sub-phase
mem 0x002302bc 4 0x1            # P0 on-pitch
mem 0x00230184 4 0x00250000     # P0+0x184 teaminfo
mem 0x0023018c 4 0x00210000     # P0+0x18c match
mem 0x00230678 4 0x1            # P1 on-pitch
mem 0x00230540 4 0x00250000     # P1 teaminfo
mem 0x00230548 4 0x00210000     # P1 match
mem 0x00230a34 4 0x1            # P2 on-pitch
mem 0x002308fc 4 0x00250000     # P2 teaminfo
mem 0x00230904 4 0x00210000     # P2 match
mem 0x00230df0 4 0x1            # P3 on-pitch
mem 0x00230cb8 4 0x00250000     # P3 teaminfo
mem 0x00230cc0 4 0x00210000     # P3 match
$1
maxsteps 3000000
EOF
  for r in "${READS[@]}"; do echo "read_mem $r" >> "$SPEC"; done
}

# Fixtures: name | pokes (';'-separated, appended after the base). All single-call.
# Player field abs addrs: +0x2c8 P0=0x2302c8 P1=0x230684 P2=0x230a40 P3=0x230dfc ;
#   +0x3a0 P0=0x2303a0 P1=0x23075c P2=0x230b18 P3=0x230ed4 ;
#   +0x388 P0=0x230388 P1=0x230744 P2=0x230b00 P3=0x230ebc ;
#   +0x8c  P0=0x23008c P1=0x230448 P2=0x230804 P3=0x230bc0 ;
#   +0x2bc P0=0x2302bc P1=0x230678 P2=0x230a34 P3=0x230df0 .
FIX=(
# --- phase 2 (static priority LUT; reads the real &DAT_006392c8) ---
"p2_argmax|mem 0x00210448 4 0x2 ; mem 0x002302c8 4 0xa ; mem 0x00230684 4 0x9 ; mem 0x00230a40 4 0x8 ; mem 0x00230dfc 4 0xc"
"p2_tie_last|mem 0x00210448 4 0x2 ; mem 0x002302c8 4 0x9 ; mem 0x00230684 4 0xc ; mem 0x00230a40 4 0x9 ; mem 0x00230dfc 4 0x8"
"p2_offpitch|mem 0x00210448 4 0x2 ; mem 0x002302bc 4 0x0 ; mem 0x002302c8 4 0x9 ; mem 0x00230684 4 0xc ; mem 0x00230a40 4 0xa ; mem 0x00230dfc 4 0x8"
"p2_allzero|mem 0x00210448 4 0x2 ; mem 0x002302c8 4 0x0 ; mem 0x00230684 4 0x1 ; mem 0x00230a40 4 0x2 ; mem 0x00230dfc 4 0x3"
# --- phase 5/7 (set-piece queue) ---
"p5_build_trunc|mem 0x00210448 4 0x5 ; mem 0x002119a0 4 0x0 ; mem 0x002303a0 4 0x100 ; mem 0x0023075c 4 0x400 ; mem 0x00230b18 4 0x200 ; mem 0x00230ed4 4 0x300 ; mem 0x0023008c 4 0x1 ; mem 0x00230448 4 0x1 ; mem 0x00230804 4 0x1 ; mem 0x00230bc0 4 0x1"
"p7_build_trunc|mem 0x00210448 4 0x7 ; mem 0x002119a0 4 0x0 ; mem 0x002303a0 4 0x100 ; mem 0x0023075c 4 0x100 ; mem 0x00230b18 4 0x100 ; mem 0x00230ed4 4 0x100 ; mem 0x00230388 4 0x10 ; mem 0x00230744 4 0x50 ; mem 0x00230b00 4 0x30 ; mem 0x00230ebc 4 0x20"
"p5_offpitch|mem 0x00210448 4 0x5 ; mem 0x002119a0 4 0x0 ; mem 0x002302bc 4 0x0 ; mem 0x002303a0 4 0x500 ; mem 0x0023075c 4 0x100 ; mem 0x00230b18 4 0x300 ; mem 0x00230ed4 4 0x200"
"p5_flag1|mem 0x00210448 4 0x5 ; mem 0x002119a0 4 0x4 ; mem 0x002002ee 1 0x1 ; mem 0x00260fa0 4 0x2 ; mem 0x002303a0 4 0x100 ; mem 0x0023075c 4 0x400 ; mem 0x00230b18 4 0x200 ; mem 0x00230ed4 4 0x300 ; mem 0x0023008c 4 0x0 ; mem 0x00230448 4 0x1 ; mem 0x00230804 4 0x1 ; mem 0x00230bc0 4 0x1"
"p5_build_nocycle|mem 0x00210448 4 0x5 ; mem 0x002119a0 4 0x4 ; mem 0x002002ee 1 0x0 ; mem 0x002303a0 4 0x100 ; mem 0x0023075c 4 0x400 ; mem 0x00230b18 4 0x200 ; mem 0x00230ed4 4 0x300"
"p5_pop_existing|mem 0x00210448 4 0x5 ; mem 0x0020020c 4 0x3 ; mem 0x00270000 4 0x00230778 ; mem 0x00270004 4 0x00230000 ; mem 0x00270008 4 0x00230b34 ; mem 0x00200168 4 0x002303bc ; mem 0x00230418 1 0x1"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 task 2 slice 5b: phase-2 LUT + phase-5/7 set-piece queue (FUN_005b8f20)." >> "$OUT"
echo "# PCode-emu ground truth; FUN_005bbf10 stubbed, faithful memmove@0x252100 injected." >> "$OUT"
echo "# Each row: 'FIX <name>' then the verbatim CALL line. bases: P0=0x230000 P1=0x2303bc" >> "$OUT"
echo "# P2=0x230778 P3=0x230b34 ; null=0 (ptr -> index via (ptr-0x230000)/0x3bc, 0 -> -1)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9]+')"
done
echo "=== selectactive5b oracle -> $OUT ==="
cat "$OUT"
