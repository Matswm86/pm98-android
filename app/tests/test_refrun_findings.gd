extends SceneTree
## The 1997-98 Manchester Utd. REFERENCE RUN, asserted.
##
## Every check below is a number, string or shape read off the original in
## docs/re/REFRUN_manutd_1997-98.md (findings R1-R17) or its evidence file
## out/refrun-manutd-9798/FINDINGS.md. If one of these fails, the port has drifted away
## from something that was actually witnessed -- not from a modelling preference.
##
##   ~/godot462 --headless --path app --script res://tests/test_refrun_findings.gd

const SEED := 20240615


func _initialize() -> void:
	quit(0 if _run() else 1)


var _fails := 0


func _assert(cond: bool, label: String) -> bool:
	print("  %s %s" % ["[PASS]" if cond else "[FAIL]", label])
	if not cond:
		_fails += 1
	return cond


func _run() -> bool:
	var ok := true
	ok = _finance_week_calendar() and ok
	ok = _ticket_price_and_gate() and ok
	ok = _weekly_books() and ok
	ok = _domestic_cup_shape() and ok
	ok = _lower_divisions_reach_46() and ok
	ok = _euro_group_badge() and ok
	ok = _deadline_warnings() and ok
	ok = _youth_training_speedup() and ok
	ok = _cup_draw_forms_and_route() and ok
	ok = _season_end_sequence() and ok
	print("")
	print("ALL PASS" if _fails == 0 else "FAILURES ABOVE (%d)" % _fails)
	return _fails == 0


# ---- R5/R9: the finance calendar -----------------------------------------

## The two captured PER WEEK frames stamp their own date span. Reproducing both exactly
## is what pins the finance year to Sunday 20 July 1997 and finance week = league week + 2.
func _finance_week_calendar() -> bool:
	print("=== R5/R9: the finance week calendar ===")
	var ok := true
	ok = _assert(FinanceModel.finance_week_span(4) == "From 10-8-1997 to 16-8-1997",
		"week 4 span == the frame's own stamp (%s)" % FinanceModel.finance_week_span(4)) and ok
	ok = _assert(FinanceModel.finance_week_span(29) == "From 1-2-1998 to 7-2-1998",
		"week 29 span == the frame's own stamp (%s)" % FinanceModel.finance_week_span(29)) and ok
	ok = _assert(FinanceModel.finance_week_span(31) == "From 15-2-1998 to 21-2-1998",
		"week 31 span == the frame's own stamp (%s)" % FinanceModel.finance_week_span(31)) and ok
	# The channelTV card was raised on hub week 27 and its fee is week 29's TELEVISION line.
	ok = _assert(FinanceModel.finance_week(27) == 29,
		"league week 27 is finance week 29") and ok
	return ok


# ---- R6/R9: the ticket price and the gate --------------------------------

func _ticket_price_and_gate() -> bool:
	print("=== R6/R9: TICKET PRICE and ATTENDANCE MONEY ===")
	var ok := true
	ok = _assert(absf(FinanceModel.TICKET_DEFAULT - 7.5) < 0.0001,
		"the default ticket price is the witnessed £7.50") and ok
	# The two FULL TIME stadium panels, exactly.
	ok = _assert(FinanceModel.attendance_money(21014, 7.5) == 157605,
		"Old Trafford 21,014 -> ATTENDANCE MONEY £157,605") and ok
	ok = _assert(FinanceModel.attendance_money(41000, 7.5) == 307500,
		"Anfield 41,000 -> ATTENDANCE MONEY £307,500") and ok
	# The channelTV table, per competition.
	ok = _assert(int(FinanceModel.TV_FEE["league"]) == 90_000, "Premier TV fee £90,000") and ok
	ok = _assert(int(FinanceModel.TV_FEE["charity_shield"]) == 187_500,
		"Charity Shield TV fee £187,500") and ok
	ok = _assert(int(FinanceModel.TV_FEE["european_cup"]) == 375_000,
		"European Cup TV fee £375,000") and ok
	ok = _assert(not FinanceModel.TV_FEE.has("cup:F.A. Cup")
		and not FinanceModel.TV_FEE.has("cup:Coca-Cola Cup"),
		"the two unmeasured domestic cup TV fees are absent, not guessed") and ok
	return ok


