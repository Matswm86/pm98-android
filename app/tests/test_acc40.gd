extends SceneTree
## Oracle-backed parity test for FUN_005acc40 (case 4/0x25 AI goal-aim set-piece feed), ported as
## Pm98Movement.goal_aim_025. Run:
##   ~/godot462 --headless --path app --script res://tests/test_acc40.gd
## ORACLE = the REAL FUN_005acc40 under the PCode emulator (tools/re/run_acc40_oracle.sh ->
## specs/acc40_oracle.txt; FUN_005ac1a0 = setup_shot and FUN_005943b0 stubbed; commentary FUN_00590f00
## gated out headless). ALL geometry leaves run REAL under the emu: FUN_005ee080 (atan), FUN_00436fb0 +
## FUN_005edfb0 (the cos/sin muladd = planar_mag), FUN_005ee0f0 (polar), FUN_0058fb50 (goalbox) /
## FUN_005ac0e0 (corner), and the vec set/sub/copy/add/sub leaves -- all inlined in the GD port.
## Each "## FIX <name>" + "CALL 0 RET ... mem[0xADDR:N]=VAL ..." banks the OUTPUTS (ball+0x62,
## player+0x5e/5f/58, aim a0/a4/a8, rng seed 0x6d3184). We run with call_setup=false so setup_shot (the
## stub) does not run; acc40 itself draws 0 rng, so the seed must be unchanged.

const SEED := 0x12345678
var _fail := 0
var _pass := 0

# oracle byte-address -> [struct, field, width]. struct: "ball"/"p".
const READS := [
	[0x270062, "ball", 0x62, 1], [0x23005e, "p", 0x5e, 1], [0x23005f, "p", 0x5f, 1],
	[0x230058, "p", 0x58, 4],
	[0x2300a0, "p", 0xa0, 4], [0x2300a4, "p", 0xa4, 4], [0x2300a8, "p", 0xa8, 4],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/acc40_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "acc40 oracle unreadable (run tools/re/run_acc40_oracle.sh)")
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
	Pm98Movement.goal_aim_025(p, rng, false)            # call_setup=false: isolate FUN_005acc40

	for r in READS:
		var struct: Dictionary = ball if r[1] == "ball" else p
		var got: int = _wrap(int(struct.get(r[2], 0)), r[3])
		_eq(name, "%s+0x%x" % [r[1], r[2]], got, _norm(mems.get(r[0]), r[3]))

	_eq(name, "rng seed", rng.state, _norm(mems.get(0x6d3184), 4))


## Mirror of run_acc40_oracle.sh (BASE + per-fixture pokes). match goal AABB + goal line; ball+0x4c is the
## aim teammate; gs holds the set-piece flag. p+0x5f pre-set only in the *_5f fixtures.
func _fixture(name: String) -> Dictionary:
	var m := {
		0x1820: 0x2000000, 0x19a0: 0, 0x44c: 0, 0x180a: 0,
		0x1828: 0x1000000, 0x182c: -0x800000, 0x1830: -0x100000,
		0x1834: 0x3000000, 0x1838: 0x800000, 0x183c: 0x100000,
	}
	var target := {0x4: 0x1000000, 0x8: 0x80000, 0xc: 0, 0x34: 0}
	var ball := {0x4c: target}
	var gs := {0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs}
	p[0x2c] = 4; p[0x30] = 3; p[0x2b8] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0
	p[0x3a4] = 0x100000; p[0x4] = 0; p[0x8] = 0; p[0xc] = 0

	match name:
		"redirect_special":
			gs[0x2ee] = 1; p[0x5c] = 1
		"special_in_corner":
			gs[0x2ee] = 1; p[0x5c] = 1; p[0x3a4] = -0x100000; p[0x4] = 0x2000000; p[0x8] = 0x200000
		"not_special":
			pass
		"preset_5f_nonspecial":
			p[0x5f] = 1
		"blocked_44c2":
			gs[0x2ee] = 1; p[0x5c] = 1; m[0x44c] = 2
		"long_feed":
			p[0x5f] = 1; target[0x4] = 0x5000000; target[0x8] = 0
		"neg_orient":
			m[0x19a0] = 1; gs[0x2ee] = 1; p[0x5c] = 1
		_:
			return {}
	return {"p": p}


## Oracle reads memory as LE of the given width; our fields may be signed -> wrap to [0, 2^(8w)).
func _wrap(v: int, w: int) -> int:
	return v & ((1 << (8 * w)) - 1)


## A banked [value, width] pair -> unsigned of that width (the emu may report it signed).
func _norm(pair: Variant, w: int) -> Variant:
	if pair == null:
		return null
	return _wrap(int(pair[0]), w)


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
