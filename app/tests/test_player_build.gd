extends SceneTree
## Transcription parity test for Pm98Match._build_team / _build_player -- the per-team 11-
## player roster build (FUN_005b6ba0 -> FUN_005a2830) that kickoff_init drives once a lineup
## is present at team[0x9c]. Run:
##   ~/godot462 --headless --path app --script res://tests/test_player_build.gd
##
## No PCode-emu oracle (FUN_005a2830 reads the career/save player record + globals); this
## LOCKS what is decompile-exact and verifiable from the built Dicts:
##  - the squad-header copy team[0xbf..0xc7],
##  - the player count + the formation-slot active table team[0x4f..],
##  - the keeper/marker role table team[0x5b..] + the role-5/6 captain pick (max +0x39c),
##  - per-player: header back-pointers, team/slot/array index, shirt, the role byte +0x2c8
##    (incl. the GK -> 1 / demarcacion 1 -> 2 home-away adjust), start positions, and the
##    full 0xde..0xe8 derived stat block (GK branches, the e3 match-mode branch, the
##    match-clock fatigue scale, the 0xea/0xeb/0x1c/0x1e derivations) -- all hand-computed
##    here against fixed records, independent of the port code,
##  - the LOAD-BEARING invariant: the whole build draws the match RNG ZERO times (the
##    kickoff 4-draw seed inventory is unchanged whether the roster is empty or full).

const U32 := 0xffffffff
const SEED := 0x12345678

# synthetic session (same shape as test_kickoff_init) so kickoff_init runs cleanly.
const SESSION := {0x4c: 0x6000000, 0x50: 0x4000000, 0xfd8: 1, 0xfdc: 0, 0xff4: 2}

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_build()
	_test_zero_draws()
	_test_kickoff_integration()
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


# --- fixed lineup: GK (slot0) + two role-5 outfielders (slot1, slot2), rest empty. ---
func _gk_record() -> Dictionary:
	return {0x4: 1, 0x28: 0, 0x2c: 1, 0x30: 1, 0x34: 60, 0x35: 70, 0x36: 20, 0x38: 40,
		0x3c: 30, 0x3d: 80, 0x3e: 50, 0x3f: 60, 0x40: 50, 0x41: 70, 0x42: 100, 0x44: 2, 0x98: 0}

func _outfield_record(shirt: int, ability: int) -> Dictionary:
	return {0x4: shirt, 0x8: 11, 0xc: 22, 0x10: 33, 0x14: 44, 0x18: 55, 0x1c: 66, 0x20: 77,
		0x24: 88, 0x28: 111, 0x2c: 3, 0x30: 5, 0x34: 70, 0x35: 80, 0x36: 30, 0x38: 50, 0x3c: 40,
		0x3d: 90, 0x3e: 55, 0x3f: 65, 0x40: ability, 0x41: 75, 0x42: 100, 0x44: 5, 0x98: 1}

func _lineup() -> Dictionary:
	var slots := [_gk_record(), _outfield_record(7, 60), _outfield_record(9, 80)]
	slots.resize(11)                                     # slots 3..10 -> null (absent)
	return {"header": [10, 20, 30, 40, 50, 60, 70, 80, 90], "slots": slots}


func _fresh_match() -> Dictionary:
	var m := Pm98Match.build_match(MatchEngine.Pm98Rng.new(0xDEADBEEF))
	Pm98Match.kickoff_init(m, SESSION.duplicate(), MatchEngine.Pm98Rng.new(SEED))
	# pin the fatigue inputs so the hand-computed stat block holds (kickoff set 0x19ac=0x5460).
	m[0x19ac] = 0
	m[0x19a0] = 0
	return m


func _test_build() -> void:
	var m := _fresh_match()
	var team: Dictionary = m["sim"][0]
	team[0x9c] = _lineup()
	team[0x2ec] = 1                                       # full strength -> no x0x5f/100 reduction
	Pm98Match._build_team(m, 0, team[0x9c], MatchEngine.Pm98Rng.new(SEED))

	var players: Array = team["players"]
	_ok(players.size() == 3, "player count == 3")
	_eqx(_g(team, 0x4), 3, "team[1] count +0x4")

	# squad-header copy team[0xbf..0xc7] = header[0..8].
	for k in range(9):
		_eqx(_g(team, 0xbf + k), (k + 1) * 10, "header copy team[0x%x]" % (0xbf + k))

	var gk: Dictionary = players[0]
	var p1: Dictionary = players[1]
	var p2: Dictionary = players[2]

	# formation-slot active table team[0x4f+slot].
	_ok(team[0x4f + 0] == gk, "active table slot0 = GK")
	_ok(team[0x4f + 1] == p1, "active table slot1 = p1")
	_ok(team[0x4f + 2] == p2, "active table slot2 = p2")
	_eqx(_g(team, 0x4f + 3), 0, "active table slot3 = 0 (empty)")

	# role table team[0x5b + role*2]: GK role(adjusted)=1 -> 0x5d; p1/p2 role5 -> 0x65/0x66.
	_ok(team[0x5b + 1 * 2] == gk, "role table [role1] = GK")
	_ok(team[0x5b + 5 * 2] == p1, "role table [role5] first = p1")
	_ok(team[0x5c + 5 * 2] == p2, "role table [role5] second = p2")

	# captain: role-5/6 max fatigued ability +0x39c. p2(92) > p1(85) -> p2 captain.
	_eqx(int(p2[0x2d6]), 1, "captain flag p2 +0x2d6")
	_eqx(int(p1[0x2d6]), 0, "p1 not captain")
	_eqx(int(gk[0x2d6]), 0, "GK not captain")
	_eqx(_g(team, 0x2e0), (-1) & U32, "team[0xb8] = -1")

	_check_p1(m, p1)
	_check_gk(gk)


