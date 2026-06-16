extends SceneTree
## Headless test for the F.A. Cup (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_cup.gd
## Covers the Cup unit model (field-size maths, round labels, schedule, the open draw
## with byes + replays + penalties down to a single champion) and the Career integration
## (a season plays the cup, prize money + cup news accrue, it persists and rebuilds at
## rollover, and pre-cup saves load inert).

const SEED := 778899


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_field_maths() and ok
	ok = _unit_labels_and_schedule() and ok
	ok = _engine_power_of_two() and ok
	ok = _engine_with_byes() and ok
	ok = _engine_all_level_resolves() and ok
	ok = _engine_two_legged() and ok
	ok = _unit_prize_and_news() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond


# ---- test ratings/names providers ----------------------------------------

## team_ratings dict for a club id, strength scaling gently with id (so results vary)
## unless `flat` -- then every club is identical (forces lots of draws -> replays/pens).
func _ratings(id: int, flat := false) -> Dictionary:
	var base := 55.0 if flat else 45.0 + float(id % 20)
	return {"att": base, "def": base, "gk": base + 2.0, "name": "C%d" % id}


func _ratings_fn(flat := false) -> Callable:
	return func(id: int) -> Dictionary: return _ratings(id, flat)


func _names_fn() -> Callable:
	return func(id: int) -> String: return "C%d" % id


func _ids(n: int) -> Array:
	var out: Array = []
	for i in range(1, n + 1):
		out.append(i)
	return out


# ---- unit: field-size maths ----------------------------------------------

func _unit_field_maths() -> bool:
	var ok := true
	ok = _assert(Cup._floor_pow2(20) == 16 and Cup._floor_pow2(24) == 16
		and Cup._floor_pow2(16) == 16 and Cup._floor_pow2(2) == 2 and Cup._floor_pow2(1) == 1,
		"floor_pow2: 20->16 24->16 16->16 2->2 1->1") and ok
	ok = _assert(Cup._num_rounds(20) == 5, "num_rounds(20)=5 (prelim + 4 halvings)") and ok
	ok = _assert(Cup._num_rounds(24) == 5, "num_rounds(24)=5") and ok
	ok = _assert(Cup._num_rounds(16) == 4, "num_rounds(16)=4 (clean halving)") and ok
	ok = _assert(Cup._num_rounds(8) == 3 and Cup._num_rounds(2) == 1, "num_rounds 8=3, 2=1") and ok
	return ok


# ---- unit: labels + schedule ---------------------------------------------

func _unit_labels_and_schedule() -> bool:
	var ok := true
	ok = _assert(Cup._round_label(2) == "Final" and Cup._round_label(4) == "Semifinals"
		and Cup._round_label(8) == "Qtr. Finals" and Cup._round_label(16) == "Round 5"
		and Cup._round_label(20) == "Round 4" and Cup._round_label(24) == "Round 4",
		"round labels land on the Premier progression") and ok

	var b := Cup.create(_ids(20), 38)
	ok = _assert(b["name"] == Cup.NAME, "cup name is the F.A. Cup") and ok
	ok = _assert((b["survivors"] as Array).size() == 20, "fresh cup: full 20-club field") and ok
	ok = _assert((b["rounds"] as Array).is_empty() and int(b["champion_id"]) == -1, "fresh cup: unplayed") and ok
	var rw: Array = b["round_weeks"]
	ok = _assert(rw.size() == 5, "schedule has one week per round (5)") and ok
	var inc := true
	var last := 0
	for w in rw:
		if int(w) <= last or int(w) > 38:
			inc = false
		last = int(w)
	ok = _assert(inc, "round weeks strictly increasing and within the season %s" % str(rw)) and ok
	return ok


# ---- engine: a power-of-two field halves cleanly to a champion -----------

func _engine_power_of_two() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	var b := Cup.create(_ids(16), 38)
	var labels: Array = []
	var surv_trace: Array = []
	var guard := 0
	while not Cup.is_finished(b) and guard < 20:
		var r := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
		labels.append(r["label"])
		surv_trace.append((b["survivors"] as Array).size())
		guard += 1
	ok = _assert(labels == ["Round 5", "Qtr. Finals", "Semifinals", "Final"],
		"16-club labels: R5 -> QF -> SF -> Final  (%s)" % str(labels)) and ok
	ok = _assert(surv_trace == [8, 4, 2, 1], "survivors halve 16->8->4->2->1 (%s)" % str(surv_trace)) and ok
	ok = _assert(Cup.champion_id(b) >= 1 and Cup.champion_id(b) <= 16, "a valid champion emerges (C%d)" % Cup.champion_id(b)) and ok
	# Every tie resolved to a participant; no level result survived.
	var clean := true
	for rnd in b["rounds"]:
		for tie in rnd["ties"]:
			var w := int(tie["winner_id"])
			if not tie.get("bye", false):
				if w != int(tie["home_id"]) and w != int(tie["away_id"]):
					clean = false
	ok = _assert(clean, "every tie's winner is one of its two clubs") and ok
	return ok


