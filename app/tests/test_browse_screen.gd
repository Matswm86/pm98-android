extends SceneTree
## Headless wiring test for the reusable PM98-chrome BrowseScreen (Track B): chrome assets
## load, rows normalize (strings + dicts), tap-to-select emits the right index, the RETURN
## button emits back_pressed, disabled rows don't select, and a drag scrolls without
## selecting (so a flick to scroll never fires a row).
##   ~/godot462 --headless --path app --script res://tests/test_browse_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman12.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var scr: BrowseScreen = load("res://scenes/BrowseScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)   # scale 1, origin 0 -> design space == screen space
	for _i in 3:
		await process_frame
	ok = _assert(scr._bg != null and scr._bar != null, "chrome bg + bar loaded") and ok
	ok = _assert(scr._f14 != null and scr._f12 != null, "PROMAN fonts loaded") and ok

	# 20 rows so the content overflows the panel and can scroll. Mix strings + dicts.
	var rows: Array = [{"text": "Alpha", "value": "1"}, "Bravo", {"text": "Charlie", "value": "3"},
		{"text": "Disabled", "enabled": false}]
	for i in range(4, 20):
		rows.append({"text": "Row %d" % i, "value": str(i)})
	scr.setup("BROWSE TEST", "subtitle", rows, {"back_label": "RETURN"})
	await process_frame
	ok = _assert(scr._rows.size() == 20, "rows normalized (%d)" % scr._rows.size()) and ok
	ok = _assert(scr._rows[1]["text"] == "Bravo" and scr._rows[1]["enabled"],
		"plain string row normalized + enabled") and ok
	ok = _assert(scr._max_scroll() > 0.0, "content overflows -> scrollable") and ok

	var got_sel: Array = []
	var got_back: Array = []
	scr.row_selected.connect(func(i: int) -> void: got_sel.append(i))
	scr.back_pressed.connect(func() -> void: got_back.append(true))

	# Tap row 0 (Alpha): center y = PANEL.y + ROW_H/2 = 50 + 13 = 63.
	scr._on_input(_touch(Vector2(320, 63), true))
	scr._on_input(_touch(Vector2(320, 63), false))
	ok = _assert(got_sel == [0], "tap row 0 emits row_selected(0) -> %s" % str(got_sel)) and ok

	# Tap the RETURN button (BACK_BTN center).
	got_sel.clear()
	scr._on_input(_touch(Vector2(579, 461), true))
	scr._on_input(_touch(Vector2(579, 461), false))
	ok = _assert(got_back.size() == 1 and got_sel.is_empty(),
		"tap RETURN emits back_pressed only") and ok

	# Tap the disabled row (index 3, center y = 50 + 3*26 + 13 = 141): no selection.
	got_sel.clear()
	scr._on_input(_touch(Vector2(320, 141), true))
	scr._on_input(_touch(Vector2(320, 141), false))
	ok = _assert(got_sel.is_empty(), "disabled row does not select (%s)" % str(got_sel)) and ok

	# Drag to scroll: press, drag up past the slop, release -> scrolled, nothing selected.
	got_sel.clear()
	scr._scroll = 0.0
	scr._on_input(_touch(Vector2(320, 300), true))
	scr._on_input(_drag(Vector2(320, 200)))     # dy = -100, well past DRAG_SLOP
	scr._on_input(_touch(Vector2(320, 200), false))
	ok = _assert(scr._scroll > 0.0, "drag scrolled the list (scroll=%.0f)" % scr._scroll) and ok
	ok = _assert(got_sel.is_empty(), "a scroll flick selects nothing (%s)" % str(got_sel)) and ok

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _drag(pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.position = pos
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
