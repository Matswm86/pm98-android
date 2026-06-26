extends SceneTree
## Composition parity test for the WIRED dribble-grid block (slice 2b: ball_touch_7260 L242-513). The
## per-slice tests drive each marker function in ISOLATION with a manually chosen pass; this test runs the
## EXACT loop the wiring uses -- n_passes = 1 + (ball+0x5c != 0), `for pass_idx: if best.idx != -1: break;
## _marker_grid_build -> _marker_scan` then `_marker_apply` (+ `_marker_tail`) -- and compares to the SAME
## binary oracle rows the per-slice tests use. This exercises the new control flow (the 2-pass progression
## AND the L280 break: markerapply/p1hit2 has ball+0x5c == 0x15, so the loop is genuinely two-pass).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260dribble.gd
##
## ORACLEs = the REAL FUN_005a7260 entered mid-function at the loop start 0x5a7e23, run for real:
##   apply rows  -> tools/re/run_7260markerapply_oracle.sh -> specs/7260markerapply_oracle.txt (APPLY ...)
##   tail rows   -> tools/re/run_7260markertail_oracle.sh  -> specs/7260markertail_oracle.txt  (TAIL  ...)

var _fail := 0
var _pass := 0

# --- marker-APPLY fixtures (mirror run_7260markerapply_oracle.sh FIX rows; pass is now LOOP-derived) ---
var _apply_fix := {
	"hit0":   {"n": 0,    "traj": {0x1a: [0x1b333, 0, 0x4000]}},
	"hit1":   {"n": 0,    "traj": {0x1a: [0x9999, 0, 0x10000]}},
	"nohit":  {"n": 0,    "traj": {}},
	"p1hit2": {"n": 0x15, "traj": {0x1c: [0x9999, 0, 0x1cccc]}},
	# Two-pass DISCRIMINATORS (slice 2b residual): N=8 => idxbase=trunc(7/4)=1 => pass-1 goal-extrapolation
	# rewrites the SCANNED work[5] (slot 0x1c) -- unlike every N=0/0x15 fixture (idxbase 0/5 leave work[5]
	# untouched, so break-vs-no-break and 1-vs-2 passes were indistinguishable). slot 0x18 = the anchor work[1].
	#   twopass => slot 0x1a/0x1c parked at z=0x40000 so pass 0 MISSES all 9 markers; pass-1 extrapolated
	#              work[5] HITS marker 6. Locks: n_passes=2, the break does NOT fire after a miss, pass_idx=1
	#              extrapolation feeds the scan. (binary ran 5645 steps = both passes.)
	#   brkkeep  => pass 0 HITS marker 6; the break FIRES so pass 1 is skipped and marker 6 applied. The
	#              port _nobreak path would extrapolate to marker 3 -> the break is load-bearing. (binary 2854
	#              steps = one pass + apply.) _init asserts the no-break counterfactual diverges.
	"twopass": {"n": 8, "traj": {0x18: [-0x30000, -0x20000, 0x3333], 0x1a: [0x40000, 0, 0x40000], 0x1c: [0x40000, 0, 0x40000]}},
	"brkkeep": {"n": 8, "traj": {0x18: [-0x30000, 0x18000, 0x3333], 0x1a: [0x40000, 0, 0x40000], 0x1c: [0x12000, -0x8000, 0x3333]}},
	"comp":   {"n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0x8000, 0x4000], 0x1c: [0x9999, 0x400, 0x1cccc]}},
	"bbox":   {"n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0, 0x4000], 0x1c: [0x9999, 0x2000, 0x1cccc]},
		"box": {0x1828: 0x9000, 0x182c: -0x10000, 0x1830: 0x1c000, 0x1834: 0xa000, 0x1838: 0x10000, 0x183c: 0x1d000}},
}
var _apply_addr := {
	"0x2a0461": ["m", 0x461], "0x230044": ["p", 0x44], "0x230040": ["p", 0x40],
	"0x230084": ["p", 0x84], "0x230080": ["p", 0x80], "0x230094": ["p", 0x94],
	"0x230098": ["p", 0x98], "0x23009c": ["p", 0x9c], "0x230066": ["p", 0x66],
	"0x280068": ["ball", 0x68], "0x28006c": ["ball", 0x6c], "0x280063": ["ball", 0x63],
	"0x280070": ["ball", 0x70], "0x28009c": ["ball", 0x9c], "0x2800a0": ["ball", 0xa0],
	"0x2800a4": ["ball", 0xa4], "0x280020": ["ball", 0x20], "0x280024": ["ball", 0x24],
	"0x280028": ["ball", 0x28], "0x2a0458": ["m", 0x458], "0x2c0094": ["stat", 0x94],
}

# --- marker-TAIL fixtures (mirror run_7260markertail_oracle.sh FIX rows; all NOHIT, ball+0x5c == 0) ---
var _tail_fix := {
	"g1pass":      {"facing": 0x1000, "vel": [0x4000, -0x2000, 0x800]},
	"g2pass":      {"facing": 0, "vel": [0x2000, -0x2000, 0x40000], "ball140": 0x40000},
	"g2fail":      {"facing": 0, "vel": [0x4000, -0x2000, 0], "ball140": 0x40000},
	"foreign":     {"facing": 0x1000, "vel": [0x4000, -0x2000, 0x800], "carrier_team": 1},
	"samecarrier": {"facing": 0x1000, "vel": [0x4000, 0, 0], "carrier_team": 0},
}
var _tail_addr := {
	"0x230048": ["p", 0x48], "0x230040": ["p", 0x40], "0x230080": ["p", 0x80],
	"0x230084": ["p", 0x84], "0x2300a0": ["p", 0xa0], "0x2300a4": ["p", 0xa4],
	"0x2300a8": ["p", 0xa8], "0x230094": ["p", 0x94], "0x230098": ["p", 0x98],
	"0x23009c": ["p", 0x9c], "0x230066": ["p", 0x66], "0x23005e": ["p", 0x5e],
}


func _init() -> void:
	var oa := _load("7260markerapply_oracle.txt", "APPLY")
	var ot := _load("7260markertail_oracle.txt", "TAIL")
	if oa.is_empty():
		_ok(false, "marker-apply oracle empty (run tools/re/run_7260markerapply_oracle.sh)")
	if ot.is_empty():
		_ok(false, "marker-tail oracle empty (run tools/re/run_7260markertail_oracle.sh)")
	for name in _apply_fix:
		if oa.has(name):
			_run_apply(name, oa[name])
		else:
			_ok(false, name + ": missing from marker-apply oracle")
	for name in _tail_fix:
		if ot.has(name):
			_run_tail(name, ot[name])
		else:
			_ok(false, name + ": missing from marker-tail oracle")
	_assert_discriminators()
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
		var row := {}
		for tok in parts:
			var eq := tok.find("=")
			if eq > 0 and tok.begins_with("0x"):
				row[tok.substr(0, eq)] = _s32(tok.substr(eq + 1).to_int())
		out[name] = row
	return out


# The EXACT wired loop (ball_touch_7260 L267-414): 1 or 2 passes, break once a marker is kept.
func _scan_loop(p: Dictionary, ball: Dictionary) -> Array:
	var best := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]
	var n_passes := 1 + (1 if int(ball.get(0x5c, 0)) != 0 else 0)
	for pass_idx in range(n_passes):
		if best[0] != -1:
			break
		var work: Array = Pm98Movement._marker_grid_build(p, pass_idx)
		Pm98Movement._marker_scan(p, work, pass_idx, best)
	return best