# ---- R9/R16: the weekly books --------------------------------------------

## The structure, not the magnitudes: a HOME week earns and an AWAY week is a pure loss of
## exactly PLAYERS' WAGE + STAFF WAGES. That is the sign error R9 measured.
func _weekly_books() -> bool:
	print("=== R9/R16: the weekly books ===")
	var ok := true
	var career := _new_career()
	if career == null:
		return _assert(false, "career built")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var home_weeks := 0
	var away_weeks := 0
	var away_exact := 0
	var loss_alerts := 0
	# Trigger corrected 2026-07-26: the at-a-loss counter follows the BANK BALANCE, not
	# the week's P&L. Probe it while the season is live: a negative balance raises the
	# alert, a positive one clears the counter.
	var probe_cash: int = career.cash
	career.cash = -20_000_000
	career.advance_week(rng)
	var neg_alert := false
	for a in career.pending_alerts:
		if str(a).begins_with("You have been running the club at a loss"):
			neg_alert = true
	career.pending_alerts.clear()
	ok = _assert(neg_alert and career.loss_weeks == 1,
		"a week closing with the bank below zero raises the alert (count %d)"
		% career.loss_weeks) and ok
	career.cash = probe_cash + 1_000_000
	career.advance_week(rng)
	ok = _assert(career.loss_weeks == 0,
		"a positive balance clears the counter (%d)" % career.loss_weeks) and ok
	career.pending_alerts.clear()
	while not career.season_over():
		var cash_before: int = career.cash
		var res := career.advance_week(rng)
		var rec: Dictionary = career.week_ledgers[-1]
		if career.cash != cash_before + FinanceModel.ledger_balance(rec):
			return _assert(false, "the bank and the books agree every week")
		var flat: int = int(rec["expense"]["PLAYERS' WAGE"]) + int(rec["expense"]["STAFF WAGES"])
		if not res.is_empty() and bool(res.get("manager_home", false)):
			home_weeks += 1
			if int(rec["income"]["TICKETS"]) <= 0:
				return _assert(false, "a home week takes money at the turnstiles")
		else:
			away_weeks += 1
			# An away week with no cup tie and no transfer books NOTHING but the flat cost.
			if FinanceModel.ledger_total(rec, "income") == 0 \
					and FinanceModel.ledger_total(rec, "expense") == flat:
				away_exact += 1
		for a in career.pending_alerts:
			if str(a).begins_with("You have been running the club at a loss"):
				loss_alerts += 1
		career.pending_alerts.clear()
	ok = _assert(home_weeks > 0 and away_weeks > 0,
		"the season has home and away weeks (%d / %d)" % [home_weeks, away_weeks]) and ok
	ok = _assert(away_exact > 0,
		"an away week is a pure PLAYERS' WAGE + STAFF WAGES loss (%d of %d such weeks)"
		% [away_exact, away_weeks]) and ok
	# A solvent season raises NO at-a-loss alert -- the whole 1997-98 refrun did not,
	# although its quiet away weeks all closed wages-only P&L-negative.
	ok = _assert(loss_alerts == 0,
		"a solvent season raises no at-a-loss alert (%d raised)" % loss_alerts) and ok
	ok = _assert(career.week_ledgers.size() > 0
		and int(career.week_ledgers[0]["week"]) == FinanceModel.finance_week(1),
		"the first banked week is finance week %d" % FinanceModel.finance_week(1)) and ok
	# Every line the screen prints exists on every record, so no row can silently vanish.
	var first: Dictionary = career.week_ledgers[0]
	var lines_ok := true
	for l in FinanceModel.INCOME_LINES:
		if not (first["income"] as Dictionary).has(l):
			lines_ok = false
	for l in FinanceModel.EXPENSE_LINES:
		if not (first["expense"] as Dictionary).has(l):
			lines_ok = false
	ok = _assert(lines_ok, "every one of the screen's 7 + 11 lines is on the record") and ok
	return ok


