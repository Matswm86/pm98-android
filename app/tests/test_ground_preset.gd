extends SceneTree
## GROUND starting-grade preset (`FUN_0057d780`) + the per-club item table it feeds.
##
## Pins the three captured careers that BIND the preset index to the division
## (`tools/re/refs/lowdiv-2026-07-28/`, drive 2026-07-28):
##   * Manchester Utd. — Premier      — preset 0 (the 2026-07-23 capture, 9/9 rows)
##   * Birmingham C    — First Div.   — preset 1 (6 of the 9 rows re-witnessed)
##   * Barnet          — Third Div.   — preset 2/3 (3 rows + the three SEATS cards)
## and the two NEW non-Man-Utd price witnesses those careers produced, which are the first
## live check that `GroundCost` is right away from the club it was extracted on.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_ground_preset.gd

var _fail := 0


func _init() -> void:
	_preset_table()
	_division_binding()
	_manutd_rows_reproduce()
	_new_price_witnesses()
	print("test_ground_preset: %s" % ("ALL PASS" if _fail == 0 else "%d FAILURE(S)" % _fail))
	quit(1 if _fail > 0 else 0)


func _ck(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		printerr("  FAIL: %s" % msg)


## The jump table at 0x57d834 is b5/e1/0b/0b -> indices 2 and 3 share one arm, and anything
## above 3 (every foreign club, numbered 7..12 by FUN_0057a180) gets no write at all.
func _preset_table() -> void:
	_ck(GroundPreset.grades(0) == [2, 0, 1, 2, 1, 1, 0, 2, 2], "preset 0 grades")
	_ck(GroundPreset.grades(1) == [1, 0, 0, 1, 0, 0, 0, 1, 1], "preset 1 grades")
	_ck(GroundPreset.grades(2) == GroundPreset.grades(3), "presets 2 and 3 share an arm")
	_ck(GroundPreset.grades(3) == [0, 0, 0, 0, 0, 0, 0, 0, 0], "preset 3 all zero")
	_ck(GroundPreset.grades(7) == [0, 0, 0, 0, 0, 0, 0, 0, 0], "index > 3 keeps the ctor zeros")
	_ck(GroundPreset.car_park(0) == [1, 1, 1, 1], "preset 0 car park 1 1 1 1")
	_ck(GroundPreset.car_park(1) == [0, 0, 0, 0], "preset 1 car park 0 0 0 0")


func _division_binding() -> void:
	_ck(GroundPreset.competition_index("eng_prem") == 0, "Premier -> 0")
	_ck(GroundPreset.competition_index("eng_div1") == 1, "First Division -> 1")
	_ck(GroundPreset.competition_index("eng_div2") == 2, "Second Division -> 2")
	_ck(GroundPreset.competition_index("eng_div3") == 3, "Third Division -> 3")
	_ck(GroundPreset.competition_index("") >= 7, "a directory-only foreign club -> 7..12")

	# WITNESSED: Birmingham C (First Div.) FLOODLIGHTS = 500.000 K.W. (1),
	# CHANGING ROOMS = BASIC (0), SCORE BOARD = ELECTRONIC (1) -- refs 11/12/13.
	var b1 := GroundPreset.grades_for_league("eng_div1")
	_ck(b1[0] == 1, "Birmingham C FLOODLIGHTS = 500.000 K.W.")
	_ck(b1[2] == 0, "Birmingham C CHANGING ROOMS = BASIC")
	_ck(b1[3] == 1, "Birmingham C SCORE BOARD = ELECTRONIC")
	# ... and its SERVICES half -- refs 14/15/16.
	_ck(b1[5] == 0, "Birmingham C MEDICAL EQUIPMENT = BASIC")
	_ck(b1[7] == 1, "Birmingham C CAFES = MEDIUM")
	_ck(b1[8] == 1, "Birmingham C TOILETS = 20 W.C.")

	# WITNESSED: Barnet (Third Div.) FLOODLIGHTS NONE, CHANGING ROOMS BASIC,
	# SCORE BOARD MANUAL -- refs 07/08/09.
	var b3 := GroundPreset.grades_for_league("eng_div3")
	_ck(b3[0] == 0 and b3[2] == 0 and b3[3] == 0, "Barnet starts at grade 0 on all three")


## Every one of the nine rows captured off the real Man Utd GROUND screen on 2026-07-23
## (app/data/ground_prices.json) must come back out of the generator unchanged.
func _manutd_rows_reproduce() -> void:
	var f := FileAccess.open("res://data/ground_prices.json", FileAccess.READ)
	if f == null:
		_ck(false, "ground_prices.json missing")
		return
	var captured: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (captured is Dictionary):
		_ck(false, "ground_prices.json unreadable")
		return
	for cat in ["facilities", "services"]:
		var want: Array = ((captured as Dictionary)[cat] as Dictionary)["Manchester Utd."]
		var got := GroundPreset.items(cat, "eng_prem", 0)   # Man Utd's stature band is 0
		_ck(got.size() == want.size(), "%s row count" % cat)
		for i in mini(got.size(), want.size()):
			var g: Dictionary = got[i]
			var w: Dictionary = want[i]
			_ck(str(g["item"]) == str(w["item"]), "%s[%d] item" % [cat, i])
			_ck(g["grades"] == w["grades"], "%s %s grade labels" % [cat, w["item"]])
			_ck(int(g["current"]) == int(w["current"]), "%s %s starting grade" % [cat, w["item"]])
			_ck(int(g["cost"]) == int(w["cost"]), "%s %s cost (%d vs %d)" % [
				cat, w["item"], int(g["cost"]), int(w["cost"])])
			_ck(int(g["weeks"]) == int(w["weeks"]), "%s %s weeks" % [cat, w["item"]])


## The first ground prices ever witnessed AWAY from Man Utd (2026-07-28 drive). Both are
## solved for the band the price implies, so they check GroundCost's table arms, not the
## port's stature model: Birmingham C's floodlight upgrade prints £200,000 / 4 weeks, which
## is coefficient 10.0 = the floodlights arm at band 5 or 6; Barnet's three SEATS cards
## print £1,000,000 / £1,750,000 / £2,500,000 at 20 / 35 / 50 weeks, which is coefficient
## 10.0 = the seats arm's price_default, i.e. any band at or above 9.
func _new_price_witnesses() -> void:
	var hit := false
	for band in [5, 6]:
		var q := GroundCost.quote("floodlights", band, 2)
		if int(q["gbp"]) == 200000 and int(q["weeks"]) == 4:
			hit = true
	_ck(hit, "Birmingham C floodlights 500.000 -> 1.000.000 K.W. = GBP 200,000 / 4 weeks")

	var seats_ok := false
	for band in range(9, 13):
		var p := GroundCost.seat_prices(band)
		var w := [GroundCost.weeks(GroundCost.CAT_SEATS, 0), GroundCost.weeks(GroundCost.CAT_SEATS, 1),
			GroundCost.weeks(GroundCost.CAT_SEATS, 2)]
		if p == [1000000, 1750000, 2500000] and w == [20, 35, 50]:
			seats_ok = true
	_ck(seats_ok, "Barnet SEATS cards = GBP 1,000,000 / 1,750,000 / 2,500,000 at 20 / 35 / 50 weeks")
