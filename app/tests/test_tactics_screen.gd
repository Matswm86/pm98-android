extends SceneTree
## Headless wiring test for the FRAME-BAKED TEAM TACTICS modal (TeamTacticsScreen,
## rebuilt 2026-07-27 from parity-run orig/25+26: chrome cut at (57,95) 526x303,
## EQWINX = the TICK, exit = the baked OK plate; gate =
## tools/re/diff_teamtactics_parity.py). Confirms the chrome + spec load, every
## control has a hit-rect, each click mutates the Tactics through the right
## setter, `changed` fires on levers, OK fires `done`, STEP = 5 (forced by the
## witnessed Bolton 45/55), and the .DBC lever seeding reproduces the frame-25
## witness state.
##   ~/godot462 --headless --path app --script res://tests/test_tactics_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_assert(false, "game_db.json present")
		quit(1)
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var club: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem" and (c.get("players", []) as Array).size() >= 14:
			club = c
			break
	ok = _assert(not club.is_empty(), "found a Premier club with a full squad") and ok

	# ---- the .DBC lever map (closed 2026-07-27, club_tactics_re.md) --------
	# Bolton's shipped stream [45,50,2,1,0,0,0] must reproduce the frame-25
	# witness state exactly: 45/50 + MIXED/MEDIUM/ZONAL/SHORT/OWN.
	var bt := Tactics.new()
	bt.apply_club_levers([45, 50, 2, 1, 0, 0, 0])
	ok = _assert(bt.passing_pct == 45 and bt.counter_pct == 50, "levers 0/1 = the %s") and ok
	ok = _assert(bt.mentality == "Mixed" and bt.tackling == "Medium"
		and bt.marking == "Zonal" and bt.clearances == "Short" and bt.pressurise == "Own",
		"levers 2..6 = MIXED/MEDIUM/ZONAL/SHORT/OWN (the frame-25 state)") and ok
	ok = _assert(bt.levers() == [45, 50, 2, 1, 0, 0, 0], "levers() round-trips the stream") and ok
	var bolton_lv := Tactics.club_levers(59)
	ok = _assert(bolton_lv == [45, 50, 2, 1, 0, 0, 0],
		"club_levers(59) = Bolton's shipped stream") and ok
	ok = _assert(TeamTacticsScreen.STEP == 5,
		"STEP = 5 (witnessed 45/55 unreachable in 10s)") and ok

	var t := Tactics.auto_pick(club, "4-4-2")
	var screen: TeamTacticsScreen = load("res://scenes/TeamTacticsScreen.gd").new()
	screen.size = Vector2(800, 600)
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f10 != null, "PROMAN font loaded into screen") and ok
	ok = _assert(not screen._spec.is_empty(), "team_tactics_modal spec loaded") and ok
	ok = _assert((screen._spec.get("tick_xy", {}) as Dictionary).size() == 5,
		"5 lever tick maps in the spec") and ok

	screen.setup(t)
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	ok = _assert(screen._hits.size() >= 18,
		"modal built its control hit-rects (%d)" % screen._hits.size()) and ok

	# Every control kind present: 13 radio boxes + 4 steppers + OK.
	var kinds: Dictionary = {}
	for h in screen._hits:
		kinds[str(h["kind"])] = true
	for k in ["mentality", "tackling", "marking", "clearances", "pressurise",
			"pass_inc", "pass_dec", "cnt_inc", "cnt_dec", "ok"]:
		ok = _assert(kinds.has(k), "control present: %s" % k) and ok
	ok = _assert(not kinds.has("close"), "the invented close-X is GONE") and ok

	var fired := {"changed": 0, "done": 0}
	screen.changed.connect(func(_d): fired["changed"] += 1)
	screen.done.connect(func(): fired["done"] += 1)

	screen._apply("mentality", "Attacking")
	ok = _assert(t.mentality == "Attacking", "click ATTACKING set mentality") and ok
	screen._apply("tackling", "Aggressive")
	ok = _assert(t.tackling == "Aggressive", "click AGGRESSIVE set tackling") and ok
	screen._apply("marking", "Man-to-man")
	ok = _assert(t.marking == "Man-to-man", "click MAN-TO-MAN set marking") and ok
	screen._apply("clearances", "Long")
	ok = _assert(t.clearances == "Long", "click LONG set clearances") and ok
	screen._apply("pressurise", "Opponent")
	ok = _assert(t.pressurise == "Opponent", "click OPPONENT set pressurise") and ok

	var p0: int = t.passing_pct
	screen._apply("pass_inc", null)
	ok = _assert(t.passing_pct == mini(p0 + TeamTacticsScreen.STEP, 100), "pass + steps up") and ok
	screen._apply("pass_dec", null)
	ok = _assert(t.passing_pct == p0, "pass - steps back") and ok
	var c0: int = t.counter_pct
	screen._apply("cnt_inc", null)
	ok = _assert(t.counter_pct == mini(c0 + TeamTacticsScreen.STEP, 100), "counter + steps up") and ok

	ok = _assert(fired["changed"] >= 8, "mutations emitted `changed` (%d)" % fired["changed"]) and ok

	# OK is the modal's real exit (the baked plate at x288..362 y365..392).
	ok = _assert(TeamTacticsScreen.OK_BTN.has_point(Vector2(325, 378)),
		"OK rect covers the baked plate centre") and ok
	screen._ok_held = true
	var e := InputEventMouseButton.new()
	e.position = screen._origin + Vector2(325, 378) * screen._scale
	e.pressed = false
	screen._on_input(e)
	ok = _assert(fired["done"] == 1, "OK release emitted done") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
