extends SceneTree
## Oracle-backed parity test for FUN_005ab5a0 (the post-shot / loose-ball resolution), ported as
## Pm98Movement.resolve_post_shot. Run:
##   ~/godot462 --headless --path app --script res://tests/test_postshot.gd
## ORACLE = the REAL FUN_005ab5a0 under the PCode emulator (tools/re/run_postshot_oracle.sh ->
## specs/postshot_oracle.txt). Each block:  "## FIX <name>" then 0+ "CALL 0 STUB ENQ ... arg0=<code>"
## (the match-event enqueues, in order) then a "CALL 0 RET ... mem[0xADDR:N]=VAL ..." line (the banked
## sim residue + the rng seed at 0x6d3184). The fixture INPUTS are mirrored here from the shell pokes;
## the oracle banks the OUTPUTS only. Object pointers map: player=0x230000(2293760), match/ball=cleared.

const SEED := 0x12345678
const PLAYER_ADDR := 0x230000     # 2293760 -- the only non-null pointer the residue ever holds

var _fail := 0
var _pass := 0


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/postshot_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "postshot oracle unreadable (run tools/re/run_postshot_oracle.sh)")
	else:
		var name := ""
		var enq: Array = []
		var rx_enq := RegEx.new()
		rx_enq.compile("STUB ENQ .* arg0=(-?\\d+)")
		var rx_mem := RegEx.new()
		rx_mem.compile("mem\\[0x([0-9a-f]+):\\d+\\]=(-?\\d+)")
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.begins_with("## FIX "):
				name = line.substr(7)
				enq = []
			elif line.find("STUB ENQ") != -1:
				enq.append(rx_enq.search(line).get_string(1).to_int())
			elif line.find(" RET ") != -1 and name != "":
				var mems := {}
				for m in rx_mem.search_all(line):
					mems[("0x" + m.get_string(1)).hex_to_int()] = m.get_string(2).to_int()
				_check(name, mems, enq)
				name = ""
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


## Build the fixture, run the port, and compare every banked field + enqueue order + the rng seed.
func _check(name: String, mems: Dictionary, enq: Array) -> void:
	var fx := _fixture(name)
	if fx.is_empty():
		_ok(false, "%s: no fixture builder" % name)
		return
	var p: Dictionary = fx["p"]
	var m: Dictionary = p[0x18c]
	var ball: Dictionary = p[0x190]
	var p184: Dictionary = p[0x184]
	var stat: Dictionary = p[0x3b8]
	var rng := MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.resolve_post_shot(p, fx["teammates"], rng)

	# pointer + scalar residue (addr -> live dict field), translated through _av.
	_eq(name, "ball+0x50", _av(ball.get(0x50), p), mems.get(0x270050))
	_eq(name, "ball+0x64", _av(ball.get(0x64), p), mems.get(0x270064))
	_eq(name, "ball+0x40", _av(ball.get(0x40), p), mems.get(0x270040))
	_eq(name, "ball+0x44", _av(ball.get(0x44), p), mems.get(0x270044))
	_eq(name, "ball+0x48", _av(ball.get(0x48), p), mems.get(0x270048))
	_eq(name, "ball+0x4c", _av(ball.get(0x4c), p), mems.get(0x27004c))
	_eq(name, "ball+0x54", _av(ball.get(0x54), p), mems.get(0x270054))
	_eq(name, "ball+0x80", _av(ball.get(0x80), p), mems.get(0x270080))
	_eq(name, "player+0x54", _av(p.get(0x54), p), mems.get(0x230054))
	_eq(name, "player+0x58", _av(p.get(0x58), p), mems.get(0x230058))
	_eq(name, "match+0x43c", _av(m.get(0x43c), p), mems.get(0x26043c))
	_eq(name, "match+0x460", _av(m.get(0x460), p), mems.get(0x260460))
	_eq(name, "match+0x438", _av(m.get(0x438), p), mems.get(0x260438))
	_eq(name, "match+0x458", _av(m.get(0x458), p), mems.get(0x260458))
	_eq(name, "stat+0x88", _av(stat.get(0x88), p), mems.get(0x2b0088))
	_eq(name, "P184+0x2e4", _av(p184.get(0x2e4), p), mems.get(0x2802e4))
	_eq(name, "rng seed", rng.state, mems.get(0x6d3184))

	# enqueue codes, in order.
	var got_codes: Array = []
	for ev in m.get(0x1a24, []):
		got_codes.append(int(ev[0]))
	_ok(got_codes == enq, "%s enqueue: got %s want %s" % [name, got_codes, enq])


