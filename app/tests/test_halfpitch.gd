extends SceneTree
## Oracle-backed parity test for FUN_0058f0b0 (half-pitch test), ported in
## Pm98Movement.player_opposite_half.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_halfpitch.gd
##
## ORACLE = the REAL FUN_0058f0b0 under the Ghidra PCode emulator, EAX = return
## (tools/re/run_halfpitch_oracle.sh -> specs/halfpitch_oracle.txt).

const M1820 := 0x140000           # match+0x1820 (mirror the oracle)
const FIX := {
	"opp_x":   {"orient": 0, "side": 0, "px": 0x100000},
	"same_x":  {"orient": 0, "side": 0, "px": -0x100000},
	"side1":   {"orient": 0, "side": 1, "px": 0x100000},
	"orient1": {"orient": 1, "side": 0, "px": -0x100000},
	"zero_x":  {"orient": 0, "side": 0, "px": 0},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "halfpitch oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, int(orc[name]))
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
	var f := FileAccess.open(_spec_path("halfpitch_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("EAX=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var m := rx.search(line)
		if m != null:
			out[toks[1]] = m.get_string(1).to_int()
	return out


func _run(name: String, eax: int) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x1820: M1820, 0x19a0: int(fx["orient"])}
	var p := {0x1d4: m, 0x4: int(fx["px"])}
	var got: int = 1 if Pm98Movement.player_opposite_half(p, int(fx["side"])) else 0
	_ok(got == eax, "%s: got %d want %d" % [name, got, eax])
