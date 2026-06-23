extends SceneTree
## STATISTICAL-engine END-TO-END parity: Pm98StatMatch.simulate vs the REAL career-
## match runner FUN_0044ee70 (PS==5 league branch) driven through the Ghidra PCode
## emulator (tools/re/run_statmatch_oracle.sh -> tools/re/specs/statmatch_oracle.txt).
##
## This is the whole-match check: a full LEAGUE fixture (H1 + H2, no extra time / no
## penalties) run draw-for-draw. Every EXPECTED row is BANKED FROM THE EMULATOR:
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
	# extra-time flag (M+0x44) and penalties flag (M+0x48) left 0 -> league match.
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
}


func _init() -> void:
	for name in FIX:
		var f: Dictionary = FIX[name]
		var rng := Pm98StatMatch.Rng.new(f["seed"])
		var mem := _build(f["str0"], f["str1"], f["keeper"], f["pass"])
		Pm98StatMatch.simulate(mem, rng)
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
