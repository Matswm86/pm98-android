extends SceneTree
## Oracle-backed parity test for FUN_005a9490 ("the lean") SLICE B-i -- the off-ball deterministic prefix:
##   * _carrier_busy_b0a60  == the REAL FUN_005b0a60 switch predicate (b0a60_oracle.txt, B0A60 rows).
##   * _lean9490_goal_aim   == local_ec low16 (the goal-aim angle) and local_e8 low16 == 0.
##   * _grid9490_build      == the 16-entry rotated trajectory grid local_c0 (9490sliceBi_oracle.txt).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_9490sliceB.gd
##
## ORACLES:
##   tools/re/run_b0a60_oracle.sh       -> specs/b0a60_oracle.txt
##   tools/re/run_9490sliceBi_oracle.sh -> specs/9490sliceBi_oracle.txt

var _fail := 0
var _pass := 0

# b0a60: name -> [action, timer]  (mirrors run_b0a60_oracle.sh FIX rows).
var _b0a60 := {
	"d_busy": [0xd, 1], "d_idle": [0xd, 0],
	"x13_busy": [0x13, 4], "x13_idle": [0x13, 5],
	"x1f": [0x1f, 0], "x21": [0x21, 0], "x2f": [0x2f, 0],
	"x28_busy": [0x28, 4], "x28_idle": [0x28, 3],
	"x29_busy": [0x29, 9], "x2c_idle": [0x2c, 3], "x2d_busy": [0x2d, 4],
	"x2e_busy": [0x2e, 2], "x2e_idle": [0x2e, 1],
	"x30_busy": [0x30, 7], "x30_idle": [0x30, 6], "x33_busy": [0x33, 7], "x34_idle": [0x34, 6],
	"x36_busy": [0x36, 0x13], "x36_idle": [0x36, 0x14],
	"x37_busy": [0x37, 5], "x37_idle": [0x37, 6],
	"default": [0x99, 0],
}

# B-i grid/scalars: name -> [facing, px, py, pz, team, orient, goalx, bx, sx, by, bz]  (mirrors the FIX rows).
var _bi := {
	"f0": [0,      0,        0,       0,       0, 1, 0x100000, 0x40000, 0x9000, 0x3000, 0x700],
	"fq": [0x4000, 0x12000, -0x8000,  0x400,   1, 0, 0x100000, 0x60000, 0x7000, 0x4000, 0x500],
	"fe": [0x2000, -0x4000,  0x9000,  0x800,   0, 0, 0x100000, 0x50000, 0x8800, 0x3500, 0x600],
	"fn": [0x6000, 0x8000,   0x40000, -0x1000, 1, 1, 0x140000, 0x30000, 0xa000, 0x2800, 0x900],
}


func _init() -> void:
	_run_b0a60()
	_run_bi()
	_run_gate()
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


