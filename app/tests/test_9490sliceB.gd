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
	_run_bii()
	_run_biiarm()
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


# ---- B-ii marker scan + apply ------------------------------------------------
# name -> fixture cfg mirroring run_9490sliceBii_oracle.sh. row < 0 -> no marker override (none).
var _bii := {
	"m0":    {"px": 0, "py": 0, "pz": 0, "anchor": 0x100000, "team": 0, "orient": 0, "goalx": 0x100000,
			  "bx": 0x10000, "by": 0, "bz": 0, "ball4c_p": true,  "row": 9, "vx": 0x17fff, "vy": 0, "vz": 0x1e147},
	"m2":    {"px": 0, "py": 0, "pz": 0, "anchor": 0x100000, "team": 0, "orient": 1, "goalx": 0x100000,
			  "bx": 0x8000, "by": 0x60000, "bz": 0, "ball4c_p": false, "row": 4, "vx": 0x9998, "vy": 0, "vz": 0xb333},
	"m2neg": {"px": 0, "py": 0, "pz": 0, "anchor": 0x100000, "team": 1, "orient": 1, "goalx": 0x100000,
			  "bx": 0x8000, "by": 0x60000, "bz": 0, "ball4c_p": false, "row": 4, "vx": 0x9998, "vy": 0, "vz": 0xb333},
	"m3":    {"px": 0x200000, "py": 0, "pz": 0, "anchor": -1, "team": 0, "orient": 0, "goalx": 0x280000,
			  "bx": 0x210000, "by": 0, "bz": 0, "ball4c_p": false, "row": 6, "vx": 0x2b332, "vy": 0, "vz": 0xcccc,
			  "aabb": [0, 0x300000, -0x80000, 0x80000, -0x80000, 0x80000]},
	"none":  {"px": 0, "py": 0, "pz": 0, "anchor": 0, "team": 0, "orient": 1, "goalx": 0x100000,
			  "bx": 0x10000, "by": 0, "bz": 0, "ball4c_p": false, "row": -1},
}


func _build_bii(cfg: Dictionary) -> Dictionary:
	var m := {0x1820: int(cfg["goalx"]), 0x19a0: int(cfg["orient"])}
	if cfg.has("aabb"):
		var a: Array = cfg["aabb"]
		m[0x1828] = int(a[0]); m[0x1834] = int(a[1])
		m[0x182c] = int(a[2]); m[0x1838] = int(a[3])
		m[0x1830] = int(a[4]); m[0x183c] = int(a[5])
	var px := int(cfg["px"]); var py := int(cfg["py"]); var pz := int(cfg["pz"])
	var ball := {0x40: 0, 0x44: 0, 0x50: 0, 0x70: 0, 0x80: 0x1234, 4: int(cfg["bx"]), 8: int(cfg["by"]), 0xc: int(cfg["bz"])}
	for s in range(0x17, 0x27):                                # 16 trajectory slots FAR (p + 0x400000)
		ball[0xc * s] = _s32(px + 0x400000)
		ball[0xc * s + 4] = _s32(py + 0x400000)
		ball[0xc * s + 8] = _s32(pz + 0x400000)
	if int(cfg["row"]) >= 0:                                    # steer one row into its box
		var sgo := 0x17 + int(cfg["row"])
		ball[0xc * sgo] = _s32(px + int(cfg["vx"]))
		ball[0xc * sgo + 4] = _s32(py + int(cfg["vy"]))
		ball[0xc * sgo + 8] = _s32(pz + int(cfg["vz"]))
	var p := {
		0x34: 0, 4: px, 8: py, 0xc: pz, 0x40: 0, 0x54: 1, 0x2bc: 1,
		0x2b8: int(cfg["team"]), 0x3a4: int(cfg["anchor"]), 0x18c: m, 0x190: ball,
	}
	ball[0x4c] = p if bool(cfg["ball4c_p"]) else 0
	return {"p": p, "ball": ball}


