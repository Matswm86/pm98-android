extends SceneTree
## Headless test for the OURS honours ledger + career resume
## (docs/SPEC_ours_additions.md item 1, approved 2026-07-25).
##   ~/godot462 --headless --path app --script res://tests/test_honours.gd
##
## What it pins:
##  * a completed season lands ONE record on `Career.honours`, and re-capturing the same
##    season overwrites rather than duplicating it;
##  * the eight-trophy fold (`honours_board`) puts the manager's club on `won` when it
##    lifted a competition and on `runner_up` when it lost the final;
##  * the "(on penalties)" qualifier survives from the bracket to the board (REFRUN R14);
##  * the U.E.F.A. Cup is on the ledger at all — that is the R14 hole the spec called out
##    as the blocker for building the board;
##  * `career_resume` gives one row per season with the board objective and the trophies;
##  * the whole ledger survives a save/load round-trip, and a pre-ledger save loads clean.

var _fails := 0


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	var c := Career.new()
	c.season = "1997-98"
	c.year = 1
	c.club_id = 59
	c.club_name = "Bolton W"
	c.league_name = "Premier League"
	c.league_id = "eng_prem"
	c.tier = 1
	c.objective_text = "Finish in the top half"
	c.objective_pos = 10
	c.club_names = {59: "Bolton W", 60: "Leeds Utd", 61: "Arsenal", 1003: "Real Madrid C.F."}
	c.euro_names = {1003: "Real Madrid C.F."}
	# A table where the manager's club is champion.
	c.table = {}
	c.rosters = {59: [], 60: [], 61: []}

	# --- the competitions the ledger folds -----------------------------------
	# F.A. Cup: Bolton beat Leeds in the final on penalties.
	c.fa_cup = {"rounds": [{"ties": [
		{"home_id": 59, "away_id": 60, "winner_id": 59, "loser_id": 60, "decided": "pens"}]}],
		"champion_id": 59}
	# Coca-Cola Cup: Arsenal beat Bolton in the final -> runner-up.
	c.league_cup = {"rounds": [{"ties": [
		{"home_id": 61, "away_id": 59, "winner_id": 61, "loser_id": 59}]}],
		"champion_id": 61}
	# The U.E.F.A. Cup — the competition R14 used to throw away.
	c.euro = {"uefa_cup": {"rounds": [{"ties": [
		{"home_id": 59, "away_id": 1003, "winner_id": 59, "loser_id": 1003}]}],
		"champion_id": 59}}
	c.charity_shield = {"winner_id": 59, "loser_id": 61, "decided": "pens"}

	c._capture_season_honours()
	ok = _assert(c.honours.size() == 1, "one record per completed season") and ok
	c._capture_season_honours()
	ok = _assert(c.honours.size() == 1, "re-capturing the same season overwrites it") and ok

	var rec: Dictionary = c.honours[0]
	ok = _assert(str(rec["season"]) == "1997-98" and int(rec["club_id"]) == 59,
		"the record carries the season and the club") and ok
	var comps: Dictionary = rec["comps"]
	ok = _assert(comps.has("uefa_cup") and int(comps["uefa_cup"]["winner_id"]) == 59,
		"the U.E.F.A. Cup IS on the ledger (the R14 hole)") and ok
	ok = _assert(str(comps["fa_cup"]["loser_name"]) == "Leeds Utd",
		"the beaten finalist is named") and ok
	ok = _assert(str(comps["uefa_cup"]["loser_name"]) == "Real Madrid C.F.",
		"a European club resolves through euro_names") and ok

	var board := c.honours_board()
	ok = _assert((board["fa_cup"]["won"] as Array).size() == 1,
		"F.A. Cup lands on WON") and ok
	ok = _assert(str(board["fa_cup"]["won"][0]["detail"]) == "on penalties",
		"the (on penalties) qualifier survives to the board (R14)") and ok
	ok = _assert((board["league_cup"]["runner_up"] as Array).size() == 1
		and (board["league_cup"]["won"] as Array).is_empty(),
		"a lost final lands on RUNNER-UP, not WON") and ok
	ok = _assert((board["uefa_cup"]["won"] as Array).size() == 1,
		"the U.E.F.A. Cup reaches the board") and ok
	ok = _assert((board["charity"]["won"] as Array).size() == 1,
		"a one-off tie (Charity Shield) folds like a bracket") and ok

	var resume := c.career_resume()
	ok = _assert(resume.size() == 1, "one resume row per season") and ok
	var r0: Dictionary = resume[0]
	ok = _assert(str(r0["objective"]) == "Finish in the top half",
		"the resume row carries the board's objective") and ok
	ok = _assert((r0["won"] as Array).has("F.A. Cup")
		and (r0["won"] as Array).has("U.E.F.A. Cup")
		and not (r0["won"] as Array).has("Coca-Cola Cup"),
		"the resume lists the trophies lifted, not the ones lost") and ok

	# --- a second season at a second club ------------------------------------
	c.season = "1998-99"
	c.year = 2
	c.club_id = 61
	c.club_name = "Arsenal"
	c.fa_cup = {}
	c.league_cup = {}
	c.euro = {}
	c.charity_shield = {}
	c._capture_season_honours()
	ok = _assert(c.honours.size() == 2, "a new season appends") and ok
	ok = _assert(c.career_resume().size() == 2
		and str(c.career_resume()[1]["club"]) == "Arsenal",
		"the resume spans clubs") and ok

	# --- persistence ---------------------------------------------------------
	var c2 := Career.from_dict(c.to_dict())
	ok = _assert(c2.honours.size() == 2, "the ledger survives save/load") and ok
	ok = _assert((c2.honours_board()["fa_cup"]["won"] as Array).size() == 1,
		"and folds the same way after a reload") and ok
	var old := c.to_dict()
	old.erase("honours")
	ok = _assert(Career.from_dict(old).honours.is_empty(),
		"a pre-ledger save loads with an empty ledger, not an error") and ok

	# --- the nine competition keys are the backdrop's eight plus Intercontinental
	ok = _assert(Career.HONOUR_COMPS.size() == 9
		and Career.HONOUR_COMPS.has("supercup")
		and Career.HONOUR_COMPS.has("cup_winners_cup"),
		"nine competitions on the board") and ok
	for k in Career.HONOUR_COMPS:
		ok = _assert(Career.HONOUR_NAMES.has(k), "every key has a display name: %s" % k) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES: %d" % _fails))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_fails += 1
	return cond
