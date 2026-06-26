extends SceneTree
## Oracle-backed parity test for the FUN_005a7260 marker TAIL (slice 2b-iii-e):
## Pm98Movement._marker_tail decides (carrier check + two proximity gates) whether to hand off to the arm-2
## active tail, exactly like the REAL binary's 0x5a8457..0x5a85ac.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260markertail.gd
##
## ORACLE = the REAL FUN_005a7260 entered mid-function (build -> scan -> apply no-op -> tail, the handoff
## FUN_005aa870 running for real), mutations read back at the shared epilogue 0x5a85a2:
## tools/re/run_7260markertail_oracle.sh -> specs/7260markertail_oracle.txt
##   (TAIL <name> arm2=<0|1> applied=<0|1> | <abs-addr>=<signed> ...).
## We rebuild identical Dicts, run _marker_grid_build -> _marker_scan -> _marker_apply -> _marker_tail with
## a Pm98Rng seeded to 0 (the oracle's DAT_006d3184), and assert every mutated field == the oracle.

var _fail := 0
var _pass := 0

# name -> fixture cfg (mirrors run_7260markertail_oracle.sh FIX rows). All NOHIT scans (applied=false).
# vel = p+0x20/24/28, facing = p+0x34, ball140 = ball+0x140 (work[3].z, fails gate1.z), carrier_team set =>
# ball+0x40 is a carrier Dict with that team.
var _fix := {
	"g1pass":      {"facing": 0x1000, "vel": [0x4000, -0x2000, 0x800]},
	"g2pass":      {"facing": 0, "vel": [0x2000, -0x2000, 0x40000], "ball140": 0x40000},
	"g2fail":      {"facing": 0, "vel": [0x4000, -0x2000, 0], "ball140": 0x40000},
	"foreign":     {"facing": 0x1000, "vel": [0x4000, -0x2000, 0x800], "carrier_team": 1},
	"samecarrier": {"facing": 0x1000, "vel": [0x4000, 0, 0], "carrier_team": 0},
}

# oracle abs-addr -> (object, field-off). p=0x230000.
var _addr := {
	"0x230048": ["p", 0x48], "0x230040": ["p", 0x40], "0x230080": ["p", 0x80],
	"0x230084": ["p", 0x84], "0x2300a0": ["p", 0xa0], "0x2300a4": ["p", 0xa4],
	"0x2300a8": ["p", 0xa8], "0x230094": ["p", 0x94], "0x230098": ["p", 0x98],
	"0x23009c": ["p", 0x9c], "0x230066": ["p", 0x66], "0x23005e": ["p", 0x5e],
}


func _init() -> void:
	var o := _load("7260markertail_oracle.txt", "TAIL")
	if o.is_empty():
		_ok(false, "marker-tail oracle empty (run tools/re/run_7260markertail_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from marker-tail oracle")
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


func _run(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _fix[name]
	var vel: Array = cfg.get("vel", [0, 0, 0])
	var m := {0x1820: 0x100000, 0x19a0: 1, 0x448: 0, 0x1a38: 1}
	var stat := {0x94: 0}
	var ctx := {0x2b8: 0, 0x2c4: 0}                          # sVar11 = p[0xb8] = 0
	var team_struct := {0: ctx}
	var ball := {0x5c: 0, 0x40: 0, 0x1d4: m, 0x140: int(cfg.get("ball140", 0))}
	if cfg.has("carrier_team"):
		ball[0x40] = {0x2b8: int(cfg["carrier_team"])}
	var p := {
		0x4: 0, 0x8: 0, 0xc: 0, 0x2b8: 0,
		0x20: int(vel[0]), 0x24: int(vel[1]), 0x28: int(vel[2]),
		0x34: int(cfg.get("facing", 0)), 0x3a0: 50, 0x2bc: 1,
		0x18c: m, 0x190: ball, 0x3b8: stat, 0x188: team_struct}

	var work: Array = Pm98Movement._marker_grid_build(p, 0)
	var best := [-1, 0, 0, 0x7c72, 0x7c72, 0, 0, 0]
	Pm98Movement._marker_scan(p, work, 0, best)
	var applied: bool = Pm98Movement._marker_apply(p, best)
	# Every fixture is a NOHIT scan: cross-check against the oracle's m+0x461 discriminator (must be 0).
	_ok(not applied and int(want.get("0x2a0461", 0)) == 0,
		"%s: expected nohit but applied=%s / oracle m+0x461=%d" % [name, applied, int(want.get("0x2a0461", 0))])
	Pm98Movement._marker_tail(p, applied, MatchEngine.Pm98Rng.new(0))

	var objs := {"p": p, "ball": ball}
	for addr in _addr:
		var spec: Array = _addr[addr]
		var obj: Dictionary = objs[spec[0]]
		var got := int(obj.get(spec[1], 0))                  # unset Dict field == zeroed emu memory
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "tail/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])