# Counterfactual loop with the L280 break REMOVED: both passes always run into the same `best`. Used only to
# prove the break is load-bearing on `brkkeep` (with break -> pass-0 marker 6; without -> pass-1 marker 3).
func _nobreak_loop(p: Dictionary, ball: Dictionary) -> Array:
	var best := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]
	var n_passes := 1 + (1 if int(ball.get(0x5c, 0)) != 0 else 0)
	for pass_idx in range(n_passes):
		var work: Array = Pm98Movement._marker_grid_build(p, pass_idx)
		Pm98Movement._marker_scan(p, work, pass_idx, best)
	return best


# Rebuild the same p/ball/m the apply path uses for fixture `name` (goal anchors + N + traj only -- enough to
# drive the loop; the apply field reads are exercised by _run_apply).
func _build_pball(name: String) -> Array:
	var cfg: Dictionary = _apply_fix[name]
	var m := {0x1a38: 1, 0x19a0: 1, 0x1820: 0x100000}
	var ball := {0x5c: int(cfg["n"]), 4: 0, 8: 0, 0xc: 0, 0x40: 0, 0x1d4: m}
	for s in cfg["traj"]:
		var v: Array = cfg["traj"][s]
		ball[0xc * s] = int(v[0]); ball[0xc * s + 4] = int(v[1]); ball[0xc * s + 8] = int(v[2])
	var p := {0x4: 0, 0x8: 0, 0xc: 0, 0x34: 0, 0x2b8: 0, 0x18c: m, 0x190: ball, 0x3b8: {0x94: 0}}
	return [p, ball]


