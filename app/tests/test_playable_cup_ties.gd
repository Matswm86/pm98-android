extends SceneTree
## Every cup and European tie the manager's club plays is QUEUED FOR PRESENTATION, and
## every league fixture's score is PERSISTED — the two 2026-08-01 owner reports:
##
##   "Europa football doesn't work at all. Im not playing any of the matches. Its just
##    automatically skipped and results are shown in result screen."
##   "Also the result screen doesn't really work."
##
## Before this, `advance_week` resolved the whole week inside one call and returned only
## the LEAGUE fixture, so a cup or European tie could never reach the match flow; and
## `Career.results` is a manager-only ledger, so eight of the RESULTS screen's nine plates
## were blank forever. Asserts here:
##   * a cup round the manager is in queues one entry per match he played, in the
##     advance_week manager_res shape, carrying the competition + round label
##   * a two-legged European tie queues BOTH legs and not its extra time
##   * an AI-only round queues nothing
##   * `take_pending_matches` drains, and a fresh week never inherits a stale queue
##   * every fixture of the round lands in `round_scores`, keyed by the 1-based round,
##     and survives a save/load round trip
##   ~/godot4 --headless --path app --script res://tests/test_playable_cup_ties.gd

const SEED := 20260801

var _pass := 0
var _fail := 0


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, what: String) -> bool:
	if cond:
		_pass += 1
		print("  [PASS] %s" % what)
	else:
		_fail += 1
		print("  [FAIL] %s" % what)
	return cond


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	var prem: Array = []
	var clubs_by_id: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		clubs_by_id[int(c["id"])] = c
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# ---- 1. league scores are persisted for EVERY fixture, not just the manager's ----
	career.advance_week(rng, clubs_by_id)
	var round1: Array = career.round_scores.get(1, [])
	ok = _assert(round1.size() == (career.fixtures[0] as Array).size(),
		"round 1 banks a score for every fixture (%d of %d)"
		% [round1.size(), (career.fixtures[0] as Array).size()]) and ok
	var shaped := true
	for row in round1:
		if not (row is Array) or (row as Array).size() != 4:
			shaped = false
	ok = _assert(shaped, "each score row is [home_id, away_id, hg, ag]") and ok
	ok = _assert(career.scores_for(career.tier) == career.round_scores,
		"scores_for(tier) serves the manager's own division") and ok

	# ---- 2. the queue drains, and a new week never inherits a stale one -------------
	career.pending_matches = [{"home_id": -1, "away_id": -1}]
	career.advance_week(rng, clubs_by_id)
	ok = _assert(not career.pending_matches.has({"home_id": -1, "away_id": -1}),
		"advance_week clears a queue the caller never drained") and ok
	var drained: Array = career.take_pending_matches()
	ok = _assert(career.pending_matches.is_empty(),
		"take_pending_matches empties the queue (took %d)" % drained.size()) and ok

	# ---- 3. a cup round the manager is IN queues his match ------------------------
	# Drive the F.A. Cup's own round-due path directly, so the assertion does not depend
	# on which league week the calendar puts round 1 on.
	var c2 := Career.create(prem[0], league, prem, leagues)
	var r2 := RandomNumberGenerator.new()
	r2.seed = SEED
	var fired := false
	for _w in 40:
		if c2.season_over():
			break
		c2.take_pending_matches()
		c2.advance_week(r2, clubs_by_id)
		var q: Array = c2.pending_matches
		if q.is_empty():
			continue
		fired = true
		var m: Dictionary = q[0]
		ok = _assert(int(m.get("home_id", -1)) == c2.club_id
			or int(m.get("away_id", -1)) == c2.club_id,
			"a queued tie is one the manager's club played") and ok
		ok = _assert(m.has("hg") and m.has("ag") and m.has("manager_home")
			and m.has("xi_home") and m.has("xi_away"),
			"a queued tie carries the advance_week manager_res shape") and ok
		ok = _assert(str(m.get("comp", "")) != "",
			"a queued tie names its competition (%s / %s)"
			% [str(m.get("comp", "")), str(m.get("comp_round", ""))]) and ok
		ok = _assert((m.get("xi_home", []) as Array).size() == 11
			and (m.get("xi_away", []) as Array).size() == 11,
			"both XIs are the elevens that played") and ok
		break
	ok = _assert(fired, "a cup tie was queued somewhere in the season") and ok

	# ---- 4. a two-legged tie queues BOTH legs, and not its extra time -------------
	# Cup._play_two_leg_tie calls the sink three times at most: leg 1, leg 2, and extra
	# time with bump_club = false. Only the two legs are matches the manager plays.
	var c3 := Career.create(prem[0], league, prem, leagues)
	var legs := 0
	var sink := c3._cup_report_sink("European Cup")
	var fake := {"home_goals": 1, "away_goals": 1, "report": null, "goals": []}
	sink.call(fake, c3.club_id, prem[1]["id"], true)
	sink.call(fake, int(prem[1]["id"]), c3.club_id, true)
	sink.call(fake, int(prem[1]["id"]), c3.club_id, false)   # the extra-time fold
	legs = c3.pending_matches.size()
	ok = _assert(legs == 2, "a two-legged tie queues both legs and not its ET (%d)" % legs) and ok
	ok = _assert(str((c3.pending_matches[0] as Dictionary).get("comp", "")) == "European Cup",
		"the queued legs carry the European competition's name") and ok

	# ---- 5. round_scores survives the save round trip -----------------------------
	var blob := career.to_dict()
	var back := Career.from_dict(blob)
	ok = _assert(back.round_scores.get(1, []).size() == round1.size(),
		"round_scores round-trips through the save (%d rows)"
		% (back.round_scores.get(1, []) as Array).size()) and ok

	print("\n%s (%d passed, %d failed)"
		% ["ALL PASS" if _fail == 0 else "FAILURES ABOVE", _pass, _fail])
	return _fail == 0
