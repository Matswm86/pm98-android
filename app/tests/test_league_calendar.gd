extends SceneTree
## Headless test for the 39-week Premier calendar (Mats QA 2026-07-26: "Premier league
## was already done in april, too soon") and the R13 pre-final divisions presentation.
## Witness chain: badge "Premier Week 32" on Sun 8 Mar 1998 (R10 p0524), badge
## "Premier Week 37" next on Sat 18 Apr (R12 p0610, First Div P=44), Third Div P=46
## table dated 2/5/1998 BEFORE the Premier's last match (R12/R13 p0638).
##   ~/godot462 --headless --path app --script res://tests/test_league_calendar.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, what: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", what])
	return cond


func _run() -> bool:
	var ok := true
	var ids: Array = []
	for i in 20:
		ids.append(1000 + i)

	# 1. Shape: 38 rounds over 39 weeks, the blank Saturday at week 35 (index 34).
	var fx := Career._league_fixtures(ids)
	ok = _assert(fx.size() == 39, "20-club league schedules 39 weeks") and ok
	ok = _assert((fx[34] as Array).is_empty(), "week 35 (Sat 4 Apr) is the blank Saturday") and ok
	var games := 0
	for r in fx:
		games += (r as Array).size()
	ok = _assert(games == 38 * 10, "all 380 fixtures survive the insertion") and ok

	# 2. Dates: the final round's Saturday is 2 May 1998 (was 25 April).
	var d39 := PMChrome.date_parts("1997-98", 39)
	ok = _assert(int(d39["day"]) == 2 and str(d39["mon"]) == "May",
		"week 39 Saturday = 2 May 1998 (the witnessed final-round date)") and ok
	var d35 := PMChrome.date_parts("1997-98", 35)
	ok = _assert(int(d35["day"]) == 4 and str(d35["mon"]) == "April",
		"the blank week's Saturday = 4 April 1998 (F.A. Cup semi weekend)") and ok

	# 3. The calendar view skips the blank round and keeps result-week identity.
	var c := Career.new()
	c.club_id = 1000
	c.fixtures = fx
	ok = _assert(c.season_fixtures().size() == 38, "CALENDAR view lists 38 rounds") and ok
	ok = _assert(c.total_weeks() == 39 and c._blank_rounds() == 1,
		"total_weeks 39, one blank round") and ok

	# 4. Transfer deadline stays on the witnessed date: "2 weeks away" at week 32.
	c.week = 32
	ok = _assert(c.deadline_weeks_left() == 2,
		"deadline reads 2 weeks away at week 32 (R10, Sun 8 Mar)") and ok

	# 5. Division pacing reproduces both R12 witnesses on the new calendar:
	#    First Division (46 rounds, head 1 -> n=45): P=44 at week 37, P=46 by week 38.
	c.week = 37
	ok = _assert(c._division_rounds_due(45) == 43,
		"First Div due 43+1head = P 44 at the 18-Apr read (p0610)") and ok
	c.week = 38
	ok = _assert(c._division_rounds_due(45) == 45,
		"First Div complete (45+1head = 46) by week 38 — before the 2-May final") and ok

	# 6. R13 queue: finished lower divisions, lowest first, never the manager's tier.
	c.tier = 1
	c.divisions = {
		2: {"fixtures": _dummy(46), "played": 46},
		3: {"fixtures": _dummy(46), "played": 44},   # not finished -> not shown
		4: {"fixtures": _dummy(46), "played": 46},
	}
	c._queue_division_finals()
	ok = _assert(c.pending_division_finals == [4, 2],
		"queue = finished divisions only, lowest tier first") and ok

	# 7. R13 ORDER (s92): `_queue_division_finals` must run AFTER the lower divisions'
	#    rounds of the week. On a Premier career the 46-round divisions read P=44 when
	#    the queue was built before `_advance_other_divisions`, so the pre-final-round
	#    tables screen NEVER queued. Pin the call order in advance_week's own source.
	var src := (load("res://scripts/Career.gd") as GDScript).source_code
	var adv := src.find("func advance_week(")
	var body := src.substr(adv, src.find("\nfunc ", adv + 10) - adv)
	var at_queue := body.rfind("\t\t_queue_division_finals()")
	var at_lower := body.find("\t_advance_other_divisions(")
	ok = _assert(at_queue > at_lower and at_lower != -1,
		"R13 queue runs after _advance_other_divisions in advance_week") and ok

	# 8. The domestic cups land on the AUTHORED 1997-98 weeks, blank-week mapped —
	#    not the old tail_fracs x 39/38 drift (F.A. R3 wk23, QF wk32...). The F.A.
	#    FINAL takes the CUP TAIL week 40, AFTER the league's last round (owner report
	#    2026-08-05 + the real run-out: league done 10 May 1998, the final 16 May).
	var host := Career.new()
	for _i in 39:
		host.fixtures.append([])
	var late := {"round": Career.PREMIER_ENTRY_ROUND, "ids": [2000, 2001]}
	var fa: Dictionary = host._cup_opts_on_calendar(Career.FA_CUP_OPTS, Career.FA_CUP_WEEKS)
	fa["late_entry"] = late
	fa["final_week"] = 40
	var lc: Dictionary = host._cup_opts_on_calendar(Career.LEAGUE_CUP_OPTS,
		Career.LEAGUE_CUP_WEEKS)
	lc["late_entry"] = late
	var ids72: Array = []
	for i in 72:
		ids72.append(3000 + i)
	ok = _assert(Cup.create(ids72, 39, fa).get("round_weeks", []) ==
		[15, 18, 22, 25, 28, 31, 35, 40],
		"F.A. Cup rounds on the authored 97-98 weeks, FINAL on tail week 40") and ok
	ok = _assert(Cup.create(ids72, 39, lc).get("round_weeks", []) ==
		[1, 6, 10, 15, 19, 22, 25, 34],
		"Coca-Cola rounds land on the authored 97-98 weeks (FINAL wk34, 29 Mar)") and ok

	# 9. THE CUP TAIL WEEK: a manager alive in a final scheduled past the league grid
	#    gets ONE more week (season_over false at week 39), the tail advance plays the
	#    final, and the season then ends. A knocked-out manager's season ends at 39.
	var t := Career.new()
	t.club_id = 7000
	for _i in 39:
		t.fixtures.append([])
	t.week = 39
	t.fa_cup = {"name": "F.A. Cup", "champion_id": -1, "survivors": [7000, 7001],
		"rounds": [{"label": "Semifinals", "ties": []}],
		"pending_draw": {"label": "Final", "round": 8, "round_legs": 1, "byes": [],
			"players": [7000, 7001]},
		"round_weeks": [15, 18, 22, 25, 28, 31, 35, 40], "n0": 72, "legs": 1,
		"two_legged_final": false, "semi_legs": 0, "round_legs_by_round": {},
		"label_scheme": "sequential", "qtr_label": "Qtr. Finals",
		"prize_round": 0, "prize_winner": 0, "group_stage": {}, "late_ids": [],
		"late_round": 0}
	ok = _assert(not t.season_over(),
		"a finalist's season is NOT over at week 39 (the tail week waits)") and ok
	var tf := t.pending_tail_final()
	ok = _assert(str(tf.get("comp", "")) == "F.A. Cup" and int(tf.get("home_id", -1)) == 7000,
		"pending_tail_final names the F.A. Cup pairing for the hub") and ok
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	t.club_names[7000] = "Mine"
	t.club_names[7001] = "Theirs"
	t.rosters[7000] = []
	var res := t.advance_week(rng2)
	ok = _assert(res.is_empty() and t.week == 40, "the tail advance is a no-league week") and ok
	ok = _assert(int(t.fa_cup.get("champion_id", -1)) != -1,
		"the F.A. FINAL resolved on the tail week") and ok
	ok = _assert(t.season_over(), "and the season is over once the final is played") and ok
	t.fa_cup["champion_id"] = -1
	t.fa_cup["survivors"] = [7001, 7002]   # knocked out: no tail week for this manager
	t.week = 39
	ok = _assert(t.season_over(), "a knocked-out manager's season still ends at week 39") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _dummy(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append([[0, 0]])
	return out
