extends SceneTree
## Oracle-backed parity test for the 3 kick-resolution action handlers, ported as
## Pm98Movement.kick_resolve(p, rng, cfg):
##   FUN_005adfc0 (engine_tick case 0x19/0x1a)  cfg KICK_ADFC0
##   FUN_005ae4c0 (case 0x14/0x16)              cfg KICK_AE4C0
##   FUN_005ae910 (case 0x15)                   cfg KICK_AE910
## Run: ~/godot462 --headless --path app --script res://tests/test_kick.gd
## ORACLE = the REAL functions under the PCode emulator (tools/re/run_{adfc0,ae4c0,ae910}_oracle.sh ->
## specs/*_oracle.txt; FUN_005ab5a0/590f00/4e9940 stubbed). Each "## FIX <name>" + "CALL 0 RET ...
## mem[..]=.." banks the OUTPUTS (ball velocity +0x20/24/28, player+0x54/58, ball+0x4c/70, match+0x462,
## ae4c0/ae910 ball+0x64, ae910 ball pos +4/8/c, and the rng seed after the 2 spread draws). kick_resolve
## runs with call_resolve=false so the seed reflects ONLY the function's own draws (stubbed-resolve oracle).

const SEED := 0x12345678
var _fail := 0
var _pass := 0

const BASE_READS := [
	[0x270020, "ball", 0x20], [0x270024, "ball", 0x24], [0x270028, "ball", 0x28],
	[0x230054, "p", 0x54], [0x230058, "p", 0x58],
	[0x27004c, "ball", 0x4c], [0x270070, "ball", 0x70],
	[0x260462, "m", 0x462],
]


func _cfg(name: String) -> Dictionary:
	match name:
		"adfc0": return Pm98Movement.KICK_ADFC0
		"ae4c0": return Pm98Movement.KICK_AE4C0
		"ae910": return Pm98Movement.KICK_AE910
	return {}


func _variants() -> Array:
	return [
		{"name": "adfc0", "oracle": "adfc0_oracle.txt", "g2c": 4, "g30": 3,
			"reads": BASE_READS, "ae910": false},
		{"name": "ae4c0", "oracle": "ae4c0_oracle.txt", "g2c": 8, "g30": 0,
			"reads": BASE_READS + [[0x270064, "ball", 0x64]], "ae910": false},
		{"name": "ae910", "oracle": "ae910_oracle.txt", "g2c": 5, "g30": 0,
			"reads": BASE_READS + [[0x270004, "ball", 0x4], [0x270008, "ball", 0x8],
				[0x27000c, "ball", 0xc], [0x270064, "ball", 0x64]], "ae910": true},
	]


func _init() -> void:
	for v in _variants():
		_run_variant(v)
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _run_variant(v: Dictionary) -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/" + String(v["oracle"])).simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "%s oracle unreadable (run tools/re/run_%s_oracle.sh)" % [v["name"], v["name"]])
		return
	var name := ""
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-f]+):\\d+\\]=(-?\\d+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			name = line.substr(7)
		elif line.find(" RET ") != -1 and name != "":
			var mems := {}
			for mm in rx.search_all(line):
				mems[("0x" + mm.get_string(1)).hex_to_int()] = mm.get_string(2).to_int()
			_check(v, name, mems)
			name = ""


func _check(v: Dictionary, name: String, mems: Dictionary) -> void:
	var p := _fixture(v, name)
	if p.is_empty():
		_ok(false, "%s/%s: no fixture builder" % [v["name"], name])
		return
	var ball: Dictionary = p[0x190]
	var m: Dictionary = p[0x18c]
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.kick_resolve(p, rng, _cfg(v["name"]), false)
	for r in v["reads"]:
		var st: Dictionary = ball if r[1] == "ball" else (m if r[1] == "m" else p)
		_eq(v["name"], name, "%s+0x%x" % [r[1], r[2]], _i32u(int(st.get(r[2], 0))), mems.get(r[0]))
	_eq(v["name"], name, "rng seed", rng.state, mems.get(0x6d3184))


func _i32u(x: int) -> int:
	return x & 0xffffffff


func _fixture(v: Dictionary, name: String) -> Dictionary:
	var tm0 := {0x2b8: 0, 0x2c4: 0}
	var m := {0x1820: 0x300000, 0x19a0: 0}
	var ball := {0x80: 1, 0x63: 0, 0x20: 0x30000, 0x24: 0x40000, 0x28: 0, 0x70: 100, 0x1d4: m}
	var p := {0x18c: m, 0x190: ball, 0x188: [tm0]}
	p[0x2c] = int(v["g2c"]); p[0x30] = int(v["g30"]); p[0x7c] = 1; p[0x34] = 0
	p[0x2b8] = 0; p[0xb8] = 0x7fff; p[0x39c] = 50; p[0x388] = 50; p[0x54] = 10
	if v["ae910"]:
		p[0x20] = 0x11111; p[0x24] = 0x22222; p[0x28] = 0x33333    # player vel (added to ball pos)
		ball[0x4] = 0x1000; ball[0x8] = 0x2000; ball[0xc] = 0x3000  # ball pos base
	match name:
		"base":
			pass
		"maxpath":
			p[0xb8] = 0x8000
		"nonsq_speed":
			ball[0x20] = 0x10000; ball[0x24] = 0x10000; ball[0x28] = 0
		"touch_lt5":
			p[0x54] = 2
		"lowacc":
			p[0x39c] = 0; p[0x388] = 0
		"side_neg":
			p[0x2b8] = 1
		"clamp70":
			ball[0x70] = 2
		"facing":
			p[0x34] = 0x2000
		_:
			return {}
	return p


func _eq(vn: String, fx: String, field: String, got: int, want: Variant) -> void:
	if want == null:
		_ok(false, "%s/%s %s: oracle had no banked value" % [vn, fx, field])
		return
	_ok(got == int(want), "%s/%s %s: got %d want %d" % [vn, fx, field, got, int(want)])


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
