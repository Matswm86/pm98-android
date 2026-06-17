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
	ok = _group_stage() and ok
	ok = _two_legged_rules() and ok
	ok = _manager_entry_prize_and_resolve() and ok
	ok = _rollover_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


## A competition's full field: the knockout survivors, or (during a group phase) the
## clubs drawn into the groups, which seed the knockout once the groups resolve.
func _field(b: Dictionary) -> Array:
	var gs: Dictionary = b.get("group_stage", {})
	if not gs.is_empty():
		return gs.get("field", [])
	return b.get("survivors", [])


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
		ok = _assert(_field(b).size() == Career.EURO_FIELD,
			"%s field = %d clubs" % [key, Career.EURO_FIELD]) and ok
	ok = _assert(_field(career.euro["european_cup"]).has(int(div[0])),
		"champions seeded into the European Cup") and ok
	ok = _assert(_field(career.euro["uefa_cup"]).has(int(div[1]))
		and _field(career.euro["uefa_cup"]).has(int(div[2])),
		"both runners-up seeded into the U.E.F.A. Cup") and ok
	ok = _assert(_field(career.euro["cup_winners_cup"]).has(int(div[4])),
		"F.A. Cup winners seeded into the Cup Winners' Cup") and ok

	# Foreign clubs are distinct across the three competitions (dealt from one bag).
	var seen: Dictionary = {}
	var clash := false
	for key in career.euro:
		for id in _field(career.euro[key]):
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
	ok = _assert(_field(career.euro["european_cup"]).has(career.club_id),
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
	ok = _assert(_field(career.euro["european_cup"]).has(career.last_champion_id),
		"the new European Cup is seeded with last season's champions") and ok
	# Without a pool (e.g. an old caller), no Europe -- backward compatible.
	var bare := _prem_career()
	var rng3 := RandomNumberGenerator.new(); rng3.seed = SEED
	while not bare.season_over():
		bare.advance_week(rng3)
	bare.advance_season(leagues, rng3)        # no euro_pool
	ok = _assert(bare.euro.is_empty(), "rollover without a pool leaves Europe inert") and ok
	return ok


# ---- the European Cup group stage ----------------------------------------

func _group_stage() -> bool:
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var ok := true
	var div: Array = career.rosters.keys()
	career.last_champion_id = int(div[0])
	career.last_runners_up = [int(div[1]), int(div[2]), int(div[3])]
	career.last_fa_winner_id = int(div[4])
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	career.mint_european_cups(_fake_pool(60), rng)
	var b: Dictionary = career.euro["european_cup"]
	var gs: Dictionary = b.get("group_stage", {})
	ok = _assert(not gs.is_empty(), "European Cup has a group stage") and ok
	ok = _assert(int(gs.get("n_groups", 0)) == 4 and int(gs.get("group_size", 0)) == 4,
		"4 groups of 4") and ok
	# Only the European Cup has groups; the other two are straight knockouts.
	ok = _assert((career.euro["uefa_cup"].get("group_stage", {}) as Dictionary).is_empty()
		and (career.euro["cup_winners_cup"].get("group_stage", {}) as Dictionary).is_empty(),
		"UEFA Cup + Cup Winners' Cup have no group stage") and ok

	var ratings_fn := func(id: int) -> Dictionary: return career._ratings_for(id)
	var names_fn := func(id: int) -> String:
		if career.club_names.has(int(id)):
			return str(career.club_names[int(id)])
		return str(career.euro_names.get(int(id), "?"))
	var guard := 0
	while not bool((b.get("group_stage", {}) as Dictionary).get("qualified", false)) and guard < 20:
		Cup.play_group_matchday(b, rng, ratings_fn, career.club_id, names_fn)
		guard += 1
	ok = _assert(bool(b["group_stage"]["qualified"]), "group stage resolves") and ok
	ok = _assert((b["survivors"] as Array).size() == 8, "8 clubs qualify to the knockout") and ok

	# Standings integrity: every club played 6 (double round-robin of 4), goals balance,
	# and points equal 3*wins + 1*draws per club.
	var played_ok := true
	var balance_ok := true
	var pts_ok := true
	var dup_ok := true
	var seen_q: Dictionary = {}
	for grp in Cup.group_tables(b):
		var sgf := 0
		var sga := 0
		for row in grp["table"]:
			played_ok = played_ok and int(row["p"]) == 6
			pts_ok = pts_ok and int(row["pts"]) == 3 * int(row["w"]) + int(row["d"])
			sgf += int(row["gf"])
			sga += int(row["ga"])
		balance_ok = balance_ok and sgf == sga
	for qid in b["survivors"]:
		dup_ok = dup_ok and not seen_q.has(int(qid))
		seen_q[int(qid)] = true
	ok = _assert(played_ok, "each club played 6 group games") and ok
	ok = _assert(balance_ok, "group goals-for == goals-against") and ok
	ok = _assert(pts_ok, "points = 3*wins + draws") and ok
	ok = _assert(dup_ok, "no club qualifies twice") and ok

	# The knockout then resolves to a champion drawn from the 8 qualifiers.
	var qualifiers: Array = (b["survivors"] as Array).duplicate()
	var kguard := 0
	while Cup.champion_id(b) == -1 and kguard < 20:
		Cup.play_round(b, rng, ratings_fn, career.club_id, names_fn)
		kguard += 1
	ok = _assert(Cup.champion_id(b) != -1, "the knockout resolves to a champion") and ok
	ok = _assert(qualifiers.has(Cup.champion_id(b)),
		"the champion came through the group stage") and ok
	return ok


# ---- two-legged tie rules (aggregate -> away goals -> ET -> penalties) ----

func _two_legged_rules() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	# Evenly matched sides so level ties (away goals / ET / penalties) actually occur.
	var r := {"att": 68.0, "def": 68.0, "gk": 68.0, "name": "Even"}
	var valid := ["agg", "away_goals", "aet", "pens"]
	var consistent := true
	var saw_nonagg := false
	var saw_et := false
	for _i in 300:
		var tie := Cup._play_two_leg_tie(rng, 1, 2, r, r)
		var decided := str(tie["decided"])
		consistent = consistent and valid.has(decided)
		# A clean aggregate result must hand the tie to the higher aggregate.
		if decided == "agg":
			var h_wins := int(tie["h_agg"]) > int(tie["a_agg"])
			consistent = consistent and (h_wins == (int(tie["winner_id"]) == 1))
		# A level aggregate must be settled by away goals / ET / penalties, never "agg".
		if int(tie["h_agg"]) == int(tie["a_agg"]):
			consistent = consistent and decided != "agg"
			saw_nonagg = true
		if decided == "aet" or decided == "pens":
			saw_et = tie.has("et_hg") and tie.has("et_ag")
	ok = _assert(consistent, "two-legged outcomes valid + aggregate-consistent") and ok
	ok = _assert(saw_nonagg, "level two-legged ties settled by away goals / ET / penalties") and ok
	ok = _assert(saw_et, "extra time is played before penalties (ET goals recorded)") and ok
	return ok
