extends SceneTree
## Headless test for injuries & suspensions (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_availability.gd
## Covers the Availability unit model (queries, weekly tick, match roll, ban
## threshold, season reset) and the Career integration (unavailable players are
## excluded from selection, weaken the ratings, and surface as club news, with a
## save/load round-trip of the new state).

const SEED := 71717171


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_queries() and ok
	ok = _unit_tick() and ok
	ok = _unit_roll_and_bans() and ok
	ok = _unit_injury_model() and ok
	ok = _unit_reset() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- unit: queries -------------------------------------------------------

func _unit_queries() -> bool:
	var ok := true
	var fit := {"name": "Fit", "injured_weeks": 0, "suspended_weeks": 0}
	var inj := {"name": "Hurt", "injured_weeks": 3, "suspended_weeks": 0}
	var sus := {"name": "Banned", "injured_weeks": 0, "suspended_weeks": 1}
	var bare := {"name": "New"}   # no fields -> treated as fit
	ok = _assert(Availability.is_available(fit), "fit player is available") and ok
	ok = _assert(Availability.is_available(bare), "player without fields defaults available") and ok
	ok = _assert(not Availability.is_available(inj), "injured player unavailable") and ok
	ok = _assert(not Availability.is_available(sus), "suspended player unavailable") and ok

	var squad: Array = [fit, inj, sus, bare]
	ok = _assert(Availability.available_players(squad).size() == 2, "available_players filters the 2 out") and ok
	ok = _assert(Availability.status_label(inj) == "INJ 3w", "injury status label") and ok
	ok = _assert(Availability.status_label(sus) == "SUS 1w", "suspension status label") and ok
	ok = _assert(Availability.status_label(fit) == "", "fit player has no badge") and ok
	# injury takes precedence over a concurrent suspension in the badge
	var both := {"name": "Both", "injured_weeks": 2, "suspended_weeks": 1}
	ok = _assert(Availability.status(both)["state"] == "INJ", "injury outranks suspension in status") and ok
	return ok


# ---- unit: weekly tick ---------------------------------------------------

func _unit_tick() -> bool:
	var ok := true
	var p := {"name": "Recoverer", "injured_weeks": 2, "suspended_weeks": 1, "yellows": 3}
	# Week 1: both counters drop by one, neither hits zero -> no news.
	var n1 := Availability.tick_week([p])
	ok = _assert(int(p["injured_weeks"]) == 1 and int(p["suspended_weeks"]) == 0,
		"tick decrements injury (2->1) and clears the 1-week ban") and ok
	# suspension reached 0 this tick -> one return news item
	ok = _assert(n1.size() == 1 and n1[0]["kind"] == "return", "ban-served emits a return item") and ok
	# Week 2: injury reaches 0 -> a fitness-return item; yellows untouched by tick.
	var n2 := Availability.tick_week([p])
	ok = _assert(int(p["injured_weeks"]) == 0, "tick clears the injury on week 2") and ok
	ok = _assert(n2.size() == 1 and n2[0]["kind"] == "return", "injury-return emits a return item") and ok
	ok = _assert(int(p["yellows"]) == 3, "tick does not touch the booking tally") and ok
	# Week 3: nothing active -> no news, no underflow.
	var n3 := Availability.tick_week([p])
	ok = _assert(n3.is_empty() and int(p["injured_weeks"]) == 0, "fit player ticks to nothing") and ok
	return ok


# ---- unit: match roll + ban threshold ------------------------------------

