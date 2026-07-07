extends SceneTree
## Oracle-backed parity test for FUN_0058fda0's PREDICTED-TRAJECTORY buffer (ball+0x114..0x1d3, 16 vec3),
## ported in Pm98Movement._ball_predict_traj (called from _ball_tail). This buffer feeds _grid9490_build
## (the lean's gate-4 catch zone) + the 7260 marker builders; deferring FUN_0058fda0 left it all-zero,
## the root cause of M5 divergence #1 (kickoff ball collected ~4 ticks late -> RNG draw-count desync).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_ballpredict.gd
##
## ORACLE = the REAL FUN_0058fda0 under the Ghidra PCode emulator, run to a clean RET
## (tools/re/run_ballpredict_oracle.sh -> specs/ballpredict_oracle.txt). Only pos/vel seeded; the
## function builds its own segments. We compare the 48 ints of the +0x114 buffer bit-for-bit. The
## segment-length scratch (+0x74/78/7c) is banked by the oracle but is internal (the port keeps it in a
## local), so it is excluded from the comparison.

const B0 := 0x230000
const U32 := 0xffffffff

# pos(+0x4/8/c) + vel(+0x20/24/28) per fixture -- must match run_ballpredict_oracle.sh exactly.
const FIX := {
	"roll_kick": {0x4: -38265, 0x8: -117125, 0xc: 0, 0x20: -3777, 0x24: -11564, 0x28: 0},
	"roll_x": {0x4: 0, 0x8: 0, 0xc: 0, 0x20: 0x8000, 0x24: 0, 0x28: 0},
	"roll_diag": {0x4: 0x1000, 0x8: 0x2000, 0xc: 0, 0x20: 0x4000, 0x24: 0x3000, 0x28: 0},
	"roll_slow": {0x4: 0x3000, 0x8: 0x5000, 0xc: 0, 0x20: 0x10, 0x24: 0x10, 0x28: 0},
	"air": {0x4: 0, 0x8: 0, 0xc: 0x20000, 0x20: 0x4000, 0x24: 0x2000, 0x28: 0x8000},
	"air2": {0x4: 0x5000, 0x8: 0, 0xc: 0x10000, 0x20: 0x2000, 0x24: 0x6000, 0x28: 0x4000},
	"air_down": {0x4: 0, 0x8: 0, 0xc: 0x8000, 0x20: 0x3000, 0x24: -0x2000, 0x28: -0x2000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "ballpredict oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, orc[name])
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("ballpredict_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			row[("0x" + mtch.get_string(1)).hex_to_int() - B0] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Dictionary = FIX[name]
	var ball := {}
	for off in src:
		ball[int(off)] = int(src[off])

	Pm98Movement._ball_predict_traj(ball)

	for off in exp:
		if int(off) < 0x114:                    # skip the +0x74/78/7c segment-length scratch
			continue
		var got := int(ball.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got %d want %d" % [name, off, Pm98Trig._i32(got), Pm98Trig._i32(want)])
