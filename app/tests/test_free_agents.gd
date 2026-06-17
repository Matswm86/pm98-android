extends SceneTree
## Headless test for T2 #9 — the free-agent signing pool. Builds a Premier career and
## asserts the pool seeds, a free agent signs for no fee on an agreed wage (and joins the
## live squad + wage bill), a lowball is rejected, the board guards (offers/squad) hold, a
## non-renewed leaver drops into the pool at the season rollover, and it all round-trips.
##   ~/godot462 --headless --path app --script res://tests/test_free_agents.gd

const SEED := 9090


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	ok = _assert(career.free_agents.size() == Career.FREE_POOL_SIZE,
		"free-agent pool seeded (%d)" % career.free_agents.size()) and ok

	# Sign one at his demand -> accepted, joins the squad, leaves the pool, costs one offer.
	var fa: Dictionary = career.free_agents[0]
	var pid := int(fa["id"])
	var demand := Contract.demanded_weekly(fa, career.tier)
	var squad0: int = career.my_squad().size()
	var offers0: int = career.offers_left
	var res := career.sign_free_agent(pid, demand, rng)
	ok = _assert(res["ok"], "free agent signed at his demand (%s)" % res["msg"]) and ok
	ok = _assert(career.my_squad().size() == squad0 + 1, "signed player joined the squad") and ok
	ok = _assert(not _has(career.free_agents, pid), "signed player left the free-agent pool") and ok
	ok = _assert(career.offers_left == offers0 - 1, "a free signing spends one weekly offer") and ok
	var signed := career._find_in(career.club_id, pid)
	ok = _assert(int(signed.get("wage", 0)) == demand and int(signed.get("contract_years", 0)) > 0,
		"signed on the agreed wage + a fresh contract") and ok

	# A lowball (below the soft floor) is rejected but still costs an offer.
	var fb: Dictionary = career.free_agents[0]
	var dem_b := Contract.demanded_weekly(fb, career.tier)
	var off_b: int = career.offers_left
	var low := career.sign_free_agent(int(fb["id"]), int(dem_b * 0.6), rng)
	ok = _assert(not low["ok"], "a lowball wage is rejected") and ok
	ok = _assert(career.offers_left == off_b - 1, "the rejected bid still spent an offer") and ok
	ok = _assert(_has(career.free_agents, int(fb["id"])), "rejected free agent stays in the pool") and ok

	# Offers guard: exhaust the week's offers, the next attempt is blocked outright.
	career.offers_left = 0
	var blocked := career.sign_free_agent(int(career.free_agents[0]["id"]), 999999, rng)
	ok = _assert(not blocked["ok"] and "offers" in blocked["msg"].to_lower(),
		"no offers left -> signing blocked") and ok

	# Season rollover: a non-renewed leaver drops into the free-agent pool.
	var leaver: Dictionary = career.rosters[career.club_id][0]
	var leaver_id := int(leaver["id"])
	leaver["contract_years"] = 1
	leaver["auto_renew"] = false
	career.advance_season(leagues, rng)
	ok = _assert(_has(career.free_agents, leaver_id),
		"a non-renewed leaver joined the free-agent pool at rollover") and ok
	ok = _assert(career.free_agents.size() <= Career.FREE_POOL_CAP, "pool stays under its cap") and ok

	# Save / load round-trips the pool.
	var path := "user://free_agents_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.free_agents.size() == career.free_agents.size(),
		"free-agent pool survived save/load") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _has(pool: Array, pid: int) -> bool:
	for p in pool:
		if int(p.get("id", -1)) == pid:
			return true
	return false


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
