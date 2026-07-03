extends SceneTree
## Headless wiring test for the TACTICS board (TACTICAS, frame 014_162413):
## confirms it mounts with a live career Tactics, loads the ten source formations,
## builds the binary-exact button hit-rects, that PARAM./RATING toggles the stat
## view, that PREDEF opens the 10-formation picker and a pick emits
## `formation_picked`, and that the nav buttons fire their signals. Headless can't
## rasterize, so this drives the same _activate() path _on_input() dispatches to,
## plus forced paint passes.
##   ~/godot462 --headless --path app --script res://tests/test_tactics_board.gd


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

	var t := Tactics.auto_pick(club, "3-5-2")
	var screen: TacticsBoardScreen = load("res://scenes/TacticsBoardScreen.gd").new()
	screen.size = Vector2(640, 480)
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null, "PROMAN fonts loaded") and ok
	ok = _assert(screen._campo != null, "CAMPO pitch texture loaded") and ok
	ok = _assert(screen._forms.size() == 10, "loaded 10 source formations (%d)" % screen._forms.size()) and ok
	# every predefined formation name from the source table is present.
	for name in ["3-4-3", "3-5-2", "4-3-3", "4-4-2", "5-3-2", "5-4-1", "4-2-4", "5-2-3", "4-5-1", "3-3-3-1"]:
		ok = _assert(screen._forms.has(name), "formation present: %s" % name) and ok

	screen.setup(club, t, "", "Premier League", "1997-98", 1)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	# The binary-exact buttons all built hit-rects.
	var kinds: Dictionary = {}
	for h in screen._hits:
		kinds[str(h["kind"])] = true
	for k in ["predef", "load", "save", "param", "rating", "team", "rival", "lineup", "return"]:
		ok = _assert(kinds.has(k), "button present: %s" % k) and ok

	# RATING is the default view; PARAM. flips to numeric, RATING flips back.
	ok = _assert(screen._rating_view, "RATING is the default stat view") and ok
	screen._activate("param")
	ok = _assert(not screen._rating_view, "PARAM. selected the numeric view") and ok
	screen._activate("rating")
	ok = _assert(screen._rating_view, "RATING re-selected the star view") and ok

	# PREDEF opens the picker; it builds one hit per formation + CANCEL.
	var picked := {"form": ""}
	screen.formation_picked.connect(func(fm: String): picked["form"] = fm)
	screen._activate("predef")
	ok = _assert(screen._picker_open, "PREDEF opened the picker") and ok
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	var pick_hits := 0
	var has_cancel := false
	for h in screen._hits:
		if str(h["kind"]).begins_with("pick:"):
			pick_hits += 1
		if str(h["kind"]) == "pick_cancel":
			has_cancel = true
	ok = _assert(pick_hits == 10, "picker shows 10 formation cells (%d)" % pick_hits) and ok
	ok = _assert(has_cancel, "picker has a CANCEL button") and ok

	# Picking 4-3-3 closes the picker and emits formation_picked("4-3-3").
	screen._activate("pick:4-3-3")
	ok = _assert(not screen._picker_open, "a pick closed the picker") and ok
	ok = _assert(picked["form"] == "4-3-3", "pick emitted formation_picked (%s)" % picked["form"]) and ok

	# CANCEL closes without a pick.
	screen._activate("predef")
	screen._activate("pick_cancel")
	ok = _assert(not screen._picker_open, "CANCEL closed the picker") and ok

	# Nav buttons fire their signals.
	var fired := {"team": 0, "rival": 0, "lineup": 0, "return": 0, "save": 0, "load": 0}
	screen.team_tactics_pressed.connect(func(): fired["team"] += 1)
	screen.view_rival_pressed.connect(func(): fired["rival"] += 1)
	screen.lineup_pressed.connect(func(): fired["lineup"] += 1)
	screen.return_pressed.connect(func(): fired["return"] += 1)
	screen.save_pressed.connect(func(): fired["save"] += 1)
	screen.load_pressed.connect(func(): fired["load"] += 1)
	for k in ["team", "rival", "lineup", "return", "save", "load"]:
		screen._activate(k)
	for k in fired:
		ok = _assert(fired[k] == 1, "%s button fired its signal" % k) and ok

	# The pitch places a token for every XI slot (11) using the real formation table.
	# gk_slot is the parked far-left disc in all ten shapes.
	var rec: Dictionary = screen._forms["3-5-2"]
	ok = _assert(int(rec.get("gk_slot", -1)) == 10, "3-5-2 gk_slot = 10 (parked)") and ok
	ok = _assert((rec.get("slots", []) as Array).size() == 11, "3-5-2 has 11 slots") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