# ---- b0a60 predicate ---------------------------------------------------------
func _run_b0a60() -> void:
	var o := {}
	var f := FileAccess.open(_spec_path("b0a60_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "b0a60 oracle missing (run tools/re/run_b0a60_oracle.sh)")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("B0A60 "):
			continue
		var parts := line.split(" ", false)
		o[parts[1]] = parts[parts.size() - 1].split("=")[1].to_int()   # AL=0|1
	if o.is_empty():
		_ok(false, "b0a60 oracle empty")
		return
	for name in _b0a60:
		if not o.has(name):
			_ok(false, "b0a60/%s missing from oracle" % name)
			continue
		var cfg: Array = _b0a60[name]
		var carrier := {0x40: int(cfg[0]), 0x2c: int(cfg[1])}
		var got := 1 if Pm98Movement._carrier_busy_b0a60(carrier) else 0
		_ok(got == int(o[name]), "b0a60/%s: got=%d want=%d" % [name, got, int(o[name])])


# ---- B-i grid + scalars ------------------------------------------------------
func _run_bi() -> void:
	# name -> [built, ec, e8, g0.x, g0.y, g0.z, ... g15.z]  (50 values after built)
	var o := {}
	var f := FileAccess.open(_spec_path("9490sliceBi_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "B-i oracle missing (run tools/re/run_9490sliceBi_oracle.sh)")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("B9490i "):
			continue
		var parts := line.split(" ", false)
		var name := parts[1]
		var built := int(parts[2])
		var vals := [built]
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				vals.append(_s32(tok.substr(eq + 1).to_int()))
		o[name] = vals
	if o.is_empty():
		_ok(false, "B-i oracle empty")
		return
	for name in _bi:
		if not o.has(name):
			_ok(false, "B-i/%s missing from oracle" % name)
			continue
		_run_bi_one(name, o[name])


func _run_bi_one(name: String, row: Array) -> void:
	var built := int(row[0])
	if built != 1 or row.size() != 1 + 2 + 48:
		_ok(false, "B-i/%s: oracle BUILT=%d size=%d (expect 1 + 50 vals)" % [name, built, row.size()])
		return
	var ec := int(row[1]) & 0xffff
	var e8 := int(row[2]) & 0xffff
	var grid_want := row.slice(3)                               # 48 ints

	var cfg: Array = _bi[name]
	var facing := int(cfg[0])
	var m := {0x1820: int(cfg[6]), 0x19a0: int(cfg[5])}
	var ball := {}
	for s in range(0x17, 0x27):
		ball[0xc * s] = _s32(int(cfg[7]) + int(cfg[8]) * s)     # bx + sx*s
		ball[0xc * s + 4] = _s32(int(cfg[9]) * (s - 31))        # by*(s-0x1f)
		ball[0xc * s + 8] = _s32(int(cfg[10]) * s)              # bz*s
	var p := {
		0x34: facing, 4: int(cfg[1]), 8: int(cfg[2]), 0xc: int(cfg[3]),
		0x2b8: int(cfg[4]), 0x18c: m, 0x190: ball,
	}

	var sc: Array = Pm98Movement._lean9490_aim_scalars(p)
	_ok((int(sc[0]) & 0xffff) == e8, "B-i/%s: local_e8 got=0x%x want=0x%x" % [name, int(sc[0]) & 0xffff, e8])
	_ok(int(sc[1]) == ec, "B-i/%s: local_ec got=0x%x want=0x%x" % [name, int(sc[1]), ec])

	var grid: Array = Pm98Movement._grid9490_build(p)
	var got := []
	for v in grid:
		got.append(int(v[0])); got.append(int(v[1])); got.append(int(v[2]))
	_ok(got == grid_want, "B-i/%s grid:\n    got =%s\n    want=%s" % [name, got, grid_want])


# ---- B-i gate prefix (reaches-scan predicate) --------------------------------
func _gate_p(name: String) -> Dictionary:
	# Builds the p/ball(/carrier) Dicts mirroring run_9490sliceBgate_oracle.sh FIX rows.
	match name:
		"reach":       return {0x40: 0, 4: 0, 8: 0, 0xc: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: 0, 4: 0, 8: 0, 0xc: 0, 0x70: 0}}
		"prox":        return {0x40: 0, 4: 0x200000, 0x54: 1, 0x2bc: 1, 0x190: {0x40: 0, 4: 0}}
		"act5":        return {0x40: 5, 4: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: 0, 4: 0, 0x70: 0}}
		"actB":        return {0x40: 0xb, 4: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: 0, 4: 0, 0x70: 0}}
		"carrierbusy": return {0x40: 0, 4: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: {0x40: 0x1f, 0x2bc: 0}, 4: 0, 0x70: 0}}
		"carrierfree": return {0x40: 0, 4: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: {0x40: 0, 0x2bc: 0}, 4: 0, 0x70: 0}}
		"scan54":      return {0x40: 0, 4: 0, 0x54: 0, 0x2bc: 1, 0x190: {0x40: 0, 4: 0, 0x70: 0}}
		"scan2bc":     return {0x40: 0, 4: 0, 0x54: 1, 0x2bc: 0, 0x190: {0x40: 0, 4: 0, 0x70: 0}}
		"ball70":      return {0x40: 0, 4: 0, 0x54: 1, 0x2bc: 1, 0x190: {0x40: 0, 4: 0, 0x70: 1}}
	return {}


func _run_gate() -> void:
	var o := {}
	var f := FileAccess.open(_spec_path("9490sliceBgate_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "gate oracle missing (run tools/re/run_9490sliceBgate_oracle.sh)")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("BGATE "):
			continue
		var parts := line.split(" ", false)
		var scan := 0
		for tok in parts:
			if tok.begins_with("scan="):
				scan = tok.split("=")[1].to_int()
		o[parts[1]] = scan
	if o.is_empty():
		_ok(false, "gate oracle empty")
		return
	for name in o:
		var p := _gate_p(name)
		if p.is_empty():
			_ok(false, "gate/%s: no fixture builder" % name)
			continue
		var got := 1 if Pm98Movement._lean9490_offball_reaches_scan(p) else 0
		_ok(got == int(o[name]), "gate/%s: reaches_scan got=%d want=%d" % [name, got, int(o[name])])

