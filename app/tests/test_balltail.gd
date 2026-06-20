extends SceneTree
## Oracle-backed parity test for the FUN_0058e2c0 post-physics TAIL (0x58eb09 spin entry .. 0x58ec96),
## ported in Pm98Movement._ball_spin / _ball_tail / _ball_drift (called from _ball_freeflight).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_balltail.gd
##
## ORACLE = the REAL FUN_0058e2c0 under the Ghidra PCode emulator, run to a clean RET
## (tools/re/run_balltail_oracle.sh -> specs/balltail_oracle.txt). Every fixture forces the free-flight
## branch (timers 0) so the slice-B physics runs, then the tail:
##   spin_*: airborne (gravity vz-=178) so dot16(vel,vel) lands in each tier -> +0x2c step +4/+3/+2/+1;
##   togg0/1: slowest tier (s<=0x222) toggles +0x30 and only steps +0x2c every other parity;
##   snap: grounded roll-stop (|vx|,|vy|<0x22) -> vel=0 -> facing + at-rest snapshot pos -> +0x84;
##   drift/drift_back: grounded roll keeps vel!=0 -> snapshot drifts to pos + heading*max(proj,0).
## The render trail FUN_0058fda0 (+0x74/+0xa8) is deferred -- not read here. Validated fields: pos
## +0x4/+0x8/+0xc, vel +0x20/+0x24/+0x28, spin +0x2c/+0x30, facing +0x34, snapshot +0x84/+0x88/+0x8c.

const B0 := 0x230000
const U32 := 0xffffffff

const FIX := {
	"spin4": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x20000, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 0},
	"spin3": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x7000, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 0},
	"spin2": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x4000, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 0},
	"spin1": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x2000, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 0},
	"togg0": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x100, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 0},
	"togg1": {0x4: 0x10000, 0x8: 0x10000, 0xc: 0x40000, 0x20: 0x100, 0x24: 0, 0x28: 0, 0x2c: 5, 0x30: 1},
	"snap": {0x4: 0x3000, 0x8: 0x5000, 0xc: 0, 0x20: 0x10, 0x24: 0x10, 0x28: 0, 0x2c: 7, 0x30: 1},
	"drift": {0x4: 0x2000, 0x8: 0x2000, 0xc: 0, 0x20: 0x800, 0x24: 0x400, 0x28: 0,
		0x2c: 3, 0x30: 0, 0x84: 0x9000, 0x88: 0x1000, 0x8c: 0},
	"drift_back": {0x4: 0x9000, 0x8: 0x9000, 0xc: 0, 0x20: 0x800, 0x24: 0x400, 0x28: 0,
		0x2c: 3, 0x30: 0, 0x84: 0x1000, 0x88: 0x1000, 0x8c: 0},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "balltail oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("balltail_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int() - B0] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Dictionary = FIX[name]
	var ball := {}
	for off in src:
		ball[int(off)] = int(src[off])

	Pm98Movement.ball_advance(ball)

	for off in exp:
		var got := int(ball.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got 0x%x want 0x%x" % [name, off, got, want])
