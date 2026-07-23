#!/usr/bin/env bash
# M5 s50: drive the REAL FUN_005b0040 through the Ghidra PCode emulator on the EXACT t1.i10
# inputs the port sees at match clk 638 / 639 / 640, and bank the computed steer TARGET
# (local_c @ 0x307ff0).
#
# WHY. The first real port-vs-silicon fork (skew-aware differ) is clk 644, ONE player, t1.i10.
# diag_m5_t1i10_site.gd proved every steer_89c0 in that window comes from _move_b0040 -- not a
# goal-anchor steer -- and that the team/orient terms are constant across the flip, so the s49
# "wrong-side selection" hypothesis is dead. diag_m5_t1i10_b0040iter.gd then showed WHAT flips:
# the <=0x12-iteration interception bisection NEVER converges here (the ball outruns the
# player: |ball.vel| 13633/tick vs curve_rate 6703), `lead` grows ~1.55x per iteration to ~1e9,
# and on the last iteration `nd + lead` overflows signed 32-bit:
#     clk 638  nd=1431300725 + lead=691703136 = 2123003861  (fits)      -> lead=+1061501930
#     clk 639  nd=1492610119 + lead=721336533 = 2213946652  (WRAPS)     -> lead=-1040510322
# The pitch clamp then pins the target to the +x/+y corner at 638 and the -x/-y corner at 639.
# That is the whole "target mirrored through the origin".
#
# So the open question is purely: does the REAL binary produce the same runaway + wrap, or does
# it differ (different loop bound, different convergence test, saturating magnitude)? This
# script answers it against the actual MANAGER.EXE code rather than by reasoning about the
# decompile.
#
# Inputs below are verbatim from diag_m5_t1i10_b0040iter.gd (Godot port, frame0 seed
# 0xea0d2a8d, capture2 struct import). Only the fields _b0040_target actually reads are set
# from real data; the steer-tail-only fields keep the run_b0040_oracle.sh fixture values since
# local_c is written before the tail-call and is read back after return.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b0040_m5_oracle.txt
SPEC=$SPECDIR/_b0040_m5_run.spec
ROUT=$SPECDIR/_b0040_m5_run.out
LUT=$SPECDIR/_b0040_m5_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

P=0x00230000; M=0x00210000; CTRL=0x00240000; GS=0x00250000; OTHER=0x00260000

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

READS="
read_mem 0x00307ff0 4
read_mem 0x00307ff4 4
read_mem 0x00307ff8 4
read_mem 0x00230004 4
read_mem 0x00230008 4
read_mem 0x0023000c 4
"

