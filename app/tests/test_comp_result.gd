extends SceneTree
## CompResultScreen — the original's own RESULTS -> CHARITY SHIELD / INTERCONTINENTAL CUP
## screen (docs/re/comp_result_screen_re.md). Headless: asset load, per-competition
## chrome selection, the un-played state, RETURN, and a paint pass.
##   ~/godot462 --headless --path app --script res://tests/test_comp_result.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/compresult/charity.png",
			"res://art/screens/compresult/intercont.png"]:
		ok = _assert(ResourceLoader.exists(path), "chrome present: %s" % path) and ok

	var scr: CompResultScreen = load("res://scenes/CompResultScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame

	# The two competitions differ ONLY in the baked chrome (MANAGER.EXE FUN_004717a0 vs
	# FUN_0048daf0 differ in the title string and the trophy bitmap and nothing else).
	scr.setup("charity", {"stadium": "Wembley",
		"home": {"name": "Manchester Utd.", "club_id": 40, "flag": 30},
		"away": {"name": "Chelsea", "club_id": 49, "flag": 30},
		"hg": 1, "ag": 0,
		"winner": {"name": "Manchester Utd.", "club_id": 40, "flag": 30}}, {})
	await process_frame
	var charity_chrome: Texture2D = scr._chrome
	ok = _assert(charity_chrome != null, "charity chrome loaded") and ok

	scr.setup("intercont", {"stadium": "Tokyo",
		"home": {"name": "Borussia D.", "club_id": 1038, "flag": 2},
		"away": {"name": "Cruzeiro", "club_id": 1306, "flag": 10}}, {})
	await process_frame
	ok = _assert(scr._chrome != null and scr._chrome != charity_chrome,
		"intercontinental swaps to its own chrome") and ok
	# An un-played tie prints no score and no winner — the original's own state in
	# 09_comp_intercont.png (Borussia D. v Cruzeiro, both score cells empty).
	ok = _assert(not scr._match.has("hg") and not scr._match.has("ag"),
		"un-played tie carries no score") and ok
	ok = _assert((scr._match.get("winner", {}) as Dictionary).is_empty(),
		"un-played tie carries no winner") and ok

	# The measured cells: both witnessed stadium names centre on 243, the score digits on
	# 325, and the club names start at x155.
	ok = _assert(CompResultScreen.STADIUM_CENTRE == 243, "STADIUM name centres on 243") and ok
	ok = _assert(CompResultScreen.SCORE_CELL[0] + CompResultScreen.SCORE_CELL[1] / 2 == 325,
		"score cell centres on 325") and ok
	ok = _assert(CompResultScreen.NAME_X == 155, "club names start at x155") and ok

	var back := [false]
	scr.back_pressed.connect(func() -> void: back[0] = true)
	_tap(scr, CompResultScreen.R_RETURN.get_center())
	ok = _assert(back[0], "RETURN emits back_pressed") and ok

	scr.queue_redraw()
	for _i in 3:
		await process_frame

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(scr: CompResultScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	scr._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	scr._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
