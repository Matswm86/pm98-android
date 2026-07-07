extends SceneTree
## Locks _dist_kick_aad30 / _dist_kick_aae40 (phase-6 keeper goal-kick distribution) bit-for-bit against
## the PCode-emu truth banked by tools/re/run_distkick_oracle.sh -> specs/distkick_oracle.txt. These are
## the leaves that clear the M5 phase-6 stall. aae40 fixtures use an EMPTY own-team (count 0) so the
## blind-throw branch fires (matching the oracle's count=0 setup). Run:
##   ~/godot462 --headless --path app --script res://tests/test_distkick.gd

const ORACLE := "res://../tools/re/specs/distkick_oracle.txt"

# READS order banked by the oracle (see its header line).
const P_OFF := [0x40, 0x2c, 0x30, 0x48, 0x84, 0x80, 0x94, 0x98, 0x9c, 0x66, 0xa0, 0xa4, 0xa8, 0xb4, 0x6c]
const B_OFF := [0x68, 0x6c, 0x9c, 0xa0, 0xa4, 0x4c]

# Fixtures MUST match run_distkick_oracle.sh: name -> [px, py, pz, facing, bx, by]
const FIX := {
	"aad30_a": [0, 0, 0, 0x2000, 0x1000, 0x2000],
	"aad30_b": [0x30000, -0x10000, 0, 0x6000, 0x28000, -0x8000],
	"aae40_a": [0, 0, 0, 0x2000, 0x1000, 0x2000],
	"aae40_b": [0x30000, -0x10000, 0, 0x6000, 0x28000, -0x8000],
}

var _checks := 0
var _fail := 0


func _init() -> void:
	var truth := _load_oracle()
	if truth.is_empty():
		push_error("no oracle rows in %s (run tools/re/run_distkick_oracle.sh)" % ORACLE)
		quit(1)
		return
	for name in truth:
		_run_fixture(name, truth[name])
	print("\n%s (%d checks, %d fixtures)" % [
		"ALL PASS" if _fail == 0 else "FAIL (%d)" % _fail, _checks, truth.size()])
	quit(1 if _fail > 0 else 0)


func _run_fixture(name: String, expect: Array) -> void:
	var fx: Array = FIX[name]
	var m := {}
	var ball := {4: fx[4], 8: fx[5], 0xc: 0}
	var gs := {0: []}                                 # empty own team -> count 0 -> aae40 blind throw
	var p := {
		4: fx[0], 8: fx[1], 0xc: fx[2], 0x34: fx[3],
		0x2c: 999, 0x30: 999,                         # non-zero so a reset is observable
		0x190: ball, 0x18c: m, 0x184: gs,
	}
	if name.begins_with("aad30"):
		Pm98Movement._dist_kick_aad30(p)
	else:
		Pm98Movement._dist_kick_aae40(p)

	var got := []
	for off in P_OFF:
		got.append(Pm98Trig._i32(_field(p, off)))
	for off in B_OFF:
		got.append(Pm98Trig._i32(_field(ball, off)))
	got.append(Pm98Trig._i32(_field(m, 0x19dc)))

	for i in range(expect.size()):
		_checks += 1
		var exp := Pm98Trig._i32(expect[i])
		if got[i] != exp:
			_fail += 1
			print("  FAIL %s field#%d: got %d  expected %d" % [name, i, got[i], exp])


## Read a field, coercing an unset key or a Dict ref (ball[0x4c] teammate) to 0 for the numeric compare.
func _field(d: Dictionary, k: int) -> int:
	var v: Variant = d.get(k, 0)
	return int(v) if (v is int or v is float) else 0


func _load_oracle() -> Dictionary:
	var f := FileAccess.open(ORACLE, FileAccess.READ)
	if f == null:
		return {}
	var out := {}
	while not f.eof_reached():
		var ln := f.get_line().strip_edges()
		if not ln.begins_with("FIX "):
			continue
		var parts := ln.split(" ", false)
		var name := parts[1]
		var vals := []
		for i in range(2, parts.size()):
			vals.append(int(parts[i]))              # unsigned i32 text; _i32 folds to signed
		out[name] = vals
	return out