# emit_spec PX PY  BX BY BZ  BVX BVY BVZ  BFACE
# The 16 formation marker slots ctrl+(idx+0x17)*0xc are an exact arithmetic ladder in the live
# capture -- verified against the per-iteration mkv values dumped by
# diag_m5_t1i10_b0040iter.gd -- namely slot[i] = ball.pos.xy + i * 4 * ball.vel.xy (each slot is
# 4 ticks of ball flight). They are generated from that rather than listed by hand.
emit_spec() {
  local px=$1 py=$2 bx=$3 by=$4 bz=$5 bvx=$6 bvy=$7 bvz=$8 bface=$9
  local mk0x=$bx mk0y=$by stepx=$(( bvx * 4 )) stepy=$(( bvy * 4 ))
  {
    echo "entry   0x5b0040"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P"
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "mem 0x006233a4 4 0x00252000"
    echo "stub 0x00605ff0 0 0 atexit"
    echo "maxsteps 8000000"
    # Per-iteration bisection trace of the REAL loop (0x5b01ee..0x5b032b). EBX is uVar7 (`lead`).
    #   0x5b0285 LEA ESI,[EAX-0x3c]  -> EAX = ticks (the IDIV quotient), EBX = lead going in
    #   0x5b0312 MOV EBX,EAX         -> EAX = new lead, ECX = nd, EBX = lead going in
    echo "trace 0x005b0285 ticks"
    echo "trace 0x005b0312 lead"
    echo "trace_reg EAX"
    echo "trace_reg EBX"
    echo "trace_reg ECX"
    cat "$LUT"
    echo "zero    0x00230000 0x00000400"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00240000 0x00000400"
    echo "zero    0x00250000 0x00000400"
    echo "zero    0x00260000 0x00000400"
    poke 0x00230184 $GS
    poke 0x0023018c $M
    poke 0x00230190 $CTRL
    poke 0x00230004 "$px"          # p.x   (real)
    poke 0x00230008 "$py"          # p.y   (real)
    poke 0x0023000c 0              # p.z   (real: 0)
    poke 0x00230070 13429          # p+0x70  (real)
    poke 0x002303ac 2739           # p+0x3ac (real)
    poke 0x002303a8 4251           # p+0x3a8 (real)  -> curve_rate = 13429*2739/15000 + 4251 = 6703
    poke 0x00230388 0x4000
    poke 0x002302bc 10             # p+0x2bc (real on-pitch/marker flag)
    poke 0x00210448 0              # M+0x448 phase 0 (open play)
    poke 0x00210461 0
    poke 0x00211970 0x7f000000
    poke 0x00211978 0x7f000000
    # REAL pitch clamp box m+0x1828 lo / m+0x1834 hi
    poke 0x00211828 -3768320; poke 0x0021182c -2359296; poke 0x00211830 -65536
    poke 0x00211834 3768320;  poke 0x00211838 2359296;  poke 0x0021183c 65536000
    poke 0x00240040 "$OTHER"       # ctrl+0x40 active player is SOMEONE ELSE (real)
    poke 0x0024004c 0              # ctrl+0x4c != p  -> carrier branch not taken (real)
    poke 0x00240004 "$bx"
    poke 0x00240008 "$by"
    poke 0x0024000c "$bz"
    poke 0x00240020 "$bvx"
    poke 0x00240024 "$bvy"
    poke 0x00240028 "$bvz"
    poke 0x00240034 "$bface"
    poke 0x00240084 0x60000
    poke 0x00240088 0x20000
    poke 0x0024008c 0
    poke 0x002400b0 0              # real: marker-adjust thresholds both 0 -> both skipped
    poke 0x002400bc 0
    # 16 interception marker slots ctrl+(idx+0x17)*0xc
    local i off mx my
    for i in $(seq 0 15); do
      off=$(( (i + 0x17) * 0xc ))
      mx=$(( mk0x + stepx * i ))
      my=$(( mk0y + stepy * i ))
      poke $(( 0x00240000 + off )) "$mx"
      poke $(( 0x00240000 + off + 4 )) "$my"
    done
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
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  echo "FIX $name | $kv" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
  grep -E 'TRACE (ticks|lead) ' "$ROUT" | sed -E "s/^/TRACE $name /" >> "$OUT"
}

: > "$OUT"
echo "# M5 s50: REAL FUN_005b0040 on the live t1.i10 clk 638/639/640 inputs." >> "$OUT"
echo "# target(local_c) @0x307ff0/4/8 ; P.pos @0x230004/8/c. Port results for comparison:" >> "$OUT"
echo "#   clk638 target=[3768320, 2359296, 154494]   (preclamp [1045495016, 187543173, 154494])" >> "$OUT"
echo "#   clk639 target=[-3768320, -2359296, 161386] (preclamp [-1023306846, -187689993, 161386])" >> "$OUT"
echo "#   clk640 target=[-3768320, -2359296, 168100] (preclamp [-994320611, -182432577, 168100])" >> "$OUT"

#          PX      PY        BX      BY        BZ      BVX   BVY  BVZ   BFACE
emit_spec  349576  -1840512  757224  -1948268  154494  13633 2451 6892  1854; run_emu; bank clk638
emit_spec  350402  -1839495  770857  -1945817  161386  13633 2451 6714  1854; run_emu; bank clk639
emit_spec  350939  -1838834  784490  -1943366  168100  13633 2451 6536  1854; run_emu; bank clk640

echo "=== b0040 M5 oracle -> $OUT ==="
cat "$OUT"
