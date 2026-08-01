extends SceneTree
## THREE UP FRONT — the port of the MANAGER_HACK.EXE cheat, checked against the REAL
## bytes. Every expected number below is banked from the Ghidra PCode emulator runs in
## `tools/hack/run_hack_oracle.sh` (write-up: docs/re/hack_three_forwards.md §3), driving
## FUN_0044ee70 PS==5 on MANAGER.EXE and MANAGER_HACK.EXE over four league seeds.
##
## Three claims, in the order that matters:
##
## 1. REGRESSION — with the cheat ON but fewer than three ATT-role players, the port must
##    still reproduce the eight banked STOCK fixtures draw-for-draw. This is the property
##    the EXE patch was built to have (same draws, same final LCG state, same events,
##    same score) and the reason cheat-OFF careers stay replayable. Asserted at full
##    depth: draws + LCG state + the whole event queue, not just the scoreline.
## 2. GATING — three forwards with the cheat OFF must give the STOCK 3-forward scores.
##    ROLE is an input the stock engine already reads, so these differ from the 0-forward
##    fixtures; getting them right is what proves the trigger is gated and not free.
## 3. EFFECT — three forwards with the cheat ON must give the HACKED scores.
##
## The fixture construction here is byte-for-byte the one `run_hack_oracle.sh:build_xi`
## emits: SEL = i+1, POS from the same 11-entry table, STR at +0xbf, PASS at +0xc2,
## keeper save on player 0, team ids 0x07 / 0x13, SHAPE 0x32, and ROLE == 3 filled from
## the LAST outfield slot backwards.
##
## Run: ~/godot4 --headless --path app --script res://tests/test_three_up_front.gd

const POS := [1, 2, 3, 5, 7, 9, 11, 13, 16, 9, 12]
var _fail := 0
var _pass := 0


func _build(str0: int, str1: int, keeper: int, passv: int, natt := 0) -> Pm98StatMatch.Mem:
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
			# ROLE (+0xcc): 3 = ATT, on side 0 only, last outfield slots first.
			if s == 0 and natt > 0 and i >= 11 - natt:
				mem.set_s32(pb + Pm98StatMatch.ROLE, 3)
		var sb := s * Pm98StatMatch.SIDE_STRIDE
		mem.set_u16(sb + Pm98StatMatch.TEAMID, tid)
		mem.set_u8(sb + Pm98StatMatch.SHAPE, 0x32)
	return mem


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-28s got=%s exp=%s" % [name, str(got), str(exp)])


# The four league squads, shared by every claim below.
const SQUAD := {
	"A": {"seed": 0x12345678, "str0": 0x46, "str1": 0x32, "keeper": 0x28, "pass": 0x40},
	"B": {"seed": 0x0abcdef1, "str0": 0x3c, "str1": 0x3c, "keeper": 0x28, "pass": 0x40},
	"C": {"seed": 0x00112233, "str0": 0x50, "str1": 0x28, "keeper": 0x20, "pass": 0x44},
	"D": {"seed": 0x7eeeeee1, "str0": 0x32, "str1": 0x46, "keeper": 0x30, "pass": 0x38},
}

# Claim 1 — the eight banked STOCK fixtures (same rows as test_statmatch_oracle.gd), which
# the cheat must not perturb when the XI has no forwards.
const STOCK := {
	"league_A": {"squad": "A", "draws": 856, "state": 3281934352, "s7": 3, "s19": 2,
		"events": [[0, 27, 0x60007], [0, 37, 0x90007], [0, 4, 0x90013], [0, 45, 0x60013],
			[1, 70, 0xb0007]]},
	"league_B": {"squad": "B", "draws": 836, "state": 3290174789, "s7": 4, "s19": 2,
		"events": [[0, 43, 0x60007], [0, 5, 0x50007], [0, 9, 0x70013], [1, 63, 0x80007],
			[1, 48, 0x70007], [1, 47, 0x60013]]},
	"league_C": {"squad": "C", "draws": 789, "state": 1500429598, "s7": 0, "s19": 1,
		"events": [[0, 14, 0x90013]]},
	"league_D": {"squad": "D", "draws": 891, "state": 3983246610, "s7": 1, "s19": 3,
		"events": [[0, 35, 0xa0007], [0, 9, 0x80013], [1, 77, 0x60013], [1, 86, 0xa0013]]},
}

