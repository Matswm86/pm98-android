extends SceneTree
## Headless test for the board's DISMISSAL, against MANAGER.EXE rather than against a
## house rule (docs/re/sack_path_re.md, disassembly re-read 2026-07-28):
##
##   * `FUN_00545fd0` (the weekly hub screen's own run) tests three conditions in ONE
##     order -- club+0x224 > 3, club+0x294 != 0, club+0x28 < 0x10 -- and raises ONE modal;
##   * `FUN_0057a980` @0x57ad6a runs the board's results review on rounds
##     10 / 14 / 18 / 22 / 26 / 30 / 34, gated by the club's expectation band;
##   * `FUN_0057d3a0` decides "below expectation" from the band alone: Premier band 1 ->
##     pos > 8, band 2 -> pos > 15, band >= 3 -> pos > 17, band 0 -> the leader within
##     7 points; lower divisions 6 / 13 / 15.
##
##   ~/godot462 --headless --path app --script res://tests/test_sacking.gd

const SEED := 7714


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := _unit_bands()
	ok = _unit_order() and ok
	ok = _integration_review() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, what: String) -> bool:
	print("  %s  %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _fresh() -> Career:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return null
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var prem_lg: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			prem_lg = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.is_empty() or prem_lg.is_empty():
		push_error("expected the Premier division")
		return null
	# GameDB merges the witnessed START OF SEASON objective label onto each club at load
	# (`_apply_club_economy`); the label IS what the port reads as club+0x58, so a headless
	# career built straight off game_db.json has to do the same or it has no band.
	var ef := FileAccess.open("res://data/club_economy.json", FileAccess.READ)
	if ef != null:
		var rows: Dictionary = (JSON.parse_string(ef.get_as_text()) as Dictionary).get("clubs", {})
		for c in prem:
			var row: Dictionary = rows.get(str(int(c["id"])), {})
			if row.has("objective"):
				c["objective"] = str(row["objective"])
	# Manchester Utd: the one club whose band is not in doubt (label "Champion" = band 0,
	# the only band reviewed at every one of the seven weeks).
	var pick: Dictionary = prem[0]
	for c in prem:
		if str(c.get("objective", "")) == "Champion":
			pick = c
			break
	return Career.create(pick, prem_lg, prem, leagues)


# ---- the band table (FUN_0057d3a0) ---------------------------------------

func _unit_bands() -> bool:
	var ok := true
	# The four Premier labels have to map onto the four Premier bands, and the three
	# labels of every lower division onto that division's three -- the fit that lets the
	# port use the witnessed objective label as club+0x58.
	ok = _assert(Career.BOARD_BAND_OF_LABEL[1].size() == 4, "the Premier carries four bands") and ok
	for t in [2, 3, 4]:
		ok = _assert((Career.BOARD_BAND_OF_LABEL[t] as Dictionary).size() == 3,
			"division %d carries three bands" % t) and ok
	var seen := {}
	for t in Career.BOARD_BAND_OF_LABEL:
		for lbl in Career.BOARD_BAND_OF_LABEL[t]:
			var b: int = Career.BOARD_BAND_OF_LABEL[t][lbl]
			ok = _assert(not seen.has(b), "band %d is claimed once (%s)" % [b, lbl]) and ok
			seen[b] = true
			ok = _assert(Career.BOARD_BAND_POS.has(b), "band %d has a threshold" % b) and ok
	ok = _assert(seen.size() == 13, "bands 0..12 are all claimed (%d)" % seen.size()) and ok
	# The exact thresholds the disassembly holds.
	ok = _assert(int(Career.BOARD_BAND_POS[1]) == 8, "Premier U.E.F.A. band trips past 8th") and ok
	ok = _assert(int(Career.BOARD_BAND_POS[2]) == 15, "Premier Mid Table trips past 15th") and ok
	ok = _assert(int(Career.BOARD_BAND_POS[3]) == 17, "Premier Avoid Relegation trips past 17th") and ok
	for b in [4, 7, 10]:
		ok = _assert(int(Career.BOARD_BAND_POS[b]) == 6, "band %d (Promotion) trips past 6th" % b) and ok
	for b in [5, 8, 11]:
		ok = _assert(int(Career.BOARD_BAND_POS[b]) == 13, "band %d (Mid Table) trips past 13th" % b) and ok
	for b in [6, 9, 12]:
		ok = _assert(int(Career.BOARD_BAND_POS[b]) == 15, "band %d (Avoid Rel.) trips past 15th" % b) and ok
	ok = _assert(int(Career.BOARD_TITLE_GAP) == 7, "the band-0 points gap is 7 (`add edi,7`)") and ok
	# The review's own shape.
	ok = _assert(Career.BOARD_REVIEW.keys() == [10, 14, 18, 22, 26, 30, 34],
		"the review weeks are the binary's seven") and ok
	ok = _assert((Career.BOARD_REVIEW[10]["bands"] as Array) == [0, 1],
		"week 10 reviews only bands 0 and 1") and ok
	ok = _assert((Career.BOARD_REVIEW[30]["bands"] as Array) == [0],
		"week 30 reviews only band 0") and ok
	ok = _assert((Career.BOARD_REVIEW[18]["bands"] as Array).is_empty(),
		"week 18 reviews every band") and ok
	ok = _assert(not bool(Career.BOARD_REVIEW[26]["recover"]),
		"week 26 re-tests `still below`, it does not call the recovery check") and ok
	return ok


# ---- FUN_00545fd0's order of test ----------------------------------------

func _unit_order() -> bool:
	var ok := true
	var c := _fresh()
	if c == null:
		return false
	ok = _assert(c.sack_message() == "", "a fresh career is not sacked") and ok

	# 3rd test: the squad floor. Emptied roster, nothing else wrong.
	var keep: Array = (c.rosters.get(c.club_id, []) as Array).duplicate()
	c.rosters[c.club_id] = keep.slice(0, Career.SACK_MIN_SQUAD - 1)
	ok = _assert(c.sack_message() == Career.SACK_MSG_SQUAD,
		"a squad under 16 is the squad-minimum sack") and ok
	ok = _assert(c.sack_message_reason() == "squad", "...reason `squad`") and ok

	# 2nd test wins over the 3rd.
	c.board_sack_flag = 1
	ok = _assert(c.sack_message() == Career.SACK_MSG_RESULTS,
		"the results flag outranks the squad floor (0x54603a before 0x546063)") and ok

	# 1st test wins over both.
	c.loss_weeks = Career.LOSS_SACK_WEEKS
	ok = _assert(c.sack_message() == Career.SACK_MSG_FINANCE,
		"the financial counter outranks both (0x546013 first)") and ok
	ok = _assert(c.sack_message_reason() == "insolvent", "...reason `insolvent`") and ok
	c.loss_weeks = Career.LOSS_SACK_WEEKS - 1
	ok = _assert(c.sack_message() == Career.SACK_MSG_RESULTS,
		"three weeks in the red does not trip it (`jbe 3`)") and ok
	c.rosters[c.club_id] = keep
	c.board_sack_flag = 0
	ok = _assert(c.sack_message() == "", "a repaired club keeps its manager") and ok

	# The strings are the binary's, newlines included.
	ok = _assert(Career.SACK_MSG_RESULTS ==
		"The Directors have held an urgent meeting,\nand have sacked you as manager of the club.",
		"the results text is MANAGER.EXE's 0x663744 verbatim") and ok
	ok = _assert(Career.SACK_MSG_FINANCE.begins_with("The Directors have held an urgent meeting.\n"),
		"the financial text is 0x663818 verbatim (full stop, then a newline)") and ok
	ok = _assert(Career.SACK_MSG_SQUAD.ends_with("needed to play in any championship."),
		"the squad text is 0x663690 verbatim") and ok
	return ok


# ---- the review, driven through a real season ----------------------------

func _integration_review() -> bool:
	var ok := true
	var c := _fresh()
	if c == null:
		return false
	# The Premier club the test picks carries a witnessed objective label, so it has a band.
	ok = _assert(c.expectation_band() >= 0,
		"an English club has an expectation band (%s -> %d)" % [c.objective_text, c.expectation_band()]) and ok

	# A club with no witnessed label is the `division > 3` arm: never reviewed.
	var no_label := _fresh()
	no_label.objective_text = "Finish 9 or higher"
	ok = _assert(no_label.expectation_band() == -1, "an unlabelled club has no band") and ok
	ok = _assert(not no_label.below_expectation(18), "...and is never below expectation") and ok
	no_label._board_results_review(18)
	ok = _assert(no_label.board_sack_flag == 0 and no_label.pending_alerts.is_empty(),
		"...so the review does nothing at all for it") and ok

	# Drive a season and watch the review fire only on its own weeks.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var warn_weeks: Array = []
	while not c.season_over():
		var before: int = (c.pending_alerts as Array).size()
		c.advance_week(rng)
		for m in (c.pending_alerts as Array).slice(before):
			if str(m) == Career.BOARD_WARN_MSG:
				warn_weeks.append(c.week)
		c.pending_alerts = []
	for w in warn_weeks:
		ok = _assert(Career.BOARD_REVIEW.has(int(w)) and bool(Career.BOARD_REVIEW[int(w)]["warn"]),
			"a board warning only ever lands on a WARN week (week %d)" % w) and ok
	print("  [note] warnings landed on %s; band %d, finished %d" % [
		str(warn_weeks), c.expectation_band(), c.position()])
	ok = _assert(c.board_reviewed.size() > 0, "the review ran during the season") and ok
	for w in c.board_reviewed:
		ok = _assert(Career.BOARD_REVIEW.has(int(w)), "review week %d is one of the seven" % w) and ok

	# A sack arm cannot fire without the warning week having gone against the club.
	var d := _fresh()
	d.objective_text = "Champion"          # band 0: reviewed at 10/14/18/22/26/30/34
	d._below_at[18] = false
	d.board_sack_flag = 1
	d._board_results_review(22)
	ok = _assert(d.board_sack_flag == 0,
		"a club that was FINE at the warning week is cleared, not sacked") and ok
	d.board_reviewed = []
	d._below_at[18] = true
	d._pos_at[18] = 1
	d._board_results_review(22)
	ok = _assert(d.board_sack_flag == 0 or d.below_expectation(22),
		"the sack arm only sets the flag when the club is still below") and ok

	# The season rollover clears the flag, as FUN_0057a730 does every pass.
	d.board_sack_flag = 1
	d._reset_board_review()
	ok = _assert(d.board_sack_flag == 0 and d.board_reviewed.is_empty(),
		"the weekly reset zeroes club+0x294 for the new season") and ok

	# ...and it survives a save/load round trip while the season is live.
	var e := _fresh()
	e.board_sack_flag = 1
	e.board_reviewed = [10, 14]
	e._below_at[10] = true
	e._pos_at[10] = 12
	var round_trip := Career.from_dict(e.to_dict())
	ok = _assert(round_trip.board_sack_flag == 1, "the sack flag survives a save/load") and ok
	ok = _assert((round_trip.board_reviewed as Array).size() == 2, "...and the reviewed weeks") and ok
	ok = _assert(bool(round_trip._below_at[10]), "...and the banked below-expectation reading") and ok
	ok = _assert(int(round_trip._pos_at[10]) == 12, "...and the banked position") and ok
	return ok
