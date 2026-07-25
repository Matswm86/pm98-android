extends SceneTree
## `Training.develop_week` vs the disassembly of FUN_00582760 (MANAGER.EXE @0x582760),
## the engine's per-player weekly development pass. Owner report 2026-07-24:
## "training doesn't actually do anything. The players' stats don't go up. They do in
## the original, so fix it so it's exact."
##
## Every assertion below is a clause of that function, not a preference:
##   mode 0        decay: `if (base[a] < live[a]) live[a]--` over +0xa0..+0xa5
##   mode 1        GENERAL: gain 1, cap 5 on all six
##   mode 2        FITNESS: NO attribute gain, condition +3 instead of +1
##   mode 3..8     one attribute, cap rand(7)+0x12 = 18..24 over base
##   core4         VE/RE/AG/CA are never touched by any of them
##   clamps        `if (0x62 < n) n = 99`; condition clamps to [0x28, 99]
##
##   ~/godot462 --headless --path app --script res://tests/test_training_exact.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _player(pid: int, v: int = 50) -> Dictionary:
	var a := {}
	for k in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]:
		a[k] = v
	return {"id": pid, "name": "P%d" % pid, "age": 27, "isGK": false,
		"attrs": a, "attrs_base": a.duplicate(), "fitness": 70}


func _run() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 1998

	# ---- mode 0: an untrained player does not move ---------------------------
	var idle := _player(1)
	for _w in 40:
		Training.develop_week(rng, [idle])
	var still := true
	for k in (idle["attrs_base"] as Dictionary):
		if int((idle["attrs"] as Dictionary)[k]) != int((idle["attrs_base"] as Dictionary)[k]):
			still = false
	ok = _assert(still, "no focus -> 40 weeks change nothing (the engine's mode 0)") and ok

	# ---- mode 3..8: a POINT A WEEK, capped at base + 18..24 -----------------
	for probe in [["SHOOTING", "TI"], ["TACKLING", "EN"], ["HANDLING", "PO"],
			["PASSING", "PA"], ["DRIBBLING", "RM"], ["HEADING", "RG"]]:
		var row: String = probe[0]
		var key: String = probe[1]
		var p := _player(2)
		var focus := {2: row}
		for w in 10:
			Training.develop_week(rng, [p], focus)
			var want: int = 50 + w + 1
			if int((p["attrs"] as Dictionary)[key]) != want:
				ok = _assert(false, "%s week %d: %s = %d, want %d" % [row, w + 1, key,
					int((p["attrs"] as Dictionary)[key]), want]) and ok
				break
		ok = _assert(int((p["attrs"] as Dictionary)[key]) == 60,
			"%s climbs a point a week (%s 50 -> %d after 10)" % [row, key,
				int((p["attrs"] as Dictionary)[key])]) and ok
		# run it out: it must stop inside [base+18, base+24] and nowhere else
		for _w in 200:
			Training.develop_week(rng, [p], focus)
		var top := int((p["attrs"] as Dictionary)[key])
		ok = _assert(top >= 68 and top <= 74,
			"%s tops out at base + 18..24 (got %d, base 50)" % [row, top]) and ok
		# no other trainable attribute moved, and the core four never do
		var strays: Array = []
		for k in ["PO", "EN", "PA", "RM", "RG", "TI", "VE", "RE", "AG", "CA"]:
			if k != key and int((p["attrs"] as Dictionary)[k]) != 50:
				strays.append(k)
		ok = _assert(strays.is_empty(), "%s moves ONLY %s (strays: %s)"
			% [row, key, ", ".join(strays)]) and ok

	# ---- mode 1 GENERAL: all six, cap +5 ------------------------------------
	var g := _player(3)
	for _w in 40:
		Training.develop_week(rng, [g], {3: Training.FOCUS_GENERAL})
	var six_ok := true
	for k in ["PO", "EN", "PA", "RM", "RG", "TI"]:
		if int((g["attrs"] as Dictionary)[k]) != 55:
			six_ok = false
	ok = _assert(six_ok, "GENERAL lifts all six to base+5 exactly") and ok
	var core_ok := true
	for k in ["VE", "RE", "AG", "CA"]:
		if int((g["attrs"] as Dictionary)[k]) != 50:
			core_ok = false
	ok = _assert(core_ok, "and never touches SPEED/STAMINA/AGGRESSION/QUALITY") and ok

	# ---- mode 2 FITNESS: condition only -------------------------------------
	var fpl := _player(4)
	fpl["fitness"] = 60
	Training.develop_week(rng, [fpl], {4: Training.FOCUS_FITNESS})
	ok = _assert(int(fpl["fitness"]) == 63, "FITNESS gives +3 condition (got %d)"
		% int(fpl["fitness"])) and ok
	var untouched := true
	for k in (fpl["attrs_base"] as Dictionary):
		if int((fpl["attrs"] as Dictionary)[k]) != 50:
			untouched = false
	ok = _assert(untouched, "and moves no attribute at all") and ok
	var npl := _player(5)
	npl["fitness"] = 60
	Training.develop_week(rng, [npl], {5: "SHOOTING"})
	ok = _assert(int(npl["fitness"]) == 61, "a skill week gives +1 condition") and ok

	# ---- decay: gains bleed back when you take him off training -------------
	var d := _player(6)
	for _w in 12:
		Training.develop_week(rng, [d], {6: "SHOOTING"})
	var peak := int((d["attrs"] as Dictionary)["TI"])
	ok = _assert(peak == 62, "12 focused weeks -> TI 62 (got %d)" % peak) and ok
	for _w in 5:
		Training.develop_week(rng, [d])
	ok = _assert(int((d["attrs"] as Dictionary)["TI"]) == peak - 5,
		"5 weeks off training bleed 5 points back") and ok
	for _w in 50:
		Training.develop_week(rng, [d])
	ok = _assert(int((d["attrs"] as Dictionary)["TI"]) == 50,
		"decay stops at the shipped base, it does not go below") and ok

	# ---- the 0x62 snap ------------------------------------------------------
	var hi := _player(7, 98)
	for _w in 3:
		Training.develop_week(rng, [hi], {7: "SHOOTING"})
	ok = _assert(int((hi["attrs"] as Dictionary)["TI"]) == 99,
		"`if (0x62 < n) n = 99` snaps 98 -> 99 (got %d)"
		% int((hi["attrs"] as Dictionary)["TI"])) and ok

	# ---- base is seeded lazily for a record that predates it ----------------
	var legacy := {"id": 8, "name": "LEGACY", "attrs": {"TI": 40, "PO": 40, "EN": 40,
		"PA": 40, "RM": 40, "RG": 40, "VE": 40, "RE": 40, "AG": 40, "CA": 40}}
	Training.develop_week(rng, [legacy], {8: "SHOOTING"})
	ok = _assert(legacy.has("attrs_base"), "a legacy record gets its base seeded") and ok
	ok = _assert(int((legacy["attrs"] as Dictionary)["TI"]) == 41,
		"and trains from it") and ok

	# ---- an unrated fringe record is skipped, like the engine ---------------
	var fringe := {"id": 9, "name": "FRINGE", "attrs": {}}
	Training.develop_week(rng, [fringe], {9: "SHOOTING"})
	ok = _assert((fringe["attrs"] as Dictionary).is_empty(), "an attr-less record is skipped") and ok

	print("test_training_exact: ", "PASS" if ok else "FAIL")
	return ok


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
