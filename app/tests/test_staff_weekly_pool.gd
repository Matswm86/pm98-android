extends SceneTree
## The CLUB PERSONNEL hire list must be a NEW list every week — the owner's
## "the same staff the whole time, so training gains are tiny" (2026-07-24).
##
## Witnessed live on the original (Bolton W career, PHYSIOTHERAPISTS list, nobody
## signed in between):
##   week 1  A. Burgess 2.5 £6,000 · R. Fields 2.0 £7,000 · N. Kelso 2.0 £5,000
##   week 3  F. Hallet  3.0 £18,000 · D. Todd 4.5 £35,000 · P. Horlicks 5.0 £47,000
##   week 4  G. Conner  1.0 £4,000  · E. Wragg 4.5 £42,000 · J. Preece 4.5 £42,000
## Three fresh candidates and a fresh star spread each time; the SAME week reopened
## gives the identical list, so the roll is on the week tick, not on screen open.
##
##   ~/godot462 --headless --path app --script res://tests/test_staff_weekly_pool.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var c := Career.new()
	c.staff_pool = []
	c.staff_seq = 9000
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var names: Array = []
	var star_sets: Array = []
	for wk in 6:
		c._refresh_staff_pool(rng)
		var phys: Array = []
		var stars: Array = []
		for m in c.staff_pool:
			if str(m.get("role", "")) == Staff.PHYSIOTHERAPIST:
				phys.append(str(m.get("name", "")))
				stars.append(float(m.get("stars", 0.0)))
		ok = _assert(phys.size() == 3, "week %d offers 3 physiotherapists" % (wk + 1)) and ok
		names.append(phys)
		star_sets.append(stars)

	var repeats := 0
	for i in range(1, names.size()):
		if (names[i] as Array) == (names[i - 1] as Array):
			repeats += 1
	ok = _assert(repeats == 0, "the list is different every week (%d repeats)" % repeats) and ok

	# ids stay unique across regenerations (the hire path looks candidates up by id)
	var ids := {}
	var dupes := 0
	for m in c.staff_pool:
		if ids.has(int(m["id"])):
			dupes += 1
		ids[int(m["id"])] = true
	ok = _assert(dupes == 0, "candidate ids are unique inside a pool") and ok
	ok = _assert(c.staff_seq > 9000, "the id minter advanced") and ok

	# every one of the 13 roles is offered, every week
	var roles := {}
	for m in c.staff_pool:
		roles[str(m.get("role", ""))] = true
	ok = _assert(roles.size() == Staff.ROLE_KEYS.size(),
		"all %d roles have candidates (got %d)" % [Staff.ROLE_KEYS.size(), roles.size()]) and ok

	# the star spread genuinely moves — the owner's complaint was being stuck at 3
	var hi := 0.0
	var lo := 9.0
	for s in star_sets:
		for v in s:
			hi = maxf(hi, float(v))
			lo = minf(lo, float(v))
	ok = _assert(hi >= 4.5, "high-quality staff do come up (best seen %.1f)" % hi) and ok
	ok = _assert(lo <= 2.0, "and weak ones too (worst seen %.1f)" % lo) and ok

	# hired staff are NOT swept away by the refresh
	var hired := {"id": 1, "role": Staff.PHYSIOTHERAPIST, "name": "K. Test", "stars": 5.0,
		"quality": 5, "wage": 45000}
	c.staff = [hired]
	c._refresh_staff_pool(rng)
	ok = _assert(c.staff.size() == 1 and c.staff[0] == hired,
		"a hired member survives the weekly refresh") and ok

	print("test_staff_weekly_pool: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