func _unit_roll_and_bans() -> bool:
	var ok := true
	# Deterministic seed: over many matches, the roll produces some injuries and some
	# bookings, and never leaves a negative counter.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var squad: Array = []
	for i in 11:
		squad.append({"name": "P%d" % i, "injured_weeks": 0, "suspended_weeks": 0, "yellows": 0})
	var injuries := 0
	var bans := 0
	var sane := true
	for _m in 200:
		# recover first so injured players don't accumulate forever
		Availability.tick_week(squad)
		var fit: Array = Availability.available_players(squad)
		for item in Availability.roll_match(rng, fit):
			if item["kind"] == "injury":
				injuries += 1
			elif item["kind"] == "suspension":
				bans += 1
		for p in squad:
			if int(p.get("injured_weeks", 0)) < 0 or int(p.get("suspended_weeks", 0)) < 0:
				sane = false
	ok = _assert(injuries > 0, "injuries occur over 200 matches (got %d)" % injuries) and ok
	ok = _assert(bans > 0, "suspensions occur over 200 matches (got %d)" % bans) and ok
	ok = _assert(sane, "no counter ever goes negative") and ok

	# Every injury carries a real binary-sourced diagnosis, and the news wording uses
	# the game's exact templates ("with a <type>", weeks not matches; serious ->
	# "badly injured"). Force injuries with chance 1.0 over the 18-name table.
	var r3 := RandomNumberGenerator.new()
	r3.seed = 999
	var typed_ok := true
	var saw_serious := false
	var saw_ordinary := false
	for _n in 300:
		var sq := [{"name": "Doc", "injured_weeks": 0}]
		var items := Availability.roll_match(r3, sq, 100.0)  # inj_chance clamps well past 1
		if items.is_empty():
			continue
		var it: Dictionary = items[0]
		if it["kind"] != "injury":
			continue
		var ti := int(it.get("type", -1))
		if ti < 0 or ti >= Availability.INJURY_TYPES.size():
			typed_ok = false
		var diag: String = Availability.injury_type_name(sq[0])
		if diag == "" or diag != Availability.INJURY_TYPES[ti]:
			typed_ok = false
		var txt: String = it["text"]
		if txt.find(diag) < 0 or txt.find("match") >= 0 or txt.find("week") < 0:
			typed_ok = false
		if ti >= Availability.SERIOUS_MIN:
			saw_serious = true
			if txt.find("badly injured") < 0:
				typed_ok = false
		else:
			saw_ordinary = true
	ok = _assert(typed_ok, "each injury has a real diagnosis + exact news wording") and ok
	ok = _assert(saw_serious and saw_ordinary, "both serious and ordinary injuries occur") and ok
	# Recovery clears the diagnosis, so a fit player reports no type.
	var rec := {"name": "Rec", "injured_weeks": 1, "injury_type": 17}
	Availability.tick_week([rec])
	ok = _assert(Availability.injury_type_name(rec) == "" and not rec.has("injury_type"),
		"recovery clears the injury diagnosis") and ok

	# The yellow threshold bans precisely: 4 bookings -> still available, the 5th -> a
	# 1-match ban with the tally reset. Force YELLOW (randf < YELLOW_CHANCE) via a seed
	# that draws low is fiddly, so exercise the rule by pre-loading 4 yellows and rolling
	# until a yellow lands.
	var q := {"name": "Booker", "injured_weeks": 0, "suspended_weeks": 0, "yellows": Availability.YELLOWS_FOR_BAN - 1}
	var r2 := RandomNumberGenerator.new()
	r2.seed = 12321
	var banned := false
	for _k in 500:
		var before := int(q["yellows"])
		var items := Availability.roll_match(r2, [q])
		if int(q.get("suspended_weeks", 0)) > 0 and int(q["yellows"]) == 0:
			banned = true
			ok = _assert(items.size() == 1 and items[0]["kind"] == "suspension",
				"5th booking triggers a suspension news item") and ok
			break
		# guard: a stray injury/red would end the loop; reset so we keep testing yellows
		if int(q.get("injured_weeks", 0)) > 0 or (int(q.get("suspended_weeks", 0)) > 0 and before == 0):
			q["injured_weeks"] = 0
			q["suspended_weeks"] = 0
			q["yellows"] = Availability.YELLOWS_FOR_BAN - 1
	ok = _assert(banned, "accumulating %d bookings forces a ban" % Availability.YELLOWS_FOR_BAN) and ok
	return ok


# ---- unit: binary-exact injury model -------------------------------------
# Locks the type distribution + per-type duration table to MANAGER.EXE
# (roll_B @0x585210 + setter @0x584e70). If a future edit drifts from the
# binary, these asserts fail. Bounds mirror tools/re/injury_model.py.

