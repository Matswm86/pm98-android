extends SceneTree
## Oracle-backed parity test for FUN_005ad010 (case 5/0x24, THE MONSTER feed / blind-aim handler), ported
## as Pm98Movement.ai_feed_024. Run:
##   ~/godot462 --headless --path app --script res://tests/test_ad010.gd
## ORACLE = the REAL FUN_005ad010 under the PCode emulator (tools/re/run_ad010_oracle.sh ->
## specs/ad010_oracle.txt; FUN_005ac1a0 = setup_shot and FUN_005943b0 stubbed, commentary headless). The
## corridor scan FUN_005b1100, restart_box_ok FUN_0059a120, goalbox FUN_0058fb50, opp-goal-x FUN_005a44f0,
## heading FUN_005aac00, atan FUN_005ee080, polar FUN_005ee0f0 and vec3-scale FUN_005ee1c0 all run REAL.
## Each "## FIX <name>" + "CALL 0 RET ... mem[0xADDR:N]=VAL ..." banks the OUTPUTS (ball+0x4c, player+0x5e/
## 58/54/34/aim a0/a4/a8 + displaced-then-restored pos 4/8/c, match+0x462, rng seed 0x6d3184). We run with
## call_setup=false so the seed reflects ONLY ad010's draws. ball+0x4c is a teammate POINTER: the oracle
## banks its address, mapped here to the fixture's teammate Dict (0 == unchanged).

const SEED := 0x12345678
var _fail := 0
var _pass := 0

# the single corridor / worst-teammate candidate tm0 @0x2a0000.
const TM0_ADDR := 0x2a0000

# oracle byte-address -> [struct, field, width]. struct: "ball"/"p"/"m".
const READS := [
	[0x23005e, "p", 0x5e, 1],
	[0x230058, "p", 0x58, 4], [0x230054, "p", 0x54, 4], [0x230034, "p", 0x34, 2],
	[0x2300a0, "p", 0xa0, 4], [0x2300a4, "p", 0xa4, 4], [0x2300a8, "p", 0xa8, 4],
	[0x230004, "p", 0x4, 4], [0x230008, "p", 0x8, 4], [0x23000c, "p", 0xc, 4],
	[0x260462, "m", 0x462, 1],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/ad010_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "ad010 oracle unreadable (run tools/re/run_ad010_oracle.sh)")
	else:
		var name := ""
		var rx_mem := RegEx.new()
		rx_mem.compile("mem\\[0x([0-9a-f]+):(\\d+)\\]=(-?\\d+)")
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.begins_with("## FIX "):
				name = line.substr(7)
			elif line.find(" RET ") != -1 and name != "":
				var mems := {}
				for m in rx_mem.search_all(line):
					mems[("0x" + m.get_string(1)).hex_to_int()] = [m.get_string(3).to_int(), m.get_string(2).to_int()]
				_check(name, mems)
				name = ""
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _check(name: String, mems: Dictionary) -> void:
	var built := _fixture(name)
	if built.is_empty():
		_ok(false, "%s: no fixture builder" % name)
		return
	var p: Dictionary = built["p"]
	var ball: Dictionary = p[0x190]
	var m: Dictionary = p[0x18c]
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.ai_feed_024(p, rng, false)            # call_setup=false: isolate FUN_005ad010

	for r in READS:
		var struct: Dictionary = ball if r[1] == "ball" else (m if r[1] == "m" else p)
		var got: int = _wrap(int(struct.get(r[2], 0)), r[3])
		_eq(name, "%s+0x%x" % [r[1], r[2]], got, _norm(mems.get(r[0]), r[3]))

	# ball+0x4c is a teammate pointer: oracle banks the address; map to the fixture's teammate Dict.
	var b4c: Variant = mems.get(0x27004c)
	if b4c == null:
		_ok(false, "%s ball+0x4c: oracle had no banked value" % name)
	else:
		var addr: int = _wrap(int(b4c[0]), 4)
		var want_tm: Variant = built["addr_map"].get(addr, null)   # null when addr == 0 (unchanged)
		var got_tm: Variant = ball.get(0x4c, null)
		# ball[0x4c] is set to literal 0 up front; treat 0 as "unchanged" (null) for the mapping.
		if got_tm is int and int(got_tm) == 0:
			got_tm = null
		_ok(got_tm == want_tm, "%s ball+0x4c: got %s want %s (addr 0x%x)" % [name, _id(got_tm), _id(want_tm), addr])

	_eq(name, "rng seed", rng.state, _norm(mems.get(0x6d3184), 4))


