#!/usr/bin/env bash
# M5 fixed-seed match sweep — the "does the recovered engine hold up over N matches" harness.
#
# WHAT IT CERTIFIES, and what it does NOT. Each seed is driven through the FULL port engine
# (app/tests/run_full_match.gd: Pm98Match.build_match -> Pm98LineupFeeder real squads ->
# Pm98Outer.step to dispatch code 10) and the run is checked for:
#   * FULL TIME reached on dispatch code 10, not a FRAME_CAP bail-out
#   * no crash / no script error
#   * DETERMINISM — the first N_DET seeds are run TWICE and the two digests must be identical
# A digest is the scoreline + phase histogram + dispatch histogram + final RNG state.
#
# That is reproducibility and robustness. It is NOT "this IS the 1998 engine": nothing here is
# compared against MANAGER.EXE. Silicon parity is a separate, much narrower measurement — see
# docs/re/M5_S55_SAMPLING_PHASE_ARTEFACT.md — and today it reaches clk 660 of a 14400-clk match,
# so no full-match silicon reference can be reproduced yet. Do not report a green sweep as parity.
#
# Usage: run_match_sweep.sh [N_SEEDS=50] [N_DET=5] [JOBS=2]
#   ~3 min of CPU per run, so 50 seeds + 5 repeats at 2 jobs is roughly 1.5 h. Runs are
#   independent; raise JOBS only if the box has the cores AND the RAM free (Godot headless
#   peaks near 1 GB per run).
set -uo pipefail
cd "$(dirname "$0")/../.."   # repo root: tools/re -> tools -> .
GODOT=${GODOT:-$HOME/godot462}
N=${1:-50}
NDET=${2:-5}
JOBS=${3:-2}
OUT=${OUT:-/tmp/pm98-match-sweep}
mkdir -p "$OUT"

digest() { # strip the wall-clock-ish lines, keep the deterministic result fields
  grep -E "^(final score|phase histogram|dispatch freezes|final rng state|clock) " "$1" | sort
}

run_one() {
  local seed=$1 tag=$2
  local log="$OUT/seed${seed}_${tag}.log"   # separate `local`: same-line expansion sees $seed unset
  PM98_SEED="$seed" "$GODOT" --headless --path app \
    --script res://tests/run_full_match.gd > "$log" 2>&1
  echo "$seed $tag rc=$?" >> "$OUT/_exits.txt"
}

echo "== sweep: $N seeds, first $NDET run twice, $JOBS jobs, logs in $OUT"
: > "$OUT/_exits.txt"
queue=()
for s in $(seq 1 "$N"); do queue+=("$s a"); done
for s in $(seq 1 "$NDET"); do queue+=("$s b"); done
for item in "${queue[@]}"; do
  while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do wait -n; done
  # shellcheck disable=SC2086  # item is "<seed> <tag>", split on purpose
  run_one $item &
done
wait

fail=0
for s in $(seq 1 "$N"); do
  log="$OUT/seed${s}_a.log"
  if [ ! -s "$log" ]; then echo "  seed $s: NO OUTPUT"; fail=$((fail + 1)); continue; fi
  if grep -qE "SCRIPT ERROR|Parse Error" "$log"; then
    echo "  seed $s: SCRIPT ERROR"; fail=$((fail + 1)); continue
  fi
  if ! grep -q "10: 1" "$log"; then
    echo "  seed $s: never reached FULL TIME (dispatch 10)"; fail=$((fail + 1)); continue
  fi
  score=$(grep "^final score" "$log" | head -1)
  if [ "$s" -le "$NDET" ]; then
    if ! diff -q <(digest "$log") <(digest "$OUT/seed${s}_b.log") > /dev/null 2>&1; then
      echo "  seed $s: NON-DETERMINISTIC across two runs"; fail=$((fail + 1)); continue
    fi
    echo "  seed $s: FT ok, deterministic  ($score)"
  else
    echo "  seed $s: FT ok  ($score)"
  fi
done
echo
echo "== $((N - fail))/$N seeds reached FULL TIME cleanly; $NDET checked for determinism; $fail failures"
exit $((fail > 0))