func _unit_injury_model() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242

	# 1) Match injuries never roll virus(0)/cold(1); every draw lands in the
	#    roll_B set {2..17}; each type actually occurs over enough draws.
	var seen := {}
	var valid := true
	for _i in 20000:
		var ti := Availability._roll_match_injury_type(rng)
		if ti < 2 or ti > 17:
			valid = false
		seen[ti] = int(seen.get(ti, 0)) + 1
	ok = _assert(valid, "match injury type always in roll_B set {2..17}") and ok
	var all_present := true
	for t in range(2, 18):
		if not seen.has(t):
			all_present = false
	ok = _assert(all_present, "every roll_B diagnosis (2..17) occurs") and ok
	# Pulled muscle (25%) is the modal match injury per the binary ladder.
	var modal := 2
	for t in seen:
		if int(seen[t]) > int(seen[modal]):
			modal = int(t)
	ok = _assert(modal == 2, "pulled muscle is the most common match injury") and ok

	# 2) Per-type duration bounds are exactly the binary jump-table range.
	#    {type: [min_weeks, max_weeks]} from tools/re/injury_model.py.
	var bounds := {
		2: [1, 2], 3: [1, 1], 4: [2, 3], 5: [3, 4], 6: [5, 8], 7: [2, 3],
		8: [1, 2], 9: [2, 2], 10: [2, 3], 11: [3, 5], 12: [18, 22],
		13: [6, 8], 14: [5, 10], 15: [25, 30], 16: [20, 28], 17: [40, 45],
	}
	var dur_ok := true
	for ti in bounds:
		var lo: int = bounds[ti][0]
		var hi: int = bounds[ti][1]
		var saw_lo := false
		var saw_hi := false
		for _j in 4000:
			var w := Availability._injury_weeks(rng, int(ti))
			if w < lo or w > hi:
				dur_ok = false
			if w == lo:
				saw_lo = true
			if w == hi:
				saw_hi = true
		# both extremes must be reachable (proves the coin formula, not a constant)
		if not (saw_lo and saw_hi):
			dur_ok = false
	ok = _assert(dur_ok, "per-type injury duration matches the binary jump table") and ok
	# Spot-check the two anchors a player will notice: dead leg is always 1 week,
	# a broken leg is season-ending (40..45 weeks).
	var dead_leg_const := true
	for _k in 500:
		if Availability._injury_weeks(rng, 3) != 1:
			dead_leg_const = false
	ok = _assert(dead_leg_const, "dead leg is exactly 1 week (binary)") and ok
	var broken := Availability._injury_weeks(rng, 17)
	ok = _assert(broken >= 40 and broken <= 45, "broken leg is 40..45 weeks (binary)") and ok
	return ok


# ---- unit: season reset --------------------------------------------------

func _unit_reset() -> bool:
	var squad: Array = [
		{"name": "A", "injured_weeks": 4, "suspended_weeks": 2, "yellows": 3},
		{"name": "B", "injured_weeks": 0, "suspended_weeks": 1, "yellows": 4},
	]
	Availability.reset(squad)
	var ok := true
	for p in squad:
		ok = _assert(int(p["injured_weeks"]) == 0 and int(p["suspended_weeks"]) == 0 and int(p["yellows"]) == 0,
			"reset clears %s" % p["name"]) and ok
	return ok


# ---- integration: a career feels the absences -----------------------------

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

	# Seeded squads carry zeroed availability fields.
	var seeded_clean := true
	for p in career.my_squad():
		if int(p.get("injured_weeks", -1)) != 0 or int(p.get("suspended_weeks", -1)) != 0:
			seeded_clean = false
	ok = _assert(seeded_clean, "fresh squad reports fully fit") and ok

	# Baseline ratings with everyone fit.
	var full := career._ratings_for(career.club_id)
	# Knock out the manager's five strongest XI players -> the side must rate weaker.
	var xi_players := career._mgr_featured_xi()
	xi_players.sort_custom(func(a, b):
		return MatchEngine.atk_score(a.get("attrs", {})) + MatchEngine.def_score(a.get("attrs", {})) \
			> MatchEngine.atk_score(b.get("attrs", {})) + MatchEngine.def_score(b.get("attrs", {})))
	var knocked := mini(5, xi_players.size())
	for i in knocked:
		xi_players[i]["injured_weeks"] = 2
	ok = _assert(career.available_squad().size() == career.my_squad().size() - knocked,
		"injured players drop out of the available squad") and ok
	var depleted := career._ratings_for(career.club_id)
	ok = _assert((depleted["att"] + depleted["def"]) < (full["att"] + full["def"]),
		"losing the best 5 weakens the rated side (%.1f -> %.1f)" % [
			full["att"] + full["def"], depleted["att"] + depleted["def"]]) and ok
	# The repaired XI never fields an unavailable player.
	var fields_fit := true
	for p in career._mgr_featured_xi():
		if not Availability.is_available(p):
			fields_fit = false
	ok = _assert(fields_fit, "the repaired XI fields only available players") and ok

	# Play a season: news accrues (results + any knocks), counters stay non-negative.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	ok = _assert(not career.news_log.is_empty(), "club news accrues over a season (%d items)" % career.news_log.size()) and ok
	var has_result := false
	for n in career.news_log:
		if n is Dictionary and n.get("kind") == "result":
			has_result = true
	ok = _assert(has_result, "the feed carries matchday result headlines") and ok

	# Save / load round-trip preserves the news feed + per-player availability.
	var path := "user://career_avail_test.json"
	# stamp a known injury so the round-trip has something to verify
	if not career.my_squad().is_empty():
		career.my_squad()[0]["injured_weeks"] = 3
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career with news/availability loads back") and ok
	if loaded != null:
		ok = _assert(loaded.news_log.size() == career.news_log.size(), "news feed survived round-trip") and ok
		var first: Dictionary = loaded.my_squad()[0] if not loaded.my_squad().is_empty() else {}
		ok = _assert(int(first.get("injured_weeks", 0)) == 3, "per-player injury survived round-trip") and ok
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