# Lock the TWO-PASS discriminators structurally (independent of the oracle field reads): twopass genuinely
# needs pass 1 (pass-0 alone misses), and brkkeep's break is load-bearing (no-break picks a different marker).
func _assert_discriminators() -> void:
	var pb: Array = _build_pball("twopass")
	var b0 := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]
	Pm98Movement._marker_scan(pb[0], Pm98Movement._marker_grid_build(pb[0], 0), 0, b0)
	_ok(b0[0] == -1, "twopass: pass-0 must MISS (got idx %d) so the 2nd pass is required" % int(b0[0]))
	_ok(_scan_loop(pb[0], pb[1])[0] == 6, "twopass: full loop must keep pass-1 marker 6")

	pb = _build_pball("brkkeep")
	var brk: int = _scan_loop(pb[0], pb[1])[0]
	var nob: int = _nobreak_loop(pb[0], pb[1])[0]
	_ok(brk == 6, "brkkeep: with break must keep pass-0 marker 6 (got %d)" % int(brk))
	_ok(nob == 3, "brkkeep: NO-break counterfactual must pick marker 3 (got %d)" % int(nob))
	_ok(brk != nob, "brkkeep: break must be load-bearing (with=%d no-break=%d)" % [int(brk), int(nob)])


func _run_apply(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _apply_fix[name]
	var m: Dictionary = cfg.get("box", {}).duplicate()
	m[0x1a38] = 1
	# Goal anchors for the pass-1 goal-extrapolation (grid_build reads m+0x19a0/0x1820 via goal_target_x);
	# == the oracle CONST poke 0x2a19a0/0x2a1820. Irrelevant for the N=0/0x15 fixtures (no scanned extrapolation).
	m[0x19a0] = 1
	m[0x1820] = 0x100000
	var stat := {0x94: 0}
	var bp: Array = cfg.get("ballpos", [0, 0, 0])
	var ball := {0x5c: int(cfg["n"]), 4: int(bp[0]), 8: int(bp[1]), 0xc: int(bp[2]), 0x40: 0, 0x1d4: m}
	for s in cfg["traj"]:
		var v: Array = cfg["traj"][s]
		ball[0xc * s] = int(v[0]); ball[0xc * s + 4] = int(v[1]); ball[0xc * s + 8] = int(v[2])
	var p := {0x4: 0, 0x8: 0, 0xc: 0, 0x34: 0, 0x2b8: 0, 0x18c: m, 0x190: ball, 0x3b8: stat}

	var best := _scan_loop(p, ball)
	var applied: bool = Pm98Movement._marker_apply(p, best)
	var oracle_applied: bool = int(want.get("0x2a0461", 0)) != 0
	_ok(applied == oracle_applied, "%s: loop applied=%s but oracle m+0x461=%d" % [name, applied, int(want.get("0x2a0461", 0))])

	var objs := {"p": p, "ball": ball, "m": m, "stat": stat}
	for addr in _apply_addr:
		var spec: Array = _apply_addr[addr]
		var got := int((objs[spec[0]] as Dictionary).get(spec[1], 0))
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "dribble-apply/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])


func _run_tail(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _tail_fix[name]
	var vel: Array = cfg.get("vel", [0, 0, 0])
	var m := {0x1820: 0x100000, 0x19a0: 1, 0x448: 0, 0x1a38: 1}
	var stat := {0x94: 0}
	var ctx := {0x2b8: 0, 0x2c4: 0}
	var team_struct := {0: ctx}
	var ball := {0x5c: 0, 0x40: 0, 0x1d4: m, 0x140: int(cfg.get("ball140", 0))}
	if cfg.has("carrier_team"):
		ball[0x40] = {0x2b8: int(cfg["carrier_team"])}
	var p := {
		0x4: 0, 0x8: 0, 0xc: 0, 0x2b8: 0,
		0x20: int(vel[0]), 0x24: int(vel[1]), 0x28: int(vel[2]),
		0x34: int(cfg.get("facing", 0)), 0x3a0: 50, 0x2bc: 1,
		0x18c: m, 0x190: ball, 0x3b8: stat, 0x188: team_struct}

	var best := _scan_loop(p, ball)
	var applied: bool = Pm98Movement._marker_apply(p, best)
	_ok(not applied and int(want.get("0x2a0461", 0)) == 0,
		"%s: expected nohit but loop applied=%s / oracle m+0x461=%d" % [name, applied, int(want.get("0x2a0461", 0))])
	Pm98Movement._marker_tail(p, applied, MatchEngine.Pm98Rng.new(0))

	var objs := {"p": p, "ball": ball}
	for addr in _tail_addr:
		var spec: Array = _tail_addr[addr]
		var got := int((objs[spec[0]] as Dictionary).get(spec[1], 0))
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "dribble-tail/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])
