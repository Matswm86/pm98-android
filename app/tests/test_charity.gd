extends SceneTree
## Headless test for cross-season honours + the Charity Shield (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_charity.gd
## Covers the single-neutral-match unit (decisive + level->penalties), honours capture at
## rollover (champion / runners-up / F.A. Cup winner), the curtain-raiser between champions
## and F.A. Cup winners, the Double -> runners-up substitution, prize + news, and save/load.

const SEED := 246810


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_single_match() and ok
	ok = _career_honours_and_shield() and ok
	ok = _double_substitution() and ok
	ok = _first_season_seed() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond


# ---- first-season curtain-raiser --------------------------------------------
# Fixed honours: Man Utd (40) v Chelsea (49). Witnessed live 2026-07-23 in the wine original:
#  - a CONTESTANT (managing Man Utd) PLAYS the shield as his first fixture (MATCH OPTIONS ->
#    KICK OFF -> full time -> champion card), result varies (Man Utd 3-2 Chelsea observed);
#  - a NON-participant (Barnsley) sees it auto-resolved into the card, winner AND decider
#    varying between fresh careers (Man Utd on pens / Chelsea clean).
func _first_season_seed() -> bool:
	var ok := true

	# (A) NON-PARTICIPANT: auto-resolved into the card, result depends on the RNG.
	var winners := {}
	var pens_seen := false
	for s in 40:
		var c := Career.new()
		c.season = "1997-98"; c.club_id = 44   # not a contestant
		c.last_champion_id = -1
		c.club_names = {40: "Manchester Utd.", 49: "Chelsea", 44: "Newcastle Utd"}
		var r := RandomNumberGenerator.new(); r.seed = SEED + s * 101
		c.play_season_opener(r)
		var t := c.charity_shield
		ok = _assert(not c.charity_shield_pending, "non-participant does NOT play the shield") and ok
		winners[int(t.get("winner_id", -1))] = true
		if str(t.get("decided", "")) == "pens":
			pens_seen = true
	ok = _assert(int(winners.keys()[0]) in [40, 49], "auto shield winner is a contestant") and ok
	ok = _assert(winners.has(40) and winners.has(49), "auto shield is simulated: both clubs win across seeds") and ok
	ok = _assert(pens_seen, "a level auto shield goes to penalties across seeds") and ok

	# (B) PARTICIPANT (manages Man Utd): the shield is PENDING -- he plays it himself.
	var car := Career.new()
	car.season = "1997-98"; car.club_id = 40
	car.last_champion_id = -1
	car.club_names = {40: "Manchester Utd.", 49: "Chelsea"}
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	car.play_season_opener(rng)
	ok = _assert(car.charity_shield_pending, "a contestant PLAYS the shield (pending, not auto-resolved)") and ok
	var p := car.pending_charity_shield()
	ok = _assert(int(p.get("champ_id", -1)) == 40 and int(p.get("fa_id", -1)) == 49,
		"pending shield is Man Utd v Chelsea") and ok
	ok = _assert(int(p.get("opp_id", -1)) == 49 and bool(p.get("home", false)),
		"Man Utd manager is home vs Chelsea") and ok
	ok = _assert(int(car.charity_shield.get("winner_id", -99)) == -99, "no winner until it is played") and ok
	# Play it: returns the match-result shape; the champion card reads the stored result.
	var res := car.play_charity_shield_match(rng, {})
	ok = _assert(not res.is_empty() and bool(res.get("charity", false)), "play returns a charity match result") and ok
	ok = _assert(int(res.get("home_id", -1)) == 40 and int(res.get("away_id", -1)) == 49,
		"played shield: Man Utd home, Chelsea away") and ok
	var cs := car.charity_shield
	ok = _assert(not car.charity_shield_pending, "pending cleared after playing") and ok
	ok = _assert(int(cs.get("winner_id", -1)) in [40, 49]
		and int(cs.get("loser_id", -1)) in [40, 49]
		and int(cs.get("loser_id", -1)) != int(cs.get("winner_id", -1)), "played shield records a winner + loser") and ok
	ok = _assert(str(cs.get("decided", "x")) in ["", "pens"], "played shield decider is normal time or penalties") and ok
	# Save/load round-trips the pending flag.
	var car2 := Career.new()
	car2.season = "1997-98"; car2.club_id = 40
	car2.last_champion_id = -1
	car2.club_names = {40: "Manchester Utd.", 49: "Chelsea"}
	car2.play_season_opener(RandomNumberGenerator.new())
	var re := Career.from_dict(car2.to_dict())
	ok = _assert(re.charity_shield_pending, "pending shield survives save/load") and ok
	return ok


# ---- unit: single neutral match ------------------------------------------

