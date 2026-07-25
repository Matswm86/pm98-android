extends SceneTree
## The owner's 2026-07-24 report on the YOUTH TEAM scout:
##   "the youth scout is the same [as the senior scout]. The players they find are
##    supposed to be possible to click on to offer contract. But that youth scout
##    result only appears once per season towards the end on original (or rather a
##    set of weeks); in our android game it's ok to lower the amount of weeks it
##    takes so we have 2 intakes per season."
##
## Before this, `_tick_youth_search` dropped a youngster straight into the youth setup
## with a news line and no offer step at all — even though MANAGER.EXE carries
## "The youth player %s has rejected your offer." (0x663be8), which only exists because
## the original ASKS. The search now returns a SHORTLIST (`Career.youth_found`) that the
## PLAYERS FOUND panel lists and a tap signs.
##
##   ~/godot462 --headless --path app --script res://tests/test_youth_prospects.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var ok := true

	# ---- cadence: the binary's own duration, over the owner's SEARCH_SPEEDUP ----
	# FUN_0053e860 @0x53e967: weeks = rand(6) + 0x37 - 5*((quality+1)>>1). At five
	# stars (quality byte 10) that is 30..35 weeks — one intake a season at best,
	# which is what the owner reported seeing. SEARCH_SPEEDUP 2 gives him two.
	var wrng := RandomNumberGenerator.new()
	wrng.seed = 9911
	var top_lo := 99999
	var top_hi := -1
	for _i in 300:
		var w := Youth.search_weeks(wrng, 10)
		top_lo = mini(top_lo, w)
		top_hi = maxi(top_hi, w)
	ok = _assert(top_lo >= 15 and top_hi <= 18,
		"a 5-star scout takes 30..35 weeks / SPEEDUP (%d..%d)" % [top_lo, top_hi]) and ok
	ok = _assert(top_hi * 2 <= 38, "two searches fit in a 38-round season") and ok
	ok = _assert(Youth.search_weeks(wrng, 10) < Youth.search_weeks(wrng, 1) + Youth.SEARCH_SPAN,
		"a 5-star scout beats a half-star one") and ok

	# ---- a search returns a SHORTLIST, it does not sign anyone --------------
	var career := Career.create(prem[0], league, prem, leagues)
	career.youth_pool = Youth.pool_of(_pool_map(db))
	career.staff = [{"id": 1, "name": "P. MITCHELL", "role": Staff.YOUTH_TEAM_SCOUT,
		"stars": 5.0, "wage": 1000}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var got_shortlist := false
	for _attempt in 12:
		career.youth = []
		career.youth_found = []
		career.start_youth_search(["DRIBBLING"])
		ok = _assert(not career.youth_search.is_empty(), "SEARCH armed") and ok
		for _w in int(career.youth_search.get("weeks", 1)):
			career._tick_youth_search(rng)
		ok = _assert(career.youth_search.is_empty(), "the search resolved") and ok
		ok = _assert(career.youth.is_empty(),
			"NOBODY joined by himself (youth=%d)" % career.youth.size()) and ok
		if not career.youth_found.is_empty():
			got_shortlist = true
			break
	ok = _assert(got_shortlist, "a 5-star scout eventually shortlists somebody") and ok
	if not got_shortlist:
		print("test_youth_prospects: FAIL")
		return false
	ok = _assert(career.youth_found.size() == 1,
		"FUN_00575e80 keeps exactly ONE (%d)" % career.youth_found.size()) and ok
	ok = _assert(not career.pending_alerts.is_empty(),
		"the finish raises a hub alert") and ok

	# ---- a shortlist row can be signed, or refuse ---------------------------
	var pid := int((career.youth_found[0] as Dictionary).get("id", -1))
	var nm := str((career.youth_found[0] as Dictionary).get("name", "?"))
	var before := career.youth.size()
	var res := career.sign_youth_prospect(pid, rng)
	ok = _assert(res.has("ok") and res.has("msg"), "the offer answers") and ok
	if bool(res["ok"]):
		ok = _assert(career.youth.size() == before + 1, "he joined the Youth Team") and ok
		ok = _assert(str(res["msg"]) == "%s has joined your Youth Team." % nm,
			"with the game's own line (%s)" % res["msg"]) and ok
	else:
		ok = _assert(str(res["msg"]) == "The youth player %s has rejected your offer." % nm,
			"with the game's own refusal (%s)" % res["msg"]) and ok
		ok = _assert(career.youth.size() == before, "and he did NOT join") and ok
	ok = _assert(_pids(career.youth_found).find(pid) == -1,
		"either way he leaves the shortlist") and ok
	ok = _assert(not bool(career.sign_youth_prospect(pid, rng)["ok"]),
		"a second tap on the same row is refused") and ok

	# ---- refusal really can happen (the string is not dead) ----------------
	var refusals := 0
	for i in 200:
		var c2 := Career.create(prem[1], league, prem, leagues)
		c2.youth_found = [{"id": 900500 + i, "name": "PROSPECT", "age": 16, "isGK": false,
			"pos": "MF", "potential": 88,
			"attrs": {"VE": 40, "RE": 40, "AG": 40, "CA": 40, "RM": 40, "RG": 40,
				"PA": 40, "TI": 40, "EN": 40, "PO": 40}}]
		var r2 := RandomNumberGenerator.new()
		r2.seed = 1000 + i
		if not bool(c2.sign_youth_prospect(900500 + i, r2)["ok"]):
			refusals += 1
	ok = _assert(refusals > 0 and refusals < 200,
		"a high-ceiling prospect sometimes refuses (%d/200)" % refusals) and ok

	# ---- the shortlist survives a save/load --------------------------------
	var d := career.to_dict()
	ok = _assert((d.get("youth_found", []) as Array).size() == career.youth_found.size(),
		"youth_found is persisted") and ok
	var back := Career.from_dict(d)
	ok = _assert(back.youth_found.size() == career.youth_found.size(),
		"and restored") and ok

	# ---- arming a new search clears the old shortlist -----------------------
	career.youth_found = [{"id": 900999, "name": "STALE", "age": 16, "attrs": {}}]
	career.start_youth_search(["PASSING"])
	ok = _assert(career.youth_found.is_empty(), "a new search clears the last shortlist") and ok

	print("test_youth_prospects: ", "PASS" if ok else "FAIL")
	return ok


## The shipped 0x26e4 youth pool out of a raw game_db dict, with the loader's own
## knock-down applied (GameDB does this at load; the headless runner has no autoloads).
func _pool_map(db: Dictionary) -> Dictionary:
	var by_id: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for c in db.get("clubs", []):
		by_id[int(c["id"])] = c
		if int(c["id"]) == Youth.POOL_CLUB_ID:
			for p in c.get("players", []):
				Youth.degrade(p, rng)
	return by_id


func _pids(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		out.append(int((r as Dictionary).get("id", -1)))
	return out


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
