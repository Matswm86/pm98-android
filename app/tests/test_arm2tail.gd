extends SceneTree
## Oracle-backed parity test for FUN_005aa870 (the "arm-2 active tail", slice 2b-iv):
## Pm98Movement._arm2_active_tail mutates p (and the ball, when istack == 0) exactly like the REAL binary.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_arm2tail.gd
##
## ORACLE = the REAL FUN_005aa870 entered at 0x5aa870 (ECX = p, char param_2 as a cdecl `arg`), the mutated
## fields read back at the function RET: tools/re/run_arm2tail_oracle.sh -> specs/arm2tail_oracle.txt
##   (ARM2 <name> istack=<0|1> | <abs-addr>=<unsigned LE> ...).
## We rebuild the identical p/ball/m/teamstruct/ctx Dicts (same pokes), run _arm2_active_tail with a
## MatchEngine.Pm98Rng seeded to the oracle's DAT_006d3184 (0x4d2), and assert every mutated field + the
## final RNG state == the oracle.

const SEED := 0x4d2

var _fail := 0
var _pass := 0

# name -> fixture cfg (mirrors run_arm2tail_oracle.sh FIX rows). Unlisted offsets default to 0.
# pos = p+0x4/8/c, vel = p+0x20/24/28, bvel = ball+0x20/24/28, bpos = ball+4/8/c, carrier = ball+0x40 == p.
var _fix := {
	"s1":      {"istack": 1, "action": 0x1e, "team": 0, "facing": 0x1000, "vel": [0x4000, -0x2000, 0x800],
		"base100": 50, "onpitch": 1, "bvel": [0x6000, 0x1000, -0x400]},
	"s1pos":   {"istack": 1, "action": 0x1e, "team": 1, "pos": [0x80000, -0x40000, 0x2000], "facing": 0x3000,
		"vel": [-0x3000, 0x5000, 0], "base100": 70, "onpitch": 0, "bvel": [0x2000, -0x6000, 0x1000]},
	"s0":      {"istack": 0, "action": 0x1e, "team": 0, "carrier": true, "facing": 0x800,
		"vel": [0x4000, -0x2000, 0x800], "base100": 40, "onpitch": 1,
		"bpos": [0x10000, 0x8000, -0x2000], "bvel": [0x6000, 0x1000, -0x400]},
	"s0nc":    {"istack": 0, "action": 0x1e, "team": 0, "carrier": false, "vel": [0x4000, 0, 0]},
	"act13":   {"istack": 1, "action": 0x13, "vel": [0x4000, 0, 0]},
	"m448":    {"istack": 1, "action": 0x1e, "team": 0, "m448": 4, "facing": 0x1800, "vel": [0x3000, 0x2000, -0x800],
		"base100": 60, "onpitch": 1, "bvel": [0x4000, -0x3000, 0x200]},
	"sv11neg": {"istack": 1, "action": 0x1e, "team": 0, "sv11": 0x9000, "facing": 0x1000,
		"vel": [0x4000, -0x2000, 0x800], "base100": 50, "onpitch": 1, "bvel": [0x6000, 0x1000, -0x400]},
}

# oracle abs-addr -> (object, field-off). p=0x230000 ball=0x280000.
var _addr := {
	"0x230048": ["p", 0x48], "0x230040": ["p", 0x40], "0x2300a0": ["p", 0xa0],
	"0x2300a4": ["p", 0xa4], "0x2300a8": ["p", 0xa8], "0x23005e": ["p", 0x5e],
	"0x230080": ["p", 0x80], "0x230084": ["p", 0x84], "0x230094": ["p", 0x94],
	"0x230098": ["p", 0x98], "0x23009c": ["p", 0x9c], "0x230066": ["p", 0x66],
	"0x280068": ["ball", 0x68], "0x28006c": ["ball", 0x6c], "0x28009c": ["ball", 0x9c],
	"0x2800a0": ["ball", 0xa0], "0x2800a4": ["ball", 0xa4],
}


func _init() -> void:
	var o := _load("arm2tail_oracle.txt", "ARM2")
	if o.is_empty():
		_ok(false, "arm2tail oracle empty (run tools/re/run_arm2tail_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from arm2tail oracle")
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
	var pos: Array = cfg.get("pos", [0, 0, 0])
	var vel: Array = cfg.get("vel", [0, 0, 0])
	var bvel: Array = cfg.get("bvel", [0, 0, 0])
	var bpos: Array = cfg.get("bpos", [0, 0, 0])
	var m := {0x1820: 0x100000, 0x19a0: 0, 0x448: int(cfg.get("m448", 0))}
	var ctx := {0x2b8: 0, 0x2c4: 0}                          # ctx slot/team 0 -> sVar11 = p[0xb8]
	var team_struct := {0: ctx}
	var ball := {
		0x20: int(bvel[0]), 0x24: int(bvel[1]), 0x28: int(bvel[2]),
		0x4: int(bpos[0]), 0x8: int(bpos[1]), 0xc: int(bpos[2])}
	var p := {
		0x40: int(cfg["action"]), 0x2b8: int(cfg.get("team", 0)),
		0x4: int(pos[0]), 0x8: int(pos[1]), 0xc: int(pos[2]),
		0x20: int(vel[0]), 0x24: int(vel[1]), 0x28: int(vel[2]),
		0x34: int(cfg.get("facing", 0)), 0x3a0: int(cfg.get("base100", 0)),
		0x2bc: int(cfg.get("onpitch", 0)), 0x18c: m, 0x190: ball, 0x188: team_struct}
	if cfg.get("carrier", false):
		ball[0x40] = p
	if cfg.has("sv11"):
		p[Pm98Movement._angle_off(0, 0)] = int(cfg["sv11"])    # sVar11 = p[0xb8 + (slot+team*11)*2]
	var rng = MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement._arm2_active_tail(p, int(cfg["istack"]), rng)

	# RNG draw-count check: the oracle reports the final DAT_006d3184 state. Reproduce it with the same LCG.
	var ref = MatchEngine.Pm98Rng.new(SEED)
	var draws := 0
	if int(cfg["action"]) != 0x13 and int(cfg["action"]) != 0x1d \
			and (int(cfg["istack"]) != 0 or cfg.get("carrier", false)):
		draws = 2
	for i in draws:
		ref.next()
	_ok(rng.state == ref.state, "%s: rng state=%d after port, ref(%d draws)=%d" % [name, rng.state, draws, ref.state])

	var objs := {"p": p, "ball": ball}
	for addr in _addr:
		var spec: Array = _addr[addr]
		var obj: Dictionary = objs[spec[0]]
		var got := int(obj.get(spec[1], 0))                  # unset Dict field == zeroed emu memory
		var exp := int(want.get(addr, 0))
		_ok(got == exp, "arm2/%s %s+0x%x: got=%d want=%d" % [name, spec[0], int(spec[1]), got, exp])
