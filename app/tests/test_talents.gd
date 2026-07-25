extends SceneTree
## Headless test for real-talent injection (Talent.gd + Career hooks + the pool file).
##   ~/godot462 --headless --path app --script res://tests/test_talents.gd
## Covers the Talent unit model (tier -> CA/potential math, senior/youth dict shape with
## the _seed_squad stamps, due/catch-up filtering), the Career integration (rollover
## injection to an AI club + the manager's academy, out-of-division skip, ledger +
## save/load round-trip, catch-up after a job change), the Training ceiling hold, the
## empty-pool no-op (the vanilla-port guarantee), and the shipped pool file's schema.

const SEED := 19980815


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_math() and ok
	ok = _unit_dicts() and ok
	ok = _unit_due() and ok
	ok = _career_integration() and ok
	ok = _training_ceiling() and ok
	ok = _pool_file() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _entry(id: int, legal: String, by: int, club_id, tier: int, debut: int,
		pos := "FW", route := "club") -> Dictionary:
	return {
		"id": id, "key": "%s|%d" % [legal, by],
		"name": legal.get_slice(" ", legal.get_slice_count(" ") - 1), "legalName": legal,
		"birthYear": by, "nationality": "ENGLAND", "flagCode": 30, "kind": "NATIONAL",
		"pos": pos, "posFine": null, "isGK": pos == "GK", "clubId": club_id,
		"clubName": "?", "route": route, "debutSeason": "%d-%02d" % [debut, (debut + 1) % 100],
		"debutYear": debut, "tier": tier, "ca": null, "potential": null,
		"heightCm": null, "weightKg": null,
	}


# ---- unit: tier math -------------------------------------------------------

func _unit_math() -> bool:
	var ok := true
	var e := _entry(600901, "TEST WONDER", 1982, 1, 1, 1998)
	# Age on the DB basis = season-start year - birthYear (no +1): 1998 - 1982 = 16.
	# (Witnessed via the FICHA; see Talent.age_in_season.)
	ok = _assert(Talent.age_in_season(e, 1998) == 16, "age basis (b.1982 is 16 in 1998-99)") and ok
	# Tier-1 prime CA 94 walked back 4.5/season for 6 seasons short of 23 -> 67.
	var ca := Talent.intake_ca(e, 17)
	ok = _assert(ca == 67, "tier-1 intake CA at 17 = 67 (got %d)" % ca) and ok
	ok = _assert(Talent.potential_of(e) == 98, "tier-1 default potential 98") and ok
	e["potential"] = 91
	ok = _assert(Talent.potential_of(e) == 91, "explicit potential override wins") and ok
	e["ca"] = 55
	ok = _assert(Talent.intake_ca(e, 17) == 55, "explicit CA override wins") and ok
	var e5 := _entry(600902, "TEST JOURNEYMAN", 1975, 1, 5, 1998)
	ok = _assert(Talent.intake_ca(e5, Talent.age_in_season(e5, 1998)) == 66,
		"tier-5 at prime age arrives at his peak (66)") and ok
	return ok


# ---- unit: dict shape ------------------------------------------------------

