extends SceneTree
## Oracle-backed INTEGRATION parity test (Task #4b item 4 -- the handler cascade / set_phase(0) lever).
## Drives Pm98Action.engine_tick all the way through a Family-A action handler AND its nested cascade leaf:
##   engine_tick (FUN_005a4600) -> goal_aim_025 (FUN_005acc40, action 4) -> setup_shot (FUN_005ac1a0)
##     -> resolve_post_shot (FUN_005ab5a0)
## and asserts the full residue + rng draw count against the REAL chain run end-to-end under the Ghidra
## PCode emulator (tools/re/run_engine_cascade_oracle.sh -> specs/engine_cascade_oracle.txt; acc40 +
## setup_shot run REAL, resolve_post_shot reached transitively + REAL, only the 6 off-path handlers /
## resolver / teammate-count / 5 movement fns / TRAIL / ENQ stay stubbed). This is the first test of the
## engine->handler->setup_shot->resolve_post_shot COMPOSITION -- i.e. that the call_setup=true wiring in
## Pm98Action._action_switch reaches set_phase(0) bit-for-bit. The per-leaf ports are separately GREEN
## (test_engine_tick / test_acc40 / test_shotsetup / test_postshot).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_engine_cascade.gd
##
## NOTE: the fixture drives resolve_post_shot's to_tail path (match+0x438 == player), so the pass/keeper/
## classify blocks (and the gs[0] roster threading) are NOT exercised here -- that is the deferred
## pass-block fixture (see handoff). The seed advances 5x (all inside setup_shot; acc40 + the tail draw 0).

const SEED := 0x12345678
const U32 := 0xffffffff
var _fail := 0
var _pass := 0

# oracle byte-address -> [struct-key, field-offset, width]. struct-key picks the linked Dict.
const READS := [
	# engine_tick skeleton residue
	[0x2302d7, "p", 0x2d7, 1], [0x2302d8, "p", 0x2d8, 1],
	[0x23002c, "p", 0x2c, 4], [0x230030, "p", 0x30, 4], [0x230040, "p", 0x40, 4], [0x230048, "p", 0x48, 4],
	[0x230050, "p", 0x50, 4], [0x23006c, "p", 0x6c, 4], [0x230088, "p", 0x88, 4],
	# acc40 (goal_aim_025) residue
	[0x270062, "ball", 0x62, 1], [0x23005e, "p", 0x5e, 1], [0x23005f, "p", 0x5f, 1],
	[0x2300a0, "p", 0xa0, 4], [0x2300a4, "p", 0xa4, 4], [0x2300a8, "p", 0xa8, 4],
	# setup_shot residue (landing + velocity + ball+0x70 + cleared touch)
	[0x270084, "ball", 0x84, 4], [0x270088, "ball", 0x88, 4], [0x27008c, "ball", 0x8c, 4],
	[0x270020, "ball", 0x20, 4], [0x270024, "ball", 0x24, 4], [0x270028, "ball", 0x28, 4],
	[0x270070, "ball", 0x70, 4], [0x230054, "p", 0x54, 4], [0x230058, "p", 0x58, 4],
	# resolve_post_shot residue (engage + set_phase(0) + counters)
	[0x270050, "ball", 0x50, 4], [0x270064, "ball", 0x64, 1], [0x270040, "ball", 0x40, 4],
	[0x270044, "ball", 0x44, 4], [0x270048, "ball", 0x48, 4], [0x27004c, "ball", 0x4c, 4],
	[0x270054, "ball", 0x54, 4], [0x270080, "ball", 0x80, 4],
	[0x260438, "m", 0x438, 4], [0x26043c, "m", 0x43c, 4], [0x260458, "m", 0x458, 4],
	[0x260460, "m", 0x460, 1], [0x260448, "m", 0x448, 4],
	[0x2b0088, "stat", 0x88, 4], [0x2802e4, "gs", 0x2e4, 4],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/engine_cascade_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "engine cascade oracle unreadable (run tools/re/run_engine_cascade_oracle.sh)")
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
	var built := _fixture()
	var p: Dictionary = built["p"]
	var stores := {
		"p": p, "ball": p[0x190], "m": p[0x18c], "gs": p[0x184], "stat": p[0x3b8],
	}
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Action.engine_tick(p, p[0x18c], rng)

	# Pointer fields hold a player/struct Dict ref after the cascade (engage writes ball+0x44/48/50 = P).
	# The oracle reports them as the region base ADDRESS; map our refs back to that address.
	var addr_of := {0x230000: p, 0x270000: stores["ball"], 0x260000: stores["m"],
		0x280000: stores["gs"], 0x2b0000: stores["stat"], 0x2a0000: p[0x190].get(0x4c)}

	for r in READS:
		var struct: Dictionary = stores[r[1]]
		var v: Variant = struct.get(r[2], 0)
		var got: int = _wrap(_field_addr(v, addr_of), r[3])
		_eq(name, "%s+0x%x" % [r[1], r[2]], got, _norm(mems.get(r[0]), r[3]))

	_eq(name, "rng seed (5 draws)", rng.state, _norm(mems.get(0x6d3184), 4))


