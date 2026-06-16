extends SceneTree
## Headless test for the winners-of-winners finals (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_supercups.gd
## Covers the European Supercup (last season's European Cup winner v Cup Winners' Cup
## winner) and the Intercontinental Cup (European Cup winner v the South American champion):
## capturing + freezing last season's European winners across the rollover, contesting both
## one-off finals, the manager's prize + news, and save/load.

const SEED := 36912


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _two_season_flow() and ok
	ok = _winner_prize_and_news() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond


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
	var c := Career.create(prem[0], league, prem, leagues)
	c.set_meta("leagues", leagues)
	return c


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


func _fake_sa() -> Dictionary:
	var players: Array = [{"isGK": true, "attrs": {"PO": 78}}]
	for _o in 10:
		players.append({"attrs": {
			"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70,
			"RG": 70, "PA": 70, "TI": 70, "EN": 70, "PO": 5}})
	return {"id": 80001, "name": "Boca Juniors", "players": players}


# ---- full two-season flow -------------------------------------------------

func _two_season_flow() -> bool:
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var leagues: Array = career.get_meta("leagues")
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED

	# Season 1 -> rollover mints Europe for season 2.
	while not career.season_over():
		career.advance_week(rng)
	career.advance_season(leagues, rng, _fake_pool(60), _fake_sa())
	ok = _assert(career.euro.size() == 3, "season 2 has European competitions") and ok
	ok = _assert(career.supercup.is_empty() and career.intercontinental.is_empty(),
		"no Supercup yet (no prior European winners)") and ok

	# Season 2 -> its European comps resolve; rollover contests the winners-of-winners.
	while not career.season_over():
		career.advance_week(rng)
	var exp_cup := Cup.champion_id(career.euro["european_cup"])
	var exp_cwc := Cup.champion_id(career.euro["cup_winners_cup"])
	career.advance_season(leagues, rng, _fake_pool(60), _fake_sa())

	ok = _assert(career.euro_winner_cup == exp_cup,
		"European Cup winner captured across the rollover (%d)" % career.euro_winner_cup) and ok
	ok = _assert(career.euro_winner_cwc == exp_cwc,
		"Cup Winners' Cup winner captured (%d)" % career.euro_winner_cwc) and ok
	ok = _assert(career.euro_winner_ratings.has(exp_cup),
		"the European Cup winner's rating was frozen for the finals") and ok

	# Supercup: European Cup winner v Cup Winners' Cup winner (unless the same club).
	if exp_cup != exp_cwc and exp_cwc != -1:
		var sc := career.supercup
		ok = _assert(not sc.is_empty(), "the European Supercup was contested") and ok
		ok = _assert(int(sc.get("home_id", -1)) == exp_cup and int(sc.get("away_id", -1)) == exp_cwc,
			"Supercup is Euro Cup winner v Cup Winners' Cup winner") and ok
		ok = _assert(int(sc.get("winner_id", -1)) in [exp_cup, exp_cwc],
			"Supercup has a valid winner") and ok

	# Intercontinental: European Cup winner v the South American champion.
	var ic := career.intercontinental
	ok = _assert(not ic.is_empty(), "the Intercontinental Cup was contested") and ok
	ok = _assert(int(ic.get("home_id", -1)) == exp_cup and int(ic.get("away_id", -1)) == 80001,
		"Intercontinental is Euro Cup winner v the S. American champion") and ok
	ok = _assert(career.euro_winner_names.get(80001, "") == "Boca Juniors",
		"the S. American champion's name was frozen") and ok

	# Save/load preserves both finals + the captured winners.
	var path := "user://career_supercup_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null
		and loaded.euro_winner_cup == career.euro_winner_cup
		and int(loaded.intercontinental.get("winner_id", -2)) == int(ic.get("winner_id", -1))
		and int(loaded.supercup.get("winner_id", -2)) == int(career.supercup.get("winner_id", -1)),
		"finals + captured winners survive save/load") and ok
	return ok


# ---- the manager's prize + news ------------------------------------------

func _winner_prize_and_news() -> bool:
	var career := _prem_career()
	if career == null:
		return _assert(false, "Premier fixture present in game_db")
	var ok := true
	var cid := career.club_id
	career.euro_winner_names = {cid: "My Club", 555: "Rivals"}
	var cash0 := career.cash
	# Manager lifts the Supercup.
	career._record_supercup_news({"winner_id": cid, "loser_id": 555, "decided": ""},
		"European Supercup", Career.SUPERCUP_PRIZE)
	ok = _assert(career.cash == cash0 + Career.SUPERCUP_PRIZE,
		"winning the Supercup pays the prize (+%d)" % Career.SUPERCUP_PRIZE) and ok
	var won_news := false
	for n in career.news_log:
		if n is Dictionary and str(n.get("text", "")).findn("won the european supercup") != -1:
			won_news = true
	ok = _assert(won_news, "the Supercup win surfaces as club news") and ok
	# Manager loses the Intercontinental: no prize, but a news line still fires.
	var cash1 := career.cash
	career._record_supercup_news({"winner_id": 555, "loser_id": cid, "decided": "pens"},
		"Intercontinental Cup", Career.INTERCONTINENTAL_PRIZE)
	ok = _assert(career.cash == cash1, "losing a final pays nothing") and ok
	return ok