# ---- R1/R2/R8: the domestic cups -----------------------------------------

func _domestic_cup_shape() -> bool:
	print("=== R1/R2/R8: the 92-club cups, Premier entering at Round 3 ===")
	var ok := true
	var career := _new_career()
	if career == null:
		return _assert(false, "career built")
	ok = _assert((career.fa_cup["survivors"] as Array).size() == 72,
		"round 1 is contested by the 72 non-Premier clubs (%d)"
		% (career.fa_cup["survivors"] as Array).size()) and ok
	ok = _assert((career.fa_cup["late_ids"] as Array).size() == 20
		and int(career.fa_cup["late_round"]) == Career.PREMIER_ENTRY_ROUND,
		"the 20 Premier clubs enter at Round %d" % Career.PREMIER_ENTRY_ROUND) and ok
	ok = _assert(int(career.league_cup["late_round"]) == Career.PREMIER_ENTRY_ROUND,
		"the Coca-Cola Cup has the same entry round") and ok
	ok = _assert(int(career.fa_cup["legs"]) == 1 and int(career.league_cup["legs"]) == 1,
		"both cups are single-leg with replays (the Round 3 card's MATCH / REPLAY)") and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	var labels: Array = []
	for r in career.fa_cup["rounds"]:
		labels.append(str((r as Dictionary)["label"]))
	ok = _assert(labels == ["Round 1", "Round 2", "Round 3", "Round 4", "Round 5",
		"Qtr. Finals", "Semifinals", "Final"],
		"the F.A. Cup runs PM98's own label ladder (%s)" % str(labels)) and ok
	# Round 3 must be the round the Premier joins, and it must hold lower-division clubs.
	var r3: Dictionary = career.fa_cup["rounds"][2]
	var count := 0
	for t in r3["ties"]:
		count += 1 if bool((t as Dictionary).get("bye", false)) else 2
	ok = _assert(count == 52, "Round 3 is contested by 52 clubs (%d)" % count) and ok
	var champ := Cup.champion_id(career.fa_cup)
	ok = _assert(champ != -1, "the F.A. Cup produces a champion") and ok
	return ok


# ---- R12: the lower divisions --------------------------------------------

func _lower_divisions_reach_46() -> bool:
	print("=== R12: the lower divisions play all 46 rounds ===")
	var ok := true
	var career := _new_career()
	if career == null:
		return _assert(false, "career built")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var at37: Dictionary = {}
	while not career.season_over():
		career.advance_week(rng)
		if career.week == 37:
			for t in [2, 3, 4]:
				at37[t] = int(career.divisions[t]["played"])
	# WITNESSED: the First Division table dated 18/4/1998 -- the manager's week 37 -- reads
	# P = 44 for every club.
	ok = _assert(int(at37.get(2, -1)) == 44,
		"the First Division has played 44 rounds at manager week 37 (%d)"
		% int(at37.get(2, -1))) and ok
	for t in [2, 3, 4]:
		var dv: Dictionary = career.divisions[t]
		ok = _assert(int(dv["played"]) == (dv["fixtures"] as Array).size()
			and int(dv["played"]) == 46,
			"tier %d finished all 46 rounds (%d)" % [t, int(dv["played"])]) and ok
	return ok


# ---- R3: the European group badge ----------------------------------------

func _euro_group_badge() -> bool:
	print("=== R3: the European group-phase badge ===")
	var ok := true
	var b := Cup.create(_ids(24), 38, {"name": "European Cup",
		"group_stage": Career.EURO_GROUPS.duplicate()})
	ok = _assert(Cup.next_label(b) == "1/8 Final",
		"the group phase reports the original's own string (%s)" % Cup.next_label(b)) and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var ratings := func(_id: int) -> Dictionary: return {"att": 50, "def": 50, "gk": 50}
	var names := func(id: int) -> String: return "C%d" % id
	# Every matchday of the group phase reports the SAME label -- witnessed three times.
	var seen: Dictionary = {}
	for i in 6:
		seen[Cup.next_label(b)] = true
		Cup.play_next(b, rng, ratings, -1, names)
	ok = _assert(seen.size() == 1 and seen.has("1/8 Final"),
		"the badge never advances through the group phase (%s)" % str(seen.keys())) and ok
	ok = _assert((b["survivors"] as Array).size() == 8,
		"six winners + two best runners-up reach the quarter finals (%d)"
		% (b["survivors"] as Array).size()) and ok
	return ok


