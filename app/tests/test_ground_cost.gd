extends SceneTree
## GROUND IMPROVEMENTS cost model (GroundCost.gd / MANAGER.EXE FUN_0057ddd0).
##
## Pins the ported model against every price ever witnessed on a real MANAGER.EXE GROUND
## screen — the five board-tier SEATS ladders from the 2026-07-19 wine campaign, the Man Utd
## CAR PARK per-level price, and all nine FACILITIES / SERVICES items from the 2026-07-23
## capture. The witnesses include the original's own float32 dirt (£10,624,999, £4,812,499),
## so a port that "cleans up" the rounding FAILS here on purpose.
##   ~/godot462 --headless --path app --script res://tests/test_ground_cost.gd


func _initialize() -> void:
	_run()


# [category, stature tier, item index, expected GBP, expected weeks]
const WITNESSES := [
	["seats", 0, 0, 4250000, 20], ["seats", 0, 1, 7437500, 35], ["seats", 0, 2, 10624999, 50],
	["seats", 1, 0, 3750000, 20], ["seats", 1, 1, 6562499, 35], ["seats", 1, 2, 9375000, 50],
	["seats", 2, 0, 3250000, 20], ["seats", 2, 1, 5687500, 35], ["seats", 2, 2, 8124999, 50],
	["seats", 3, 0, 2750000, 20], ["seats", 3, 1, 4812499, 35], ["seats", 3, 2, 6875000, 50],
	["seats", 4, 0, 2250000, 20], ["seats", 4, 1, 3937500, 35], ["seats", 4, 2, 5624999, 50],
	["car_park_ne", 0, 0, 2975000, 7],
	["floodlights", 0, 0, 500000, 4],
	["under_soil_heating", 0, 0, 1200000, 8],
	["changing_rooms", 0, 0, 225000, 3],
	["access_to_the_stadium", 0, 0, 900000, 6],
	["medical_equipment", 0, 0, 150000, 2],
	["club_shop", 0, 1, 25000, 1],
	["cafes", 0, 3, 500000, 20],
	["toilets", 0, 0, 50000, 1],
]


func _run() -> void:
	var ok := true

	for w in WITNESSES:
		var q := GroundCost.quote(str(w[0]), int(w[1]), int(w[2]))
		ok = _assert(int(q["gbp"]) == int(w[3]) and int(q["weeks"]) == int(w[4]),
			"%s tier %d idx %d -> £%d/%dwk (want £%d/%dwk)"
			% [w[0], w[1], w[2], q["gbp"], q["weeks"], w[3], w[4]]) and ok

	# All four CAR PARK quadrants share one table in the binary (categories 3-6).
	var q0 := GroundCost.car_park_price(0)
	for c in GroundCost.CAT_CAR_PARK:
		ok = _assert(int(GroundCost.quote(str(c), 0, 0)["gbp"]) == q0,
			"car park quadrant %s matches" % c) and ok

	# seat_prices() is the three-card convenience wrapper.
	ok = _assert(GroundCost.seat_prices(0) == [4250000, 7437500, 10624999],
		"seat_prices(0) = the Champion ladder") and ok

	# A stature band above the switch's 0..8 arms lands on the arm default, not out of range.
	# SEATS default is 10.0 -> 20wk * 5000 * 10 = £1,000,000.
	ok = _assert(int(GroundCost.quote("seats", 12, 0)["gbp"]) == 1000000,
		"stature 12 falls to the SEATS default arm") and ok
	ok = _assert(GroundCost.coefficient("seats", 9, 0) == GroundCost.coefficient("seats", 12, 0),
		"every band past 8 shares the default coefficient") and ok

	# CLUB SHOP / CAFES build time rises with the target grade (FUN_0057ddd0's third argument).
	ok = _assert(GroundCost.weeks("club_shop", 1) == 1 and GroundCost.weeks("club_shop", 2) == 5
		and GroundCost.weeks("club_shop", 3) == 10, "CLUB SHOP weeks ladder 1/5/10") and ok
	ok = _assert(GroundCost.weeks("cafes", 0) == 1 and GroundCost.weeks("cafes", 3) == 20,
		"CAFES weeks ladder 1..20") and ok

	# SCORE BOARD is the one item priced by grade rather than by club (cat 10).
	ok = _assert(int(GroundCost.quote("score_board", 0, 1)["gbp"]) == 100000
		and int(GroundCost.quote("score_board", 8, 1)["gbp"]) == 100000,
		"SCORE BOARD price is club-independent") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
