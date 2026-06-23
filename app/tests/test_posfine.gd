extends SceneTree
## Fine-position wiring test: the bridge (Pm98StatMatch.build_mem / _fill_participant)
## must set each participant's POS field (the POS_WEIGHT scorer-roulette index) from the
## player's decoded `posFine` (game_db, the EQUIPOS Y-12 byte), and fall back to the
## representative per-role code only when posFine is absent or out of range.
##
## Asserts:
##   1. a player WITH a valid posFine -> participant POS == posFine (used verbatim).
##   2. GK posFine (1) -> POS_WEIGHT[1] == 0 (keepers never win the scorer roulette).
##   3. a player WITHOUT posFine -> the per-role fallback (POS_OF), GK slot 0 -> 1.
##   4. an out-of-range posFine -> falls back, never indexes past POS_WEIGHT.
##   5. real game_db coverage: every fielded outfielder's posFine indexes a valid weight,
##      and every fielded keeper's posFine resolves to weight 0.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_posfine.gd

var _fail := 0
var _pass := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", msg)


func _pos_of(side: int, idx: int, mem: Pm98StatMatch.Mem) -> int:
	return mem.s32(Pm98StatMatch._player(side, idx) + Pm98StatMatch.POS)


func _pl(pos: String, fine: Variant) -> Dictionary:
	# minimal fielded player (non-empty attrs so the slot is selected)
	var d := {"pos": pos, "attrs": {"VE": 50, "RE": 50, "AG": 50, "CA": 50, "PO": 50, "PA": 50}}
	if fine != null:
		d["posFine"] = fine
	return d


func _run() -> void:
	# --- 1+2+3+4: synthetic XI exercising every branch -----------------------
	var xi0: Array = [
		_pl("GK", 1),    # slot 0 GK, posFine 1 -> POS 1 -> weight 0
		_pl("FW", 9),    # central striker, posFine 9 -> POS 9 -> weight 35
		_pl("DF", 2),    # defender, posFine 2 -> POS 2 -> weight 3
		_pl("MF", null), # no posFine -> per-role fallback POS_OF[MF] = 12
		_pl("FW", null), # no posFine -> per-role fallback POS_OF[FW] = 9
		_pl("DF", 99),   # out-of-range posFine -> fallback POS_OF[DF] = 3
		_pl("MF", 13), _pl("MF", 7), _pl("DF", 4), _pl("FW", 14), _pl("MF", 17),
	]
	var xi1: Array = xi0.duplicate()
	var mem := Pm98StatMatch.build_mem(xi0, xi1, 0x100, 0x200)

	_ok(_pos_of(0, 0, mem) == 1, "GK posFine 1 -> POS 1")
	_ok(Pm98StatMatch.POS_WEIGHT[_pos_of(0, 0, mem)] == 0, "GK POS indexes weight 0")
	_ok(_pos_of(0, 1, mem) == 9, "striker posFine 9 -> POS 9")
	_ok(Pm98StatMatch.POS_WEIGHT[_pos_of(0, 1, mem)] == 35, "striker POS indexes weight 35")
	_ok(_pos_of(0, 2, mem) == 2, "defender posFine 2 -> POS 2 (verbatim)")
	_ok(_pos_of(0, 3, mem) == int(Pm98StatMatch.POS_OF["MF"]), "no posFine -> POS_OF[MF] fallback")
	_ok(_pos_of(0, 4, mem) == int(Pm98StatMatch.POS_OF["FW"]), "no posFine -> POS_OF[FW] fallback")
	_ok(_pos_of(0, 5, mem) == int(Pm98StatMatch.POS_OF["DF"]), "out-of-range posFine -> fallback")
	# every POS set is a valid POS_WEIGHT index (no fallback/decode escapes the table)
	for s in range(2):
		for i in range(11):
			var pi := _pos_of(s, i, mem)
			_ok(pi >= 0 and pi < Pm98StatMatch.POS_WEIGHT.size(), "POS in range side %d slot %d" % [s, i])

	# --- 5: real game_db coverage --------------------------------------------
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_ok(false, "game_db.json present")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var db: Dictionary = parsed if parsed is Dictionary else {}
	var gk_total := 0
	var gk_weight0 := 0
	var fine_total := 0
	var fine_valid := 0
	for c in db.get("clubs", []):
		for p in (c as Dictionary).get("players", []):
			var pd: Dictionary = p
			var fine: Variant = pd.get("posFine")
			if fine == null:
				continue
			fine_total += 1
			if int(fine) >= 0 and int(fine) < Pm98StatMatch.POS_WEIGHT.size():
				fine_valid += 1
			if pd.get("pos") == "GK":
				gk_total += 1
				if int(fine) >= 0 and int(fine) < Pm98StatMatch.POS_WEIGHT.size() \
						and Pm98StatMatch.POS_WEIGHT[int(fine)] == 0:
					gk_weight0 += 1
	_ok(fine_total > 5000, "game_db posFine present on the bulk of players (got %d)" % fine_total)
	_ok(fine_valid == fine_total, "every decoded posFine is a valid POS_WEIGHT index (%d/%d)"
			% [fine_valid, fine_total])
	# Keepers are demarcacion GK (the Y-3 byte); their fine code (the Y-12 byte) should
	# resolve to scorer weight 0. A handful of original records disagree between the two
	# bytes (e.g. STURM GRAZ FODA, LILLESTROM KIHLSTEDT, LOK.SOFIA MANOLKOV -- low-PO
	# outfielders the broad byte mis-tags as GK), faithfully reproduced; allow <=1%.
	_ok(gk_total > 500, "game_db has the expected keeper population (got %d)" % gk_total)
	_ok(gk_weight0 >= int(gk_total * 0.99),
			"keepers' posFine -> weight 0 within original-data noise (%d/%d)" % [gk_weight0, gk_total])


func _init() -> void:
	_run()
	print("test_posfine: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
