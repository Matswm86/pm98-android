extends SceneTree
## Headless test for the WEEKLY illness tick -- `FUN_0057a980` @0x57a9f4-0x57aac8 and
## `roll_A` @0x5850b0, ported 2026-07-28 (docs/re/injury_model_re.md). It is the only path
## in the game that can produce a virus or a cold, and it runs for every club every week
## whether or not it played.
##
##   ~/godot462 --headless --path app --script res://tests/test_weekly_illness.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := _unit_ladder()
	ok = _unit_gates() and ok
	ok = _unit_pick() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, what: String) -> bool:
	print("  %s  %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _squad(n: int, fitness: int = 99) -> Array:
	var out: Array = []
	for i in n:
		out.append({"id": i, "name": "P%02d" % i, "fitness": fitness,
			"injured_weeks": 0, "injury_weeks_total": 0, "injury_type": -1})
	return out


# ---- roll_A's ladder ------------------------------------------------------

func _unit_ladder() -> bool:
	var ok := true
	# Walk every one of the 100 draws through the CDF and count the diagnoses. The
	# percentages are docs/re/injury_model_re.md's roll_A column, which is the ladder
	# read off 0x5850b0 compare by compare.
	var hist := {}
	for r in 100:
		var ti := -1
		for row in Availability.WEEK_INJURY_CDF:
			if r < int(row[0]):
				ti = int(row[1])
				break
		if ti < 0:
			ti = 16 if r < 0x63 else 17
		hist[ti] = int(hist.get(ti, 0)) + 1
	var want := {0: 24, 1: 1, 2: 5, 3: 10, 4: 10, 5: 8, 6: 8, 7: 8, 9: 1,
		10: 5, 11: 5, 12: 2, 13: 5, 14: 5, 15: 1, 16: 1, 17: 1}
	for ti in want:
		ok = _assert(int(hist.get(ti, 0)) == int(want[ti]),
			"roll_A gives %s %d%% (got %d)" % [
				Availability.INJURY_TYPES[ti], int(want[ti]), int(hist.get(ti, 0))]) and ok
	var total := 0
	for ti in hist:
		total += int(hist[ti])
	ok = _assert(total == 100, "the ladder covers all 100 draws (%d)" % total) and ok
	ok = _assert(not hist.has(8),
		"sprained wrist is roll_B ONLY -- roll_A gives that band to virus") and ok
	return ok


# ---- the three gates ------------------------------------------------------

func _unit_gates() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()

	# `injured + 16 >= squad` blocks it outright: a 16-man squad can never fall ill.
	var small := _squad(16)
	var fired := false
	for s in 400:
		rng.seed = s
		if not Availability.roll_weekly_illness(rng, small).is_empty():
			fired = true
	ok = _assert(not fired, "a 16-man squad is exempt (`add ebp,0x10 / cmp / jae`)") and ok

	# `2 * injured >= squad` blocks it too.
	var half := _squad(24)
	for i in 12:
		(half[i] as Dictionary)["injured_weeks"] = 3
	fired = false
	for s in 400:
		rng.seed = s
		if not Availability.roll_weekly_illness(rng, half).is_empty():
			fired = true
	ok = _assert(not fired, "half the squad already injured is exempt (`lea edx,[ebp+ebp]`)") and ok

	# A healthy 24-man squad: the 1-in-7 gate means it fires on ROUGHLY a seventh of
	# weeks. Measured over 700 seeded weeks against a fresh squad each time.
	var hits := 0
	for s in 700:
		rng.seed = s
		if not Availability.roll_weekly_illness(rng, _squad(24)).is_empty():
			hits += 1
	var rate := float(hits) / 700.0
	ok = _assert(rate > 0.09 and rate < 0.20,
		"a healthy squad falls ill on ~1 week in 7 (%.3f over 700)" % rate) and ok
	return ok


# ---- the victim pick ------------------------------------------------------

func _unit_pick() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()

	# Every man who does fall ill carries a real diagnosis, a duration and the news line
	# in MANAGER.EXE's own wording.
	var lines := 0
	var virus_or_cold := 0
	for s in 900:
		rng.seed = s
		var sq := _squad(24)
		for n in Availability.roll_weekly_illness(rng, sq):
			lines += 1
			var txt := str(n["text"])
			ok = _assert(txt.begins_with("P") and txt.ends_with("."),
				"the line is the EXE's format (%s)" % txt) and ok
			if txt.contains("with a virus") or txt.contains("with a cold"):
				virus_or_cold += 1
			var ill: Dictionary = {}
			for p in sq:
				if int(p.get("injured_weeks", 0)) > 0:
					ill = p
			ok = _assert(not ill.is_empty()
					and int(ill["injured_weeks"]) >= 1
					and int(ill["injury_weeks_total"]) == int(ill["injured_weeks"])
					and int(ill["injury_type"]) >= 0,
				"the victim carries weeks + total + diagnosis") and ok
			break   # one assertion pass per firing is enough
	ok = _assert(lines > 20, "the tick fired enough times to test (%d)" % lines) and ok
	# Virus + cold are 25 % of roll_A, so a quarter of illnesses should be one of them --
	# and they can ONLY come from this path.
	var share := float(virus_or_cold) / maxf(1.0, float(lines))
	ok = _assert(share > 0.10 and share < 0.45,
		"a quarter of weekly diagnoses are virus/cold (%.2f of %d)" % [share, lines]) and ok

	# Fitness weighting: with one very unfit man in the first-team window and the rest at
	# full fitness, he takes more than his 1-in-12 share of the illnesses.
	var him := 0
	var runs := 0
	for s in 3000:
		rng.seed = s
		var sq := _squad(24)
		(sq[5] as Dictionary)["fitness"] = 40
		if Availability.roll_weekly_illness(rng, sq).is_empty():
			continue
		runs += 1
		if int((sq[5] as Dictionary).get("injured_weeks", 0)) > 0:
			him += 1
	var his_share := float(him) / maxf(1.0, float(runs))
	print("  [note] the unfit man took %d of %d illnesses (%.3f)" % [him, runs, his_share])
	ok = _assert(runs > 100, "enough illnesses to measure the weighting (%d)" % runs) and ok
	ok = _assert(his_share > 1.0 / 12.0,
		"the least fit man is picked more often than uniform (%.3f > %.3f)" % [
			his_share, 1.0 / 12.0]) and ok
	return ok