func _check_p1(m: Dictionary, p: Dictionary) -> void:
	_ok(p[0x184] == m["sim"][0], "p1 own header +0x61")
	_ok(p[0x188] == m["sim"][1], "p1 opp header +0x62")
	_ok(p[0x18c] == m, "p1 match +0x63")
	_eqx(int(p[0x2b8]), 0, "p1 team idx +0xae")
	_eqx(int(p[0x2bc]), 1, "p1 slot +0xaf")
	_eqx(int(p[0x2c0]), 7, "p1 shirt +0xb0")
	_eqx(int(p[0x2c4]), 1, "p1 array idx +0xb1")
	_eqx(int(p[0x2cc]), 111, "p1 +0xb3 = rec+0x28")
	_eqx(int(p[0x2c8]), 5, "p1 role +0x2c8 (demarcacion 5 unchanged)")
	# start positions rec+8..+0x24.
	_eqx(int(p[0x1f8]), 11, "p1 pos +0x7e"); _eqx(int(p[0x1fc]), 22, "p1 pos +0x7f")
	_eqx(int(p[0x200]), 0, "p1 pos +0x80 = 0"); _eqx(int(p[0x204]), 33, "p1 pos +0x81")
	_eqx(int(p[0x228]), 55, "p1 pos +0x8a"); _eqx(int(p[0x234]), 88, "p1 pos +0x8d")
	_eqx(int(p[0x2da]), 1, "p1 byte +0x2da (rec+0x98)")
	_eqx(int(p[0x36c]), 4, "p1 +0xdb = rec+0x30-1")
	_eqx(int(p[0x370]), 2, "p1 +0xdc = rec+0x2c-1")
	_eqx(int(p[0x2d0]), 60, "p1 fitness +0xb4 clamp(100->0x3c)")
	_eqx(int(p[0x2dc]), 0, "p1 +0xb7 = (0+0)*0x100+0")
	# derived stat block (hand-computed: clk=36000, m19a0=0, full strength).
	_eqx(int(p[0x378]), 70, "p1 0xde = rec+0x34")
	_eqx(int(p[0x37c]), 92, "p1 0xdf fatigued (80 -> 92)")
	_eqx(int(p[0x380]), 30, "p1 0xe0 = rec+0x36")
	_eqx(int(p[0x388]), 81, "p1 0xe2 fatigued (50 -> 81)")
	_eqx(int(p[0x38c]), 80, "p1 0xe3 branch ((40+200)/3)")
	_eqx(int(p[0x390]), 90, "p1 0xe4 = rec+0x3d")
	_eqx(int(p[0x394]), 55, "p1 0xe5 = rec+0x3e (outfield)")
	_eqx(int(p[0x398]), 65, "p1 0xe6 = rec+0x3f")
	_eqx(int(p[0x39c]), 85, "p1 0xe7 ability fatigued (60 -> 85)")
	_eqx(int(p[0x3a0]), 90, "p1 0xe8 fatigued (75 -> 90)")
	_eqx(int(p[0x3a8]), 4423, "p1 0xea derived")
	_eqx(int(p[0x3ac]), 2850, "p1 0xeb derived")
	_eqx(int(p[0x70]), 9800, "p1 0x1c = 0xde*0x8c")
	_eqx(int(p[0x74]), 9800, "p1 0x1d = 0xde*0x8c")
	_eqx(int(p[0x78]), 110, "p1 0x1e = 0x78 - 0xe0/3")


func _check_gk(p: Dictionary) -> void:
	_eqx(int(p[0x2bc]), 0, "GK slot +0xaf = 0")
	_eqx(int(p[0x2c8]), 1, "GK role +0x2c8 forced to 1")
	_eqx(int(p[0x394]), 100, "GK 0xe5 forced to 100")
	_eqx(int(p[0x37c]), 96, "GK 0xdf = ((70+200)/3=90) fatigued -> 96")
	_eqx(int(p[0x39c]), 81, "GK 0xe7 ability fatigued (50 -> 81)")
	_eqx(int(p[0x2dc]), 0x100, "GK +0xb7 = (1+0)*0x100")


func _test_zero_draws() -> void:
	var m := _fresh_match()
	var team: Dictionary = m["sim"][0]
	team[0x9c] = _lineup()
	var rng := MatchEngine.Pm98Rng.new(SEED)
	var before := rng.state
	Pm98Match._build_team(m, 0, team[0x9c], rng)
	_eqx(rng.state, before, "LOAD-BEARING: _build_team drew 0 (rng state unchanged)")


func _test_kickoff_integration() -> void:
	# lineups present on BOTH teams BEFORE kickoff -> the build runs mid-kickoff but adds 0
	# draws, so kickoff still consumes EXACTLY 4 (side + 3 timers).
	var m := Pm98Match.build_match(MatchEngine.Pm98Rng.new(0xDEADBEEF))
	m["sim"][0][0x9c] = _lineup()
	m["sim"][1][0x9c] = _lineup()
	var live := MatchEngine.Pm98Rng.new(SEED)
	Pm98Match.kickoff_init(m, SESSION.duplicate(), live)

	var ref := MatchEngine.Pm98Rng.new(SEED)
	for i in range(4):
		ref.next()
	_eqx(live.state, ref.state, "kickoff+full roster drew EXACTLY 4 (build = 0)")
	_eqx(int(m["sim"][0][0x4]), 3, "team0 built 3 players in kickoff")
	_eqx(int(m["sim"][1][0x4]), 3, "team1 built 3 players in kickoff")


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _eqx(got: int, want: int, msg: String) -> void:
	_ok((got & U32) == (want & U32), "%s: got 0x%x want 0x%x" % [msg, got & U32, want & U32])


func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))