func _unit_single_match() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	# Strong (id 1) vs weak (id 2): a clear winner emerges, never a bye, valid loser.
	var strong := func(id: int) -> Dictionary:
		var b := 80.0 if id == 1 else 30.0
		return {"att": b, "def": b, "gk": b, "name": "C%d" % id}
	var t := Cup.single_neutral_match(rng, 1, 2, strong)
	ok = _assert(int(t["winner_id"]) in [1, 2] and int(t["loser_id"]) in [1, 2]
		and int(t["winner_id"]) != int(t["loser_id"]) and not t.get("bye", false),
		"single match returns one winner, one loser, never a bye") and ok
	ok = _assert(t.has("hg") and t.has("ag"), "single match records a scoreline") and ok
	# Identical sides over many runs: some matches go level and are settled on penalties.
	var pens := 0
	for i in 60:
		var flat := func(id: int) -> Dictionary: return {"att": 50.0, "def": 50.0, "gk": 50.0, "name": "x"}
		var tt := Cup.single_neutral_match(rng, 1, 2, flat)
		if str(tt.get("decided", "")) == "pens":
			ok = _assert(int(tt["hg"]) == int(tt["ag"]), "a penalties result was level in normal time") and ok
			pens += 1
	ok = _assert(pens > 0, "level ties go to penalties over many runs (%d/60)" % pens) and ok
	return ok


# ---- career: honours capture + the shield --------------------------------

func _prem_fixture() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return {}
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
	return {"leagues": leagues, "league": league, "prem": prem}


func _career_honours_and_shield() -> bool:
	var fx := _prem_fixture()
	if fx.is_empty() or (fx["prem"] as Array).is_empty():
		return _assert(false, "Premier fixture present in game_db")
	var leagues: Array = fx["leagues"]
	var prem: Array = fx["prem"]
	var career := Career.create(prem[0], fx["league"], prem, leagues)
	var ok := true

	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)

	# Expected honours, read off the finished season BEFORE the rollover rebuilds it.
	var final_table := career.standings()
	var exp_champ := int(final_table[0]["id"])
	var exp_runner := int(final_table[1]["id"])
	var exp_fa := Cup.champion_id(career.fa_cup)
	ok = _assert(exp_fa != -1, "F.A. Cup produced a winner to contest the shield") and ok

	career.advance_season(leagues, rng)

	ok = _assert(career.last_champion_id == exp_champ,
		"champion captured (%d)" % career.last_champion_id) and ok
	ok = _assert(not career.last_runners_up.is_empty() and int(career.last_runners_up[0]) == exp_runner,
		"runners-up order captured (2nd = %d)" % exp_runner) and ok
	ok = _assert(career.last_fa_winner_id == exp_fa,
		"F.A. Cup winner captured (%d)" % career.last_fa_winner_id) and ok

	var cs := career.charity_shield
	ok = _assert(not cs.is_empty(), "the Charity Shield was staged at rollover") and ok
	var champ := int(cs.get("champ_id", -1))
	var fa := int(cs.get("fa_id", -1))
	ok = _assert(champ == exp_champ, "shield home side = the champions") and ok
	ok = _assert(fa == exp_fa or (exp_fa == exp_champ and fa == exp_runner),
		"shield away side = F.A. Cup winners (or runners-up if a Double)") and ok
	# The manager (prem[0]) may himself be a contestant -> the shield is PENDING (he plays it);
	# otherwise it auto-resolves into a winner + a news line.
	var path := "user://career_charity_test.json"
	if career.charity_shield_pending:
		ok = _assert(career.club_id == champ or career.club_id == fa,
			"pending only when the manager is a contestant") and ok
		career.save(path)
		var lp := Career.load_save(path)
		ok = _assert(lp != null and lp.charity_shield_pending, "pending shield survives save/load") and ok
	else:
		var w := int(cs.get("winner_id", -1))
		ok = _assert(w == champ or w == fa, "shield winner is one of the two contestants") and ok
		var newcup := 0
		for n in career.news_log:
			if n is Dictionary and n.get("kind") == "cup" and str(n.get("text", "")).findn("charity shield") != -1:
				newcup += 1
		ok = _assert(newcup >= 1, "the shield result surfaces as club news") and ok
		career.save(path)
		var loaded := Career.load_save(path)
		ok = _assert(loaded != null
			and loaded.last_champion_id == career.last_champion_id
			and loaded.last_fa_winner_id == career.last_fa_winner_id
			and int(loaded.charity_shield.get("winner_id", -2)) == w,
			"honours + shield survive save/load") and ok
	return ok


# ---- the Double: champions also won the F.A. Cup -> runners-up step up -----

func _double_substitution() -> bool:
	var fx := _prem_fixture()
	if fx.is_empty() or (fx["prem"] as Array).is_empty():
		return _assert(false, "Premier fixture present in game_db")
	var prem: Array = fx["prem"]
	var career := Career.create(prem[0], fx["league"], prem, fx["leagues"])
	var ok := true
	# Force a Double: the champions also hold the F.A. Cup. The league runners-up should
	# take the vacant shield berth.
	var champ := int(prem[0]["id"])
	var runner := int(prem[1]["id"])
	career.last_champion_id = champ
	career.last_fa_winner_id = champ           # same club -> Double
	career.last_runners_up = [runner]
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	career._play_charity_shield(rng)
	var cs := career.charity_shield
	ok = _assert(not cs.is_empty(), "Double still produces a shield") and ok
	ok = _assert(int(cs.get("champ_id", -1)) == champ and int(cs.get("fa_id", -1)) == runner,
		"Double: runners-up (%d) replace the champions in the second berth" % runner) and ok
	return ok
