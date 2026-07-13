extends SceneTree
## Headless test for THE CALENDAR (FixturesScreen.gd) — the screen the hub
## FIXTURES icon opens in the original (walkthrough 050 -> 051..054 -> 055).
## Feeds the frame-051-true fixture set (fresh Man Utd career, Fri 1 Aug 1997)
## and asserts the witnessed calendar mechanics: the sheet grid (1 AUG = Friday
## col 5; 31 AUG overflows the AUGUST sheet and carries into SEPTEMBER's leading
## cell), the witnessed weekday strings (Sunday/Monday/Weds/Friday), the TODAY
## fixture pick, the NEXT-four list, competition shade tables, month paging
## clamps, and the tap round-trips.
##   ~/godot4 --headless --path app -s tests/test_fixtures_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var screen: FixturesScreen = load("res://scenes/FixturesScreen.gd").new()
	get_root().add_child(screen)
	for _i in 2:
		await process_frame
	screen.size = Vector2(640, 480)           # native -> hit-tests map 1:1

	# ---- frame-051-true season data (fresh MU career, Fri 1 Aug 1997) --------
	var entries := _frame_entries()
	screen.setup(_header(), entries, {"y": 1997, "m": 8, "d": 1})

	# --- 0. baseline detection: this IS the witnessed frame-051 state -----------
	# (so _draw shows the baked frame pixels — frame-true — not the app-font redraw)
	ok = _assert(screen._baseline, "frame-051 season detected as the baked baseline") and ok

	# --- 1. sheet grid mechanics (witnessed on the AUGUST/SEPTEMBER sheets) ----
	var aug: Array = FixturesScreen._sheet_cells(1997, 8)
	ok = _assert(aug.size() == 30, "AUGUST 1997 sheet has 30 cells (31 overflows row 5)") and ok
	var c1: Dictionary = aug[0]
	ok = _assert(int(c1["d"]) == 1 and int(c1["col"]) == 5 and int(c1["row"]) == 0,
		"1 AUG 1997 sits at col 5 (Friday), row 0") and ok
	var missing31 := true
	for c in aug:
		if int(c["d"]) == 31:
			missing31 = false
	ok = _assert(missing31, "31 AUG dropped from its own sheet (witnessed)") and ok
	var carry: Array = FixturesScreen._carry_cells(1997, 9)
	ok = _assert(carry.size() == 1 and int(carry[0]["d"]) == 31 and int(carry[0]["col"]) == 0
		and int(carry[0]["m"]) == 8, "31 AUG carries into SEPTEMBER leading cell (col 0)") and ok
	ok = _assert(FixturesScreen._carry_cells(1997, 8).is_empty(),
		"no July carry into AUGUST (July fits its sheet — witnessed empty lead cells)") and ok
	var sep: Array = FixturesScreen._sheet_cells(1997, 9)
	ok = _assert(sep.size() == 30 and int(sep[0]["col"]) == 1,
		"SEPTEMBER 1997: 30 cells, 1 SEP on col 1 (Monday)") and ok

	# --- 2. witnessed weekday strings ------------------------------------------
	ok = _assert(FixturesScreen.WEEKDAYS[FixturesScreen._wd(1997, 8, 3)] == "Sunday",
		"3 AUG 1997 -> Sunday (witnessed)") and ok
	ok = _assert(FixturesScreen.WEEKDAYS[FixturesScreen._wd(1997, 8, 4)] == "Monday",
		"4 AUG 1997 -> Monday (witnessed)") and ok
	ok = _assert(FixturesScreen.WEEKDAYS[FixturesScreen._wd(1997, 8, 6)] == "Weds",
		"6 AUG 1997 -> Weds (witnessed abbreviation)") and ok
	ok = _assert(FixturesScreen.WEEKDAYS[FixturesScreen._wd(1997, 8, 8)] == "Friday",
		"8 AUG 1997 -> Friday (witnessed)") and ok

	# --- 3. TODAY pick + the NEXT-four list -------------------------------------
	var today := screen._entry_on(1997, 8, 1)
	ok = _assert(str(today.get("home", "")) == "Juventus",
		"TODAY = Juventus - Manchester Utd. (frame 051 TODAY band)") and ok
	ok = _assert(FixturesScreen._plain("Manchester Utd.") == "MANCHESTER UTD",
		"TODAY title strips the trailing dot (witnessed 'MANCHESTER UTD')") and ok
	var nxt: Array = screen._next_entries(4)
	var names: Array = []
	for e in nxt:
		names.append("%s|%d" % [str(e["away"]), int(e["d"])])
	ok = _assert(str(names) == str(["Chelsea|3", "Manchester Utd.|4", "Sao Paulo|6", "River|8"]),
		"NEXT four = Chelsea 3 / Barcelona 4 / Sao Paulo 6 / River 8 (frame 051)") and ok

	# --- 4. competition cells + shades ------------------------------------------
	ok = _assert(screen._comp_of(1997, 8, 1) == "preseason", "1 AUG cell preseason") and ok
	ok = _assert(screen._comp_of(1997, 8, 3) == "charity", "3 AUG cell charity") and ok
	ok = _assert(screen._comp_of(1997, 8, 10) == "league", "10 AUG cell league") and ok
	ok = _assert(screen._comp_of(1997, 9, 17) == "euro_league", "17 SEP cell euro-league") and ok
	ok = _assert(screen._comp_of(1997, 8, 2) == "", "2 AUG has no fixture") and ok
	var ps := screen._shades("preseason")
	ok = _assert(ps["bar1"] == Color8(212, 127, 0) and ps["bar2"] == Color8(212, 159, 0)
		and ps["dark"] == Color8(102, 50, 12), "preseason shades = witnessed values") and ok
	var ch := screen._shades("charity")
	ok = _assert(ch["bar1"] == Color8(80, 80, 80) and ch["dark"] == Color8(80, 80, 80),
		"charity shades = witnessed values") and ok
	var lg := screen._shades("league")
	ok = _assert(lg.has("bar1") and lg["cell"] == Color8(166, 202, 240),
		"league shades derived from the legend colour (documented approximation)") and ok

	# --- 5. month paging + clamps -------------------------------------------------
	ok = _assert(screen._month[0] == 1997 and screen._month[1] == 8,
		"left sheet opens on today's month (AUGUST 1997)") and ok
	_tap(screen, FixturesScreen.R_ARROW_L.get_center())
	ok = _assert(screen._month[1] == 8, "paging left clamps at the first fixture month") and ok
	_tap(screen, FixturesScreen.R_ARROW_R.get_center())
	ok = _assert(screen._month[1] == 8,
		"paging right clamps so the right sheet stays on the last fixture month") and ok
	# a longer season: paging walks and clamps at both ends
	var long_entries := entries.duplicate()
	long_entries.append({"y": 1998, "m": 5, "d": 2, "comp": "league", "comp_name": "League",
		"round": "Week 38", "home_id": 40, "away_id": 49, "home": "Manchester Utd.",
		"away": "Chelsea", "home_flag": 30, "away_flag": 30})
	screen.setup(_header(), long_entries, {"y": 1997, "m": 8, "d": 1})
	ok = _assert(not screen._baseline,
		"a longer season diverges from the baked baseline (redraw path)") and ok
	_tap(screen, FixturesScreen.R_ARROW_R.get_center())
	ok = _assert(screen._month[0] == 1997 and screen._month[1] == 9,
		"paging right advances one month") and ok
	for _i in 12:
		_tap(screen, FixturesScreen.R_ARROW_R.get_center())
	ok = _assert(screen._month[0] == 1998 and screen._month[1] == 4,
		"paging clamps with MAY 1998 (last fixture) on the right sheet") and ok
	for _i in 12:
		_tap(screen, FixturesScreen.R_ARROW_L.get_center())
	ok = _assert(screen._month[0] == 1997 and screen._month[1] == 8,
		"paging left clamps back at AUGUST 1997") and ok

	# --- 6. tap round-trips ---------------------------------------------------------
	screen.setup(_header(), entries, {"y": 1997, "m": 8, "d": 1})
	var got := {"back": 0, "res": 0, "tab": 0}
	screen.back_pressed.connect(func() -> void: got["back"] += 1)
	screen.results_pressed.connect(func() -> void: got["res"] += 1)
	screen.tables_pressed.connect(func() -> void: got["tab"] += 1)
	_tap(screen, FixturesScreen.R_RETURN.get_center())
	ok = _assert(got["back"] == 1, "RETURN tap emits back_pressed") and ok
	_tap(screen, FixturesScreen.R_RESULTS.get_center())
	ok = _assert(got["res"] == 1, "RESULTS tap emits results_pressed") and ok
	_tap(screen, FixturesScreen.R_TABLES.get_center())
	ok = _assert(got["tab"] == 1, "LEAGUE TABLES tap emits tables_pressed") and ok
	ok = _assert(screen._hit(Vector2(300, 250)) == "", "a tap on the TODAY band is a no-op") and ok
	# press on a target, release elsewhere: no signal
	var down := InputEventScreenTouch.new()
	down.position = FixturesScreen.R_RETURN.get_center()
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = Vector2(10, 10)
	up.pressed = false
	screen._on_input(up)
	ok = _assert(got["back"] == 1, "press RETURN + release elsewhere = no signal") and ok

	# --- 7. empty season is safe (honest empty states) -------------------------------
	screen.setup(_header(), [], {"y": 1997, "m": 8, "d": 1})
	ok = _assert(screen._next_entries(4).is_empty(), "no entries -> empty NEXT list") and ok
	ok = _assert(screen._entry_on(1997, 8, 1).is_empty(), "no entries -> empty TODAY") and ok
	_tap(screen, FixturesScreen.R_ARROW_R.get_center())
	ok = _assert(screen._month[1] == 8, "no entries -> paging pinned, no crash") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## The season exactly as binding frame 051 shows it (fresh MU career):
