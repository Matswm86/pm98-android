#!/usr/bin/env bash
# Run EVERY app/tests/test_*.gd headless and report pass/fail.
#
# Success is decided on the EXIT CODE plus explicit failure markers, NOT on a
# success string. The suites do not share one: they end with "ALL PASS",
# "DIVISIONS OK", "MORALE: ALL GREEN", "test_outer: 50 checks, 0 FAIL" and
# others. A 2026-07-28 sweep that grepped only for "ALL PASS" reported 36 of 243
# failing when every one of them passed -- so the marker list is the wrong
# instrument and this script does not use one.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
GODOT=${GODOT:-$HOME/godot462}
pass=0; fail=0; failed=""
for f in app/tests/test_*.gd; do
  t=$(basename "$f" .gd)
  out=$(timeout "${PM98_TEST_TIMEOUT:-400}" "$GODOT" --headless --path app \
        --script "res://tests/$t.gd" 2>&1); rc=$?
  if [ $rc -ne 0 ] || printf '%s' "$out" | grep -qiE \
      "FAILURES ABOVE|[1-9][0-9]* FAIL|FAIL:|\[FAIL\]|SCRIPT ERROR"; then
    fail=$((fail+1)); failed="$failed $t"
    printf 'FAIL %s\n' "$t"
  else
    pass=$((pass+1))
  fi
done
echo "PASS=$pass FAIL=$fail"
[ -n "$failed" ] && echo "FAILED:$failed"
exit $((fail > 0))
