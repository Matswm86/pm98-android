extends SceneTree
## Oracle-backed parity test for the FUN_005a7260 dribble-block lane-CLEARANCE chain (slice 2b-i):
##   Pm98Movement._lane_perp_dist   == FUN_005b0e90  (perp dist to the dribble-lane segment)
##   Pm98Movement._lane_clearance   == FUN_005b1070 -> FUN_005b0fd0 (min over OTHER active players)
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b1070.gd
##
## ORACLE = the REAL functions driven through the Ghidra PCode emulator:
##   tools/re/run_b0e90_oracle.sh -> specs/b0e90_oracle.txt   (B0E90 <name> <steps> EAX=<dist>)
##   tools/re/run_b1070_oracle.sh -> specs/b1070_oracle.txt   (B1070 <name> <steps> EAX=<mindist>)
## We rebuild the identical Dict/Array fixtures and assert the GDScript return == EAX, bit-exact.
## 13107200 == 0xc80000 == the off-lane / none-active sentinel.

var _fail := 0
var _pass := 0

# b0e90: name -> [angle, halfmag, radius, [px,py,pz], [plx,ply,plz]]
var _b0e90 := {
	"boxmiss": [0,      0x80000, 0x20000, [0, 0, 0],             [0x40000, 0x70000, 0]],
	"online":  [0,      0x80000, 0x20000, [0, 0, 0],             [0x40000, 0, 0]],
	"perp":    [0,      0x80000, 0x20000, [0, 0, 0],             [0x40000, 0x20000, 0]],
	"behind":  [0,      0x80000, 0x20000, [0, 0, 0],             [-0x10000, 0, 0]],
	"beyond":  [0,      0x80000, 0x20000, [0, 0, 0],             [0x90000, 0, 0]],
	"diag":    [0x2000, 0x80000, 0x20000, [0x10000, 0x10000, 0], [0x50000, 0x48000, 0]],
}
# NOTE: fixtures must yield INTEGER perpendicular magnitudes -- the emulator rounds the FP->int
# conversion to nearest (no x87 control-word model) while the real game/GDScript truncate; they only
# diverge at a non-integer magnitude. See run_b0e90_oracle.sh (a pure-z 0x18000 offset -> 98304.93).

# b1070: name -> [target, radius, roster_spec] where roster_spec is a list of [x,y,z,active] OR
# the sentinel "SELF" meaning "insert p itself here". p.pos = (0,0,0).
var _b1070 := {
	"none":     [[0x80000, 0, 0], 0x20000, [[0x40000, 0x20000, 0, 0], [0x40000, 0, 0, 0]]],
	"one":      [[0x80000, 0, 0], 0x20000, [[0x40000, 0x20000, 0, 1], [0x40000, 0, 0, 0]]],
	"min2":     [[0x80000, 0, 0], 0x20000, [[0x40000, 0x20000, 0, 1], [0x40000, 0x10000, 0, 1]]],
	"offlane":  [[0x80000, 0, 0], 0x20000, [[0x40000, 0x70000, 0, 1]]],
	"skipself": [[0x80000, 0, 0], 0x20000, ["SELF", [0x40000, 0x20000, 0, 1]]],
}


func _init() -> void:
	var o90 := _load("b0e90_oracle.txt", "B0E90")
	var o70 := _load("b1070_oracle.txt", "B1070")
	if o90.is_empty():
		_ok(false, "b0e90 oracle empty (run tools/re/run_b0e90_oracle.sh)")
	else:
		for name in _b0e90:
			if o90.has(name):
				_run_b0e90(name, int(o90[name]))
			else:
				_ok(false, name + ": missing from b0e90 oracle")
	if o70.is_empty():
		_ok(false, "b1070 oracle empty (run tools/re/run_b1070_oracle.sh)")
	else:
		for name in _b1070:
			if o70.has(name):
				_run_b1070(name, int(o70[name]))
			else:
				_ok(false, name + ": missing from b1070 oracle")
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
		# parts: [tag, name, "RET"/"HALT", "steps=N", "EAX=val"]
		var name := parts[1]
		for tok in parts:
			if tok.begins_with("EAX="):
				out[name] = tok.substr(4).to_int()
	return out


func _run_b0e90(name: String, want: int) -> void:
	var s: Array = _b0e90[name]
	var ppos: Array = s[3]
	var lp: Array = s[4]
	var pl := {4: lp[0], 8: lp[1], 0xc: lp[2]}
	var got: int = Pm98Movement._lane_perp_dist(pl, ppos, int(s[0]), int(s[1]), int(s[2]))
	_ok(got == want, "b0e90/%s: got %d want %d" % [name, got, want])


func _run_b1070(name: String, want: int) -> void:
	var s: Array = _b1070[name]
	var target: Array = s[0]
	var radius: int = s[1]
	var p := {4: 0, 8: 0, 0xc: 0, 0x2bc: 1}
	var roster := []
	for rs in s[2]:
		if rs is String and rs == "SELF":
			roster.append(p)
		else:
			roster.append({4: rs[0], 8: rs[1], 0xc: rs[2], 0x2bc: rs[3]})
	var got: int = Pm98Movement._lane_clearance(p, roster, target, radius)
	_ok(got == want, "b1070/%s: got %d want %d" % [name, got, want])