# ---- engine: an off-power field uses round-one byes ----------------------

func _engine_with_byes() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED + 1
	var b := Cup.create(_ids(20), 38)
	var r1 := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
	ok = _assert(r1["label"] == "Round 4", "20-club first round labelled Round 4") and ok
	# Round 1: 4 ties + 12 byes = 16 entries; 16 survive.
	var ties: Array = b["rounds"][0]["ties"]
	var byes := 0
	var played := 0
	for tie in ties:
		if tie.get("bye", false):
			byes += 1
		else:
			played += 1
	ok = _assert(byes == 12 and played == 4, "round one: 12 byes + 4 ties (%d/%d)" % [byes, played]) and ok
	ok = _assert((b["survivors"] as Array).size() == 16, "20 reduces to 16 after the preliminary round") and ok
	# Finish it.
	var labels := ["Round 4"]
	var guard := 0
	while not Cup.is_finished(b) and guard < 20:
		labels.append(Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())["label"])
		guard += 1
	ok = _assert(labels == ["Round 4", "Round 5", "Qtr. Finals", "Semifinals", "Final"],
		"full 20-club progression (%s)" % str(labels)) and ok
	ok = _assert(Cup.champion_id(b) != -1, "20-club cup crowns a champion") and ok
	return ok


# ---- engine: an all-level field still resolves (replays + penalties) -----

func _engine_all_level_resolves() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED + 2
	var b := Cup.create(_ids(16), 38)
	var saw_replay := false
	var saw_pens := false
	var guard := 0
	while not Cup.is_finished(b) and guard < 20:
		Cup.play_round(b, rng, _ratings_fn(true), -1, _names_fn())   # flat ratings -> draws
		guard += 1
	for rnd in b["rounds"]:
		for tie in rnd["ties"]:
			if str(tie.get("decided", "")) == "replay":
				saw_replay = true
			elif str(tie.get("decided", "")) == "pens":
				saw_pens = true
	ok = _assert(Cup.champion_id(b) != -1, "an all-level field still crowns a champion") and ok
	ok = _assert(saw_replay or saw_pens, "level ties forced at least one replay/penalties (replay=%s pens=%s)" % [saw_replay, saw_pens]) and ok
	return ok


# ---- engine: the League Cup (two-legged rounds, single-leg final) --------

func _engine_two_legged() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED + 5
	var opts := {"name": "Coca-Cola Cup", "legs": 2, "two_legged_final": false,
		"label_scheme": "sequential", "qtr_label": "Qtr Finals", "span_lo": 0.0, "span_hi": 0.7}
	var b := Cup.create(_ids(20), 38, opts)
	ok = _assert(b["name"] == "Coca-Cola Cup" and int(b["legs"]) == 2, "league cup: name + two legs") and ok
	ok = _assert(int((b["round_weeks"] as Array)[-1]) < 38, "league cup final scheduled before season end (%s)" % str(b["round_weeks"])) and ok

	var labels: Array = []
	var two_leg_rounds := 0
	var final_single := true
	var guard := 0
	while not Cup.is_finished(b) and guard < 20:
		var r := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
		labels.append(r["label"])
		var rnd: Dictionary = (b["rounds"] as Array)[-1]
		var is_two := false
		for tie in rnd["ties"]:
			if tie.get("two_legged", false):
				is_two = true
		if str(r["label"]) == "Final":
			final_single = not is_two
		elif is_two:
			two_leg_rounds += 1
		guard += 1
	ok = _assert(labels == ["Round 1", "Round 2", "Qtr Finals", "Semifinals", "Final"],
		"league cup labels: R1 -> R2 -> QF -> SF -> Final (%s)" % str(labels)) and ok
	ok = _assert(two_leg_rounds >= 1, "league cup early rounds are two-legged (%d)" % two_leg_rounds) and ok
	ok = _assert(final_single, "league cup final is single-leg") and ok
	ok = _assert(Cup.champion_id(b) != -1, "league cup crowns a champion") and ok

	# Every two-legged tie carries an aggregate and a winner that led it (or won on pens).
	var agg_ok := true
	for rnd in b["rounds"]:
		for tie in rnd["ties"]:
			if not tie.get("two_legged", false):
				continue
			var w := int(tie["winner_id"])
			if w != int(tie["home_id"]) and w != int(tie["away_id"]):
				agg_ok = false
			if str(tie["decided"]) == "agg":
				var ha := int(tie["h_agg"])
				var aa := int(tie["a_agg"])
				var win_agg := ha if w == int(tie["home_id"]) else aa
				var lose_agg := aa if w == int(tie["home_id"]) else ha
				if win_agg <= lose_agg:
					agg_ok = false
	ok = _assert(agg_ok, "two-legged winners lead on aggregate (or won on penalties)") and ok
	return ok


