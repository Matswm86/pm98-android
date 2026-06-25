extends SceneTree
## Oracle-backed parity test for FUN_005b05a0 PHASE 2 (the sector-grid approach-ball steer, slice
## 2b-ii-phase2): Pm98Movement._approach_steer_target == the composed steer TARGET the real binary
## hands to FUN_005a89c0.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b05a0_phase2.gd
##
## ORACLE = the REAL FUN_005b05a0 forced into phase 2 (empty bbox) with FUN_005a89c0 STUBBED, the target
## read off the stack: tools/re/run_b05a0_phase2_oracle.sh -> specs/b05a0_phase2_oracle.txt
##   (B05A0P2 <name> steer=1 | 0x307fc0=<tx> 0x307fc4=<ty> 0x307fc8=<tz>).
## We rebuild the identical p/m/ball Dicts (goalx 0x100000; grid[i].x = goalx + 0x30000*(i-0x16),
## grid[i].y = 0x8000) and assert the GDScript target == the oracle's [tx, ty, tz] bit-for-bit.

var _fail := 0
var _pass := 0

# name -> {bx, by, bz, vx, vy}  (mirrors run_b05a0_phase2_oracle.sh FIX rows).
var _fix := {
	"sectorlo":    {"bx": 0x110000, "by": 0,        "bz": 0, "vx": 0x80000, "vy": 0},
	"sectorclamp": {"bx": 0x280000, "by": 0,        "bz": 0, "vx": 0,       "vy": 0},
	"sectormid":   {"bx": 0x1c0000, "by": 0,        "bz": 0, "vx": 0x10000, "vy": 0},
	"angled":      {"bx": 0x180000, "by": 0x80000,  "bz": 0, "vx": 0x20000, "vy": 0x10000},
}


func _init() -> void:
	var o := _load("b05a0_phase2_oracle.txt", "B05A0P2")
	if o.is_empty():
		_ok(false, "b05a0 phase2 oracle empty (run tools/re/run_b05a0_phase2_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from b05a0 phase2 oracle")
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


func _s32(v: int) -> int:
	return v - 0x100000000 if v >= 0x80000000 else v


# name -> [tx, ty, tz] (signed), parsed from the three banked stack addresses.
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
		var vals := {}
		for tok in parts:
			for addr in ["0x307fc0", "0x307fc4", "0x307fc8"]:
				if tok.begins_with(addr + "="):
					vals[addr] = _s32(tok.substr(addr.length() + 1).to_int())
		if vals.size() == 3:
			out[name] = [vals["0x307fc0"], vals["0x307fc4"], vals["0x307fc8"]]
	return out


func _run(name: String, want: Array) -> void:
	var s: Dictionary = _fix[name]
	var m := {0x1820: 0x100000, 0x19a0: 1}
	var ball := {
		4: int(s["bx"]), 8: int(s["by"]), 0xc: int(s["bz"]),
		0x20: int(s["vx"]), 0x24: int(s["vy"]), 0x28: 0,
	}
	for i in range(0x17, 0x24):                         # trajectory grid slots 0x17..0x23
		ball[0xc * i] = 0x100000 + 0x30000 * (i - 0x16)
		ball[0xc * i + 4] = 0x8000
		ball[0xc * i + 8] = 0
	var p := {4: 0, 8: 0, 0xc: 0, 0x2b8: 0, 0x18c: m, 0x190: ball}
	var got: Array = Pm98Movement._approach_steer_target(p)
	_ok(got == want, "b05a0p2/%s: target=%s want=%s" % [name, got, want])