func _run_bii() -> void:
	var o := {}
	var f := FileAccess.open(_spec_path("9490sliceBii_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "B-ii oracle missing (run tools/re/run_9490sliceBii_oracle.sh)")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("B9490ii "):
			continue
		var parts := line.split(" ", false)
		var kv := {}
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				kv[tok.substr(0, eq)] = _s32(tok.substr(eq + 1).to_int())
		o[parts[1]] = kv
	if o.is_empty():
		_ok(false, "B-ii oracle empty")
		return
	for name in _bii:
		if not o.has(name):
			_ok(false, "B-ii/%s missing from oracle" % name)
			continue
		_run_bii_one(name, o[name])


func _run_bii_one(name: String, want: Dictionary) -> void:
	var fx := _build_bii(_bii[name])
	var p: Dictionary = fx["p"]
	var ball: Dictionary = fx["ball"]
	var sc: Array = Pm98Movement._lean9490_aim_scalars(p)
	var e8 := int(sc[0])                                        # already _s16'd signed
	var ec := int(sc[1])
	var grid: Array = Pm98Movement._grid9490_build(p)
	Pm98Movement._lean9490_marker_scan_apply(p, grid, e8, ec, null)
	# Compare the apply field writes against the oracle (read at the real RET).
	_eq(name, "action", int(want["0x230040"]), int(p.get(0x40, 0)))
	_eq(name, "p80",    int(want["0x230080"]), int(p.get(0x80, 0)))
	_eq(name, "p84",    int(want["0x230084"]), int(p.get(0x84, 0)))
	_eq(name, "p94",    int(want["0x230094"]), int(p.get(0x94, 0)))
	_eq(name, "p98",    int(want["0x230098"]), int(p.get(0x98, 0)))
	_eq(name, "p9c",    int(want["0x23009c"]), int(p.get(0x9c, 0)))
	_eq(name, "p66",    int(want["0x230066"]) & 0xffff, int(p.get(0x66, 0)) & 0xffff)
	_eq(name, "p7c",    int(want["0x23007c"]), int(p.get(0x7c, 0)))
	_eq(name, "ball4c", int(want["0x28004c"]), int(ball.get(0x4c, 0)) if not (ball.get(0x4c) is Dictionary) else -999)
	_eq(name, "ball5c", int(want["0x28005c"]), int(ball.get(0x5c, 0)))


func _eq(name: String, field: String, want: int, got: int) -> void:
	_ok(got == want, "B-ii/%s %s: got=%d (0x%x) want=%d (0x%x)" % [name, field, got, got & 0xffffffff, want, want & 0xffffffff])


# ---- B-ii-b: marker-4 action==5 arm-2 tail -----------------------------------
# Marker 4 (row 3, action 5, angle 0) wins; the apply temp-moves p, runs the REAL arm-2 active tail
# (2 RNG draws), restores, then writes the 9490 locomotion. Mirrors run_9490sliceBiiarm_oracle.sh.
const ARM_SEED := 0x4d2


func _run_biiarm() -> void:
	var o := {}
	var f := FileAccess.open(_spec_path("9490sliceBiiarm_oracle.txt"), FileAccess.READ)
	if f == null:
		_ok(false, "B-ii-b oracle missing (run tools/re/run_9490sliceBiiarm_oracle.sh)")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("B9490iiarm "):
			continue
		var parts := line.split(" ", false)
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				o[tok.substr(0, eq)] = _s32(tok.substr(eq + 1).to_int())
	if o.is_empty():
		_ok(false, "B-ii-b oracle empty")
		return

	# Build the marker-4 fixture (mirrors the oracle pokes).
	var m := {0x1820: 0x100000, 0x19a0: 0, 0x448: 0}
	var ctx := {0x2b8: 0, 0x2c4: 0}
	var teamstruct := {0: ctx}
	var ball := {0x40: 0, 0x44: 0, 0x50: 0, 0x70: 0, 0x80: 0x1234, 0x4c: 0,
		4: 0x10000, 8: 0, 0xc: 0, 0x20: 0x400000, 0x24: 0x400000, 0x28: 0}
	for s in range(0x17, 0x27):
		ball[0xc * s] = 0x400000; ball[0xc * s + 4] = 0x400000; ball[0xc * s + 8] = 0x400000
	var sgo := 0x17 + 3                                          # row 3 -> center4 (0x9998,0,0)
	ball[0xc * sgo] = 0x9998; ball[0xc * sgo + 4] = 0; ball[0xc * sgo + 8] = 0
	var p := {
		0x34: 0, 4: 0, 8: 0, 0xc: 0, 0x40: 0, 0x54: 1, 0x2bc: 1, 0x2b8: 0, 0x3a0: 50, 0x3a4: 0x100000,
		0x20: 0x4000, 0x24: _s32(-0x2000), 0x28: 0x800, 0x18c: m, 0x190: ball, 0x188: teamstruct,
	}
	var rng = MatchEngine.Pm98Rng.new(ARM_SEED)
	var sc: Array = Pm98Movement._lean9490_aim_scalars(p)
	var grid: Array = Pm98Movement._grid9490_build(p)
	var applied := Pm98Movement._lean9490_marker_scan_apply(p, grid, int(sc[0]), int(sc[1]), rng)
	_ok(applied, "B-ii-b/m4: marker should apply")
	_eq("m4", "action", int(o["0x230040"]), int(p.get(0x40, 0)))
	_eq("m4", "reachx", int(o["0x2300a0"]), int(p.get(0xa0, 0)))
	_eq("m4", "reachy", int(o["0x2300a4"]), int(p.get(0xa4, 0)))
	_eq("m4", "reachz", int(o["0x2300a8"]), int(p.get(0xa8, 0)))
	_eq("m4", "p48",    int(o["0x230048"]), int(p.get(0x48, 0)))
	_eq("m4", "p5e",    int(o["0x23005e"]) & 0xff, int(p.get(0x5e, 0)) & 0xff)
	_eq("m4", "p80",    int(o["0x230080"]), int(p.get(0x80, 0)))
	_eq("m4", "p84",    int(o["0x230084"]), int(p.get(0x84, 0)))
	_eq("m4", "p94",    int(o["0x230094"]), int(p.get(0x94, 0)))
	_eq("m4", "p98",    int(o["0x230098"]), int(p.get(0x98, 0)))
	_eq("m4", "p9c",    int(o["0x23009c"]), int(p.get(0x9c, 0)))
	_eq("m4", "p66",    int(o["0x230066"]) & 0xffff, int(p.get(0x66, 0)) & 0xffff)
	_eq("m4", "p7c",    int(o["0x23007c"]), int(p.get(0x7c, 0)))
	_eq("m4", "ball4c", int(o["0x28004c"]), int(ball.get(0x4c, 0)))
	_eq("m4", "ball5c", int(o["0x28005c"]), int(ball.get(0x5c, 0)))
	_eq("m4", "rng",    int(o["0x6d3184"]) & 0xffffffff, int(rng.state) & 0xffffffff)

