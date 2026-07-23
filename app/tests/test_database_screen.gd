extends SceneTree
## Headless wiring test for the reversed dbasewin.exe DATA BASE squad view
## (DataBaseScreen): confirms the four column rects, the LISTS/PHOTOS row
## metrics, the "more" badge and the nav-button rects all stay inside the
## 640x480 canvas; that the FONDO/PROMAN/Futuri18/Calend8 assets exist and
## load; that instantiating the screen loads its fonts + background; and
## that setup(club) with a real GameDB club wires _club and populates the
## tappable _rows (in both LISTS and PHOTOS mode) without crashing on redraw.
##   ~/godot4 --headless --path app --script res://tests/test_database_screen.gd


func _initialize() -> void:
	_run()


## Mirrors DataBaseScreen._row_cap() (FUN_0042b540 iVar8) using the class's own consts.
func _row_cap_for(key: String, photos: bool) -> int:
	if key == "GK":
		return DataBaseScreen.CAP_GK_PHOTOS if photos else DataBaseScreen.CAP_GK_LISTS
	return DataBaseScreen.CAP_OUT_PHOTOS if photos else DataBaseScreen.CAP_OUT_LISTS


func _run() -> void:
	var ok := true

	# ---- static geometry: column rects, nav buttons, legend stay in the 640x480 canvas ----
	for col in DataBaseScreen.COLS:
		var r: Rect2 = col["rect"]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"column rect in canvas: %s" % col["key"]) and ok

	for entry in [["BTN_TOGGLE", DataBaseScreen.BTN_TOGGLE], ["BTN_PRINT", DataBaseScreen.BTN_PRINT],
			["RETURN_BTN", DataBaseScreen.RETURN_BTN]]:
		var br: Rect2 = entry[1]
		ok = _assert(br.position.x >= 0 and br.position.y >= 0 and br.end.x <= 640 and br.end.y <= 480,
			"rect in canvas: %s" % entry[0]) and ok

	for cell in DataBaseScreen.LEGEND:
		var x: float = cell["x"]
		ok = _assert(x >= 0 and x < 640 and DataBaseScreen.LEGEND_Y + 11 <= 480,
			"legend cell in canvas: %s" % cell["label"]) and ok

	ok = _assert(DataBaseScreen.STATUS_BAR.size() >= 4,
		"STATUS_BAR array covers status codes 0..3 (%d entries)" % DataBaseScreen.STATUS_BAR.size()) and ok

	# The "more" badge is drawn at column.rect.position + MORE_BADGE, per column: must sit
	# inside both the owning column's rect and the overall canvas.
	for col in DataBaseScreen.COLS:
		var r: Rect2 = col["rect"]
		var bx: float = r.position.x + DataBaseScreen.MORE_BADGE.position.x
		var by: float = r.position.y + DataBaseScreen.MORE_BADGE.position.y
		var bw: float = DataBaseScreen.MORE_BADGE.size.x
		var bh: float = DataBaseScreen.MORE_BADGE.size.y
		ok = _assert(bx >= 0 and by >= 0 and bx + bw <= 640 and by + bh <= 480,
			"MORE_BADGE in canvas for column %s" % col["key"]) and ok
		ok = _assert(bx + bw <= r.end.x and by + bh <= r.end.y,
			"MORE_BADGE stays inside its own column %s" % col["key"]) and ok

	# Row metrics (LISTS + PHOTOS): item box must fit the column width, and the LAST visible
	# row (per the binary's fixed cap, FUN_0042b540) must fit the column height.
	for photos in [false, true]:
		var mode_name := "PHOTOS" if photos else "LISTS"
		var first_y: float = DataBaseScreen.FIRST_Y_PH if photos else DataBaseScreen.FIRST_Y
		var pitch: float = DataBaseScreen.PITCH_PH if photos else DataBaseScreen.PITCH
		var item_x: float = DataBaseScreen.ROW_X_PH if photos else DataBaseScreen.ROW_X
		var item_w: float = DataBaseScreen.ROW_W_PH if photos else DataBaseScreen.ROW_W
		var item_h: float = DataBaseScreen.ITEM_H_PH if photos else DataBaseScreen.ITEM_H
		for col in DataBaseScreen.COLS:
			var r: Rect2 = col["rect"]
			ok = _assert(item_x + item_w <= r.size.x,
				"%s row width fits column %s (%.0f<=%.0f)" % [mode_name, col["key"], item_x + item_w, r.size.x]) and ok
			var cap := _row_cap_for(str(col["key"]), photos)
			var max_rows: int = min(int(floor((r.size.y - first_y) / pitch)), cap)
			ok = _assert(max_rows > 0,
				"%s column %s has positive visible row capacity (%d)" % [mode_name, col["key"], max_rows]) and ok
			if max_rows > 0:
				var last_bottom: float = first_y + (max_rows - 1) * pitch + item_h
				ok = _assert(last_bottom <= r.size.y,
					"%s last-row bottom fits column %s (%.1f<=%.1f)" % [mode_name, col["key"], last_bottom, r.size.y]) and ok

	# ---- frame-baked assets exist and load ----
	for path in ["res://art/screens/fondo_dbase.png",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman12.fnt", "res://art/fonts/proman18.fnt",
			"res://art/fonts/futuri18.fnt", "res://art/fonts/calend8.fnt",
			"res://art/icons/dbase_new_signing.png", "res://art/icons/dbase_youth.png",
			"res://art/icons/dbase_absence.png", "res://art/icons/dbase_more_gk.png",
			"res://art/icons/dbase_more_players.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# ---- GameDB: get a real club with players (same lookup pattern as
	# shot_dbase_card_tapthrough.gd / shot_dbase_card.gd) ----
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		gamedb = load("res://scripts/GameDB.gd").new()
		gamedb.name = "GameDB"
		get_root().add_child(gamedb)
	for _i in 10:
		if not gamedb.clubs.is_empty():
			break
		await process_frame
	ok = _assert(not gamedb.clubs.is_empty(), "GameDB loaded clubs") and ok

	var club: Dictionary = {}
	for c in gamedb.clubs:
		if not (c.get("players", []) as Array).is_empty():
			club = c
			break
	ok = _assert(not club.is_empty(), "GameDB has a club with a non-empty players array") and ok

	# ---- instantiate the screen, confirm assets loaded on _ready ----
	var screen: DataBaseScreen = load("res://scenes/DataBaseScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f10 != null and screen._f12 != null and screen._f18 != null
			and screen._ffut != null and screen._fcal != null,
		"PROMAN10/12/18 + Futuri18 + Calend8 fonts loaded") and ok
	ok = _assert(screen._bg != null, "FONDO DBASE background loaded") and ok

	# ---- setup() wires the club and, once drawn, populates the tappable rows ----
	screen.setup(club)
	for _i in 3:
		await process_frame
	ok = _assert(screen._club.get("id") == club.get("id"), "setup() wires _club to the given club") and ok
	ok = _assert(screen._rows.size() > 0,
		"setup() + draw populate tappable _rows (%d rows for %d players)"
			% [screen._rows.size(), (club.get("players", []) as Array).size()]) and ok

	var rows_ok_lists := true
	for row in screen._rows:
		var rr: Rect2 = row["r"]
		if not (rr.position.x >= 0 and rr.position.y >= 0 and rr.end.x <= 640 and rr.end.y <= 480):
			rows_ok_lists = false
	ok = _assert(rows_ok_lists,
		"all %d LISTS-mode row rects stay inside the 640x480 canvas" % screen._rows.size()) and ok

	# ---- PHOTOS-mode toggle: rows stay populated and in-canvas under the wider layout ----
	screen._photos = true
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	ok = _assert(screen._rows.size() > 0,
		"PHOTOS mode keeps _rows populated (%d)" % screen._rows.size()) and ok
	var rows_ok_photos := true
	for row in screen._rows:
		var rr: Rect2 = row["r"]
		if not (rr.position.x >= 0 and rr.position.y >= 0 and rr.end.x <= 640 and rr.end.y <= 480):
			rows_ok_photos = false
	ok = _assert(rows_ok_photos,
		"all %d PHOTOS-mode row rects stay inside the 640x480 canvas" % screen._rows.size()) and ok

	# ---- a final redraw pass (LISTS again) must not crash ----
	screen._photos = false
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	ok = _assert(is_instance_valid(screen), "screen survives a final redraw pass without crashing") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
