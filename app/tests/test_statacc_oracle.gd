extends SceneTree
## STATISTICAL-engine leaf parity: Pm98StatMatch._stats vs the REAL per-segment
## player-stats accumulator FUN_00450510 driven through the Ghidra PCode emulator
## (tools/re/run_statacc_oracle.sh -> tools/re/specs/statacc_oracle.txt).
##
## The load-bearing assertions are DRAWS and FINAL STATE: FUN_00450510 consumes a
## heavily data-dependent number of rand() draws, and any drift desyncs the whole
## second-half scorer stream in simulate(). The sampled stat fields are a secondary
## correctness check. Every EXPECTED row is BANKED FROM THE EMULATOR.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_statacc_oracle.gd

const POS := [1, 2, 3, 5, 7, 9, 11, 13, 16, 9, 12]
var _fail := 0
var _pass := 0


func _build(str0: int, str1: int, passv: int) -> Pm98StatMatch.Mem:
	var mem := Pm98StatMatch.Mem.new()
	for s in range(2):
		var strg := str0 if s == 0 else str1
		for i in range(11):
			var pb := Pm98StatMatch._player(s, i)
			mem.set_u16(pb + Pm98StatMatch.SEL, i + 1)
			mem.set_s32(pb + Pm98StatMatch.POS, POS[i])
			mem.set_u8(pb + Pm98StatMatch.STR, strg)
			mem.set_u8(pb + Pm98StatMatch.PASS, passv)
	return mem


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-22s got=%s exp=%s" % [name, str(got), str(exp)])


# name -> [draws, final_state, poss0, poss1, p0kp, p0pass, p0tkl, p0drb, p0rate, p1pass, p1rate]
var EXP := {
	"A_clean":  [395, 3148439573, 3, 4, 0, 3, 0, 0, 0, 1, 0],
	"B_events": [400, 2054110344, 3, 4, 0, 3, 0, 0, 0, 1, 0],
	"C_roles":  [298, 3363291277, 5, 3, 0, 1, 0, 3, 4, 5, 2],
	"D_et":     [163, 837697878,  0, 0, 0, 0, 4, 0, 0, 0, 2],
}


func _run(name: String, mem: Pm98StatMatch.Mem, seed: int, dur: int) -> void:
	var rng := Pm98StatMatch.Rng.new(seed)
	Pm98StatMatch._stats(mem, rng, dur, 0, 0)
	var e: Array = EXP[name]
	var p0 := Pm98StatMatch._player(0, 1)
	var p1 := Pm98StatMatch._player(1, 1)
	_ck(name + ".draws", rng.draws, e[0])
	_ck(name + ".state", rng.state, e[1])
	_ck(name + ".poss0", mem.s32(Pm98StatMatch.POSS), e[2])
	_ck(name + ".poss1", mem.s32(Pm98StatMatch.SIDE_STRIDE + Pm98StatMatch.POSS), e[3])
	_ck(name + ".p0kp", mem.s32(p0 + 0x104), e[4])
	_ck(name + ".p0pass", mem.s32(p0 + 0x108), e[5])
	_ck(name + ".p0tkl", mem.s32(p0 + 0x10c), e[6])
	_ck(name + ".p0drb", mem.s32(p0 + 0x110), e[7])
	_ck(name + ".p0rate", mem.s32(p0 + 0x114), e[8])
	_ck(name + ".p1pass", mem.s32(p1 + 0x108), e[9])
	_ck(name + ".p1rate", mem.s32(p1 + 0x114), e[10])


func _goal(mem: Pm98StatMatch.Mem, shirt: int, team: int, minute: int) -> void:
	mem.events.append({"type": 0, "minute": minute, "p4": 0, "payload": (shirt << 16) | team})


func _init() -> void:
	# A_clean
	_run("A_clean", _build(0x46, 0x32, 0x40), 0x12345678, 0x2d)

	# B_events: 3 goals (shirts 6,9 side0/team7; 9 side1/team0x13)
	var memB := _build(0x46, 0x32, 0x40)
	_goal(memB, 6, 0x7, 27)
	_goal(memB, 9, 0x7, 37)
	_goal(memB, 9, 0x13, 4)
	_run("B_events", memB, 0x12345678, 0x2d)

	# C_roles: side1 players 1 & 9 role 2; side0 player 5 has a pending-shot marker.
	var memC := _build(0x50, 0x3c, 0x55)
	memC.set_s32(Pm98StatMatch._player(1, 1) + Pm98StatMatch.ROLE, 2)
	memC.set_s32(Pm98StatMatch._player(1, 9) + Pm98StatMatch.ROLE, 2)
	memC.set_s32(Pm98StatMatch._player(0, 5) + Pm98StatMatch.DC, 1)
	memC.set_s32(Pm98StatMatch._player(0, 5) + Pm98StatMatch.E8, 0x14)
	_run("C_roles", memC, 0x0b2050f3, 0x2d)

	# D_et: extra-time duration 0xf
	_run("D_et", _build(0x40, 0x40, 0x30), 0x0009abcd, 0xf)

	print("test_statacc_oracle: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
