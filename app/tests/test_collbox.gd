extends SceneTree
## Oracle-backed parity test for the two ball-collision box leaves, ported in
## Pm98Movement.box_add3 (FUN_00590b10) and Pm98Movement.boxes_overlap (FUN_00590b30). Both are
## leaves of the goal/post collision loop in FUN_0058e2c0 (the next unported ball-physics slice).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_collbox.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator (memory for box_add3, EAX for
## boxes_overlap), tools/re/run_collbox_oracle.sh -> specs/collbox_oracle.txt.

const U32 := 0xffffffff
const FIX := {
	"b10_pos":  {"k": "add", "v": [100, 200, 300], "s": 0x10000},
	"b10_neg":  {"k": "add", "v": [0, 0, 0], "s": -5},
	"b10_wrap": {"k": "add", "v": [0x50000000, 0, -0x40000000], "s": 0x40000000},
	"ov_hit":    {"k": "ov", "b": [0x50, 0x50, 0x50, 0x150, 0x150, 0x150]},
	"ov_xedge":  {"k": "ov", "b": [0x100, 0x50, 0x50, 0x200, 0x150, 0x150]},
	"ov_xsep":   {"k": "ov", "b": [0x200, 0, 0, 0x300, 0x100, 0x100]},
	"ov_yedge":  {"k": "ov", "b": [0, 0x100, 0, 0x100, 0x200, 0x100]},
	"ov_zedge":  {"k": "ov", "b": [0, 0, 0x100, 0x100, 0x100, 0x200]},
	"ov_inside": {"k": "ov", "b": [0x10, 0x10, 0x10, 0x20, 0x20, 0x20]},
	"ov_neg":    {"k": "ov", "b": [-0x50, -0x50, -0x50, 0x10, 0x10, 0x10]},
}
const AFIX := [0, 0, 0, 0x100, 0x100, 0x100]
const V3_ADDRS := [0x230000, 0x230004, 0x230008]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "collbox oracle file empty/unreadable")
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


# Parse "FIX <name> ... [EAX=v] [mem[0xADDR:W]=v ...]": row -> {"eax": v, "mem": {addr: v}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("collbox_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rxe := RegEx.new(); rxe.compile("EAX=(-?[0-9]+)")
	var rxm := RegEx.new(); rxm.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {"mem": {}}
		var e := rxe.search(line)
		if e != null:
			row["eax"] = e.get_string(1).to_int()
		for mtch in rxm.search_all(line):
			row["mem"][("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	match fx["k"]:
		"add":
			var r: Array = Pm98Movement.box_add3(fx["v"], int(fx["s"]))
			var em: Dictionary = exp["mem"]
			for i in 3:
				_ok((int(r[i]) & U32) == (int(em[V3_ADDRS[i]]) & U32),
					"%s [%d]: got 0x%x want 0x%x" % [name, i, int(r[i]) & U32, int(em[V3_ADDRS[i]]) & U32])
		"ov":
			var got: int = 1 if Pm98Movement.boxes_overlap(AFIX, fx["b"]) else 0
			_ok(got == int(exp.get("eax", -1)), "%s: got %d want %d" % [name, got, int(exp.get("eax", -1))])
