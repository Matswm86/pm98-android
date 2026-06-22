#!/usr/bin/env bash
# Stage 3 task 2 (step 4, build oracle): drive the REAL per-player builder
# FUN_005a2830 through the Ghidra PCode emulator and bank the exact derived
# stat block. Ground truth that Pm98Match._build_player must reproduce
# bit-for-bit (app/tests/test_player_build_oracle.gd), INCLUDING the recovered
# 0xe1 ftol() field -- this run exercises the real x87 fld/fild/fmul -> _ftol
# path @0x5a2e36..0x5a2e65, pinning what the disasm+gcc-x87 cross-check derived.
#
# FUN_005a2830(__thiscall this=player P, int team, int slot, int match M, rec R):
#   ebp == ECX == P (the player struct being built). Reads the source record R
#   (byte-keyed), the team header TH = M+0x46c+team*800 (R0 selector at TH+0x31c,
#   part-strength flag TH+0x2ec), and the match M (mode M+0x19a0, clock M+0x19ac,
#   M+0x1a5c, M+0x1820, glyph table ptr M+0x2550). Writes the derived block at
#   P+0x2c0(0xb0)..P+0x3ac(0xeb). NO RNG.
#
# Emulation wrinkles:
#   * ftol = FUN_00605fb0 = `jmp [0x6233a4]`, an UNBOUND msvcrt _ftol import. We
#     inject a faithful truncate-toward-zero _ftol @0x252000 and repoint the IAT
#     slot, exactly as run_movement/run_relmatrix. The 0xe1 selector doubles
#     (0.6/0.8/1.0 @0x639248/50/58) are STATIC .rdata, already mapped at their VAs.
#     KNOWN-WRONG COLUMN: 0xe1. Ghidra's PCode emu holds the x87 stack as 64-bit
#     doubles, so `byte*0.6` (a 55-bit-mantissa product) rounds UP to the nearest
#     double before ftol -> the banked 0xe1 reads 3/6/153 for byte 5/10/255, whereas
#     real 80-bit x87 keeps the value < the integer and truncates to 2/5/152. Every
#     INTEGER field is emulator-exact; for 0xe1 trust the gcc-x87 oracle / the
#     exact-integer port instead (see app/tests/test_player_build_oracle.gd CAVEAT).
#   * the name/photo string block (0x5a2950..0x5a2a32) calls Win32 lstrcpyA/
#     lstrlenA (via [0x623054]/[0x623040]) + sprintf (via [0x6233cc]). All display,
#     none read downstream -- we repoint those slots to dummy stub VAs (esi=lstrcpyA
#     stdcall/8, edi=lstrlenA stdcall/4 [ret 0 -> appends harmlessly], sprintf
#     cdecl/0) so the stack stays balanced and the math runs.
#   * the sprite-load block (0x5a31c2..0x5a3231) is skipped by stubbing FUN_005ec1d0
#     -> 0. The one-shot offset-table build (guard DAT_00674628) is skipped by
#     presetting the guard byte to 1. The 6x6/8x8 kit-mask loops read the glyph
#     table at M+0x2550 -> a zeroed region (0x255000), so every cell is 0 and the
#     loops write nothing. FUN_00590aa0/5b1190/5c9210 (ctors over our zeroed P) run.
#
# Memory map (all below image base 0x400000, so `zero`/`mem` map them fresh):
#   player P@0x230000  match M@0x210000 (team header TH@0x21046c=M+0x46c, team 0)
#   record R@0x240000  _ftol@0x252000  glyph-zero@0x255000  stub VAs 0x254000..
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/playerbuild_oracle.txt
SPEC=$SPECDIR/_playerbuild_run.spec
ROUT=$SPECDIR/_playerbuild_run.out

P=0x230000 ; M=0x210000 ; R=0x240000 ; TH=0x21046c

# Readback: object base + offset (decimal width). Covers every ported branch.
READS=(
  "0x2302c0 4" "0x2302c4 4" "0x2302c8 4" "0x2302d0 4" "0x2302dc 4"   # 0xb0 0xb1 0xb2 0xb4 0xb7
  "0x230378 4" "0x23037c 4" "0x230380 4" "0x230384 4" "0x230388 4"   # 0xde 0xdf 0xe0 0xe1 0xe2
  "0x23038c 4" "0x230390 4" "0x230394 4" "0x230398 4" "0x23039c 4"   # 0xe3 0xe4 0xe5 0xe6 0xe7
  "0x2303a0 4" "0x2303a8 4" "0x2303ac 4"                             # 0xe8 0xea 0xeb
  "0x230070 4" "0x230074 4" "0x230078 4"                             # 0x1c 0x1d 0x1e
  "0x23036c 4" "0x230370 4" "0x2302da 1"                             # 0xdb 0xdc 0x2da
  "0x2301f8 4" "0x230228 4"                                          # start pos 0x7e 0x8a
)

