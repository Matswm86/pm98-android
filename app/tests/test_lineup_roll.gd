extends SceneTree
## Headless test for the PRE-MATCH XI-vs-XI PHOTO ROLL (LineupRollScreen.gd,
## charter #5) + the MATCH OPTIONS LINE-UPS toggle that gates it — semantics
## per the LIVE witness run (docs/re/matchday_flow_witness_re.md):
## clean fondo first (row 1 NOT pre-landed), ~4.3s row pitch, tap mid-roll
## snaps to the complete board, the complete board AUTO-advances after the
## hold (zero-click), a tap on the complete board advances immediately;
## MATCH OPTIONS: LINE-UPS defaults ON, only the ON/OFF cell toggles (the
## label plate is inert), and matchday launch_on_select fires confirmed on a
## view-mode tap.
##   ~/godot462 --headless --path app --script res://tests/test_lineup_roll.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/matchflow/prematch_bg.png",
			"res://art/screens/matchflow/prematch_full.png",
			"res://art/screens/matchflow/roll_sil.png",
			"res://art/screens/matchflow/brief_running.png",
			"res://art/screens/matchflow/brief_ft.png",
			"res://art/screens/alert/yes.png",
			"res://art/screens/alert/no.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset exists: %s" % path) and ok

	var scr: LineupRollScreen = load("res://scenes/LineupRollScreen.gd").new()
	root.add_child(scr)
	var home_xi: Array = []
	var away_xi: Array = []
	for i in 11:
		home_xi.append({"num": i + 1, "name": "Home %d" % (i + 1), "photo_id": null})
		away_xi.append({"num": 20 + i, "name": "Away %d" % (i + 1), "photo_id": 3371})
	scr.setup("Aston Villa", "Bolton W", "Gregory", "mwm", 1, 2, home_xi, away_xi)
	var dones: Array = []
	scr.done.connect(func() -> void: dones.append(true))

	ok = _assert(not scr.is_complete() and scr._t == 0.0,
		"mount state: clean fondo, nothing landed (witness f0092)") and ok
	scr._process(scr.FONDO_TIME + 0.1)
	ok = _assert(scr._t - scr.row_start(0) > 0.0 and scr._t - scr.row_start(1) < 0.0,
		"row 1 starts after the fondo beat; row 2 not yet (4.3s pitch)") and ok

	# the board completes on the witnessed clock and AUTO-advances after the hold
	while scr._t < scr.complete_time():
		scr._process(1.0)
	ok = _assert(scr.is_complete() and dones.is_empty(),
		"complete at ~%.1fs, no auto-advance before the hold" % scr.complete_time()) and ok
	while scr._t < scr.complete_time() + scr.HOLD_TIME + 0.5 and dones.is_empty():
		scr._process(1.0)
	ok = _assert(dones.size() == 1,
		"complete board AUTO-advances after the hold (zero-click witness)") and ok

	# a tap mid-roll snaps to the complete board; a tap on it advances at once
	scr.setup("A", "B", "", "", 1, 2, home_xi, away_xi)
	scr._finished = false
	dones.clear()
	scr._process(2.0)
	scr._on_input(_touch(Vector2(320, 240), true))
	scr._on_input(_touch(Vector2(320, 240), false))
	ok = _assert(scr.is_complete() and dones.is_empty(),
		"tap mid-roll snaps to the complete board (no advance)") and ok
	scr._on_input(_touch(Vector2(320, 240), true))
	scr._on_input(_touch(Vector2(320, 240), false))
	ok = _assert(dones.size() == 1, "tap on the complete board advances") and ok
	scr.queue_free()

	# MATCH OPTIONS: LINE-UPS cell-only toggle + matchday launch-on-select
	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	root.add_child(opt)
	opt.setup("brief")
	ok = _assert(bool(opt._s.get("lineups", false)), "LINE-UPS defaults ON") and ok
	ok = _assert(opt._hit(opt.LINEUPS_ON.get_center()) == "lineups",
		"ON/OFF cell hit-tests as lineups") and ok
	ok = _assert(opt._hit(Vector2(162, 356)) == "",
		"LINE-UPS label plate is INERT (witnessed)") and ok
	opt._activate("lineups")
	ok = _assert(not bool(opt._s.get("lineups", true)), "cell tap flips OFF") and ok
	var got: Array = []
	opt.confirmed.connect(func(m: String, s: Dictionary) -> void: got.append([m, s]))
	opt._activate("ok")
	ok = _assert(got.size() == 1 and got[0][1].get("lineups") == false,
		"OK carries lineups=false in the control block") and ok
	# matchday context: a view-mode tap launches immediately (witnessed §2)
	opt.launch_on_select = true
	opt._activate("watch")
	ok = _assert(got.size() == 2 and got[1][0] == "watch",
		"launch_on_select: view-mode tap fires confirmed immediately") and ok
	opt.launch_on_select = false
	opt._activate("brief")
	ok = _assert(got.size() == 2,
		"settings context: view-mode tap only selects (no confirm)") and ok
	opt.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
