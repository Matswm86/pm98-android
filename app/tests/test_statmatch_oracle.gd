extends SceneTree
## STATISTICAL-engine END-TO-END parity: Pm98StatMatch.simulate vs the REAL career-
## match runner FUN_0044ee70 (PS==5 league branch) driven through the Ghidra PCode
## emulator (tools/re/run_statmatch_oracle.sh -> tools/re/specs/statmatch_oracle.txt).
##
## This is the whole-match check: full LEAGUE fixtures (H1 + H2) AND full CUP fixtures
## (H1 + H2 + extra time + penalty shootout) run draw-for-draw. Every EXPECTED row is
## BANKED FROM THE EMULATOR:
##   * draws  -- total rand() draws the emulator traced (stream alignment)
##   * state  -- final msvcrt-LCG state (a second stream-alignment anchor)
##   * events -- the complete goal queue {type(=seg), minute(seg-offset applied), payload}
##   * score  -- goals per team id (7 vs 0x13)
##
## Run: ~/godot462 --headless --path app --script res://tests/test_statmatch_oracle.gd

const POS := [1, 2, 3, 5, 7, 9, 11, 13, 16, 9, 12]
var _fail := 0
var _pass := 0


func _build(str0: int, str1: int, keeper: int, passv: int) -> Pm98StatMatch.Mem:
	var mem := Pm98StatMatch.Mem.new()
	for s in range(2):
		var strg := str0 if s == 0 else str1
		var tid := 0x07 if s == 0 else 0x13
		for i in range(11):
			var pb := Pm98StatMatch._player(s, i)
			mem.set_u16(pb + Pm98StatMatch.SEL, i + 1)
			mem.set_s32(pb + Pm98StatMatch.POS, POS[i])
			mem.set_u8(pb + Pm98StatMatch.STR, strg)
			mem.set_u8(pb + Pm98StatMatch.PASS, passv)
			if i == 0:
				mem.set_u8(pb + Pm98StatMatch.GKSAVE, keeper)
		var sb := s * Pm98StatMatch.SIDE_STRIDE
		mem.set_u16(sb + Pm98StatMatch.TEAMID, tid)
		mem.set_u8(sb + Pm98StatMatch.SHAPE, 0x32)
	# The ET / penalty branch (M+0x44 / M+0x48 + the full-time gate) is driven through
	# simulate()'s run_et / run_pen args rather than these flags (see _init / cup_*).
	return mem


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-22s got=%s exp=%s" % [name, str(got), str(exp)])