## A residue field translated to the oracle integer: the player pointer -> 2293760, null/unset -> 0,
## a plain scalar -> itself. (No residue field ever holds any pointer other than the player.)
func _av(v: Variant, p: Dictionary) -> int:
	if v is Dictionary:
		return PLAYER_ADDR if v == p else -0xBAD   # the only pointer the residue holds is the player
	if v == null:
		return 0
	return int(v)


## Mirror of the shell-fixture pokes (run_postshot_oracle.sh). All structs are dicts; refs wired as
## p[0x18c]=match, p[0x190]=ball, p[0x184]=P184, p[0x3b8]=stat, ball[0x1d4]=match.
func _fixture(name: String) -> Dictionary:
	var m := {}
	var ball := {0x1d4: m}
	var p184 := {}
	var stat := {}
	var p := {0x18c: m, 0x190: ball, 0x184: p184, 0x3b8: stat}
	var teammates: Array = []
	match name:
		"tail_438":
			p[0x40] = 0x13
			m[0x438] = p
			ball[0x4c] = p                      # owned by self -> contested stat fires
			p[0x4] = 0x200000
			p[0x3a4] = 0
		"enq10", "enq10_skip":
			p[0x40] = 2
			m[0x1820] = 0x200000
			p[0x4] = 0x100000
			p[0x8] = 0x200000
			p[0x3a4] = -1
			ball[0xcc] = 0x400000
			ball[0xd0] = 0x200000
			m[0x44c] = 4 if name == "enq10_skip" else 0
			m[0x438] = p
		"passhit":
			p[0x40] = 2
			p[0x4] = 0
			p[0x3a4] = -1
			ball[0x20] = 0x100000
			ball[0x4c] = {0x190: ball, 0x18c: m, 0x4: 0, 0x3a4: 0}   # owner owns the ball -> 5b0bb0 hits
			m[0x448] = 0
		"keeper_inc", "keeper_noinc":
			p[0x40] = 2
			p[0x4] = 0
			p[0x8] = 0
			p[0xa0] = 0
			p[0xa4] = 0
			m[0x1820] = 0x100000
			p[0x34] = 0x4000 if name == "keeper_noinc" else 0   # facing off the goal -> no inc
			p[0x3a4] = 0x100000
			m[0x448] = 1
		"passteam_keeper":
			p[0x40] = 2
			p[0x4] = 0
			p[0x8] = 0
			p[0xa0] = 0
			p[0xa4] = 0
			m[0x1820] = 0x100000
			p[0x34] = 0
			p[0x3a4] = 0x100000
			m[0x448] = 0
			ball[0x20] = -1                     # sign(anchor) != sign(ball+0x20) -> enter pass-block
			teammates = [{0x190: ball, 0x18c: m}]   # one teammate that hits the capsule -> early tail
		"enq0e":
			p[0x40] = 2
			m[0x1820] = 0x200000
			p[0x4] = 0x100000
			p[0x8] = 0x200000
			p[0x3a4] = 1
			p[0xa0] = 0
			m[0x448] = 1
			ball[0x4c] = {}                     # owned (any non-null) -> contested stat
			ball[0x48] = {0x2b8: 1}             # an opponent of a different team -> the 0xe branch
			ball[0xc] = 0
		"classify_draw":
			p[0x40] = 2
			p[0x4] = -1
			p[0x8] = 0
			p[0xa0] = 0
			p[0xa4] = 0
			m[0x1820] = 0x200000
			p[0x3a4] = 1
			m[0x448] = 1
			ball[0x4c] = {}                     # owned -> classification ladder (the lone rng draw)
		_:
			return {}
	return {"p": p, "teammates": teammates}


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
