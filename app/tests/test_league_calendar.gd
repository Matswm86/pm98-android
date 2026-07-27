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

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _dummy(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append([[0, 0]])
	return out
