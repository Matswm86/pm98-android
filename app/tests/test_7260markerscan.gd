extends SceneTree
## Oracle-backed parity test for FUN_005a7260 MARKER SCAN (slice 2b-iii-c):
## Pm98Movement._marker_scan == the per-pass best-state the REAL binary tracks in its [esp] slot cluster.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260markerscan.gd
##
## ORACLE = the REAL FUN_005a7260 entered mid-function (grid build then scan), the best-state read back after
## one scan pass at the 0x5a8274 increment: tools/re/run_7260markerscan_oracle.sh -> specs/7260markerscan_oracle.txt
##   (SCAN <name> scanned=1 | 0x308028=<idx> 0x308024=<frame4> 0x308034=<score> 0x308048=<head> 0x30804c=<hd1>
##    0x308050=<wx> 0x308054=<wy> 0x308058=<wz>).
## We rebuild the identical p/m/ball Dicts (same trajectory pokes, p.pos/ball.pos/facing 0, m bbox 0, same N
## + pass), run _marker_grid_build then _marker_scan over a seeded best, and assert best == the oracle row.

var _fail := 0
var _pass := 0

# name -> {pass, n, traj, ballpos, box}  (mirrors run_7260markerscan_oracle.sh FIX rows).
# traj = {slot: [x,y,z]}; ballpos = [x,y,z] (default 0); box = {m_off: val} for the marker bbox.
var _fix := {
	"hit0":   {"pass": 0, "n": 0,     "traj": {0x1a: [0x1b333, 0, 0x4000]}},
	"nohit":  {"pass": 0, "n": 0,     "traj": {}},
	"p1hit2": {"pass": 1, "n": 0x15,  "traj": {0x1c: [0x9999, 0, 0x1cccc]}},
	"comp":   {"pass": 0, "n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0x8000, 0x4000], 0x1c: [0x9999, 0x400, 0x1cccc]}},
	"bbox":   {"pass": 0, "n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0, 0x4000], 0x1c: [0x9999, 0x2000, 0x1cccc]},
		"box": {0x1828: 0x9000, 0x182c: -0x10000, 0x1830: 0x1c000, 0x1834: 0xa000, 0x1838: 0x10000, 0x183c: 0x1d000}},
}


func _init() -> void:
	var o := _load("7260markerscan_oracle.txt", "SCAN")
	if o.is_empty():
		_ok(false, "marker-scan oracle empty (run tools/re/run_7260markerscan_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from marker-scan oracle")
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


# name -> the 8 best-state values (signed), in read order idx, frame4, score, head, hd1, wx, wy, wz.
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
		if vals.size() == 8:
			out[name] = vals
	return out


func _run(name: String, want: Array) -> void:
	var cfg: Dictionary = _fix[name]
	var m: Dictionary = cfg.get("box", {}).duplicate()       # bbox m+0x1828..0x183c (default all 0, zeroed)
	var bp: Array = cfg.get("ballpos", [0, 0, 0])
	var ball := {0x5c: int(cfg["n"]), 4: int(bp[0]), 8: int(bp[1]), 0xc: int(bp[2])}
	var traj: Dictionary = cfg["traj"]
	for s in traj:
		var v: Array = traj[s]
		ball[0xc * s] = int(v[0])
		ball[0xc * s + 4] = int(v[1])
		ball[0xc * s + 8] = int(v[2])
	var p := {0x4: 0, 0x8: 0, 0xc: 0, 0x34: 0, 0x2b8: 0, 0x18c: m, 0x190: ball}
	var pass_idx := int(cfg["pass"])
	var work: Array = Pm98Movement._marker_grid_build(p, pass_idx)
	var best := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]          # per-pass-loop seed
	Pm98Movement._marker_scan(p, work, pass_idx, best)
	_ok(best == want, "markerscan/%s:\n    got =%s\n    want=%s" % [name, best, want])
