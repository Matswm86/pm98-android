extends SceneTree
## The INJURIES screen's PHYS. "+" button — the owner's "can't heal an injured player".
##
## Everything asserted here is lifted from MANAGER.EXE, not fitted:
##   FUN_00584db0(injury, q):  q = min(q, 10);  injury[+3] = q
##                             injury[+0] = injury[+1] * (20 - q) * 5 / 100
##   FUN_00543080:             refuse if already treated / no physio hired /
##                             treated_count >= FUN_00578b80(physio)
##   FUN_00578b80 case 6:      q<3 ->1, <5 ->2, <7 ->3, <9 ->4, else 5   ("N PLAYERS")
## and the capacity ladder is cross-checked against the live frame that pins a 4.5-star
## physio (q = 9) to "5 PLAYERS".
##
##   ~/godot462 --headless --path app --script res://tests/test_physio_treatment.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# --- the formula, straight off FUN_00584db0 ------------------------------
	ok = _assert(Availability.treated_weeks(10, 10) == 5,
		"a maxed physio (q=10) HALVES a 10-week injury") and ok
	ok = _assert(Availability.treated_weeks(40, 10) == 20, "and a 40-week one") and ok
	ok = _assert(Availability.treated_weeks(10, 9) == 5,
		"q=9 -> 10*11/20 = 5 (integer truncation, as the binary)") and ok
	ok = _assert(Availability.treated_weeks(10, 5) == 7, "q=5 -> 10*15/20 = 7") and ok
	ok = _assert(Availability.treated_weeks(10, 1) == 9, "q=1 -> 10*19/20 = 9") and ok
	ok = _assert(Availability.treated_weeks(10, 25) == 5, "q is clamped at 10") and ok

	# --- the capacity ladder, FUN_00578b80 case 6 ----------------------------
	var want := {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4, 9: 5, 10: 5}
	var lad := true
	for q in want:
		if Staff.physio_capacity({"stars": q * 0.5}) != int(want[q]):
			lad = false
	ok = _assert(lad, "N PLAYERS ladder 1/1/2/2/3/3/4/4/5/5 over q 1..10") and ok
	ok = _assert(Staff.physio_capacity({"stars": 4.5}) == 5,
		"the witnessed 4.5-star physio reads '5 PLAYERS'") and ok
	ok = _assert(Staff.quality_byte({"stars": 4.5}) == 9, "4.5 stars == quality byte 9") and ok

	# --- the guarded action --------------------------------------------------
	var p := {"id": 1, "injured_weeks": 8, "injury_weeks_total": 8, "injury_type": 6}
	var squad: Array = [p]
	ok = _assert(Availability.treat(p, squad, 10, 5), "the treatment applies") and ok
	ok = _assert(int(p["injured_weeks"]) == 4, "8 weeks -> 4 (got %d)" % int(p["injured_weeks"])) and ok
	ok = _assert(Availability.is_treated(p), "the row now shows BOTONON (treated)") and ok
	ok = _assert(not Availability.treat(p, squad, 10, 5),
		"a second tap is refused — the engine's flag is one-way") and ok
	ok = _assert(int(p["injured_weeks"]) == 4, "and the weeks did not move again") and ok

	# recomputed from the ORIGINAL total, not from what is left
	var q2 := {"id": 2, "injured_weeks": 3, "injury_weeks_total": 8, "injury_type": 6}
	var s2: Array = [q2]
	Availability.treat(q2, s2, 10, 5)
	ok = _assert(int(q2["injured_weeks"]) == 4,
		"a part-served 8-week injury still resolves to 8/2 = 4 (got %d)"
			% int(q2["injured_weeks"])) and ok

	# capacity: a 1-slot physio can only ever hold one man
	var a := {"id": 3, "injured_weeks": 6, "injury_weeks_total": 6, "injury_type": 5}
	var b := {"id": 4, "injured_weeks": 6, "injury_weeks_total": 6, "injury_type": 5}
	var s3: Array = [a, b]
	ok = _assert(Availability.treat(a, s3, 2, 1), "the first man gets the only slot") and ok
	ok = _assert(not Availability.treat(b, s3, 2, 1),
		"the second is refused silently while the slot is held") and ok

	# no physio hired -> inert
	var c := {"id": 5, "injured_weeks": 4, "injury_weeks_total": 4, "injury_type": 3}
	ok = _assert(not Availability.treat(c, [c], 0, 0), "no physio hired -> nothing happens") and ok

	# recovery clears the flag so the next injury can be treated too
	var d := {"id": 6, "injured_weeks": 2, "injury_weeks_total": 2, "injury_type": 2,
		"physio_treated": 10}
	Availability.tick_week([d])
	Availability.tick_week([d])
	ok = _assert(not d.has("physio_treated"), "full recovery clears the treated flag") and ok

	print("test_physio_treatment: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