# Claims 2 and 3 — three ATT-role players on side 0. `off` = the STOCK binary's score,
# `on` = MANAGER_HACK.EXE's, both from the same four seeds (docs/re/hack_three_forwards.md
# §3). Side 0 is the triggering side, so `on` is 6-x unless the stock rolls gave it more.
const ATT3 := {
	"att3_A": {"squad": "A", "off": [3, 2], "on": [6, 2]},
	"att3_B": {"squad": "B", "off": [3, 3], "on": [6, 2]},
	"att3_C": {"squad": "C", "off": [2, 1], "on": [6, 0]},
	"att3_D": {"squad": "D", "off": [4, 2], "on": [6, 3]},
}


## The ORACLE run is configured EXACTLY as MANAGER_HACK.EXE, so the banked emulator rows
## above stay the assertion. Two port-side settings differ from the shipped game and are
## restored here for that reason (both 2026-08-01):
##   * `cheat_manager_side` — the shipped build gates every trigger on the MANAGER's side
##     so an AI club fielding three forwards cannot collect the buff. The EXE patch has no
##     such gate, so the oracle marks side 0 (the triggering side) as the manager's.
##   * `cheat_chance_floor` — the shipped build floors the armed side at 2 chances a half
##     on the owner's request; the cave writes 3, which is what these rows were traced at.
func _run_one(sq: Dictionary, natt: int, cheat: bool) -> Dictionary:
	Pm98StatMatch.cheat_three_up_front = cheat
	Pm98StatMatch.cheat_manager_side = 0 if cheat else -1
	Pm98StatMatch.cheat_chance_floor = Pm98StatMatch.CAVE_CHANCE_FLOOR
	var rng := Pm98StatMatch.Rng.new(sq["seed"])
	var mem := _build(sq["str0"], sq["str1"], sq["keeper"], sq["pass"], natt)
	Pm98StatMatch.simulate(mem, rng, false, false)
	Pm98StatMatch.cheat_three_up_front = false
	Pm98StatMatch.cheat_manager_side = -1
	Pm98StatMatch.cheat_chance_floor = 2
	var sc := Pm98StatMatch.score(mem)
	return {"rng": rng, "mem": mem, "s7": int(sc.get(0x07, 0)), "s19": int(sc.get(0x13, 0))}


func _init() -> void:
	# 1. REGRESSION: cheat ON, no forwards -> the banked stock rows, at full depth.
	for name in STOCK:
		var f: Dictionary = STOCK[name]
		var r := _run_one(SQUAD[f["squad"]], 0, true)
		_ck(name + ".draws", r["rng"].draws, f["draws"])
		_ck(name + ".state", r["rng"].state, f["state"])
		var ev: Array = f["events"]
		var got_ev: Array = r["mem"].events
		_ck(name + ".count", got_ev.size(), ev.size())
		for i in range(min(got_ev.size(), ev.size())):
			var e: Dictionary = got_ev[i]
			var x: Array = ev[i]
			_ck("%s.ev%d" % [name, i], "%d/%d/0x%x" % [e["type"], e["minute"], e["payload"]],
				"%d/%d/0x%x" % [x[0], x[1], x[2]])
		_ck(name + ".score", "%d-%d" % [r["s7"], r["s19"]], "%d-%d" % [f["s7"], f["s19"]])

	# 2. GATING and 3. EFFECT: three forwards, cheat OFF then ON.
	for name in ATT3:
		var f: Dictionary = ATT3[name]
		var sq: Dictionary = SQUAD[f["squad"]]
		var off: Array = f["off"]
		var on: Array = f["on"]
		var r_off := _run_one(sq, 3, false)
		_ck(name + ".cheat_off", "%d-%d" % [r_off["s7"], r_off["s19"]],
			"%d-%d" % [off[0], off[1]])
		var r_on := _run_one(sq, 3, true)
		_ck(name + ".cheat_on", "%d-%d" % [r_on["s7"], r_on["s19"]],
			"%d-%d" % [on[0], on[1]])

	# The flag must be left OFF for any later script in the same process.
	_ck("flag_restored", Pm98StatMatch.cheat_three_up_front, false)

	print("test_three_up_front: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
