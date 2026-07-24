extends SceneTree
## MAN OF THE MATCH parity: Pm98StatStore.pick_mom vs the REAL FUN_0044a370 driven
## through the Ghidra PCode emulator
## (tools/re/run_moms_oracle.sh -> tools/re/specs/moms_oracle.txt).
##
## Every EXPECTED pid below is BANKED FROM THE EMULATOR, transcribed from that spec
## file. The nine fixtures rebuild the harness's record arrays exactly: every record
## carries ratios A = B = C = D = 50, so its score is 50 + 10*min(goals, 10) and the
## selection is legible by eye.
##
##   A_max          3 home + 1 away, ascending goals   -> 21 (argmax spans BOTH arrays)
##   B_gate38       top scorer has rec+0x38 != 0       -> 13 (gated out)
##   C_yellow       top scorer has rec+0x30 == 2       -> 13 (gated out)
##   D_red          top scorer has rec+0x34 != 0       -> 13 (gated out)
##   E_tie_home     two home records, equal score      -> 11 (FIRST wins a tie)
##   F_tie_cross_r0 home ties away, result code 0      -> 11
##   G_tie_cross_r1 home ties away, result code 1      -> 11 (the code changes nothing
##                                                      while the event list is empty)
##   H_empty        no records at all                  -> 0  (nobody is MoM)
##   I_goalcap      10 vs 40 goals                     -> 11 (min(goals,10) caps both)
##
## Run: ~/godot462 --headless --path app --script res://tests/test_mom_oracle.gd

var _fail := 0
var _pass := 0


func _ck(name: String, got, exp) -> void:
	if str(got) == str(exp):
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %-30s got=%s exp=%s" % [name, str(got), str(exp)])


## One record exactly as run_moms_oracle.sh's rec() seeds it.
func _rec(min_v: int, inv: int, goals: int, shon: int, shoff: int, pon: int, poff: int,
		ton: int, toff: int, yel: int, red: int, f38: int, pid: int) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(Pm98StatStore.REC_SIZE)
	r.encode_s32(Pm98StatStore.R_MIN, min_v)
	r.encode_s32(Pm98StatStore.R_INVOLVE, inv)
	r.encode_s32(Pm98StatStore.R_GOALS, goals)
	r.encode_s32(Pm98StatStore.R_SHOTS_ON, shon)
	r.encode_s32(Pm98StatStore.R_SHOTS_OFF, shoff)
	r.encode_s32(Pm98StatStore.R_PASS_OK, pon)
	r.encode_s32(Pm98StatStore.R_PASS_FAIL, poff)
	r.encode_s32(Pm98StatStore.R_TACK_OK, ton)
	r.encode_s32(Pm98StatStore.R_TACK_FAIL, toff)
	r.encode_s32(Pm98StatStore.R_YELLOW, yel)
	r.encode_s32(Pm98StatStore.R_RED, red)
	r.encode_s32(Pm98StatStore.R_F38, f38)
	r.encode_u16(Pm98StatStore.R_PID, pid)
	return r


## Build a Report from [home records], [away records] (each already a 0x48-byte block).
func _report(home: Array, away: Array) -> Pm98StatStore.Report:
	var rep := Pm98StatStore.Report.new(0x28, 0x11)
	for side in 2:
		var arr: PackedByteArray = PackedByteArray()
		var src: Array = home if side == 0 else away
		for r in src:
			arr.append_array(r as PackedByteArray)
		if side == 0:
			rep.home = arr
			rep.home_count = src.size()
		else:
			rep.away = arr
			rep.away_count = src.size()
	return rep


func _base(goals: int, pid: int, yel := 0, red := 0, f38 := 0) -> PackedByteArray:
	return _rec(50, 50, goals, 1, 1, 1, 1, 1, 1, yel, red, f38, pid)


func _initialize() -> void:
	print("== MoM selector oracle (FUN_0044a370) ==")

	# The score itself: ratios all 50 -> (50+50+50+50)>>2 = 50, plus 10*min(goals,10).
	_ck("score.goals0", Pm98StatStore.mom_score(_report([_base(0, 11)], [])
		.fields(0, 0)), 50)
	_ck("score.goals3", Pm98StatStore.mom_score(_report([_base(3, 11)], [])
		.fields(0, 0)), 80)
	_ck("score.goalcap", Pm98StatStore.mom_score(_report([_base(40, 11)], [])
		.fields(0, 0)), 150)

	# A_max -> 21
	var a := _report([_base(0, 11), _base(1, 12), _base(2, 13)], [_base(3, 21)])
	_ck("A_max", Pm98StatStore.pick_mom(a), 21)
	_ck("A_max.header", a.hdr.decode_u16(Pm98StatStore.F_MOM_PID), 21)

	# B_gate38 / C_yellow / D_red -> 13 (the higher-scoring away record is gated out)
	_ck("B_gate38", Pm98StatStore.pick_mom(
		_report([_base(2, 13)], [_base(3, 21, 0, 0, 1)])), 13)
	_ck("C_yellow", Pm98StatStore.pick_mom(
		_report([_base(2, 13)], [_base(3, 21, 2, 0, 0)])), 13)
	_ck("D_red", Pm98StatStore.pick_mom(
		_report([_base(2, 13)], [_base(3, 21, 0, 1, 0)])), 13)

	# E/F/G -> 11: the first record wins a tie, inside one array and across the two.
	_ck("E_tie_home", Pm98StatStore.pick_mom(
		_report([_base(1, 11), _base(1, 12)], [])), 11)
	_ck("FG_tie_cross", Pm98StatStore.pick_mom(
		_report([_base(1, 11)], [_base(1, 21)])), 11)

	# H_empty -> 0, and the header is stamped with 0 rather than left dirty.
	var h := _report([], [])
	h.hdr.encode_u16(Pm98StatStore.F_MOM_PID, 0x1234)
	_ck("H_empty", Pm98StatStore.pick_mom(h), 0)
	_ck("H_empty.header", h.hdr.decode_u16(Pm98StatStore.F_MOM_PID), 0)

	# I_goalcap -> 11: 10 and 40 goals score the same, so the first record wins.
	_ck("I_goalcap", Pm98StatStore.pick_mom(
		_report([_base(10, 11), _base(40, 12)], [])), 11)

	# Every record gated out -> nobody, even though records exist.
	_ck("all_gated", Pm98StatStore.pick_mom(
		_report([_base(2, 13, 0, 1, 0)], [_base(3, 21, 2, 0, 0)])), 0)

	# fold_back stamps rec+0x0c on the picked record and only on it.
	var f := _report([_base(0, 11), _base(3, 12)], [])
	var store: Dictionary = {}
	Pm98StatStore.fold_back(f, store, Pm98StatStore.pick_mom(f))
	_ck("fold.mom_row", f.field(0, 1, Pm98StatStore.R_MOM), 1)
	_ck("fold.other_row", f.field(0, 0, Pm98StatStore.R_MOM), 0)
	_ck("fold.mom_season", (store[12] as PackedInt32Array)[Pm98StatStore.R_MOM / 4], 1)
	_ck("fold.other_season", (store[11] as PackedInt32Array)[Pm98StatStore.R_MOM / 4], 0)

	print("%d checks, %d failed" % [_pass + _fail, _fail])
	quit(1 if _fail > 0 else 0)
