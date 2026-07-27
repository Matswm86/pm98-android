extends SceneTree
## INPUT-DRIVEN tap-through of the DATA BASE card flow — the real Main booted the
## normal way, then driven end-to-end by synthesized InputEventScreenTouch taps
## (press+release through Input.parse_input_event), never by calling the nav
## methods directly. This is the piece test_browse_nav.gd does not cover: the
## hit rects, press/release matching, signal wiring and z-order of
##   TITLE -> DATA BASE -> league -> club -> DATA BASE squad row -> player card
##   -> CAREER tab -> RETURN -> RETURN
## exactly as a finger drives them on device (emulate_mouse_from_touch is on by
## default there, so every tap is also checked for double-fire: one tap must
## raise exactly ONE screen). Captures a PNG per stage as the visual record.
##   PM98_TAP_DIR=out/tap godot --rendering-driver opengl3 --path app \
##     --script res://tests/shot_dbase_card_tapthrough.gd

var _shots := 0
var _dir := ""


func _initialize() -> void:
	_run()


func _tap(pos: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = pos
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = pos
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame
	await process_frame


func _shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_shots += 1
	var img := get_root().get_texture().get_image()
	var path := _dir.path_join("tap_%02d_%s.png" % [_shots, label])
	img.save_png(path)
	print("  SHOT %s (%dx%d)" % [path.get_file(), img.get_width(), img.get_height()])


func _count(main: Node, type: Variant) -> int:
	var n := 0
	for c in main.get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion() and is_instance_of(c, type):
			n += 1
	return n


func _find(main: Node, type: Variant) -> Node:
	for c in main.get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion() and is_instance_of(c, type):
			return c
	return null


## A finger drag (press -> interpolated ScreenDrag steps -> release). A drag past
## DRAG_SLOP scrolls the browse list and must NOT select the row under the finger.
func _drag(from: Vector2, to: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = from
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	for i in range(1, 7):
		var mv := InputEventScreenDrag.new()
		mv.index = 0
		mv.position = from.lerp(to, i / 6.0)
		Input.parse_input_event(mv)
		await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = to
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame


## Tap a BrowseScreen row by its text, drag-scrolling it into the panel first when it
## sits below the fold (design==window space at 640x480). Returns false if absent.
func _browse_tap_row(br: BrowseScreen, text: String) -> bool:
	var idx := -1
	for i in br._rows.size():
		if str(br._rows[i]["text"]) == text:
			idx = i
	if idx < 0:
		return false
	var pr: Rect2 = BrowseScreen.PANEL
	var row_y := func() -> float:
		return pr.position.y + idx * BrowseScreen.ROW_H - br._scroll + BrowseScreen.ROW_H * 0.5
	if row_y.call() > pr.end.y - 8.0 or row_y.call() < pr.position.y + 8.0:
		var want: float = clampf(idx * BrowseScreen.ROW_H - pr.size.y * 0.5, 0.0, br._max_scroll())
		var delta: float = want - br._scroll
		await _drag(Vector2(320, 380), Vector2(320, 380 - delta))
	await _tap(Vector2(320, row_y.call()))
	return true


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("TAP-THROUGH SKIPPED: needs a rendering driver (DataBaseScreen row rects fill in _draw)")
		quit(1)
		return
	_dir = OS.get_environment("PM98_TAP_DIR")
	if _dir == "":
		_dir = "out/tap"
	DirAccess.make_dir_recursive_absolute(_dir)
	get_root().size = Vector2i(640, 480)

	# Harness isolation: a prior career save in user:// makes boot resume past the
	# TITLE door and the boot assert fails (2026-07-26 sweep note — harness-state
	# contamination, not an app bug). Tests own their state.
	Career.delete_save()

	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 30:
		await process_frame
	var ok := true

	# Boot state: home browse mounted beneath, TITLE front door on top.
	ok = _assert(_count(main, TitleScreen) == 1, "boot raises one TITLE screen") and ok
	await _shot("title")

	# 1. Tap DATA BASE on the title (hit rect 20,197 332x45).
	await _tap(Vector2(186, 219))
	ok = _assert(_count(main, TitleScreen) == 0, "DATA BASE tap dismisses the title") and ok
	var home: BrowseScreen = main._browse
	ok = _assert(home != null and is_instance_valid(home), "home browse revealed beneath") and ok
	ok = _assert(_count(main, BrowseScreen) == 1, "exactly one browse after the tap (no double-fire)") and ok
	await _shot("home")

	# Target: the walked card player (id 45, Schmeichel) -> his club + league.
	var gamedb: Node = get_root().get_node("GameDB")
	var club: Dictionary = {}
	var league: Dictionary = {}
	for c in gamedb.clubs:
		for p in c.get("players", []):
			if int(p.get("id", -1)) == 45:
				club = c
	ok = _assert(not club.is_empty(), "GameDB holds the walked player id 45") and ok
	for lg in gamedb.leagues:
		if str(lg["id"]) == str(club.get("leagueId")):
			league = lg
	ok = _assert(not league.is_empty(), "his club sits in a league") and ok
	if club.is_empty() or league.is_empty():
		print("\nFAILURES ABOVE")
		quit(1)
		return

	# 2. Tap the league row on the home browse.
	ok = _assert(await _browse_tap_row(home, str(league["name"])),
		"home browse lists the league") and ok
	var lgbr: BrowseScreen = main._browse
	ok = _assert(lgbr != null and is_instance_valid(lgbr) and lgbr != home,
		"league tap mounts the league browse") and ok
	ok = _assert(_count(main, BrowseScreen) == 1, "old browse freed (no double-fire)") and ok
	await _shot("league")

	# 3. Tap the club row (drag-scrolled into view) -> the reversed DATA BASE squad view.
	ok = _assert(await _browse_tap_row(lgbr, str(club["name"])),
		"league browse lists the club") and ok
	var db: DataBaseScreen = main._database
	ok = _assert(db != null and is_instance_valid(db), "club tap mounts the DATA BASE squad view") and ok
	ok = _assert(_count(main, DataBaseScreen) == 1, "exactly one squad view") and ok
	await _shot("dbase_squad")
	if db == null:
		print("\nFAILURES ABOVE")
		quit(1)
		return

	# 4. Tap a player row (prefer id 45 if visible; else the first row with a bio).
	ok = _assert(not db._rows.is_empty(), "squad view drew its tappable rows") and ok
	var row: Dictionary = {}
	for r in db._rows:
		if int((r["p"] as Dictionary).get("id", -1)) == 45:
			row = r
	if row.is_empty():
		for r in db._rows:
			var bio := DataBaseCardScreen.bios_of(int((r["p"] as Dictionary).get("id", -1)))
			if not bio.is_empty():
				row = r
				break
	if row.is_empty() and not db._rows.is_empty():
		row = db._rows[0]
	var want: Dictionary = row.get("p", {})
	await _tap((row["r"] as Rect2).get_center())
	var card: DataBaseCardScreen = _find(main, DataBaseCardScreen)
	ok = _assert(card != null, "row tap raises the DATA BASE player card") and ok
	ok = _assert(_count(main, DataBaseCardScreen) == 1,
		"exactly ONE card (device double-fire guard)") and ok
	if card == null:
		print("\nFAILURES ABOVE")
		quit(1)
		return
	ok = _assert(int(card._p.get("id", -1)) == int(want.get("id", -2)),
		"card shows the TAPPED player (%s)" % str(want.get("name", "?"))) and ok
	ok = _assert(card._view == "pdata", "card opens on PERSONAL DATA") and ok
	await _shot("card_pdata")

	# 5. Tap the CAREER tab (tab index 3) when the bio enables it.
	if card._tab_ok[3]:
		var tabr: Array = DataBaseCardScreen.TAB_X[3]
		await _tap(Vector2((tabr[0] + tabr[1]) * 0.5, DataBaseCardScreen.TAB_Y0 + 10))
		ok = _assert(card._view == "career", "CAREER tab tap switches the view") and ok
		await _shot("card_career")
	else:
		print("  [note] CAREER tab disabled for this bio; tab tap skipped")

	# 6. RETURN on the card -> back to the squad view (card freed, squad intact).
	await _tap(DataBaseCardScreen.BTN_RETURN.get_center())
	ok = _assert(_find(main, DataBaseCardScreen) == null, "card RETURN dismisses the card") and ok
	ok = _assert(is_instance_valid(db) and not db.is_queued_for_deletion(),
		"squad view still mounted beneath") and ok
	await _shot("back_at_squad")

	# 7. RETURN on the squad view -> back to the league browse.
	await _tap(DataBaseScreen.RETURN_BTN.get_center())
	ok = _assert(_count(main, DataBaseScreen) == 0, "squad RETURN dismisses the squad view") and ok
	ok = _assert(main._database == null, "Main clears its _database ref") and ok
	ok = _assert(is_instance_valid(lgbr) and not lgbr.is_queued_for_deletion(),
		"league browse still mounted beneath") and ok
	await _shot("back_at_league")

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
