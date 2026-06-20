extends SceneTree
## Oracle-backed parity test for the axis-rotation leaves FUN_005ee670 / 005ee6e0 / 005ee750, ported in
## Pm98Trig.rot_vec3 (plane 0=Z/xy, 1=Y/xz, 2=X/yz).
##
## Run headless: ~/godot462 --headless --path app --script res://tests/test_rotvec.gd
## ORACLE = tools/re/run_rotvec_oracle.sh -> specs/rotvec_oracle.txt (the REAL leaves under the PCode emu).

const V0 := 0x200000
const U32 := 0xffffffff

# name -> [x, y, z, angle, plane]
const FIX := {
	"z_q": [0x10000, 0x0, 0x30000, 0x4000, 0],
	"z_oct": [0x20000, -0x10000, 0x12345, 0x2000, 0],
	"z_neg": [-0x18000, 0x8000, 0x7777, -0x1800, 0],
	"y_q": [0x10000, 0x55555, 0x0, 0x4000, 1],
	"y_oct": [0x20000, 0x9999, -0x10000, 0x2abc, 1],
	"y_neg": [-0x14000, 0x3333, 0x28000, -0x3000, 1],
	"x_q": [0x44444, 0x10000, 0x0, 0x4000, 2],
	"x_oct": [0x1234, 0x20000, 0x8000, 0x1500, 2],
	"x_neg": [0x6666, -0x18000, 0x10000, -0x2200, 2],
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "rotvec oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("rotvec_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int() - V0] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Array = FIX[name]
	var v := Pm98Trig.rot_vec3([int(src[0]), int(src[1]), int(src[2])], int(src[3]), int(src[4]))
	var got := {0x0: int(v[0]) & U32, 0x4: int(v[1]) & U32, 0x8: int(v[2]) & U32}
	for off in exp:
		_ok(got[off] == (int(exp[off]) & U32), "%s +0x%x: got 0x%x want 0x%x" % [name, off, got[off], int(exp[off]) & U32])
