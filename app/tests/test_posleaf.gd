extends SceneTree
## Oracle-backed parity test for the two FUN_005b73a0 positioning leaves, ported in
## Pm98Movement.pos_forward_ok (FUN_005b04e0) and count_goalside_opponents (FUN_005b0b40).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_posleaf.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator, EAX = return
## (tools/re/run_posleaf_oracle.sh -> specs/posleaf_oracle.txt). Mirrors each fixture, runs the
## GDScript port, and asserts the return matches the banked EAX.

# Shared match box (mirror the oracle): bounds + the goal-line scale.
const MBOX := {0x1828: -0x200000, 0x1834: 0x200000, 0x182c: -0x180000, 0x1838: 0x180000,
	0x1830: -0x10000, 0x183c: 0x100000, 0x1820: 0x140000}
const PANCHOR := 0x140000                    # player+0x3a4 for the 5b04e0 fixtures (sign +1)
# Shared opponents for the 5b0b40 fixtures: [x, anchor]. player.x=0x40000 anchor=0x40000 -> base 0x80000.
const OPP := [[0x100000, 0], [0x20000, 0]]
const FIX := {
	"b04e0_ok":       {"k": "e", "pos": [-0x100000, 0x10000, 0]},
	"b04e0_outbox":   {"k": "e", "pos": [0x300000, 0x10000, 0]},
	"b04e0_online":   {"k": "e", "pos": [-0x10000, 0x10000, 0]},
	"b04e0_ybig":     {"k": "e", "pos": [-0x100000, 0x1428f5, 0]},
	"b04e0_samesign": {"k": "e", "pos": [0x100000, 0x10000, 0]},
	"b0b40_one":      {"k": "c", "thresh": 0x20000},
	"b0b40_all":      {"k": "c", "thresh": 0x100000},
	"b0b40_none":     {"k": "c", "thresh": -0x80000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "posleaf oracle file empty/unreadable")
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


# Parse "FIX <name> ... EAX=<val>": row -> {name: eax}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("posleaf_oracle.txt"), FileAccess.READ)
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
	if fx["k"] == "e":
		var m := MBOX.duplicate()
		var p := {0x18c: m, 0x3a4: PANCHOR}
		var got: int = 1 if Pm98Movement.pos_forward_ok(p, fx["pos"]) else 0
		_ok(got == eax, "%s: got %d want %d" % [name, got, eax])
	else:
		var opponents := []
		for o in OPP:
			opponents.append({0x4: int(o[0]), 0x3a4: int(o[1])})
		var p := {0x4: 0x40000, 0x3a4: 0x40000}
		var got := Pm98Movement.count_goalside_opponents(p, opponents, int(fx["thresh"]))
		_ok(got == eax, "%s: got %d want %d" % [name, got, eax])
