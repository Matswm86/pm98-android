extends SceneTree
## Headless wiring test for the frame-baked START OF SEASON division sheet: confirms
## the season chrome + 24-row box + user-row + tab art + PROMAN fonts load, every
## baked geometry constant (CONTINUE, tabs, cell centring, row bands, box24) stays
## inside the 640x480 canvas and matches its art's own pixel size, setup() wires
## divisions data and clamps start_tab both directions, and the design-space hit
## test / _on_input state machine actually flips _tab and emits continue_pressed.
##   ~/godot4 --headless --path app --script res://tests/test_season_start_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Frame-baked chrome, art and fonts present and loadable.
	for path in ["res://art/screens/seasonflow/season.png",
			"res://art/screens/seasonflow/season_box24.png",
			"res://art/screens/seasonflow/season_row_user.png",
			"res://art/screens/seasonflow/season_tab_hot.png",
			"res://art/screens/seasonflow/season_tab_cold.png",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt",
			"res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# The season chrome is the full 640x480 frame.
	var chrome: Texture2D = load("res://art/screens/seasonflow/season.png")
	ok = _assert(chrome.get_width() == SeasonStartScreen.W and chrome.get_height() == SeasonStartScreen.H,
		"chrome is 640x480") and ok

	# box24 (24-row division insert) stays inside the canvas from its blit position.
	var box24: Texture2D = load("res://art/screens/seasonflow/season_box24.png")
	ok = _assert(SeasonStartScreen.BOX24_POS.x + box24.get_width() <= SeasonStartScreen.W
		and SeasonStartScreen.BOX24_POS.y + box24.get_height() <= SeasonStartScreen.H,
		"box24 stays in canvas") and ok

	# The user-row strip's height matches BAND_H and its width stays in canvas from x=44.
	var row_user: Texture2D = load("res://art/screens/seasonflow/season_row_user.png")
	ok = _assert(row_user.get_height() == SeasonStartScreen.BAND_H, "row_user height == BAND_H") and ok
	ok = _assert(44 + row_user.get_width() <= SeasonStartScreen.W, "row_user stays in canvas") and ok

	# Tab chip art matches every TABS[] rect's own size (draw_texture_rect stretches
	# to r, so a size mismatch would silently distort the chip rather than crash).
	var tab_hot: Texture2D = load("res://art/screens/seasonflow/season_tab_hot.png")
	var tab_cold: Texture2D = load("res://art/screens/seasonflow/season_tab_cold.png")
	for i in SeasonStartScreen.TABS.size():
		var tr: Rect2 = SeasonStartScreen.TABS[i]
		ok = _assert(tab_hot.get_size() == tr.size and tab_cold.get_size() == tr.size,
			"tab art matches TABS[%d] size" % i) and ok

	# CONTINUE + every tab rect stay inside the 640x480 canvas.
	var rects := {"BTN_CONTINUE": SeasonStartScreen.BTN_CONTINUE}
	for i in SeasonStartScreen.TABS.size():
		rects["TABS[%d]" % i] = SeasonStartScreen.TABS[i]
	for key in rects:
		var r: Rect2 = rects[key]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0
			and r.end.x <= SeasonStartScreen.W and r.end.y <= SeasonStartScreen.H,
			"rect in canvas: %s" % key) and ok

	# TEAM_X and the MANAGER/OBJECTIVE cell spans stay inside the canvas.
	ok = _assert(SeasonStartScreen.TEAM_X >= 0 and SeasonStartScreen.TEAM_X <= SeasonStartScreen.W,
		"TEAM_X in canvas") and ok
	for entry in [["MGR_CELL", SeasonStartScreen.MGR_CELL], ["OBJ_CELL", SeasonStartScreen.OBJ_CELL]]:
		var c: Array = entry[1]
		ok = _assert(int(c[0]) >= 0 and int(c[0]) + int(c[1]) <= SeasonStartScreen.W,
			"cell in canvas: %s" % entry[0]) and ok

	# The 20-row and 24-row band layouts (ROW20_Y0/ROW24_Y0 + PITCH * row count)
	# both stay inside the canvas height.
	ok = _assert(SeasonStartScreen.ROW20_Y0 + 20 * SeasonStartScreen.PITCH <= SeasonStartScreen.H,
		"20-row band stays in canvas") and ok
	ok = _assert(SeasonStartScreen.ROW24_Y0 + 24 * SeasonStartScreen.PITCH <= SeasonStartScreen.H,
		"24-row band stays in canvas") and ok

	# Instantiate the screen.
	var screen: SeasonStartScreen = load("res://scenes/SeasonStartScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(screen._chrome != null and screen._box24 != null and screen._row_user != null
		and screen._tab_hot != null and screen._tab_cold != null, "chrome art loaded") and ok

	# setup() wires divisions + start_tab. Shape matches the setup() docstring:
	# Array of {title: String, rows: Array of [team, manager, objective, is_user]}.
	var divisions: Array = [
		{"title": SeasonStartScreen.TAB_LABELS[0], "rows": _build_rows(20, 0)},
		{"title": SeasonStartScreen.TAB_LABELS[1], "rows": _build_rows(20, -1)},
		{"title": SeasonStartScreen.TAB_LABELS[2], "rows": _build_rows(20, 5)},
		{"title": SeasonStartScreen.TAB_LABELS[3], "rows": _build_rows(24, -1)},
	]
	screen.setup(divisions, 2)
	ok = _assert(screen._divisions == divisions, "_divisions wired") and ok
	ok = _assert(screen._tab == 2, "_tab set to start_tab") and ok

	# start_tab clamps both directions (clampi(start_tab, 0, divisions.size() - 1)).
	screen.setup(divisions, 99)
	ok = _assert(screen._tab == divisions.size() - 1, "_tab clamps to last division on overflow") and ok
	screen.setup(divisions, -5)
	ok = _assert(screen._tab == 0, "_tab clamps to 0 on negative start_tab") and ok

	# Land on the 24-row (big) division so the redraw below exercises the box24 path.
	screen.setup(divisions, 3)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	# A tap on tab 0's centre (design space) flips _tab via the real
	# _to_design -> _target_at -> _on_input pipeline, not a hand-set value.
	var tab0_center: Vector2 = SeasonStartScreen.TABS[0].position + SeasonStartScreen.TABS[0].size * 0.5
	var p0 := _design_to_screen(screen, tab0_center)
	screen._on_input(_mouse_event(p0, true))
	ok = _assert(screen._press == "tab:0", "tab tap press sets _press to tab:0") and ok
	screen._on_input(_mouse_event(p0, false))
	ok = _assert(screen._tab == 0, "tab tap release switches _tab to 0") and ok
	ok = _assert(screen._press == "", "_press cleared after tab release") and ok

	# A tap on CONTINUE's centre resolves through the same pipeline and emits
	# continue_pressed.
	var got_continue := [false]
	screen.continue_pressed.connect(func(): got_continue[0] = true)
	var cc: Vector2 = SeasonStartScreen.BTN_CONTINUE.position + SeasonStartScreen.BTN_CONTINUE.size * 0.5
	var pc := _design_to_screen(screen, cc)
	screen._on_input(_mouse_event(pc, true))
	ok = _assert(screen._press == "continue", "continue tap press sets _press to continue") and ok
	screen._on_input(_mouse_event(pc, false))
	ok = _assert(got_continue[0], "continue tap release emits continue_pressed") and ok
	ok = _assert(screen._press == "", "_press cleared after continue release") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## rows: n entries of [team, manager, objective, is_user], with row user_idx (if
## >= 0) flagged is_user -- the shape setup()'s docstring + _draw() both read.
func _build_rows(n: int, user_idx: int) -> Array:
	var rows: Array = []
	for i in n:
		rows.append(["Club %02d" % (i + 1), "Manager %02d" % (i + 1), "Mid-table", i == user_idx])
	return rows


## Mirrors SeasonStartScreen._to_design()'s own transform (Control size -> design
## space) so a synthetic InputEventMouseButton positioned here round-trips through
## the screen's real _to_design() to the intended design-space point, whatever the
## headless viewport's actual size resolves to.
func _design_to_screen(screen: SeasonStartScreen, d: Vector2) -> Vector2:
	var sz := screen.size
	var s: float = (min(sz.x / SeasonStartScreen.W, sz.y / SeasonStartScreen.H)
		if sz.x > 0 and sz.y > 0 else 1.0)
	var off := Vector2((sz.x - SeasonStartScreen.W * s) * 0.5, (sz.y - SeasonStartScreen.H * s) * 0.5)
	return d * s + off


func _mouse_event(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
