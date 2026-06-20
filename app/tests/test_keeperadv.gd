extends SceneTree
## Oracle-backed parity test for FUN_005a22d0 (GOALKEEPER ball-tracking advance), ported in
## Pm98Movement.keeper_advance.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_keeperadv.gd
##
## ORACLE = the REAL FUN_005a22d0 under the Ghidra PCode emulator (LUTs injected, FUN_005a50c0 sprite
## stubbed to ret) run to a clean RET (tools/re/run_keeperadv_oracle.sh -> specs/keeperadv_oracle.txt).
## Fixtures cover team-1/team-2 goals, the far-branch chase (+/- past the 0x40000 deadband, boundary
## gates), the close-branch inverted shade, the 0xa3 friction, the 0x1555 clamp, and all three facing
## cases (vel>0 -> 0, vel<0 -> 0x8000, vel==0 -> atan to the ball). Validated keeper fields: +0x3c0
## velocity, +0x4 x, +0x34 facing word, +0x40 position code.

const K0 := 0x230000
const U32 := 0xffffffff

# name -> {team, kx, ky, vel, bx, by, line}
const FIX := {
	"far_right_t1": {"team": 1, "kx": 0x40000, "ky": 0, "vel": 0, "bx": 0x180000, "by": 0, "line": 0x100000},
	"far_left_t1": {"team": 1, "kx": 0xc0000, "ky": 0, "vel": 0, "bx": 0x40000, "by": 0, "line": 0x100000},
	"far_deadband": {"team": 1, "kx": 0x100000, "ky": 0, "vel": 0, "bx": 0x110000, "by": 0x80000, "line": 0x180000},
	"close_invR": {"team": 1, "kx": 0x110000, "ky": 0, "vel": 0, "bx": 0x100000, "by": 0, "line": 0x180000},
	"close_invL": {"team": 1, "kx": 0x110000, "ky": 0, "vel": 0, "bx": 0x120000, "by": 0, "line": 0x180000},
	"team2_far": {"team": 2, "kx": -0x40000, "ky": 0, "vel": 0, "bx": -0x180000, "by": 0, "line": 0x100000},
	"clamp_max": {"team": 1, "kx": 0x40000, "ky": 0, "vel": 0x1500, "bx": 0x180000, "by": 0, "line": 0x180000},
	"at_right_blk": {"team": 1, "kx": 0x100000, "ky": 0, "vel": 0, "bx": 0x180000, "by": 0, "line": 0x100000},
}

# oracle field addr -> keeper offset
const READ_OFF := {0x2303c0: 0x3c0, 0x230004: 0x4, 0x230034: 0x34, 0x230040: 0x40}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "keeperadv oracle file empty/unreadable")
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


# Parse "FIX <name> ... mem[0xADDR:W]=val ...": row -> {keeper_offset: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("keeperadv_oracle.txt"), FileAccess.READ)
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
			var addr := ("0x" + mtch.get_string(1)).hex_to_int()
			if READ_OFF.has(addr):
				row[int(READ_OFF[addr])] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Dictionary = FIX[name]
	var m := {0x1614: int(src["bx"]), 0x1618: int(src["by"]), 0x1820: int(src["line"])}
	var k := {0x18c: m, 0x3bc: int(src["team"]), 0x4: int(src["kx"]), 0x8: int(src["ky"]), 0x3c0: int(src["vel"])}

	Pm98Movement.keeper_advance(k)

	for off in exp:
		var got := int(k.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got 0x%x want 0x%x" % [name, off, got, want])