func _unit_dicts() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var e := _entry(600903, "TEST SENIOR", 1980, 7, 2, 1998)
	var p := Talent.make_senior(e, rng, 1998, 1)
	for k in ["contract_years", "contract_term", "injured_weeks", "suspended_weeks",
			"yellows", "dev_progress", "auto_renew", "wage", "morale", "fitness"]:
		ok = _assert(p.has(k), "senior dict carries _seed_squad stamp '%s'" % k) and ok
	ok = _assert(int(p["contract_years"]) == 3, "age-19 arrival gets a 3-year deal") and ok
	ok = _assert(int(p["potential"]) == 92, "senior keeps his hidden ceiling (tier-2 92)") and ok
	ok = _assert(p["photoId"] == null, "no face-bank photo (screens draw none)") and ok
	var gk := Talent.make_senior(_entry(600904, "TEST KEEPER", 1980, 7, 3, 1998, "GK"), rng, 1998, 1)
	ok = _assert(int(gk["attrs"]["PO"]) > int(gk["attrs"]["TI"]), "keeper's PO is his headline") and ok
	var fw := Talent.make_youth(_entry(600905, "TEST STRIKER", 1982, 7, 1, 1998), rng, 1998)
	ok = _assert(bool(fw["is_youth"]) and fw.has("ready") and fw.has("potential"),
		"youth dict carries the Youth.gd markers") and ok
	ok = _assert(bool(fw["ready"]) == (int(fw["attrs"]["CA"]) >= Youth.READY_CA),
		"ready tracks READY_CA") and ok
	var fa := Talent.make_free_agent(
		_entry(600931, "TEST FREEBIE", 1981, -1, 2, 1998, "MF", "free_agent"), rng, 1998)
	ok = _assert(bool(fa["free_agent"]) and int(fa["contract_years"]) == 0
		and int(fa["clubId"]) == -1, "free-agent dict is out-of-contract and clubless") and ok
	ok = _assert(int(fa["potential"]) == 92 and fa.has("attrs") and fa.has("age"),
		"free agent keeps his hidden ceiling (tier-2 92) + attrs") and ok
	return ok


# ---- unit: due filtering ---------------------------------------------------

func _unit_due() -> bool:
	var ok := true
	var pool := [
		_entry(600906, "DUE NOW", 1982, 1, 3, 1998),
		_entry(600907, "DUE EARLIER", 1980, 1, 3, 1997),
		_entry(600908, "DUE LATER", 1990, 1, 3, 2005),
	]
	var used: Dictionary = {}
	var due := Talent.due(pool, 1998, used)
	ok = _assert(due.size() == 1 and str(due[0]["legalName"]) == "DUE NOW",
		"due() = exactly this season's debutants") and ok
	var catchup := Talent.due_catchup(pool, 1998, used)
	ok = _assert(catchup.size() == 2, "due_catchup() sweeps everything <= now") and ok
	used["DUE NOW|1982"] = "1998-99"
	ok = _assert(Talent.due(pool, 1998, used).is_empty(), "the ledger blocks re-delivery") and ok
	return ok


# ---- integration: a career season ------------------------------------------