## preseason friendlies 1/4/6/8 AUG, Charity Shield 3 AUG, league 10/14/23/28/31
## AUG + 13/20/25/27 SEP, a European League date 17 SEP.
func _frame_entries() -> Array:
	var out: Array = [
		{"y": 1997, "m": 8, "d": 1, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 1021, "away_id": 40,
			"home": "Juventus", "away": "Manchester Utd.", "home_flag": 36, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 3, "comp": "charity", "comp_name": "Charity Shield",
			"round": "Final", "home_id": 40, "away_id": 49,
			"home": "Manchester Utd.", "away": "Chelsea", "home_flag": 30, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 4, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 1000, "away_id": 40,
			"home": "F.C. Barcelona", "away": "Manchester Utd.", "home_flag": 71, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 6, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 40, "away_id": 1301,
			"home": "Manchester Utd.", "away": "Sao Paulo", "home_flag": 30, "away_flag": 20},
		{"y": 1997, "m": 8, "d": 8, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 40, "away_id": 1361,
			"home": "Manchester Utd.", "away": "River", "home_flag": 30, "away_flag": 5},
	]
	for d in [10, 14, 23, 28, 31]:
		out.append({"y": 1997, "m": 8, "d": d, "comp": "league", "comp_name": "League",
			"round": "Week", "home_id": 40, "away_id": 49, "home": "Manchester Utd.",
			"away": "Chelsea", "home_flag": 30, "away_flag": 30})
	for d in [13, 20, 25, 27]:
		out.append({"y": 1997, "m": 9, "d": d, "comp": "league", "comp_name": "League",
			"round": "Week", "home_id": 40, "away_id": 49, "home": "Manchester Utd.",
			"away": "Chelsea", "home_flag": 30, "away_flag": 30})
	out.append({"y": 1997, "m": 9, "d": 17, "comp": "euro_league", "comp_name": "European League",
		"round": "Round 1", "home_id": 40, "away_id": 1021, "home": "Manchester Utd.",
		"away": "Juventus", "home_flag": 30, "away_flag": 36})
	return out


func _header() -> Dictionary:
	return {"mode": "manager", "top": "MWM", "bottom": "Manchester Utd.", "club_id": 40,
		"weekday": "Friday", "day": "1", "month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"}


func _tap(screen: FixturesScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	screen._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
