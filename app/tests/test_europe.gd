extends SceneTree
## Headless test for the European competitions (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_europe.gd
## Covers minting the three comps from last season's honours (champion -> European Cup,
## runners-up -> U.E.F.A. Cup, F.A. Cup winners -> Cup Winners' Cup), the foreign-club
## field (frozen ratings, distinct across comps), the manager's entry bonus + UEFA prize
## schedule, that each comp resolves to a champion, foreign-rating resolution, and save/load.

const SEED := 13579


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _mint_and_fields() and ok
	ok = _manager_entry_prize_and_resolve() and ok
	ok = _rollover_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond


# ---- fixtures + a synthetic foreign pool ---------------------------------

func _prem_career() -> Career:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return null
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
	if prem.is_empty() or league.is_empty():
		return null
	return Career.create(prem[0], league, prem, leagues)


## A pool of `n` synthetic foreign clubs (ids 90000+) with rate-able squads.
func _fake_pool(n: int, base := 60) -> Array:
	var out: Array = []
	for k in n:
		var players: Array = [{"isGK": true, "attrs": {"PO": base + 10}}]
		for _o in 10:
			players.append({"attrs": {
				"VE": base, "RE": base, "AG": base, "CA": base, "RM": base,
				"RG": base, "PA": base, "TI": base, "EN": base, "PO": 5}})
		out.append({"id": 90000 + k, "name": "Euro%02d" % k, "players": players})
	return out


# ---- mint + fields --------------------------------------------------------

func _mint_and_fields() -> bool:
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var ok := true
	# Known honours (distinct domestic clubs from our division).
	var div: Array = career.rosters.keys()
	career.last_champion_id = int(div[0])
	career.last_runners_up = [int(div[1]), int(div[2]), int(div[3])]
	career.last_fa_winner_id = int(div[4])
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	career.mint_european_cups(_fake_pool(60), rng)

	ok = _assert(career.euro.size() == 3, "three European competitions minted") and ok
	for key in ["european_cup", "uefa_cup", "cup_winners_cup"]:
		ok = _assert(career.euro.has(key), "minted %s" % key) and ok
		var b: Dictionary = career.euro.get(key, {})
		ok = _assert((b.get("survivors", []) as Array).size() == Career.EURO_FIELD,
			"%s field = %d clubs" % [key, Career.EURO_FIELD]) and ok
	ok = _assert((career.euro["european_cup"]["survivors"] as Array).has(int(div[0])),
		"champions seeded into the European Cup") and ok
	ok = _assert((career.euro["uefa_cup"]["survivors"] as Array).has(int(div[1]))
		and (career.euro["uefa_cup"]["survivors"] as Array).has(int(div[2])),
		"both runners-up seeded into the U.E.F.A. Cup") and ok
	ok = _assert((career.euro["cup_winners_cup"]["survivors"] as Array).has(int(div[4])),
		"F.A. Cup winners seeded into the Cup Winners' Cup") and ok

	# Foreign clubs are distinct across the three competitions (dealt from one bag).
	var seen: Dictionary = {}
	var clash := false
	for key in career.euro:
		for id in career.euro[key]["survivors"]:
			if int(id) >= 90000:
				if seen.has(int(id)):
					clash = true
				seen[int(id)] = true
	ok = _assert(not clash, "no foreign club appears in two competitions") and ok
	ok = _assert(career.euro_ratings.size() >= 16 and career.euro_names.size() >= 16,
		"foreign ratings + names frozen (%d)" % career.euro_ratings.size()) and ok
	# A foreign opponent's rating resolves through _ratings_for.
	var fid := int(seen.keys()[0])
	var fr := career._ratings_for(fid)
	ok = _assert(fr.has("att") and fr.has("gk") and str(fr.get("name", "")) != "?",
		"foreign rating resolves via _ratings_for") and ok
	return ok


# ---- manager entry bonus + prize + the comps resolve ----------------------

func _manager_entry_prize_and_resolve() -> bool:
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var ok := true
	var div: Array = career.rosters.keys()
	# Force the manager to be the champions so he enters the European Cup.
	career.last_champion_id = career.club_id
	career.last_runners_up = [int(div[1]), int(div[2]), int(div[3])]
	career.last_fa_winner_id = int(div[4])
	var cash0 := career.cash
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	career.mint_european_cups(_fake_pool(60), rng)
	ok = _assert((career.euro["european_cup"]["survivors"] as Array).has(career.club_id),
		"manager (champions) is in the European Cup") and ok
	ok = _assert(career.cash >= cash0 + Career.EURO_ENTRY,
		"entry bonus credited for competing (+%d)" % Career.EURO_ENTRY) and ok
	var entry_news := false
	for n in career.news_log:
		if n is Dictionary and str(n.get("text", "")).findn("from uefa for competing") != -1:
			entry_news = true
	ok = _assert(entry_news, "entry surfaces as club news") and ok

	# Play the whole season: every European competition reaches a champion.
	var rng2 := RandomNumberGenerator.new(); rng2.seed = SEED
	while not career.season_over():
		career.advance_week(rng2)
	for key in career.euro:
		ok = _assert(Cup.champion_id(career.euro[key]) != -1,
			"%s resolves to a champion within the season" % key) and ok

	# Save/load preserves the brackets + frozen ratings.
	var path := "user://career_euro_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.euro.size() == 3
		and Cup.champion_id(loaded.euro["european_cup"]) == Cup.champion_id(career.euro["european_cup"])
		and loaded.euro_ratings.size() == career.euro_ratings.size(),
		"European brackets + frozen ratings survive save/load") and ok
	return ok


# ---- full rollover integration -------------------------------------------

func _rollover_integration() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	# Roll over WITH a foreign pool -> Europe is minted for the new season.
	career.advance_season(leagues, rng, _fake_pool(60))
	ok = _assert(career.euro.size() == 3, "rollover with a pool mints Europe") and ok
	ok = _assert((career.euro["european_cup"]["survivors"] as Array).has(career.last_champion_id),
		"the new European Cup is seeded with last season's champions") and ok
	# Without a pool (e.g. an old caller), no Europe -- backward compatible.
	var bare := _prem_career()
	var rng3 := RandomNumberGenerator.new(); rng3.seed = SEED
	while not bare.season_over():
		bare.advance_week(rng3)
	bare.advance_season(leagues, rng3)        # no euro_pool
	ok = _assert(bare.euro.is_empty(), "rollover without a pool leaves Europe inert") and ok
	return ok