emit_spec() {
  # $1 = team  $2 = slot  $3 = pokes (record/header/match fields; ';'-separated)
  cat > "$SPEC" <<EOF
entry   0x5a2830
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $P
arg     $1
arg     $2
arg     $M
arg     $R
zero    0x00210000 0x00003000
zero    0x00230000 0x00001000
zero    0x00240000 0x00000400
zero    0x00255000 0x00004000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000     # _ftol -> injected truncate thunk
mem 0x00623054 4 0x00254000     # lstrcpyA  -> stub (stdcall/8)
mem 0x00623040 4 0x00254010     # lstrlenA  -> stub (stdcall/4, ret 0)
mem 0x006233cc 4 0x00254020     # sprintf   -> stub (cdecl/0)
stub 0x00254000 0 8
stub 0x00254010 0 4
stub 0x00254020 0 0
stub 0x005ec1d0 0 0             # FUN_005ec1d0(buf) cdecl -> 0 : skip sprite-load block
stub 0x005c9f60 0 8             # (unreached when 5ec1d0 -> 0, kept for safety)
stub 0x005d4ac0 0 4
mem 0x00674628 1 0x1            # one-shot table-build guard -> already done (skip)
mem 0x00212550 4 0x00255000     # M+0x2550 = glyph table ptr -> zeroed region
mem 0x0021046c 4 $P             # TH[0] = player array base (arr_idx 0)
mem 0x00210758 1 0x1            # TH+0x2ec part-strength flag = full (no reduction)
mem 0x00240004 4 0x0000270f     # R+0x4 shirt (u16) -- unique, no sub-table match
$3
EOF
  { echo "maxsteps 8000000"; for r in "${READS[@]}"; do echo "read_mem $r"; done; } >> "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

# Fixtures: name | team | slot | pokes. Record bytes chosen to exercise each branch.
# R offsets: +0x34(de) +0x35(df) +0x36(e0) +0x37(e1-base) +0x38(e2) +0x3c(e3)
#   +0x3d(e4) +0x3e(e5) +0x3f(e6) +0x40(e7) +0x41(e8) +0x42(fit) +0x44(role)
#   +0x2c(dc+1) +0x30(db+1) +0x98(2da) +0x8(pos7e) +0x18(pos8a)
# TH+0x31c = 0xe1 selector (0->0.6 1->0.8 else 1.0). M+0x19a0 mode. M+0x19ac clock.
BASE_REC="mem 0x240034 1 0x32 ; mem 0x240035 1 0x28 ; mem 0x240036 1 0x5a ; mem 0x240037 1 0x0a ; mem 0x240038 1 0x40 ; mem 0x24003c 1 0x3c ; mem 0x24003d 1 0x46 ; mem 0x24003e 1 0x50 ; mem 0x24003f 1 0x4b ; mem 0x240040 1 0x55 ; mem 0x240041 1 0x3a ; mem 0x240042 1 0x2d ; mem 0x240044 1 0x03 ; mem 0x24002c 1 0x02 ; mem 0x240030 1 0x01 ; mem 0x240098 1 0x01 ; mem 0x240008 4 0x11112222 ; mem 0x240018 4 0x33334444"

FIX=(
"outfield_s2|0|5|$BASE_REC ; mem 0x210788 4 0x2 ; mem 0x21a5c 4 0x0"
"gk_s2|0|0|$BASE_REC ; mem 0x210788 4 0x2"
"sel0_06|0|5|$BASE_REC ; mem 0x240037 1 0x05 ; mem 0x210788 4 0x0"
"sel1_08|0|5|$BASE_REC ; mem 0x240037 1 0x05 ; mem 0x210788 4 0x1"
"sel0_trap10|0|5|$BASE_REC ; mem 0x240037 1 0x0a ; mem 0x210788 4 0x0"
"sel0_255|0|5|$BASE_REC ; mem 0x240037 1 0xff ; mem 0x210788 4 0x0"
"mode4|0|5|$BASE_REC ; mem 0x210788 4 0x2 ; mem 0x2119a0 4 0x4"
"clock18k|0|5|$BASE_REC ; mem 0x210788 4 0x2 ; mem 0x2119ac 4 0x4650"
"partstr|0|5|$BASE_REC ; mem 0x210788 4 0x2 ; mem 0x210758 1 0x0"
"team1|1|5|$BASE_REC ; mem 0x210788 4 0x2"
)

: > "$OUT"
echo "# Stage 3 task 2 step-4 player-build (FUN_005a2830) ground truth (PCode emu;" >> "$OUT"
echo "# real x87 ftol path for 0xe1; display/sprite stubbed; decimal LE; P=0x230000)." >> "$OUT"
echo "# cols: name RET | b0 b1 b2 b4 b7 | de df e0 e1 e2 e3 e4 e5 e6 e7 e8 ea eb | 1c 1d 1e | db dc 2da | p7e p8a" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME TEAM SLOT POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$TEAM" "$SLOT" "$POKES"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  vals=""
  for r in "${READS[@]}"; do a=${r%% *}; vals+="$(mval "$S" "$a") "; done
  printf 'FIX %-13s %-4s | %s\n' "$NAME" "${RET:-?}" "$vals" >> "$OUT"
  echo "[$NAME] ${RET:-?} e1=$(mval "$S" 0x230384) e3=$(mval "$S" 0x23038c) df=$(mval "$S" 0x23037c)"
done
echo "=== playerbuild oracle -> $OUT ==="
cat "$OUT"