## A field value -> the int the oracle banked. Scalar ints pass through; a Dict ref maps to its region
## base address (identity match against the known structs); an unknown ref is a hard -0xBAD sentinel.
func _field_addr(v: Variant, addr_of: Dictionary) -> int:
	if v is Dictionary:
		for base in addr_of:
			if is_same(addr_of[base], v):
				return base
		return -0xBAD
	return int(v)


## Mirror of run_engine_cascade_oracle.sh (FRAME + ACC40 + SETUP + RESOLVE + PTRS). Linked Dicts:
## p[0x18c]=match, p[0x190]=ball, p[0x184]=gs/P184, p[0x3b8]=stat, ball[0x4c]=target, ball[0x1d4]=match,
## match[0x468]=play-state, match[0x438]=p (is-controlled -> resolve_post_shot to_tail).
func _fixture() -> Dictionary:
	var target := {0x4: 0x1000000, 0x8: 0x80000, 0xc: 0, 0x34: 0}
	var stat := {}
	var playstate := {0xfa0: 0}
	var m := {
		# ACC40 goal geometry
		0x1820: 0x2000000, 0x19a0: 0, 0x44c: 0, 0x180a: 0,
		0x1828: 0x1000000, 0x182c: -0x800000, 0x1830: -0x100000,
		0x1834: 0x3000000, 0x1838: 0x800000, 0x183c: 0x100000,
		# RESOLVE: match+0x460 = 0 (no stale taker), match+0x448 = 0 (open play)
		0x460: 0, 0x448: 0,
		0x468: playstate,
	}
	var ball := {0x4c: target, 0x1d4: m, 0x70: 100, 0x40: 0, 0x63: 0}
	var gs := {0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x3b8: stat}
	# FRAME: action 4, frame guard p+0x2c=4 / p+0x30=2 (->3 after tick_action with +0x48 locked), +0x88=0.
	p[0x40] = 4; p[0x2c] = 4; p[0x30] = 2; p[0x48] = 5; p[0x88] = 0
	p[0x3a4] = 0x100000; p[0x4] = 0; p[0x8] = 0; p[0xc] = 0; p[0x2bc] = 1
	# ACC40 non-special inputs
	p[0x5c] = 0; p[0x2b8] = 0
	# SETUP inputs (ball owned -> skill +0x394; cvar4=0; touch +0x54/58; rating +0x70)
	p[0x394] = 80; p[0x3a0] = 70; p[0x70] = 8000; p[0x54] = 5; p[0x58] = 6; p[0x5e] = 0
	# RESOLVE: match+0x438 = the player -> to_tail
	m[0x438] = p
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
	_ok(got == int(want), "%s %s: got 0x%x want 0x%x" % [name, field, got & U32, int(want) & U32])


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
