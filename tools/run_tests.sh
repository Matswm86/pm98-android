#!/bin/bash
# Run the whole tests/test_*.gd suite in parallel and report by EXIT CODE.
#
# Grepping stdout for "ALL PASS" is what the ad-hoc sweeps used to do, and it lies: the
# suite has at least five green footers in the wild ("ALL PASS", "<name>: PASS",
# "ALL GREEN", "ALL OK", "MAKE-OFFER: ALL GREEN"), so a footer grep reported 22 healthy
# tests as failures on 2026-08-01. Every test calls quit(0) on success and quit(1) on
# failure, which is also what CI gates on — use that.
#
# Usage:  tools/run_tests.sh [-j N] [pattern]
#   tools/run_tests.sh                  # whole suite
#   tools/run_tests.sh -j 4 youth       # only tests whose name matches "youth"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$HOME/godot4}"
JOBS=6
if [ "${1:-}" = "-j" ]; then JOBS="$2"; shift 2; fi
PATTERN="${1:-}"
LOGS="${PM98_TEST_LOGS:-/tmp/pm98-tests}"
mkdir -p "$LOGS"

cd "$ROOT/app" || exit 2

run_one() {
	local t
	t="$(basename "$1" .gd)"
	if timeout 600 "$GODOT" --headless --path . --script "res://tests/$t.gd" \
			> "$LOGS/$t.log" 2>&1; then
		echo "PASS $t"
	else
		echo "FAIL $t (rc=$? — see $LOGS/$t.log)"
	fi
}
export -f run_one
export GODOT LOGS

mapfile -t TESTS < <(printf '%s\n' tests/test_*.gd | { [ -n "$PATTERN" ] && grep -- "$PATTERN" || cat; })
printf '%s\n' "${TESTS[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {} \
	| tee "$LOGS/sweep.txt"

echo "----"
echo "PASS $(grep -c '^PASS' "$LOGS/sweep.txt") / ${#TESTS[@]}"
grep '^FAIL' "$LOGS/sweep.txt" && exit 1
exit 0