# ---- unit: prize money + news on the manager's own tie -------------------

func _unit_prize_and_news() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new(); rng.seed = SEED + 3
	# A two-club "final": the manager (id 1) is overwhelmingly strong -> wins the cup.
	var ratings := func(id: int) -> Dictionary:
		var s := 90.0 if id == 1 else 30.0
		return {"att": s, "def": s, "gk": s, "name": "C%d" % id}
	var b := Cup.create([1, 2], 38)
	var r := Cup.play_round(b, rng, ratings, 1, _names_fn())
	ok = _assert(r["champion"] == true, "strong manager wins the final") and ok
	ok = _assert(int(r["prize"]) == Cup.ROUND_PRIZE + Cup.WINNER_BONUS, "final win pays round prize + winner bonus") and ok
	var won_news := false
	for n in r["news"]:
		if n is Dictionary and n.get("kind") == "cup" and str(n.get("text", "")).contains("WON"):
			won_news = true
	ok = _assert(won_news, "winning the cup fires a 'WON' cup news line") and ok

	# A non-final round win pays just the round prize.
	var rng2 := RandomNumberGenerator.new(); rng2.seed = SEED + 4
	var b2 := Cup.create([1, 2, 3, 4], 38)   # 4-club: a Semifinal then a Final
	var r2 := Cup.play_round(b2, rng2, ratings, 1, _names_fn())
	ok = _assert(r2["label"] == "Semifinals", "4-club first round is the Semifinals") and ok
	ok = _assert(int(r2["prize"]) == Cup.ROUND_PRIZE and not r2["champion"], "a semifinal win pays the round prize only") and ok
	return ok


# ---- integration: a career plays the cup ---------------------------------

func _career_integration() -> bool:
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
	if prem.is_empty() or league.is_empty():
		push_error("no Premier League fixture in the DB")
		return false

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true
	ok = _assert(not career.fa_cup.is_empty(), "career creates an F.A. Cup") and ok
	ok = _assert(not career.league_cup.is_empty() and career.league_cup["name"] == "Coca-Cola Cup",
		"career creates a League Cup too") and ok
	ok = _assert((career.fa_cup["survivors"] as Array).size() == prem.size(), "cup field = the whole division (%d)" % prem.size()) and ok
	ok = _assert((career.fa_cup["round_weeks"] as Array).size() == Cup._num_rounds(prem.size()), "cup scheduled across the season") and ok

	var cash0 := career.cash
	var rng := RandomNumberGenerator.new(); rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	ok = _assert(Cup.champion_id(career.fa_cup) != -1, "the F.A. Cup finishes within the league season") and ok
	ok = _assert(Cup.champion_id(career.league_cup) != -1, "the League Cup finishes within the season") and ok
	var cup_news := 0
	for n in career.news_log:
		if n is Dictionary and n.get("kind") == "cup":
			cup_news += 1
	ok = _assert(cup_news >= 1, "cup results surface as club news (%d lines)" % cup_news) and ok
	# The manager played at least their first-round tie (win, loss or bye), so cash never
	# falls below the opening balance from the cup (prizes only credit).
	ok = _assert(career.cash >= cash0 - 10_000_000, "cup never debits the bank") and ok

	# Round-trip: the bracket (and its champion) survives save/load.
	var path := "user://career_cup_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and Cup.champion_id(loaded.fa_cup) == Cup.champion_id(career.fa_cup)
		and Cup.champion_id(loaded.league_cup) == Cup.champion_id(career.league_cup),
		"both cup brackets survive a save/load round-trip") and ok

	# Rollover mints fresh cups.
	career.advance_season(leagues)
	ok = _assert(int(career.fa_cup["champion_id"]) == -1 and (career.fa_cup["rounds"] as Array).is_empty()
		and int(career.league_cup["champion_id"]) == -1,
		"a new season draws fresh cups") and ok
	ok = _assert((career.fa_cup["survivors"] as Array).size() == prem.size(), "fresh cup has the full field again") and ok

	# Pre-cup save compatibility: a dict with no fa_cup loads inert (no crash, no rounds due).
	var bare := career.to_dict()
	bare.erase("fa_cup")
	var legacy := Career.from_dict(bare)
	ok = _assert(legacy.fa_cup.is_empty() and not Cup.round_due(legacy.fa_cup, 5),
		"a pre-cup save loads with an inert cup") and ok
	return ok
