extends SceneTree
## Oracle-backed parity test for FUN_005edfd0 (chained 16.16 fixmul), ported as Pm98Trig.fixmul3.
## Run: ~/godot462 --headless --path app --script res://tests/test_fixmul3.gd
## ORACLE = the REAL FUN_005edfd0 under the PCode emulator (tools/re/run_fixmul3_oracle.sh ->
## specs/fixmul3_oracle.txt). Each row: FIX <name> <a> <b> <c> EAX=<ret>.

const U32 := 0xffffffff
var _fail := 0
var _pass := 0


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/fixmul3_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "fixmul3 oracle unreadable (run tools/re/run_fixmul3_oracle.sh)")
	else:
		var rx := RegEx.new()
		rx.compile("^FIX (\\S+) (\\S+) (\\S+) (\\S+) EAX=(-?[0-9]+)")
		while not f.eof_reached():
			var m := rx.search(f.get_line().strip_edges())
			if m == null:
				continue
			var a := _parse(m.get_string(2))
			var b := _parse(m.get_string(3))
			var c := _parse(m.get_string(4))
			var want := m.get_string(5).to_int()
			var got: int = Pm98Trig.fixmul3(a, b, c)
			_ok((got & U32) == (want & U32),
				"%s fixmul3(0x%x,0x%x,0x%x): got 0x%x want 0x%x" % [m.get_string(1), a, b, c, got & U32, want & U32])
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _parse(s: String) -> int:
	var neg := s.begins_with("-")
	if neg:
		s = s.substr(1)
	var v := s.hex_to_int() if s.begins_with("0x") else s.to_int()
	return -v if neg else v


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