## Mirror of run_ad010_oracle.sh (BASE + per-fixture pokes). gs[0] = corridor roster [tm0]; p[0x188] =
## worst-teammate roster [tm0]; m = the match. tm0 is OFF the facing corridor by default (tm0+8 high) so
## the default fixtures take blind / tail; HIT fixtures override tm0 onto the +x ray.
func _fixture(name: String) -> Dictionary:
	var m := {
		0x1820: 0x2000000, 0x19a0: 0, 0x44c: 0, 0x180a: 0, 0x19cc: 0, 0x462: 0,
		0x1828: 0x1000000, 0x182c: -0x800000, 0x1830: -0x100000,
		0x1834: 0x3000000, 0x1838: 0x800000, 0x183c: 0x100000,
	}
	var ball := {0x1d4: m}
	var tm0 := {0x2bc: 1, 0x2b8: 0, 0x2c4: 1, 0x4: 0x2000000, 0x8: 0x900000, 0xc: 0}
	var gs := {0: [tm0], 0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x188: [tm0]}
	p[0x2c] = 3; p[0x30] = 3; p[0x34] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0; p[0x5e] = 0
	p[0x3a4] = 0x100000; p[0x2b8] = 0; p[0x2bc] = 0
	p[0x4] = 0x2000000; p[0x8] = 0; p[0xc] = 0
	p[0xe8] = 0x100000; p[0xba] = 0                    # self skill[idx1] + bias short[idx1]

	match name:
		"p0_nonspec_miss":
			pass
		"p0_special_hit":
			gs[0x2ee] = 1; p[0x5c] = 1; tm0[0x4] = 0x22aa000; tm0[0x8] = 0
		"p0_special_miss":
			gs[0x2ee] = 1; p[0x5c] = 1
		"p0_nonspec_biasneg":
			p[0xba] = 0xfffb                           # word = -5 -> the -0x222 bias branch
		"44c4_nonspec_miss":
			p[0x2bc] = 1; m[0x44c] = 4
		"44c4_special_hit":
			p[0x2bc] = 1; m[0x44c] = 4; gs[0x2ee] = 1; p[0x5c] = 1; tm0[0x4] = 0x22b3000; tm0[0x8] = 0
		"44c4_p58zero_skip":
			p[0x2bc] = 1; m[0x44c] = 4; gs[0x2ee] = 1; p[0x5c] = 1; p[0x58] = 0
		"44c5_19cc0_miss":
			p[0x2bc] = 1; m[0x44c] = 5
		"44c5_19cc1":
			p[0x2bc] = 1; m[0x44c] = 5; m[0x19cc] = 1
		"44c_other":
			p[0x2bc] = 1; m[0x44c] = 0
		"preamble_boost":
			p[0x54] = 0x20
		"preamble_special":
			p[0x54] = 0x20; gs[0x2ee] = 1; p[0x5c] = 1; tm0[0x4] = 0x25a4000; tm0[0x8] = 0
		_:
			return {}
	return {"p": p, "addr_map": {TM0_ADDR: tm0}}


## Oracle reads memory as LE of the given width; our fields may be signed -> wrap to [0, 2^(8w)).
func _wrap(v: int, w: int) -> int:
	return v & ((1 << (8 * w)) - 1)


## A banked [value, width] pair -> unsigned of that width (the emu may report it signed).
func _norm(pair: Variant, w: int) -> Variant:
	if pair == null:
		return null
	return _wrap(int(pair[0]), w)


func _id(tm: Variant) -> String:
	if tm == null:
		return "null"
	if tm is Dictionary and int((tm as Dictionary).get(0x2c4, -1)) == 1:
		return "tm0"
	return "?"


func _eq(name: String, field: String, got: int, want: Variant) -> void:
	if want == null:
		_ok(false, "%s %s: oracle had no banked value" % [name, field])
		return
	_ok(got == int(want), "%s %s: got %d want %d" % [name, field, got, int(want)])


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