# ---- R10: the transfer deadline -------------------------------------------

func _deadline_warnings() -> bool:
	print("=== R10: the transfer-deadline warnings ===")
	var ok := true
	ok = _assert(Career.DEADLINE_TAIL == 5,
		"DEADLINE_TAIL is 5 (the 39-week calendar shuts the window on week 34)") and ok
	var career := _new_career()
	if career == null:
		return _assert(false, "career built")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var seen: Array = []
	var deadline_week := -1
	while not career.season_over():
		career.advance_week(rng)
		for a in career.pending_alerts:
			if str(a).begins_with("The transfer deadline is now"):
				seen.append([career.week, str(a)])
		career.pending_alerts.clear()
		if deadline_week == -1 and not career.transfers_open():
			deadline_week = career.week
	ok = _assert(seen.size() == 2, "exactly two warnings, no deadline-day event (%d)"
		% seen.size()) and ok
	if seen.size() == 2:
		ok = _assert(str(seen[0][1]) == "The transfer deadline is now 2 weeks away.",
			"the two-week warning is the original's own wording (%s)" % str(seen[0][1])) and ok
		ok = _assert(str(seen[1][1]) == "The transfer deadline is now 1 week away.",
			"the one-week warning is the same string, pluralised (%s)" % str(seen[1][1])) and ok
		ok = _assert(int(seen[0][0]) == 32,
			"the first warning lands on the witnessed week 32 (Sun 8 Mar, R10) (week %d)"
			% int(seen[0][0])) and ok
	ok = _assert(deadline_week == career.total_weeks() - Career.DEADLINE_TAIL,
		"the window shuts on week %d" % deadline_week) and ok
	return ok


# ---- R17: the youth training lever ---------------------------------------

func _youth_training_speedup() -> bool:
	print("=== R17: halved youth training ===")
	var ok := true
	ok = _assert(Training.YOUTH_GROWTH_SPEEDUP == 2,
		"the gain is doubled (the owner's 2x, the twin of Youth.SEARCH_SPEEDUP)") and ok
	# THE TRAP: with a +2 step and an ODD remaining gap, a skip-on-overshoot clamp stalls
	# the youth one point short of BASE forever and he never reports ready.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var base: Dictionary = {}
	var attrs: Dictionary = {}
	for a in Training.CORE4:
		base[a] = 61
		attrs[a] = 60          # gap of ONE -- odd, and smaller than the step
	for a in Training.TRAINABLE:
		base[a] = 61
		attrs[a] = 60
	var youth: Array = [{"name": "Spindle", "attrs": attrs, "base_attrs": base, "fitness": 90}]
	var ready := false
	for _w in 200:
		for n in Training.develop_youth_week(rng, youth):
			if str(n.get("text", "")).findn("ready to be promoted") != -1:
				ready = true
		if ready:
			break
	ok = _assert(ready, "an ODD remaining gap still reaches BASE and reports ready") and ok
	var capped := true
	for a in Training.CORE4:
		if int(attrs[a]) > int(base[a]):
			capped = false
	ok = _assert(capped, "no attribute overshoots the youth's own shipped BASE") and ok
	return ok


