extends SceneTree
## Oracle-backed parity test for FUN_005ad970 (case 0x36 AI lay-off / short-feed), ported as
## Pm98Movement.feed_layoff_036. Run:
##   ~/godot462 --headless --path app --script res://tests/test_ad970.gd
## ORACLE = the REAL FUN_005ad970 under the PCode emulator (tools/re/run_ad970_oracle.sh ->
## specs/ad970_oracle.txt; FUN_005ac1a0 = setup_shot and FUN_005943b0 stubbed; the corridor leaf
## FUN_005b1100/005b0e90 runs REAL). Each "## FIX <name>" + "CALL 0 RET ... mem[0xADDR:N]=VAL ..." line
## banks the OUTPUTS (ball+0x63/4c, player+0x5e/54/58/34/aim a0/a4/a8 + displaced-then-restored pos
## 4/8/c, and the rng seed 0x6d3184). We run feed_layoff_036 with call_setup=false so the seed reflects
## ONLY this function's draws (the oracle stubs setup_shot). ball+0x4c is a teammate POINTER: the oracle
## banks its address, mapped here to the fixture's teammate Dict (0 == unchanged).

const SEED := 0x12345678
var _fail := 0
var _pass := 0

# teammate base addresses (oracle: 0x2a0000 + k*0x3bc) -> fixture key, resolved per-fixture.
const TM0_ADDR := 0x2a0000
const TM1_ADDR := 0x2a03bc

# oracle byte-address -> [struct, field, width]. struct: "ball"/"p"; "b4c" handled specially.
const READS := [
	[0x270063, "ball", 0x63, 1], [0x23005e, "p", 0x5e, 1],
	[0x230058, "p", 0x58, 4], [0x230054, "p", 0x54, 4], [0x230034, "p", 0x34, 2],
	[0x2300a0, "p", 0xa0, 4], [0x2300a4, "p", 0xa4, 4], [0x2300a8, "p", 0xa8, 4],
	[0x230004, "p", 0x4, 4], [0x230008, "p", 0x8, 4], [0x23000c, "p", 0xc, 4],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/ad970_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "ad970 oracle unreadable (run tools/re/run_ad970_oracle.sh)")
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
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.feed_layoff_036(p, rng, false)        # call_setup=false: isolate FUN_005ad970

	for r in READS:
		var struct: Dictionary = ball if r[1] == "ball" else p
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
		_ok(got_tm == want_tm, "%s ball+0x4c: got %s want %s (addr 0x%x)" % [name, _id(got_tm, built), _id(want_tm, built), addr])

	_eq(name, "rng seed", rng.state, _norm(mems.get(0x6d3184), 4))


## Mirror of run_ad970_oracle.sh (BASE + per-fixture pokes). gs[0] and p[0x188] SHARE the roster array
## (the oracle shares the firstptr 0x2a0000). Returns {p, addr_map} where addr_map maps the oracle
## teammate addresses to their Dicts so ball+0x4c can be checked.
func _fixture(name: String) -> Dictionary:
	var m := {}
	var ball := {0x1d4: m}
	# tm0 @0x2a0000, tm1 @0x2a03bc -- the BASE layout.
	var tm0 := {0x4: 0x2fa000, 0x8: 0, 0xc: 0, 0x2b8: 0, 0x2c4: 1, 0x2bc: 1}
	var tm1 := {0x4: 0x100000, 0x8: 0x500000, 0xc: 0, 0x2b8: 0, 0x2c4: 2, 0x2bc: 1}
	var roster := [tm0, tm1]
	var gs := {0: roster, 0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x188: roster}
	# guard + BASE self fields.
	p[0x2c] = 0x13; p[0x30] = 0; p[0x34] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0
	# self per-position skill table (idx1=tm0 worst, idx2=tm1) + bias short for idx1 (p+0xba).
	p[0xe8] = 0x100000; p[0xec] = 0x200000; p[0xba] = 0

	match name:
		"nonspecial_hit":
			pass
		"special_hit":
			gs[0x2ee] = 1; p[0x5c] = 1
		"nonspecial_miss":
			tm0[0x8] = 0x900000; tm1[0x8] = 0x900000
		"special_miss":
			gs[0x2ee] = 1; p[0x5c] = 1; tm0[0x8] = 0x900000; tm1[0x8] = 0x900000
		"bias_gt0":
			p[0xba] = 5
		"no_teammate":
			gs[0] = []; p[0x188] = []
		"two_corridor":
			tm1[0x4] = 0x2c0000; tm1[0x8] = 0x40000
		_:
			return {}
	return {"p": p, "addr_map": {TM0_ADDR: tm0, TM1_ADDR: tm1}}


## Oracle reads memory as LE of the given width; our fields may be signed -> wrap to [0, 2^(8w)).
func _wrap(v: int, w: int) -> int:
	return v & ((1 << (8 * w)) - 1)


## A banked [value, width] pair -> unsigned of that width (the emu may report it signed).
func _norm(pair: Variant, w: int) -> Variant:
	if pair == null:
		return null
	return _wrap(int(pair[0]), w)


func _id(tm: Variant, built: Dictionary) -> String:
	if tm == null:
		return "null"
	if tm == built["addr_map"].get(TM0_ADDR):
		return "tm0"
	if tm == built["addr_map"].get(TM1_ADDR):
		return "tm1"
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
