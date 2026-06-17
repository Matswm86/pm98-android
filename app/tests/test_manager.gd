extends SceneTree
## Headless test for the manager career across clubs (#14): the Manager decision math,
## then the Career integration -- board review, sacking, taking a new job, the history
## record and reputation carrying across the move, with a save/load round-trip.
##   ~/godot462 --headless --path app --script res://tests/test_manager.gd

const SEED := 4242


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := _unit_manager()
	ok = _integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- Manager.gd pure decision math ---------------------------------------

func _unit_manager() -> bool:
	var ok := true
	# Reputation: beating the objective is positive, missing it negative; trophies + drop.
	ok = _assert(Manager.reputation_delta(1, 6, 20, 3, {"league": true}) > 0.0,
		"winning while well above objective lifts reputation") and ok
	ok = _assert(Manager.reputation_delta(18, 8, 20, 3) < 0.0,
		"finishing below objective lowers reputation") and ok
	ok = _assert(Manager.reputation_delta(19, 8, 20, 3) < Manager.reputation_delta(12, 8, 20, 3),
		"relegation (19th) costs more reputation than a mid-table miss") and ok

	# Sacking: relegated when survival wasn't the brief -> sacked; a big gap -> sacked.
	ok = _assert(bool(Manager.sack_decision(19, 8, 20, 3, false, 3)["sacked"]),
		"relegated with a non-survival objective is a sacking") and ok
	ok = _assert(not bool(Manager.sack_decision(19, 17, 20, 3, true, 3)["sacked"]),
		"relegated is forgiven when the brief was survival") and ok
	ok = _assert(bool(Manager.sack_decision(15, 8, 20, 3, false, 3)["sacked"]),
		"finishing 7 below objective (>= SACK_GAP) is a sacking") and ok
	ok = _assert(not bool(Manager.sack_decision(13, 8, 20, 3, false, 1)["sacked"]),
		"first season gets more slack (5 below objective survives)") and ok
	ok = _assert(not bool(Manager.sack_decision(9, 8, 20, 3, false, 3)["sacked"]),
		"just below objective is not a sacking") and ok

	# Offers: a stronger reputation commands a higher strength band; a sacking dents it.
	var strong := Manager.offer_band(90.0, false)
	var weak := Manager.offer_band(20.0, false)
	ok = _assert(float(strong["hi"]) > float(weak["hi"]),
		"higher reputation offers stronger clubs") and ok
	var clean := Manager.offer_band(70.0, false)
	var dented := Manager.offer_band(70.0, true)
	ok = _assert(float(dented["hi"]) <= float(clean["hi"]),
		"being sacked does not raise the offer band") and ok

	# Headhunting: overachieve + high reputation -> a suitor can appear; underachieve -> never.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	ok = _assert(not Manager.headhunted(10, 11, 80.0, rng),
		"no headhunt without beating the objective by HEADHUNT_GAP") and ok
	var any := false
	for s in 40:
		var r := RandomNumberGenerator.new()
		r.seed = s
		if Manager.headhunted(1, 8, 85.0, r):
			any = true
			break
	ok = _assert(any, "a strong overachiever does get headhunted across seeds") and ok
	return ok


# ---- Career integration --------------------------------------------------