## R4 + R8 -- the cup draw's live route and its two panel forms.
##
## R8's switch is the FULL round's tie count, and R4 is the route that was missing: the
## original raises the SORTEO unprompted when a knockout round is drawn, and the port's
## 0-px screen had no live caller at all.
func _cup_draw_forms_and_route() -> bool:
	print("R4/R8  the cup draw: two panel forms, and a live route")
	var ok := true
	var scr: CupDrawScreen = load("res://scenes/CupDrawScreen.gd").new()
	# > 16 ties -> the scrollable single-line list; <= 16 -> the grid. Both witnessed:
	# the F.A. Cup ROUND 3 (32) and Coca-Cola ROUND 2 (25) list, ROUND 3 (16) and the
	# F.A. Cup ROUND 4 (16) grid.
	scr.setup("league_cup", "Coca-Cola Cup", "ROUND 3", [], 16, ["MATCH", "REPLAY"])
	ok = _assert(scr.is_grid(), "16 ties -> the GRID form") and ok
	scr.setup("fa_cup", "F.A. Cup", "ROUND 3", [], 32, ["MATCH", "REPLAY"])
	ok = _assert(not scr.is_grid(), "32 ties -> the scrollable LIST form") and ok
	scr.setup("league_cup", "Coca-Cola Cup", "ROUND 2", [], 25, ["1ST LEG", "2ND LEG"])
	ok = _assert(not scr.is_grid(), "25 ties -> the LIST form") and ok
	scr.setup("fa_cup", "F.A. Cup", "ROUND 4", [], 16, ["MATCH", "REPLAY"])
	ok = _assert(scr.is_grid(), "the F.A. Cup ROUND 4's 16 ties -> the GRID form") and ok
	scr.free()
	# The plate label is the EXE's own uppercase form, and the leg plates follow the ROUND.
	var single := {"rounds": [{"label": "Qtr. Finals", "ties": [{"home_id": 1, "away_id": 2}]}]}
	ok = _assert(Cup.draw_round_plate(single) == "QTR FINALS",
		"the QTR FINALS plate is the EXE's own spelling") and ok
	ok = _assert(Cup.draw_leg_plates(single) == ["MATCH", "REPLAY"],
		"a single-match round shows MATCH / REPLAY") and ok
	var twoleg := {"rounds": [{"label": "Round 2 - 1st",
		"ties": [{"home_id": 1, "away_id": 2, "two_legged": true}]}]}
	ok = _assert(Cup.draw_round_plate(twoleg) == "ROUND 2",
		"the per-leg suffix is dropped from the ROUND plate") and ok
	ok = _assert(Cup.draw_leg_plates(twoleg) == ["1ST LEG", "2ND LEG"],
		"a two-legged round shows 1ST LEG / 2ND LEG") and ok
	ok = _assert(Cup.draw_art_key({"name": "F.A. Cup"}) == "fa_cup"
		and Cup.draw_art_key({"name": "Coca-Cola Cup"}) == "league_cup"
		and Cup.draw_art_key({"name": "U.E.F.A. Cup"}) == "uefa_cup"
		and Cup.draw_art_key({"name": "Cup Winners' Cup"}) == "cup_winners_cup"
		and Cup.draw_art_key({"name": "European Cup"}) == "european_cup",
		"each competition picks its own SORTEO strip") and ok
	# The route: a played week must leave the draw queued for the hub to raise.
	var c := _new_career()
	if c == null:
		return _assert(false, "career fixture loaded") and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var drew := false
	for _i in 24:
		c.advance_week(rng)
		if not (c.pending_cup_draws as Array).is_empty():
			drew = true
			break
	ok = _assert(drew, "a resolved knockout round queues its SORTEO for the hub") and ok
	if drew:
		var d: Dictionary = (c.pending_cup_draws as Array)[0]
		ok = _assert(not (d.get("ties", []) as Array).is_empty(),
			"the queued draw carries the round's ties") and ok
		ok = _assert(str(d.get("round", "")) == str(d.get("round", "")).to_upper(),
			"the queued round plate is uppercase, as the EXE's block is") and ok
	return ok


