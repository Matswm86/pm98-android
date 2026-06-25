extends SceneTree
## Oracle-backed parity test for FUN_005a7260 GRID BUILD (slice 2b-iii-b):
## Pm98Movement._marker_grid_build == the 16-entry vec3 work grid the REAL binary builds on the stack.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260gridbuild.gd
##
## ORACLE = the REAL FUN_005a7260 entered mid-function, the built stack grid read back at esp+0xb0
## (work[0..15] = 48 LE u32): tools/re/run_7260gridbuild_oracle.sh -> specs/7260gridbuild_oracle.txt
##   (GBUILD <name> built=1 | 0x3080ac=<w0.x> 0x3080b0=<w0.y> ... 0x308168=<w15.z>).
## We rebuild the identical p/m/ball Dicts (same trajectory slots 0x17..0x26, same N, same pass) and
## assert _marker_grid_build(p, pass) flattened == the oracle's 48 values bit-for-bit.

var _fail := 0
var _pass := 0

# name -> {pass, n}  (mirrors run_7260gridbuild_oracle.sh FIX rows).
var _fix := {
	"copy0": {"pass": 0, "n": 0},
	"p1n1":  {"pass": 1, "n": 1},
	"p1n13": {"pass": 1, "n": 0xd},
	"p1n33": {"pass": 1, "n": 0x21},
	"p1n61": {"pass": 1, "n": 0x3d},
}


func _init() -> void:
	var o := _load("7260gridbuild_oracle.txt", "GBUILD")
	if o.is_empty():
		_ok(false, "grid-build oracle empty (run tools/re/run_7260gridbuild_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from grid-build oracle")
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


# name -> the 48 banked grid values (signed), in read order work[0].x, .y, .z, work[1]...
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
		var vals := []
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				vals.append(_s32(tok.substr(eq + 1).to_int()))
		if vals.size() == 48:
			out[name] = vals
	return out


func _run(name: String, want: Array) -> void:
	var cfg: Dictionary = _fix[name]
	var m := {0x1820: 0x100000, 0x19a0: 1}
	var ball := {0x5c: int(cfg["n"])}
	for s in range(0x17, 0x27):                         # trajectory slots 0x17..0x26
		ball[0xc * s] = 0x100000 + 0x8000 * s
		ball[0xc * s + 4] = _s32(0x4000 * (s - 0x1e))   # sign-varying y
		ball[0xc * s + 8] = 0x800 * s
	var p := {0x2b8: 0, 0x18c: m, 0x190: ball}
	var grid: Array = Pm98Movement._marker_grid_build(p, int(cfg["pass"]))
	var got := []
	for v in grid:
		got.append(int(v[0]))
		got.append(int(v[1]))
		got.append(int(v[2]))
	_ok(got == want, "gridbuild/%s:\n    got =%s\n    want=%s" % [name, got, want])