func _integration() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])

	var prem: Array = []
	var div1: Array = []
	var prem_lg: Dictionary = {}
	var div1_lg: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			prem_lg = lg
		elif lg.get("id") == "eng_div1":
			div1_lg = lg
	for c in all:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
		elif c.get("leagueId") == "eng_div1":
			div1.append(c)
	if prem.is_empty() or div1.is_empty() or prem_lg.is_empty() or div1_lg.is_empty():
		push_error("expected Premier + Division One clubs/leagues")
		return false

	var ok := true

	# Manage the weakest top-flight club so it finishes low; force an unmeetable objective so
	# the board review sacks the manager deterministically.
	prem.sort_custom(func(a, b): return _ovr(a) < _ovr(b))
	var career := Career.create(prem[0], prem_lg, prem, leagues)
	ok = _assert(absf(career.reputation - Manager.REP_START) < 0.01, "a new career starts at REP_START") and ok
	ok = _assert(career.seasons_at_club() == 1, "first season at the club") and ok

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	var fp := career.position()
	ok = _assert(fp >= 10, "the weakest club finished in the bottom half (got %d)" % fp) and ok

	career.objective_pos = 1                  # the board demanded the title
	career.objective_text = "Win the league"  # ... so it is not a survival brief
	var rep_before := career.reputation
	var rv := career.board_review()
	ok = _assert(bool(rv["sacked"]), "missing an unmeetable objective gets you sacked") and ok
	ok = _assert(career.sacked, "the career is flagged sacked") and ok
	ok = _assert(career.reputation < rep_before, "a sacking lowers reputation (%.1f -> %.1f)" % [
		rep_before, career.reputation]) and ok
	# Idempotent: a second review in the same season does not double-apply the hit.
	var rep_after_first := career.reputation
	career.board_review()
	ok = _assert(absf(career.reputation - rep_after_first) < 0.01, "board review is idempotent per season") and ok

	# Take a job at a Division One club: a new spell, the old one recorded, reputation carried.
	var new_club: Dictionary = div1[0]
	var old_club_id := career.club_id
	var rep_carry := career.reputation
	career.take_job(new_club, div1_lg, div1, leagues)
	ok = _assert(career.club_id == int(new_club["id"]), "now managing the new club") and ok
	ok = _assert(career.league_id == "eng_div1", "moved into Division One") and ok
	ok = _assert(career.manager_history.size() == 1, "the old spell was recorded") and ok
	ok = _assert(int(career.manager_history[0]["club_id"]) == old_club_id, "history names the old club") and ok
	ok = _assert(str(career.manager_history[0]["reason"]) == "sacked", "old spell recorded as a sacking") and ok
	ok = _assert(absf(career.reputation - rep_carry) < 0.01, "reputation carried across the move") and ok
	ok = _assert(not career.sacked and career.pending_offers.is_empty(), "the new job clears the sacking state") and ok
	ok = _assert(career.week == 0 and not career.finished, "the new club's season starts fresh") and ok
	ok = _assert(career.seasons_at_club() == 1, "first season at the new club") and ok
	ok = _assert(career.rosters.has(career.club_id) and not career.my_squad().is_empty(),
		"the new club has a live squad") and ok
	ok = _assert(career.euro.is_empty() and career.last_champion_id == -1,
		"no European/honours state carried to the new club") and ok

	# The new club's season also plays out cleanly.
	rng.seed = SEED + 1
	while not career.season_over():
		career.advance_week(rng)
	var games_ok := true
	for id in career.table:
		if int(career.table[id]["P"]) != career.total_weeks():
			games_ok = false
	ok = _assert(games_ok, "the new club's season played its full schedule") and ok

	# Save / load round-trip preserves the cross-club career.
	var path := "user://career_manager_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career loaded from disk") and ok
	if loaded != null:
		ok = _assert(absf(loaded.reputation - career.reputation) < 0.01, "reputation survived round-trip") and ok
		ok = _assert(loaded.manager_history.size() == 1, "history survived round-trip") and ok
		ok = _assert(loaded.spell_start_year == career.spell_start_year, "spell span survived round-trip") and ok

	# Over-achieving path: a strong club beating a lenient objective keeps the job + climbs.
	prem.sort_custom(func(a, b): return _ovr(a) > _ovr(b))
	var winner := Career.create(prem[0], prem_lg, prem, leagues)
	var wr := RandomNumberGenerator.new()
	wr.seed = SEED + 7
	while not winner.season_over():
		winner.advance_week(wr)
	winner.objective_pos = winner.standings().size()   # board only wanted survival-level finish
	winner.objective_text = "Avoid relegation"
	var wrep := winner.reputation
	var wrv := winner.board_review()
	ok = _assert(not bool(wrv["sacked"]), "beating a lenient objective keeps the job") and ok
	ok = _assert(winner.reputation > wrep, "over-achieving raises reputation (%.1f -> %.1f)" % [
		wrep, winner.reputation]) and ok

	return ok


func _ovr(club: Dictionary) -> float:
	var r := MatchEngine.team_ratings(club)
	return float(r["att"]) + float(r["def"]) + float(r["gk"])


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
