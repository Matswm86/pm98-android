extends SceneTree
## Headless wiring test for the CUP screen (F.A. Cup / Coca-Cola Cup run + latest draw):
## confirms the marble/BARRA chrome + PROMAN fonts + trophy art load, the RUN_PANEL /
## DRAW_PANEL / LBL_RETURN / TROPHY_AT+TROPHY_H geometry stays inside the 640x480 canvas,
## and setup() wires the club/manager/season/status data. RETURN is decorative chrome
## (the whole screen is tap-anywhere dismiss per CupScreen's own doc comment), so this
## test asserts that reality rather than treating LBL_RETURN as a distinct tap target.
##   ~/godot4 --headless --path app --script res://tests/test_cup_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# RUN_PANEL, DRAW_PANEL, LBL_RETURN stay inside the 640x480 canvas.
	for entry in [["RUN_PANEL", CupScreen.RUN_PANEL], ["DRAW_PANEL", CupScreen.DRAW_PANEL],
			["LBL_RETURN", CupScreen.LBL_RETURN]]:
		var r: Rect2 = entry[1]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= CupScreen.W and r.end.y <= CupScreen.H,
			"rect in canvas: %s" % entry[0]) and ok

	# TROPHY_AT + TROPHY_H stay inside the canvas.
	ok = _assert(CupScreen.TROPHY_AT.x >= 0 and CupScreen.TROPHY_AT.y >= 0
		and CupScreen.TROPHY_AT.y + CupScreen.TROPHY_H <= CupScreen.H,
		"trophy art (TROPHY_AT + TROPHY_H) in canvas") and ok

	# Frame chrome + trophy art + PROMAN fonts loaded in _ready() are present and loadable.
	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/screens/cup/trophy.png", "res://art/fonts/proman14.fnt",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Instantiate + let _ready() run.
	var screen: CupScreen = load("res://scenes/CupScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(screen._bg != null and screen._bar != null and screen._trophy != null,
		"chrome + trophy textures loaded") and ok

	# Feed the screen via the real setup() signature and confirm the data wires through.
	var run_rows := [
		{"round": "Round 3", "line": "Man Utd 2-0 Wrexham", "accent": CupScreen.C_WIN},
		{"round": "Round 4", "line": "Newcastle 1-1 Man Utd", "accent": CupScreen.C_TEXT},
	]
	var draw_rows := [
		{"line": "Man Utd v Barnsley", "mine": true},
		{"line": "Chelsea v Wimbledon", "mine": false},
	]
	screen.setup("Manchester Utd.", "MWM", "1997-98", "STILL IN", CupScreen.C_WIN,
		"16 clubs remain  -  Round 5 in 3 wks", run_rows, "Round 5", draw_rows, 6,
		"F.A. CUP", "res://art/screens/cup/trophy.png")
	await process_frame
	ok = _assert(screen._club == "Manchester Utd.", "club wired") and ok
	ok = _assert(screen._manager == "MWM", "manager wired") and ok
	ok = _assert(screen._season == "1997-98", "season wired") and ok
	ok = _assert(screen._status == "STILL IN", "status wired") and ok
	ok = _assert(screen._status_col == CupScreen.C_WIN, "status_col wired") and ok
	ok = _assert(screen._draw_more == 6, "draw_more wired") and ok
	ok = _assert(screen._title == "F.A. CUP", "title wired") and ok
	ok = _assert(screen._trophy != null, "emblem_path reloaded a texture") and ok

	# RETURN is decorative chrome, not a distinct tap target: the class doc says the whole
	# screen is tap-anywhere dismiss, and _draw() paints LBL_RETURN as a plain panel + label
	# with no input handling anywhere in the script. Assert that reality rather than
	# inventing hit-testing behaviour the screen does not implement.
	ok = _assert(not screen.has_method("_gui_input") and not screen.has_method("_input")
		and not screen.has_method("_unhandled_input"),
		"no input handler on CupScreen: RETURN is decorative, not a distinct hit target") and ok

	# Negative-status wiring: a knocked-out run still wires through with its own colour.
	screen.setup("Manchester Utd.", "MWM", "1997-98", "KNOCKED OUT", CupScreen.C_LOSS,
		"Out in Round 4", [], "", [], 0)
	await process_frame
	ok = _assert(screen._status == "KNOCKED OUT", "knocked-out status wired") and ok
	ok = _assert(screen._status_col == CupScreen.C_LOSS, "knocked-out status_col wired") and ok
	ok = _assert(screen._run_rows.is_empty() and screen._draw_rows.is_empty(),
		"empty run/draw rows wired (not-entered-yet path)") and ok

	# Repaint does not crash.
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
