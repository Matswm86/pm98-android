extends SceneTree
## Oracle-backed parity test for the FUN_005a7260 dribble-block near-ball pull-in (slice 2b-ii):
##   Pm98Movement._near_ball_pullin_decide == FUN_005b05a0's "call FUN_005b0040?" gate decision.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b05a0.gd
##
## ORACLE = the REAL FUN_005b05a0 driven through the Ghidra PCode emulator with FUN_005b0040 stubbed:
##   tools/re/run_b05a0_oracle.sh -> specs/b05a0_oracle.txt   (B05A0 <name> ... b0040=<0|1>)
## We rebuild the identical Dict/Array fixtures and assert _near_ball_pullin_decide == (b0040 == 1).
## The lane clearance (FUN_005b1070) runs REAL on both sides; clear/blocked fixtures sit far from the
## radius boundary so LUT residuals can't flip the decision (the boundary itself is disasm-verified).

var _fail := 0
var _pass := 0

# name -> {ball_x, ball_168, ball_1bc, carrier_team (-1 = none), roster: [[x,y,z,active], ...]}.
# Mirrors run_b05a0_oracle.sh: m goal anchor = [0x100000,0,0]; bbox x[0,0x200000] y/z[-0x100000,0x100000].
var _fix := {
	"bboxfail":      {"ball_x": 0x300000, "carrier": -1, "roster": []},
	"nearfail":      {"ball_x": 0x1f9000, "carrier": -1, "roster": []},
	"near2":         {"ball_x": 0x1f9000, "ball_168": 0x100000, "carrier": -1, "roster": [[0, 0, 0, 0]]},
	"near3":         {"ball_x": 0x1f9000, "ball_1bc": 0x100000, "carrier": -1, "roster": [[0, 0, 0, 0]]},
	"carriersame":   {"ball_x": 0x100000, "carrier": 0, "roster": []},
	"carrierdiff":   {"ball_x": 0x100000, "carrier": 1, "roster": [[0, 0, 0, 0]]},
	"clearmove":     {"ball_x": 0x100000, "carrier": -1, "roster": [[0, 0, 0, 0]]},
	"blockednomove": {"ball_x": 0x100000, "carrier": -1, "roster": [[0x80000, 0, 0, 1]]},
}


func _init() -> void:
	var o := _load("b05a0_oracle.txt", "B05A0")
	if o.is_empty():
		_ok(false, "b05a0 oracle empty (run tools/re/run_b05a0_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, int(o[name]))
			else:
				_ok(false, name + ": missing from b05a0 oracle")
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


func _load(fname: String, tag: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path(fname), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with(tag + " "):
			continue
		var parts := line.split(" ", false)
		var name := parts[1]
		for tok in parts:
			if tok.begins_with("b0040="):
				out[name] = tok.substr(6).to_int()
	return out


func _run(name: String, want_hit: int) -> void:
	var s: Dictionary = _fix[name]
	var m := {
		0x1820: 0x100000, 0x19a0: 1,
		0x1828: 0, 0x1834: 0x200000,
		0x182c: -0x100000, 0x1838: 0x100000,
		0x1830: -0x100000, 0x183c: 0x100000,
	}
	var ball := {
		4: int(s.get("ball_x", 0x100000)), 8: 0, 0xc: 0,
		0x168: int(s.get("ball_168", 0)), 0x16c: 0, 0x170: 0,
		0x1bc: int(s.get("ball_1bc", 0)), 0x1c0: 0, 0x1c4: 0,
	}
	var carrier_team: int = int(s["carrier"])
	if carrier_team >= 0:
		ball[0x40] = {0x2b8: carrier_team}
	else:
		ball[0x40] = 0
	var roster := []
	for r in s["roster"]:
		roster.append({4: r[0], 8: r[1], 0xc: r[2], 0x2bc: r[3]})
	var gs := {0: roster}
	var p := {4: 0, 8: 0, 0xc: 0, 0x2b8: 0, 0x184: gs, 0x18c: m, 0x190: ball}
	var got: bool = Pm98Movement._near_ball_pullin_decide(p)
	_ok(got == (want_hit == 1), "b05a0/%s: decide=%s want b0040=%d" % [name, got, want_hit])
