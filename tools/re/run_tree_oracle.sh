#!/usr/bin/env bash
# Stage 2: sweep a branch-covering fixture matrix through the REAL resolver
# FUN_005aeda0 (PCode-emulated) and dump each fixture's exact RNG draw stream +
# final RNG state. This is the ground truth the GDScript decision-tree port
# (Pm98Resolver) must reproduce bit-for-bit. Proven LUT-invariant (see
# docs/re/match_engine_re.md oracle note), so a zero trig LUT is used.
#
# Each matrix row: NAME PANG TANG POS ENGAGED SKILL HDR  (hex values).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
TMPL=$SPECDIR/resolver_tree.tmpl
OUT=$SPECDIR/tree_oracle_streams.txt

# NAME            PANG     TANG     POS  ENGAGED SKILL HDR
MATRIX=(
  "baseline       0x0      0x0      0x0  0x0     0x0   0x0"
  "fwd_skill      0x0      0x0      0x9  0x0     0x32  0x0"
  "header         0x0      0x0      0x9  0x0     0x32  0x14"
  "engaged_hdr    0x0      0x0      0x9  0x1     0x32  0x14"
  "angle_else     0x0      0x4000   0x9  0x0     0x32  0x14"
  "engaged_angle  0x0      0x4000   0x9  0x1     0x50  0x14"
  # bVar5-TRUE goal/save outcomes (Stage 2c): exercise the resolved-outcome block
  # (match+0x461 bit0 via FUN_0058fb50, bit2 = save, stats +0x9c/+0xa0, the
  # M+0x19ac div-guarded FUN_0044ec00 path). hi_face = a save (bvar7), hi_angle =
  # an on-target miss (bvar5 set, no save/goal -> bit0 only). Both need skill 0x64.
  "hi_face        0x0      0x0      0x9  0x0     0x64  0x14"
  "hi_angle       0x0      0x4000   0x9  0x0     0x64  0x14"
)

: > "$OUT"
echo "# Stage 2 resolver decision-tree ground truth (oracle = PCode emu, zero LUT)" >> "$OUT"
echo "# Outcome cols: bits=match+0x461  g/o/a=stats +0x98/+0x9c/+0xa0  Tst=T+0x40 final" >> "$OUT"
echo "# fixture | nrng | draws(in order) | state | enq set | bits g/o/a Tst | RET?" >> "$OUT"
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9]+" | cut -d= -f2 || true; }
field() { echo "$1" | grep -oE "$2=[0-9]+" | cut -d= -f2 || true; }  # tolerant: 0/absent ok
for row in "${MATRIX[@]}"; do
  read -r NAME PANG TANG POS ENGAGED SKILL HDR <<<"$row"
  sed -e "s/__PANG__/$PANG/" -e "s/__TANG__/$TANG/" -e "s/__POS__/$POS/" \
      -e "s/__ENGAGED__/$ENGAGED/" -e "s/__SKILL__/$SKILL/" -e "s/__HDR__/$HDR/" \
      "$TMPL" > "$SPECDIR/_tree_run.spec"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPECDIR/_tree_run.spec" "$SPECDIR/_tree_run.out" \
    >/dev/null 2>&1 || true
  DRAWS=$(grep -oE 'TRACE rng #[0-9]+ step=[0-9]+ EAX=[0-9]+' "$SPECDIR/_tree_run.out" \
            | grep -oE 'EAX=[0-9]+' | cut -d= -f2 | paste -sd, -)
  SUMMARY=$(grep -E 'CALL 0 (RET|HALT)' "$SPECDIR/_tree_run.out" | head -1)
  NRNG=$(field "$SUMMARY" rng)
  RET=$(echo "$SUMMARY" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  ENQ=$(field "$SUMMARY" enqueue)
  SET=$(field "$SUMMARY" setstate)
  STATE=$(mval "$SUMMARY" 0x6d3184); BITS=$(mval "$SUMMARY" 0x200461)
  G=$(mval "$SUMMARY" 0x230098);     O=$(mval "$SUMMARY" 0x23009c)
  A=$(mval "$SUMMARY" 0x2300a0);      TST=$(mval "$SUMMARY" 0x210040)
  printf '%-14s | %-2s | %-46s | %-11s | enq=%-1s set=%-1s | bits=%-3s %s/%s/%s Tst=%s | %s\n' \
    "$NAME" "${NRNG:-0}" "${DRAWS:-NONE}" "${STATE:-NA}" "${ENQ:-0}" "${SET:-0}" \
    "${BITS:-NA}" "${G:-0}" "${O:-0}" "${A:-0}" "${TST:-NA}" "${RET:-?}" >> "$OUT"
  echo "[$NAME] nrng=${NRNG:-0} enq=${ENQ:-0} bits=${BITS:-NA} g/o/a=${G:-0}/${O:-0}/${A:-0} Tst=${TST:-NA} $RET"
done
echo "=== tree oracle -> $OUT ==="
cat "$OUT"
