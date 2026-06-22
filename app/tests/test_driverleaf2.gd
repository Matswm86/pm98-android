extends SceneTree
## Oracle-backed parity test for four more FUN_00598740 driver leaves (restart-placement ladder +
## event-queue gate), ported in Pm98Movement.vec3_set (FUN_00590aa0), play_state_eq (FUN_005943b0/
## f0/d0), clamp_x_goalside (FUN_0059a1e0), restart_box_ok (FUN_0059a120).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_driverleaf2.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator (EAX / memory),
## tools/re/run_driverleaf2_oracle.sh -> specs/driverleaf2_oracle.txt. play_state EAX is masked
## & 0xff (the binary leaves CONCAT31 junk in the upper bytes; the caller reads AL only).

const U32 := 0xffffffff
# Each fixture mirrors the emu setup exactly. "k" picks the GDScript call.
const FIX := {
	"vec_set":      {"k": "copy", "args": [0x11110000, 0x22220000, 0x33330000]},
	"ps_eq0_T":     {"k": "ps", "n": 0, "mode": 0},
	"ps_eq0_F":     {"k": "ps", "n": 0, "mode": 2},
	"ps_eq2_T":     {"k": "ps", "n": 2, "mode": 2},
	"ps_eq4_T":     {"k": "ps", "n": 4, "mode": 4},
	# clamp: match+0x1820=0xb0000, player+0x3a4=dir, vec=[x,0,0], factor 0x5f.
	"clamp_neg":    {"k": "clamp", "goalx": 0xb0000, "dir": -1, "vec": [0x100000, 0, 0], "f": 0x5f},
	"clamp_pos":    {"k": "clamp", "goalx": 0xb0000, "dir": 1, "vec": [-0x100000, 0, 0], "f": 0x5f},
	"clamp_no":     {"k": "clamp", "goalx": 0xb0000, "dir": 1, "vec": [0, 0, 0], "f": 0x5f},
	# restart box: dims xmin/xmax=-/+0x200000, ymin/ymax=-/+0x200000, zmin/zmax=0/0x100000, goalx=0x200000.
	"rb_same_T":    {"k": "rb", "dir": 1, "vec": [0x110000, 0, 0x10000]},
	"rb_oppside_F": {"k": "rb", "dir": -1, "vec": [0x110000, 0, 0x10000]},
	"rb_shallow_F": {"k": "rb", "dir": 1, "vec": [0xf0000, 0, 0x10000]},
	"rb_outbox_F":  {"k": "rb", "dir": 1, "vec": [0x300000, 0, 0x10000]},
}
const BOX := {0x1828: -0x200000, 0x1834: 0x200000, 0x182c: -0x200000, 0x1838: 0x200000,
	0x1830: 0, 0x183c: 0x100000, 0x1820: 0x200000}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "driverleaf2 oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("driverleaf2_oracle.txt"), FileAccess.READ)
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
		"copy":
			var r: Array = Pm98Movement.vec3_set(fx["args"][0], fx["args"][1], fx["args"][2])
			var em: Dictionary = exp["mem"]
			var addrs := [0x230000, 0x230004, 0x230008]
			for i in 3:
				_ok((int(r[i]) & U32) == (int(em[addrs[i]]) & U32),
					"%s [%d]: got 0x%x want 0x%x" % [name, i, int(r[i]) & U32, int(em[addrs[i]]) & U32])
		"ps":
			var m := {0x468: {0xfa0: int(fx["mode"])}}
			var got: int = 1 if Pm98Movement.play_state_eq(m, int(fx["n"])) else 0
			var want: int = int(exp.get("eax", -1)) & 0xff
			_ok(got == want, "%s: got %d want %d (EAX&0xff)" % [name, got, want])
		"clamp":
			var p := {0x18c: {0x1820: int(fx["goalx"])}, 0x3a4: int(fx["dir"])}
			var r: Array = Pm98Movement.clamp_x_goalside(p, fx["vec"], int(fx["f"]))
			var want: int = int(exp["mem"][0x230100]) & U32
			_ok((int(r[0]) & U32) == want, "%s x: got 0x%x want 0x%x" % [name, int(r[0]) & U32, want])
		"rb":
			var m := {}
			for k in BOX:
				m[k] = BOX[k]
			var p := {0x18c: m, 0x3a4: int(fx["dir"])}
			var got: int = 1 if Pm98Movement.restart_box_ok(p, fx["vec"]) else 0
			_ok(got == int(exp.get("eax", -1)), "%s: got %d want %d" % [name, got, int(exp.get("eax", -1))])
