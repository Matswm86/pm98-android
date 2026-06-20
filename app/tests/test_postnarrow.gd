extends SceneTree
## Oracle-backed parity test for FUN_005efac0 (post swept narrow-phase + reflect), ported in
## Pm98Movement._post_narrow. Run: ~/godot462 --headless --path app --script res://tests/test_postnarrow.gd
##
## ORACLE = tools/re/run_postnarrow_oracle.sh -> specs/postnarrow_oracle.txt (the REAL function under the
## PCode emu, axis-aligned quad / boxgeo +X, MulDiv import stubbed to ret 0). Validates the hit flag and,
## on hit, the clipped pos + reflected vel + 2-int deflect. The rotation path is pinned by test_rotvec;
## the tilted-quad MulDiv interpolation by _muldiv vs the Win32 spec.

const U32 := 0xffffffff

# The same synthetic post the oracle pokes: a rectangle in the world YZ plane at x=0, boxgeo +X.
const POST := {
	0x0: 0, 0x4: -0x40000, 0x8: 0,
	0xc: 0, 0x10: 0x40000, 0x14: 0,
	0x18: 0, 0x1c: 0x40000, 0x20: 0x40000,
	0x24: 0, 0x28: -0x40000, 0x2c: 0x40000,
	0x48: 0x10000, 0x4c: 0, 0x50: 0,
}

# name -> [px, py, pz, vx, vy, vz, id]
const FIX := {
	"hit_mid": [-0x20000, -0x20000, 0x20000, 0x40000, 0, 0, 0x9eb8],
	"miss_hi": [-0x20000, -0x20000, 0x60000, 0x40000, 0, 0, 0x9eb8],
	"miss_lowy": [-0x20000, -0x50000, 0x20000, 0x40000, 0, 0, 0x9eb8],
	"hit_cross": [-0x20000, 0x10000, 0x30000, 0x40000, 0, 0, 0x7ae1],
	"miss_away": [-0x20000, -0x20000, 0x20000, -0x40000, 0, 0, 0x9eb8],
}

# oracle addr -> ("pos"/"vel"/"out", index)
const RD := {
	0x240000: ["pos", 0], 0x240004: ["pos", 1], 0x240008: ["pos", 2],
	0x240010: ["vel", 0], 0x240014: ["vel", 1], 0x240018: ["vel", 2],
	0x240020: ["out", 0], 0x240024: ["out", 1],
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "postnarrow oracle file empty/unreadable")
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


# row -> {"hit": eax, "pos":[...], "vel":[...], "out":[...]}
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("postnarrow_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rxm := RegEx.new()
	rxm.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	var rxe := RegEx.new()
	rxe.compile("EAX=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {"pos": [0, 0, 0], "vel": [0, 0, 0], "out": [0, 0], "hit": 0}
		var me := rxe.search(line)
		if me:
			row["hit"] = me.get_string(1).to_int() & 0xff
		for mtch in rxm.search_all(line):
			var addr := ("0x" + mtch.get_string(1)).hex_to_int()
			if RD.has(addr):
				var t: Array = RD[addr]
				row[t[0]][int(t[1])] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Array = FIX[name]
	var post: Dictionary = POST.duplicate()
	post[0x54] = int(src[6])
	var ball := {0x4: int(src[0]), 0x8: int(src[1]), 0xc: int(src[2]),
		0x20: int(src[3]), 0x24: int(src[4]), 0x28: int(src[5])}
	var out: Array = []
	var hit := Pm98Movement._post_narrow(ball, post, out)
	_ok((1 if hit else 0) == int(exp["hit"]), "%s hit: got %d want %d" % [name, 1 if hit else 0, int(exp["hit"])])
	if not hit:
		return
	var ep: Array = exp["pos"]
	var ev: Array = exp["vel"]
	var eo: Array = exp["out"]
	_ok((int(ball[0x4]) & U32) == (int(ep[0]) & U32), "%s pos.x: got 0x%x want 0x%x" % [name, int(ball[0x4]) & U32, int(ep[0]) & U32])
	_ok((int(ball[0x8]) & U32) == (int(ep[1]) & U32), "%s pos.y: got 0x%x want 0x%x" % [name, int(ball[0x8]) & U32, int(ep[1]) & U32])
	_ok((int(ball[0xc]) & U32) == (int(ep[2]) & U32), "%s pos.z: got 0x%x want 0x%x" % [name, int(ball[0xc]) & U32, int(ep[2]) & U32])
	_ok((int(ball[0x20]) & U32) == (int(ev[0]) & U32), "%s vel.x: got 0x%x want 0x%x" % [name, int(ball[0x20]) & U32, int(ev[0]) & U32])
	_ok((int(ball[0x24]) & U32) == (int(ev[1]) & U32), "%s vel.y: got 0x%x want 0x%x" % [name, int(ball[0x24]) & U32, int(ev[1]) & U32])
	_ok((int(ball[0x28]) & U32) == (int(ev[2]) & U32), "%s vel.z: got 0x%x want 0x%x" % [name, int(ball[0x28]) & U32, int(ev[2]) & U32])
	if out.size() == 2:
		_ok((int(out[0]) & U32) == (int(eo[0]) & U32), "%s out0: got 0x%x want 0x%x" % [name, int(out[0]) & U32, int(eo[0]) & U32])
		_ok((int(out[1]) & U32) == (int(eo[1]) & U32), "%s out1: got 0x%x want 0x%x" % [name, int(out[1]) & U32, int(eo[1]) & U32])
