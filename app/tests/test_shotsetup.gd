extends SceneTree
## Oracle-backed parity test for FUN_005ac1a0 (the shot / trajectory setup), ported as
## Pm98Movement.setup_shot. Run:
##   ~/godot462 --headless --path app --script res://tests/test_shotsetup.gd
## ORACLE = the REAL FUN_005ac1a0 under the PCode emulator (tools/re/run_shotsetup_oracle.sh ->
## specs/shotsetup_oracle.txt; FUN_005ab5a0 stubbed there). Each "## FIX <name>" then a "CALL 0 RET ...
## mem[0xADDR:N]=VAL ..." line banks the OUTPUTS (landing ball+0x84/88/8c, velocity ball+0x20/24/28,
## ball+0x70, player+0x54/58, the FUN_0058f100 copy ball+0x90/94/98, and the rng seed 0x6d3184). We
## run setup_shot with call_resolve=false so the seed reflects ONLY this function's draws (matching the
## stubbed oracle); resolve_post_shot is verified separately and never overwrites these ball writes.
## Fixture INPUTS mirror the shell pokes; ball pos / player pos at origin unless overridden.

const SEED := 0x12345678
var _fail := 0
var _pass := 0

# oracle byte-address -> (struct, field) the value lives in.
const READS := [
	[0x270084, "ball", 0x84], [0x270088, "ball", 0x88], [0x27008c, "ball", 0x8c],
	[0x270020, "ball", 0x20], [0x270024, "ball", 0x24], [0x270028, "ball", 0x28],
	[0x270070, "ball", 0x70],
	[0x230054, "p", 0x54], [0x230058, "p", 0x58],
	[0x270090, "ball", 0x90], [0x270094, "ball", 0x94], [0x270098, "ball", 0x98],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/shotsetup_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "shotsetup oracle unreadable (run tools/re/run_shotsetup_oracle.sh)")
	else:
		var name := ""
		var rx_mem := RegEx.new()
		rx_mem.compile("mem\\[0x([0-9a-f]+):\\d+\\]=(-?\\d+)")
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.begins_with("## FIX "):
				name = line.substr(7)
			elif line.find(" RET ") != -1 and name != "":
				var mems := {}
				for m in rx_mem.search_all(line):
					mems[("0x" + m.get_string(1)).hex_to_int()] = m.get_string(2).to_int()
				_check(name, mems)
				name = ""
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _check(name: String, mems: Dictionary) -> void:
	var fx := _fixture(name)
	if fx.is_empty():
		_ok(false, "%s: no fixture builder" % name)
		return
	var p: Dictionary = fx
	var ball: Dictionary = p[0x190]
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.setup_shot(p, [], rng, false)        # call_resolve=false: isolate FUN_005ac1a0

	for r in READS:
		var struct: Dictionary = ball if r[1] == "ball" else p
		_eq(name, "%s+0x%x" % [r[1], r[2]], _i32u(int(struct.get(r[2], 0))), mems.get(r[0]))
	_eq(name, "rng seed", rng.state, mems.get(0x6d3184))


## The oracle reads memory as UNSIGNED LE; our int32 fields may be negative -> wrap to [0, 2^32).
func _i32u(v: int) -> int:
	return v & 0xffffffff


## Mirror of run_shotsetup_oracle.sh (BASE + per-fixture pokes). Refs: p[0x18c]=match, p[0x190]=ball,
## ball[0x1d4]=match. Returns the player dict (ball/match reachable through it).
func _fixture(name: String) -> Dictionary:
	var m := {0x1820: 0x300000}
	var ball := {0x1d4: m, 0x70: 100}
	var p := {0x18c: m, 0x190: ball}
	ball[0x40] = p                                    # shooter controls ball -> guard short-circuits
	# BASE
	p[0x40] = 2
	p[0xa0] = 0x200000; p[0xa4] = 0x40000; p[0xa8] = 0
	p[0x3a4] = -1; p[0x2bc] = 1
	p[0x3a0] = 70; p[0x394] = 80; p[0x54] = 5; p[0x58] = 6
	p[0x70] = 8000
	match name:
		"cvar0_owned":
			p[0x5e] = 0; ball[0x4c] = {}
		"bVar2_true":
			p[0x5e] = 0; ball[0x4c] = {}; p[0xa0] = 0x60000; p[0xa4] = 0
		"cvar1_owned":
			p[0x5e] = 1; ball[0x4c] = {}
		"unowned":
			p[0x5e] = 1
		"cvar0_unowned":
			p[0x5e] = 0
		"action13":
			p[0x5e] = 1; ball[0x4c] = {}; p[0x40] = 0x13
		"action37":
			p[0x5e] = 1; ball[0x4c] = {}; p[0x40] = 0x37
		"phase44c6":
			p[0x5e] = 0; ball[0x4c] = {}; m[0x44c] = 6
		"phase44c4":
			p[0x5e] = 1; ball[0x4c] = {}; m[0x44c] = 4
		"aim_goal":
			p[0x5e] = 1; ball[0x4c] = {}
			m[0x1828] = 0x100000; m[0x182c] = 0; m[0x1830] = -0x100000
			m[0x1834] = 0x280000; m[0x1838] = 0x100000; m[0x183c] = 0x100000
		"late2bc":
			p[0x5e] = 1; ball[0x4c] = {}; p[0x2bc] = 0
			p[0x4] = -0x200000; p[0x8] = 0x40000; p[0xc] = 0
			m[0x1828] = -0x280000; m[0x182c] = 0; m[0x1830] = -0x100000
			m[0x1834] = -0x100000; m[0x1838] = 0x100000; m[0x183c] = 0x100000
		"clamp70":
			p[0x5e] = 1; ball[0x4c] = {}; ball[0x70] = 2
		"touch_lt4":
			p[0x5e] = 0; ball[0x4c] = {}; p[0x54] = 1; p[0x58] = 2
		"skip":
			p[0x5e] = 1; ball[0x4c] = {}
			ball[0x40] = {0x4: 0x111, 0x8: 0x222, 0xc: 0x333}   # engaged != shooter
			ball[0x63] = 1; m[0x448] = 0
		_:
			return {}
	return p


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
