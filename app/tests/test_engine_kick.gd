extends SceneTree
## Oracle-backed INTEGRATION parity test (handoff item 1 -- the KICK tail + the pass-block roster scan).
## Drives Pm98Action.engine_tick all the way through a Family-A KICK action handler AND on into the
## post-shot resolution:
##   engine_tick (FUN_005a4600) -> kick_resolve (FUN_005ae4c0, action 0x14) -> resolve_post_shot (FUN_005ab5a0)
## and asserts the full residue + rng draw count against the REAL chain run end-to-end under the Ghidra
## PCode emulator (tools/re/run_engine_kick_oracle.sh -> specs/engine_kick_oracle.txt; kick_resolve +
## resolve_post_shot run REAL, only the off-path handlers / setup_shot / resolver / teammate-count / 5
## movement fns / TRAIL / ENQ / kick EFFECT / AUDIO stay stubbed). It is the kick counterpart to
## test_engine_cascade.gd (the acc40 -> setup_shot tail) and CLOSES the gs[0] roster-threading gap that
## test left deferred: the kick handler threads _ref(p,0x184).get(0,[]) into resolve_post_shot, and the
## kick_passblock fixture forces the pass-target scan over that threaded roster (oracle: PASS trace fired).
##
##   kick_tail      -- match+0x438 == player -> resolve_post_shot short-circuits to the tail; proves the
##                     engine -> kick_handler -> resolve_post_shot DIRECT composition reaches set_phase(0).
##   kick_passblock -- match+0x438 != player, side_neg -> ball+0x20 < 0 -> sign(anchor) != sign(ball+0x20):
##                     the pass scan runs; a teammate at the shooter (scale 0) hits the capsule. The
##                     threaded gs[0] roster is the ONLY thing that delivers that teammate to the scan.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_engine_kick.gd

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
	# kick_resolve residue (launch velocity + cleared touch + ball flags + match flag)
	[0x270020, "ball", 0x20, 4], [0x270024, "ball", 0x24, 4], [0x270028, "ball", 0x28, 4],
	[0x230054, "p", 0x54, 4], [0x230058, "p", 0x58, 4], [0x27004c, "ball", 0x4c, 4], [0x270070, "ball", 0x70, 4],
	[0x260462, "m", 0x462, 4], [0x270064, "ball", 0x64, 4],
	# resolve_post_shot residue (engage + set_phase(0) + counters)
	[0x270050, "ball", 0x50, 4], [0x270040, "ball", 0x40, 4], [0x270044, "ball", 0x44, 4],
	[0x270048, "ball", 0x48, 4], [0x270054, "ball", 0x54, 4], [0x270080, "ball", 0x80, 4],
	[0x260438, "m", 0x438, 4], [0x26043c, "m", 0x43c, 4], [0x260458, "m", 0x458, 4],
	[0x260460, "m", 0x460, 1], [0x260448, "m", 0x448, 4], [0x26044c, "m", 0x44c, 4],
	[0x2b0088, "stat", 0x88, 4], [0x2802e4, "gs", 0x2e4, 4],
]


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/engine_kick_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "engine kick oracle unreadable (run tools/re/run_engine_kick_oracle.sh)")
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
	var p: Dictionary = built["p"]
	var stores := {
		"p": p, "ball": p[0x190], "m": p[0x18c], "gs": p[0x184], "stat": p[0x3b8],
	}
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Action.engine_tick(p, p[0x18c], rng)

	# Pointer fields hold a player/struct Dict ref after the cascade (engage writes ball+0x44/48/50 = P).
	# The oracle reports them as the region base ADDRESS; map our refs back to that address.
	var addr_of := {0x230000: p, 0x270000: stores["ball"], 0x260000: stores["m"],
		0x280000: stores["gs"], 0x2b0000: stores["stat"], 0x2a0000: built.get("tm0")}

	for r in READS:
		var struct: Dictionary = stores[r[1]]
		var v: Variant = struct.get(r[2], 0)
		var got: int = _wrap(_field_addr(v, addr_of), r[3])
		_eq(name, "%s+0x%x" % [r[1], r[2]], got, _norm(mems.get(r[0]), r[3]))

	_eq(name, "rng seed (2 draws)", rng.state, _norm(mems.get(0x6d3184), 4))


## A field value -> the int the oracle banked. Scalar ints pass through; a Dict ref maps to its region
## base address (identity match against the known structs); an unknown ref is a hard -0xBAD sentinel.
func _field_addr(v: Variant, addr_of: Dictionary) -> int:
	if v is Dictionary:
		for base in addr_of:
			if addr_of[base] != null and is_same(addr_of[base], v):
				return base
		return -0xBAD
	return int(v)


## Mirror of run_engine_kick_oracle.sh (FRAME + KICK + RESCOM + per-fixture). Linked Dicts: p[0x18c]=match,
## p[0x190]=ball, p[0x184]=gs/P184, p[0x3b8]=stat, p[0x188]=[tm0] (kick tm-array), ball[0x1d4]=match,
## tm0[0x190]=ball / tm0[0x18c]=match. kick_tail: match[0x438]=p (-> resolve to_tail). kick_passblock:
## p[0x2b8]=1 (side_neg -> ball+0x20 < 0) and gs[0]=[tm0] (the threaded pass-scan roster).
func _fixture(name: String) -> Dictionary:
	var stat := {}
	var m := {
		0x1820: 0x300000, 0x19a0: 0,            # goal geometry (raw goalx; side picked by p+0x2b8)
		0x448: 0, 0x460: 0, 0x44c: 3,           # open play; no stale taker; +0x44c nonzero -> set_phase(0) drives it to 0
		0x180a: 0,                              # headless display gate
	}
	var ball := {0x4c: 0, 0x1d4: m, 0x70: 100, 0x63: 0, 0x20: 0x30000, 0x24: 0x40000, 0x28: 0}
	var tm0 := {0x18c: m, 0x190: ball, 0x2b8: 0, 0x2c4: 0, 0x188: []}
	var gs := {}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x3b8: stat, 0x188: [tm0]}
	# FRAME: action 0x14, frame guard p+0x2c=8 / p+0x30=3 (->0 after tick_action with +0x48 locked), +0x88=0.
	p[0x40] = 0x14; p[0x2c] = 8; p[0x30] = 3; p[0x48] = 5; p[0x88] = 0
	p[0x4] = 0; p[0x8] = 0; p[0xc] = 0; p[0x3a4] = 0x100000; p[0x2bc] = 1
	p[0xa0] = 0; p[0xa4] = 0                     # aim == player pos -> scale 0 in the pass capsule
	# KICK inputs: speed from ball vel (3,4,0)<<16 (perfect square 0x50000); touch 10; acc/power 50; min path.
	p[0x54] = 10; p[0x39c] = 50; p[0x388] = 50; p[0xb8] = 0x7fff; p[0x34] = 0
	if name == "kick_tail":
		m[0x438] = p                            # controlled -> resolve_post_shot to_tail (no roster scan)
		p[0x2b8] = 0
	else:                                       # kick_passblock
		p[0x2b8] = 1                            # side_neg -> goalx negated -> ball+0x20 < 0 -> pass scan entered
		gs[0] = [tm0]                          # the threaded roster (binary reads **(int**)(p+0x184))
	return {"p": p, "tm0": tm0}


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
