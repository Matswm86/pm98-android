extends SceneTree
## STATISTICAL-engine leaf parity: Pm98StatMatch._resolve vs the REAL chance/
## goal resolver FUN_0044ece0 driven through the Ghidra PCode emulator
## (tools/re/run_statresolve_oracle.sh -> tools/re/specs/statresolve_oracle.txt).
## Every EXPECTED row below is BANKED FROM THE EMULATOR: count (1=goal event, 0=
## keeper save), event type (= seg), event minute (seg-offset applied by FUN_004510b0),
## and the payload (scorerShirt<<16 | teamId). The injected msvcrt-LCG rand() and the
## GDScript Rng share constants + seed, so the rand stream -- and thus the scorer the
## roulette lands on -- matches draw-for-draw.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_statresolve_oracle.gd
##
## Each fixture builds the emulator's match struct in a flat Pm98StatMatch.Mem: two
## XIs (shirts 1..11 at +0x88, position codes [1,2,3,5,7,9,11,13,16,9,12] at +0xc8),
## team ids 0x07/0x13, and the defending keeper's save byte (+0xc0). gk_out clears
## the defending keeper's shirt so the save gate is skipped.

const POS := [1, 2, 3, 5, 7, 9, 11, 13, 16, 9, 12]
var _fail := 0
var _pass := 0


func _build_match(side: int, keeper: int, defender_gk_in: bool) -> Pm98StatMatch.Mem:
	var mem := Pm98StatMatch.Mem.new()
	for s in range(2):
		var tid := 0x07 if s == 0 else 0x13
		for i in range(11):
			var pb := Pm98StatMatch._player(s, i)
			mem.set_u16(pb + Pm98StatMatch.SEL, i + 1)
			mem.set_s32(pb + Pm98StatMatch.POS, POS[i])
			if i == 0:
				mem.set_u8(pb + Pm98StatMatch.GKSAVE, keeper)
		mem.set_u16(s * Pm98StatMatch.SIDE_STRIDE + Pm98StatMatch.TEAMID, tid)
	if not defender_gk_in:
		var defender := 1 - side
		mem.set_u16(Pm98StatMatch._player(defender, 0) + Pm98StatMatch.SEL, 0)
	return mem


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-16s got=%s exp=%s" % [name, str(got), str(exp)])


# Fixture: name -> {seed, side, seg, minute, keeper, gk_in}. Mirrors the oracle's
# FIX array in tools/re/run_statresolve_oracle.sh exactly.
var FIX := {
	"goal_seg0_sh5":   {"seed": 0x1007, "side": 0, "seg": 0, "min": 7,  "keeper": 0x28, "gk_in": true},
	"goal_seg1_sh9":   {"seed": 0x1015, "side": 0, "seg": 1, "min": 20, "keeper": 0x28, "gk_in": true},
	"goal_seg2_sh11":  {"seed": 0x101c, "side": 0, "seg": 2, "min": 33, "keeper": 0x28, "gk_in": true},
	"goal_seg3_sh7":   {"seed": 0x103f, "side": 0, "seg": 3, "min": 11, "keeper": 0x28, "gk_in": true},
	"save_keep40":     {"seed": 0x1,    "side": 0, "seg": 0, "min": 7,  "keeper": 0x28, "gk_in": true},
	"lowkeep_goal6":   {"seed": 0x100e, "side": 0, "seg": 0, "min": 5,  "keeper": 0x03, "gk_in": true},
	"side1_goal_sh5":  {"seed": 0x1007, "side": 1, "seg": 0, "min": 22, "keeper": 0x28, "gk_in": true},
	"gkout_goal_sh2":  {"seed": 0x3,    "side": 0, "seg": 0, "min": 9,  "keeper": 0x28, "gk_in": false},
}

# EXPECTED -- BANKED FROM THE PCODE EMULATOR (tools/re/specs/statresolve_oracle.txt).
# name -> [count, type, minute, payload]  (count: 1=goal event, 0=keeper save).
var EXP := {
	"goal_seg0_sh5":  [1, 0, 7,   (5 << 16) | 0x07],
	"goal_seg1_sh9":  [1, 1, 65,  (9 << 16) | 0x07],
	"goal_seg2_sh11": [1, 2, 123, (11 << 16) | 0x07],
	"goal_seg3_sh7":  [1, 3, 116, (7 << 16) | 0x07],
	"save_keep40":    [0, 0, 0, 0],
	"lowkeep_goal6":  [1, 0, 5,   (6 << 16) | 0x07],
	"side1_goal_sh5": [1, 0, 22,  (5 << 16) | 0x13],
	"gkout_goal_sh2": [1, 0, 9,   (2 << 16) | 0x07],
}


func _init() -> void:
	for name in FIX:
		var f: Dictionary = FIX[name]
		var rng := Pm98StatMatch.Rng.new(f["seed"])
		var mem := _build_match(f["side"], f["keeper"], f["gk_in"])
		Pm98StatMatch._resolve(mem, rng, f["side"], f["seg"], f["min"])
		var count := mem.events.size()
		var e: Array = EXP[name]
		_ck(name + ".count", count, e[0])
		if count == 1:
			var ev: Dictionary = mem.events[0]
			_ck(name + ".type", ev["type"], e[1])
			_ck(name + ".minute", ev["minute"], e[2])
			_ck(name + ".payload", ev["payload"], e[3])

	print("test_statresolve_oracle: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