func _career_integration() -> bool:
	var ok := true
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var clubs_by_id: Dictionary = {}
	for c in db.get("clubs", []):
		clubs_by_id[int(c["id"])] = c
	var prem: Array = []
	var div1: Array = []
	var league: Dictionary = {}
	var league1: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
		elif lg.get("id") == "eng_div1":
			league1 = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
		elif c.get("leagueId") == "eng_div1":
			div1.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	var my_id := career.club_id
	var rival_id := int(prem[1]["id"])
	var away_id := int(div1[0]["id"])   # a real club OUTSIDE the live division
	var pool := [
		_entry(600911, "RIVAL PRODIGY", 1982, rival_id, 1, 1998),
		_entry(600912, "HOME PRODIGY", 1982, my_id, 1, 1998),
		_entry(600913, "FARAWAY PRODIGY", 1982, away_id, 1, 1998),
		_entry(600914, "FUTURE PRODIGY", 1990, rival_id, 1, 2005),
		_entry(600915, "MARKET PRODIGY", 1982, -1, 1, 1998, "FW", "free_agent"),
	]

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng, clubs_by_id)
	# Contracts are randomised at club init, so the number of players who leave on a
	# free at the rollover is not fixed. With enough leavers the free-agent pool hits
	# FREE_POOL_CAP and the MARKET PRODIGY assertion below flips (it defers, which is
	# correct engine behaviour and is covered separately). Give everyone a running
	# contract so this sub-test measures routing, not pool headroom.
	for p in career.rosters[my_id]:
		p["contract_years"] = 3
	career.advance_season(leagues, rng, [], {}, pool)
	ok = _assert(career.season == "1998-99", "rolled into 1998-99") and ok

	var rival_ids: Array = career.rosters[rival_id].map(func(p): return int(p["id"]))
	ok = _assert(rival_ids.has(600911), "AI-club debutant landed in the rival roster") and ok
	for p in career.rosters[rival_id]:
		if int(p["id"]) == 600911:
			ok = _assert(p.has("wage") and p.has("morale") and int(p["potential"]) == 98,
				"AI arrival is contract-stamped and keeps his ceiling") and ok
	var youth_ids: Array = career.youth.map(func(p): return int(p["id"]))
	ok = _assert(youth_ids.has(600912), "manager-club debutant joined the youth academy") and ok
	var joined := false
	for n in career.news_log:
		if String(n.get("text", "")).contains("PRODIGY") \
				and String(n.get("text", "")).contains("joined your Youth Team"):
			joined = true
	ok = _assert(joined, "faithful academy news line fired") and ok
	ok = _assert(career.talents_used.has("RIVAL PRODIGY|1982")
		and career.talents_used.has("HOME PRODIGY|1982"), "ledger records both deliveries") and ok
	ok = _assert(not career.talents_used.has("FARAWAY PRODIGY|1982"),
		"out-of-division talent stays due (not marked used)") and ok
	ok = _assert(not career.talents_used.has("FUTURE PRODIGY|1990"),
		"2005 debutant not delivered in 1998") and ok
	var fa_ids: Array = career.free_agents.map(func(p): return int(p.get("id", -1)))
	ok = _assert(fa_ids.has(600915) and career.talents_used.has("MARKET PRODIGY|1982"),
		"clubless debutant landed on the free-transfer market") and ok
	# News lines carry the display name ("PRODIGY"), not the legal name.
	var market_news := false
	for n in career.news_log:
		if String(n.get("text", "")).contains("PRODIGY") \
				and String(n.get("text", "")).contains("free transfer"):
			market_news = true
	ok = _assert(market_news, "free-agent arrival news line fired") and ok

	# Save / load round-trip keeps the ledger + the injected players.
	var path := "user://talent_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.talents_used.has("RIVAL PRODIGY|1982"),
		"ledger survives save/load") and ok
	if loaded != null:
		var lr: Array = loaded.rosters[rival_id].map(func(p): return int(p["id"]))
		ok = _assert(lr.has(600911), "injected player survives save/load") and ok

	# Job change into the other division: catch-up delivers the faraway talent there.
	career.take_job(div1[0], league1, div1, leagues, "test move")
	ok = _assert(career.talents_used.is_empty(), "job change resets the ledger") and ok
	var n := career.inject_due_talents(pool, rng)
	ok = _assert(n >= 1 and career.talents_used.has("FARAWAY PRODIGY|1982"),
		"catch-up delivers the due talent in his own division (%d arrived)" % n) and ok
	# A full free-agent market defers a market-routed talent: he stays due.
	var pool_fa := [_entry(600916, "DEFERRED PRODIGY", 1982, -1, 1, 1998, "FW", "free_agent")]
	var full: Array = []
	for i in Career.FREE_POOL_CAP:
		full.append({"id": 900000 + i})
	career.free_agents = full
	ok = _assert(career.inject_due_talents(pool_fa, rng) == 0
		and not career.talents_used.has("DEFERRED PRODIGY|1982"),
		"full market defers the free-agent talent (stays due)") and ok
	# We just took over HIS club, and he is still youth-age (18 after take_job's year
	# tick) -- so he arrives through OUR academy, the faithful route.
	var far_youth: Array = career.youth.map(func(p): return int(p["id"]))
	ok = _assert(far_youth.has(600913), "he came through his real club's academy (ours now)") and ok

	# The vanilla guarantee: an empty pool injects nothing and touches no ledger.
	var plain := Career.create(prem[0], league, prem, leagues)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = SEED
	while not plain.season_over():
		plain.advance_week(rng2, clubs_by_id)
	plain.advance_season(leagues, rng2, [], {})
	ok = _assert(plain.talents_used.is_empty(), "empty pool -> empty ledger") and ok
	for cid in plain.rosters:
		for p in plain.rosters[cid]:
			if int(p.get("id", 0)) >= 600000 and int(p.get("id", 0)) < Career.FREE_ID_BASE:
				ok = _assert(false, "vanilla rollover minted a talent-band id") and ok
	return ok