## R15 -- the season-end sequence's three new screens carry the frame's own shape.
func _season_end_sequence() -> bool:
	print("R15  THE CHAMPIONSHIPS / END OF SEASON / PLAYERS OF THE YEAR")
	var ok := true
	# Eight slots, in the sheet's own order, and Career answers with eight entries.
	ok = _assert(ChampionshipsScreen.SLOTS.size() == 8, "the sheet has eight fixed slots") and ok
	var comps: Array = []
	for slot in ChampionshipsScreen.SLOTS:
		comps.append(str((slot as Dictionary)["comp"]))
	ok = _assert(comps == Career.CHAMPIONSHIP_SLOTS,
		"Career returns its eight finals in the sheet's own slot order") and ok
	# The U.E.F.A. Cup's card is the narrow one: ONE score cell, not two.
	var uefa: Dictionary = ChampionshipsScreen.SLOTS[5]
	ok = _assert(str(uefa["comp"]) == "uefa_cup"
		and (uefa["scores"] as Array).size() == 1,
		"the U.E.F.A. Cup card carries ONE score cell") and ok
	for i in [4, 6, 7]:
		var slot2: Dictionary = ChampionshipsScreen.SLOTS[i]
		ok = _assert((slot2["scores"] as Array).size() == 2,
			"the %s card carries TWO score cells" % str(slot2["comp"])) and ok
	# END OF SEASON's plate counts are the chrome's own and match PYRAMID_ZONES.
	ok = _assert((EndOfSeasonScreen.MID_ROWS[1] as Array).size() == 4
		and (EndOfSeasonScreen.REL_ROWS[1] as Array).size() == 3,
		"the Premier shows 4 U.E.F.A. places and 3 relegated") and ok
	ok = _assert((EndOfSeasonScreen.REL_ROWS[4] as Array).is_empty(),
		"the Third Division has no relegation column") and ok
	for t in [2, 3, 4]:
		var z: Dictionary = Career.PYRAMID_ZONES[t]
		var ups: int = int(z["up"]) + (1 if int(z["playoff"]) > 0 else 0)
		ok = _assert((EndOfSeasonScreen.MID_ROWS[t] as Array).size() == ups,
			"tier %d's promoted plates match PYRAMID_ZONES" % t) and ok
		ok = _assert((EndOfSeasonScreen.REL_ROWS[t] as Array).size() == int(z["down"]),
			"tier %d's relegated plates match PYRAMID_ZONES" % t) and ok
	# PLAYERS OF THE YEAR is one award per club: ten rows x two columns x four tabs = 80
	# on screen, and 92 across a full pyramid.
	ok = _assert(PlayersYearScreen.ROWS == 10 and PlayersYearScreen.COLS.size() == 2,
		"PLAYERS OF THE YEAR shows twenty clubs a page") and ok
	ok = _assert(PlayersYearScreen.TABS.size() == 4, "four division tabs, in a 2x2 grid") and ok
	return ok


# ---- helpers -------------------------------------------------------------

func _ids(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(9000 + i)
	return out


## A Manchester Utd. career with the full four-division pyramid attached (the cups need it).
func _new_career() -> Career:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return null
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league_by_id: Dictionary = {}
	var by_league: Dictionary = {}
	for lg in leagues:
		league_by_id[str(lg.get("id", ""))] = lg
		by_league[str(lg.get("id", ""))] = []
	for c in db.get("clubs", []):
		var lid := str(c.get("leagueId", ""))
		if by_league.has(lid):
			(by_league[lid] as Array).append(c)
	var sf := FileAccess.open("res://data/season_seed_1997.json", FileAccess.READ)
	var seeds: Dictionary = JSON.parse_string(sf.get_as_text()) if sf != null else {}
	var divs: Array = []
	for lid in ["eng_prem", "eng_div1", "eng_div2", "eng_div3"]:
		divs.append({"league_id": lid, "name": str(league_by_id[lid].get("name", lid)),
			"tier": int(league_by_id[lid].get("tier", 1)), "clubs": by_league[lid]})
	var prem: Array = by_league["eng_prem"]
	var manu: Dictionary = {}
	for c in prem:
		if int(c.get("id", -1)) == 40:
			manu = c
	if manu.is_empty():
		return null
	return Career.create(manu, league_by_id["eng_prem"], prem, leagues,
		{"divisions": divs, "seeds": seeds})
