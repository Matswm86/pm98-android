extends SceneTree
## Oracle-backed parity test for the per-player DECIDE coordinate helpers
## (FUN_005a44f0 / 5a4510 / 0059a0e0 / 5b11f0), ported in Pm98Movement.gd. These are the
## per-team-side orientation + vec-compose primitives FUN_005a3400 (the DECIDE) and
## FUN_005b73a0 (positioning) call.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_decidehelper.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator
## (tools/re/run_decidehelper_oracle.sh -> tools/re/specs/decidehelper_oracle.txt). Each row
## is `FIX <name> fn=<addr> in=<input ints, csv> out=<scalar | 3-int vec>`; this test
## dispatches by fn, calls the GDScript port with `in`, and asserts the output bit-for-bit.

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_helpers()
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


func _spec_path(name: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(name).simplify_path()


func _s32(v: int) -> int:
	v &= 0xffffffff
	return v - 0x100000000 if v >= 0x80000000 else v


func _test_helpers() -> void:
	print("== DECIDE coordinate helpers vs PCode-emu oracle ==")
	var f := FileAccess.open(_spec_path("decidehelper_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "cannot open oracle " + _spec_path("decidehelper_oracle.txt"))
		return
	var rows := 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var name := toks[1]
		var fn := ""
		var arr := PackedInt64Array()
		var want := PackedInt64Array()
		for t in toks:
			if t.begins_with("fn="):
				fn = t.substr(3)
			elif t.begins_with("in="):
				for s in t.substr(3).split(","):
					arr.append(s.to_int())
			elif t.begins_with("out="):
				for s in t.substr(4).split(","):
					want.append(_s32(s.to_int()))
		rows += 1
		match fn:
			"5a44f0":
				var got := Pm98Movement.goal_target_x(arr[0], arr[1], arr[2])
				_ok(got == want[0], "%s goal_target_x: got %d want %d" % [name, got, want[0]])
			"5a4510":
				var got: Array = Pm98Movement.mirror_to_side(arr[0], arr[1], [arr[2], arr[3], arr[4]])
				for i in 3:
					_ok(got[i] == want[i], "%s mirror_to_side[%d]: got %d want %d" % [name, i, got[i], want[i]])
			"5b11f0":
				var got: Array = Pm98Movement.vec_compose([arr[0], arr[1]], arr[2])
				for i in 3:
					_ok(got[i] == want[i], "%s vec_compose[%d]: got %d want %d" % [name, i, got[i], want[i]])
			_:
				_ok(false, "%s unknown fn tag %s" % [name, fn])
	_ok(rows == 6, "decidehelper oracle had 6 fixtures (got %d)" % rows)
