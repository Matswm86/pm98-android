extends SceneTree
## STATISTICAL-engine parity: Pm98StatMatch.ft_gate vs the REAL full-time / tie
## resolution gate FUN_00450e60 (@0x450e60), driven through the Ghidra PCode emulator
## (tools/re/run_ftgate_oracle.sh -> tools/re/specs/ftgate_oracle.txt).
##
## The gate reads no rand() -- it is pure score arithmetic over the leg-carry fields,
## the decision flags, and the four leaf score readers (FUN_00450d60/db0/e00/e30).
## Each EXPECTED RET below is BANKED FROM THE EMULATOR (0 = still level, 1 = side 0
## through, 2 = side 1 through). The test rebuilds the SAME synthetic match struct the
## oracle fed the binary -- a queue of S0/S1 normal goals + P0/P1 penalty events plus
## the gate fields -- and asserts the port returns the binary's byte.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_ftgate_oracle.gd

const TID0 := 0x07
const TID1 := 0x13
var _fail := 0
var _pass := 0


## Build a struct with `s0`/`s1` normal goals + `p0`/`p1` penalty events and the gate
## fields. `fields` = [F20, F24, F28, A, B, C, D, F44, F48] (the FUN_00450e60 inputs).
func _build(fields: Array, s0: int, s1: int, p0: int, p1: int) -> Pm98StatMatch.Mem:
	var mem := Pm98StatMatch.Mem.new()
	mem.set_u16(Pm98StatMatch.TEAMID, TID0)
	mem.set_u16(Pm98StatMatch.TEAMID1, TID1)
	for _i in range(s0):
		_ev(mem, 2, 0, TID0)
	for _i in range(s1):
		_ev(mem, 2, 0, TID1)
	for _i in range(p0):
		_ev(mem, 4, 0, TID0)
	for _i in range(p1):
		_ev(mem, 4, 0, TID1)
	var off := [Pm98StatMatch.G_F20, Pm98StatMatch.G_F24, Pm98StatMatch.G_F28,
		Pm98StatMatch.G_A, Pm98StatMatch.G_B, Pm98StatMatch.G_C, Pm98StatMatch.G_D,
		Pm98StatMatch.G_ET, Pm98StatMatch.G_PEN]
	for k in range(off.size()):
		mem.set_s32(off[k], fields[k])
	return mem


func _ev(mem: Pm98StatMatch.Mem, type: int, p4: int, tid: int) -> void:
	mem.events.append({"type": type, "minute": 0, "p4": p4, "payload": (0x9 << 16) | tid})


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-22s got=%s exp=%s" % [name, str(got), str(exp)])


# name -> {fields:[F20,F24,F28,A,B,C,D,F44,F48], s:[S0,S1,P0,P1], ret}  (ret banked from emulator)
var FIX := {
	"single_s0win":          {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [2, 1, 0, 0], "ret": 1},
	"single_s1win":          {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [1, 2, 0, 0], "ret": 2},
	"single_level_noaway":   {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [1, 1, 0, 0], "ret": 0},
	"single_level_pen_s0":   {"fields": [0, 1, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [1, 1, 3, 2], "ret": 1},
	"single_level_pen_s1":   {"fields": [0, 1, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [1, 1, 2, 3], "ret": 2},
	"single_level_pen_tie":  {"fields": [0, 1, 0, 0xff, 0xff, 0xff, 0xff, 0, 1], "s": [1, 1, 2, 2], "ret": 0},
	"nopen_s0win":           {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 0], "s": [2, 0, 0, 0], "ret": 1},
	"nopen_s1win":           {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 0], "s": [0, 2, 0, 0], "ret": 2},
	"nopen_level":           {"fields": [0, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 0], "s": [1, 1, 0, 0], "ret": 0},
	"agg_f28_s1ahead":       {"fields": [0, 0, 1, 1, 0, 0xff, 0xff, 0, 1], "s": [0, 2, 0, 0], "ret": 2},
	"agg_f28_s0ahead":       {"fields": [0, 0, 1, 2, 0, 0xff, 0xff, 0, 1], "s": [1, 0, 0, 0], "ret": 1},
	"agg_f28_level_pen_s0":  {"fields": [0, 1, 1, 1, 1, 0xff, 0xff, 0, 1], "s": [1, 1, 2, 1], "ret": 1},
	"bot_level_draw":        {"fields": [0, 0, 0, 1, 1, 0xff, 0xff, 0, 1], "s": [1, 1, 0, 0], "ret": 0},
	"bot_away_s1":           {"fields": [0, 0, 0, 0, 1, 0xff, 0xff, 0, 1], "s": [2, 1, 0, 0], "ret": 2},
	"bot_agg_s0":            {"fields": [0, 0, 0, 0, 0, 0xff, 0xff, 0, 1], "s": [3, 1, 0, 0], "ret": 1},
}


func _init() -> void:
	for name in FIX:
		var f: Dictionary = FIX[name]
		var sc: Array = f["s"]
		var mem := _build(f["fields"], sc[0], sc[1], sc[2], sc[3])
		_ck(name, Pm98StatMatch.ft_gate(mem), f["ret"])
	print("test_ftgate_oracle: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