# ---- Training holds an injected talent at his ceiling ------------------------

func _training_ceiling() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# The old invented `potential` ceiling lived inside a development model that no
	# longer exists: FUN_00582760 never touches CA on a senior at all (only the youth
	# mode 0x20 does, and only up to his own shipped rating). So the ceiling is now
	# enforced by the ENGINE's own rule — CA is untrainable — and that is what is
	# asserted here.
	var e := _entry(600921, "CAPPED KID", 1980, 7, 5, 1998)   # tier 5: peak 66, ceiling 70
	var p := Talent.make_senior(e, rng, 1998, 1)
	p["age"] = 18
	p["id"] = 600921
	p["attrs"]["CA"] = 70
	var squad := [p]
	for _w in 200:
		Training.develop_week(rng, squad, {600921: "SHOOTING"})
	ok = _assert(int(p["attrs"]["CA"]) == 70,
		"CA is untrainable: 200 focused weeks leave it at 70 (got %d)" % int(p["attrs"]["CA"])) and ok
	ok = _assert(int(p["attrs"]["TI"]) > 0, "but the focused attribute did move") and ok
	# A vanilla dict trains the same way -- no per-player exception exists any more.
	var v := {"id": 1, "name": "VANILLA", "age": 18, "isGK": false,
		"attrs": {"VE": 50, "RE": 50, "AG": 50, "CA": 50, "RM": 50,
			"RG": 50, "PA": 50, "TI": 50, "EN": 50, "PO": 25}}
	for _w in 100:
		Training.develop_week(rng, [v], {1: "SHOOTING"})
	ok = _assert(int(v["attrs"]["TI"]) > 50, "a vanilla record trains identically") and ok
	ok = _assert(int(v["attrs"]["CA"]) == 50, "and its CA is equally untouched") and ok
	return ok


# ---- the shipped pool file ---------------------------------------------------

func _pool_file() -> bool:
	var ok := true
	var f := FileAccess.open("res://data/talent_pool.json", FileAccess.READ)
	if f == null:
		print("  [SKIP] res://data/talent_pool.json not present (vanilla build)")
		return true
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	ok = _assert(typeof(parsed) == TYPE_DICTIONARY, "pool parses") and ok
	var talents: Array = (parsed as Dictionary).get("talents", [])
	ok = _assert(talents.size() >= 30, "starter pool carries the curated crop (%d)" % talents.size()) and ok
	# Per-entry checks are quiet on PASS -- the shipped pool is thousands of rows.
	var keys: Dictionary = {}
	var ids: Dictionary = {}
	var clean := true
	for t in talents:
		clean = _check(int(t["id"]) >= Talent.TALENT_ID_BASE and int(t["id"]) < Career.FREE_ID_BASE,
			"id %d in the talent band" % int(t["id"])) and clean
		clean = _check(not keys.has(t["key"]) and not ids.has(int(t["id"])),
			"no duplicate key/id (%s)" % str(t["key"])) and clean
		keys[t["key"]] = true
		ids[int(t["id"])] = true
		clean = _check(int(t["debutYear"]) >= 1998 and int(t["tier"]) >= 1 and int(t["tier"]) <= 5,
			"sane debut/tier for %s" % str(t["key"])) and clean
		var route := str(t.get("route", "club"))
		if route == "club":
			clean = _check(t["clubId"] != null and int(t["clubId"]) > 0,
				"club-routed %s carries a club id" % str(t["key"])) and clean
		elif route == "free_agent":
			clean = _check(Talent.club_of(t) == -1,
				"free-agent %s is clubless" % str(t["key"])) and clean
	ok = _assert(clean, "all %d pool entries pass the schema checks" % talents.size()) and ok
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond


## Quiet assert for per-row sweeps: prints only failures.
func _check(cond: bool, label: String) -> bool:
	if not cond:
		print("  [FAIL] %s" % label)
	return cond