# name -> {seed, str0, str1, keeper, pass, draws, state, score7, score19, events:[[type,minute,payload],...]}
var FIX := {
	"league_A": {
		"seed": 0x12345678, "str0": 0x46, "str1": 0x32, "keeper": 0x28, "pass": 0x40,
		"draws": 856, "state": 3281934352, "score7": 3, "score19": 2,
		"events": [[0, 27, 0x60007], [0, 37, 0x90007], [0, 4, 0x90013], [0, 45, 0x60013], [1, 70, 0xb0007]],
	},
	"league_B": {
		"seed": 0x0abcdef1, "str0": 0x3c, "str1": 0x3c, "keeper": 0x28, "pass": 0x40,
		"draws": 836, "state": 3290174789, "score7": 4, "score19": 2,
		"events": [[0, 43, 0x60007], [0, 5, 0x50007], [0, 9, 0x70013], [1, 63, 0x80007], [1, 48, 0x70007], [1, 47, 0x60013]],
	},
	"league_C": {
		"seed": 0x00112233, "str0": 0x50, "str1": 0x28, "keeper": 0x20, "pass": 0x44,
		"draws": 789, "state": 1500429598, "score7": 0, "score19": 1,
		"events": [[0, 14, 0x90013]],
	},
	"league_D": {
		"seed": 0x7eeeeee1, "str0": 0x32, "str1": 0x46, "keeper": 0x30, "pass": 0x38,
		"draws": 891, "state": 3983246610, "score7": 1, "score19": 3,
		"events": [[0, 35, 0xa0007], [0, 9, 0x80013], [1, 77, 0x60013], [1, 86, 0xa0013]],
	},
	# cup_* : same seeds/squads as league_*, but extra time + penalties forced on
	# (run_et = run_pen = true, i.e. the still-level full-time gate). type 2/3 = ET
	# goals, type 4 = penalty-shootout events (no minute, outside the scoreline).
	"cup_A": {
		"cup": true,
		"seed": 0x12345678, "str0": 0x46, "str1": 0x32, "keeper": 0x28, "pass": 0x40,
		"draws": 1314, "state": 4204157906, "score7": 5, "score19": 2,
		"events": [[0, 27, 0x60007], [0, 37, 0x90007], [0, 4, 0x90013], [0, 45, 0x60013],
			[1, 70, 0xb0007], [2, 91, 0x90007], [3, 110, 0x60007], [4, 0, 0xb0007]],
	},
	"cup_B": {
		"cup": true,
		"seed": 0x0abcdef1, "str0": 0x3c, "str1": 0x3c, "keeper": 0x28, "pass": 0x40,
		"draws": 1255, "state": 3935604398, "score7": 4, "score19": 2,
		"events": [[0, 43, 0x60007], [0, 5, 0x50007], [0, 9, 0x70013], [1, 63, 0x80007],
			[1, 48, 0x70007], [1, 47, 0x60013], [4, 0, 0x10007], [4, 0, 0x50007],
			[4, 0, 0x60007], [4, 0, 0xb0013], [4, 0, 0xa0013]],
	},
	"cup_C": {
		"cup": true,
		"seed": 0x00112233, "str0": 0x50, "str1": 0x28, "keeper": 0x20, "pass": 0x44,
		"draws": 1229, "state": 2734095446, "score7": 5, "score19": 1,
		"events": [[0, 14, 0x90013], [2, 98, 0xb0007], [2, 102, 0x90007], [2, 101, 0x60007],
			[2, 100, 0xa0007], [3, 117, 0x40007], [4, 0, 0x20007], [4, 0, 0x50013],
			[4, 0, 0x10013], [4, 0, 0x80013], [4, 0, 0x30013], [4, 0, 0x40013]],
	},
	"cup_D": {
		"cup": true,
		"seed": 0x7eeeeee1, "str0": 0x32, "str1": 0x46, "keeper": 0x30, "pass": 0x38,
		"draws": 1341, "state": 2638942172, "score7": 1, "score19": 6,
		"events": [[0, 35, 0xa0007], [0, 9, 0x80013], [1, 77, 0x60013], [1, 86, 0xa0013],
			[2, 91, 0xa0013], [3, 109, 0x80013], [3, 114, 0x90013], [4, 0, 0xb0007],
			[4, 0, 0x20007], [4, 0, 0x90007], [4, 0, 0xa0007], [4, 0, 0x20007],
			[4, 0, 0x80013], [4, 0, 0xb0013], [4, 0, 0x50013], [4, 0, 0x30013],
			[4, 0, 0x70013], [4, 0, 0x30013]],
	},
}


func _init() -> void:
	for name in FIX:
		var f: Dictionary = FIX[name]
		var rng := Pm98StatMatch.Rng.new(f["seed"])
		var mem := _build(f["str0"], f["str1"], f["keeper"], f["pass"])
		var cup: bool = f.get("cup", false)
		Pm98StatMatch.simulate(mem, rng, cup, cup)
		_ck(name + ".draws", rng.draws, f["draws"])
		_ck(name + ".state", rng.state, f["state"])
		_ck(name + ".count", mem.events.size(), (f["events"] as Array).size())
		var ev: Array = f["events"]
		for i in range(min(mem.events.size(), ev.size())):
			var e: Dictionary = mem.events[i]
			var x: Array = ev[i]
			_ck("%s.ev%d" % [name, i], "%d/%d/0x%x" % [e["type"], e["minute"], e["payload"]],
				"%d/%d/0x%x" % [x[0], x[1], x[2]])
		var sc := Pm98StatMatch.score(mem)
		_ck(name + ".score7", int(sc.get(0x07, 0)), f["score7"])
		_ck(name + ".score19", int(sc.get(0x13, 0)), f["score19"])

	print("test_statmatch_oracle: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
