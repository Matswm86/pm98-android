extends SceneTree
## Oracle-backed parity test for FUN_005a7260 marker APPLY (slice 2b-iii-d):
## Pm98Movement._marker_apply mutates p / ball / m / stat exactly like the REAL binary's apply block.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260markerapply.gd
##
## ORACLE = the REAL FUN_005a7260 entered mid-function (grid build -> scan -> apply), the mutated fields read
## back at the 0x5a8457 apply-tail: tools/re/run_7260markerapply_oracle.sh -> specs/7260markerapply_oracle.txt
##   (APPLY <name> applied=<0|1> | <abs-addr>=<signed> ...).
## We rebuild the identical p/m/ball/stat Dicts (same trajectory pokes, p.pos/ball.pos/facing 0), run
## _marker_grid_build -> _marker_scan -> _marker_apply, and assert every mutated Dict field == the oracle.

var _fail := 0
var _pass := 0

# name -> {pass, n, traj, ballpos, box}  (mirrors run_7260markerapply_oracle.sh FIX rows).
var _fix := {
	"hit0":   {"pass": 0, "n": 0,    "traj": {0x1a: [0x1b333, 0, 0x4000]}},
	"hit1":   {"pass": 0, "n": 0,    "traj": {0x1a: [0x9999, 0, 0x10000]}},
	"nohit":  {"pass": 0, "n": 0,    "traj": {}},
	"p1hit2": {"pass": 1, "n": 0x15, "traj": {0x1c: [0x9999, 0, 0x1cccc]}},
	"comp":   {"pass": 0, "n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0x8000, 0x4000], 0x1c: [0x9999, 0x400, 0x1cccc]}},
	"bbox":   {"pass": 0, "n": 0, "ballpos": [0x100000, 0, 0],
		"traj": {0x1a: [0x1b333, 0, 0x4000], 0x1c: [0x9999, 0x2000, 0x1cccc]},
		"box": {0x1828: 0x9000, 0x182c: -0x10000, 0x1830: 0x1c000, 0x1834: 0xa000, 0x1838: 0x10000, 0x183c: 0x1d000}},
}

# Each oracle abs-addr -> (object, field-off) so we can diff Dict state against the read-back row.
# p=0x230000 ball=0x280000 m=0x2a0000 stat=0x2c0000.
var _addr := {
	"0x2a0461": ["m", 0x461], "0x230044": ["p", 0x44], "0x230040": ["p", 0x40],
	"0x230084": ["p", 0x84], "0x230080": ["p", 0x80], "0x230094": ["p", 0x94],
	"0x230098": ["p", 0x98], "0x23009c": ["p", 0x9c], "0x230066": ["p", 0x66],
	"0x280068": ["ball", 0x68], "0x28006c": ["ball", 0x6c], "0x280063": ["ball", 0x63],
	"0x280070": ["ball", 0x70], "0x28009c": ["ball", 0x9c], "0x2800a0": ["ball", 0xa0],
	"0x2800a4": ["ball", 0xa4], "0x280020": ["ball", 0x20], "0x280024": ["ball", 0x24],
	"0x280028": ["ball", 0x28], "0x2a0458": ["m", 0x458], "0x2c0094": ["stat", 0x94],
}


func _init() -> void:
	var o := _load("7260markerapply_oracle.txt", "APPLY")
	if o.is_empty():
		_ok(false, "marker-apply oracle empty (run tools/re/run_7260markerapply_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from marker-apply oracle")
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


# name -> {abs-addr: signed-value} for every read-back field.
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


func _run(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _fix[name]
	var m: Dictionary = cfg.get("box", {}).duplicate()       # bbox m+0x1828..0x183c (default all 0)
	m[0x1a38] = 1                                            # freeze event queue (enqueue early-returns)
	var stat := {0x94: 0}
	var bp: Array = cfg.get("ballpos", [0, 0, 0])
	var ball := {0x5c: int(cfg["n"]), 4: int(bp[0]), 8: int(bp[1]), 0xc: int(bp[2]), 0x40: 0, 0x1d4: m}
	var traj: Dictionary = cfg["traj"]
	for s in traj:
		var v: Array = traj[s]
		ball[0xc * s] = int(v[0])
		ball[0xc * s + 4] = int(v[1])
		ball[0xc * s + 8] = int(v[2])
	var p := {0x4: 0, 0x8: 0, 0xc: 0, 0x34: 0, 0x2b8: 0, 0x18c: m, 0x190: ball, 0x3b8: stat}
	var pass_idx := int(cfg["pass"])
	var work: Array = Pm98Movement._marker_grid_build(p, pass_idx)
	var best := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]
	Pm98Movement._marker_scan(p, work, pass_idx, best)
	var applied: bool = Pm98Movement._marker_apply(p, best)

	# Cross-check the applied flag against the oracle's m+0x461 discriminator (0x10 set => applied).
	var oracle_applied: bool = int(want.get("0x2a0461", 0)) != 0
	_ok(applied == oracle_applied, "%s: applied=%s but oracle m+0x461=%d" % [name, applied, int(want.get("0x2a0461", 0))])

	var objs := {"p": p, "ball": ball, "m": m, "stat": stat}
	for addr in _addr:
		var spec: Array = _addr[addr]
		var obj: Dictionary = objs[spec[0]]
		var got := int(obj.get(spec[1], 0))                  # unset Dict field == zeroed emu memory
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "apply/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])
