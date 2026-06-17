extends SceneTree
## Headless wiring test for the MAIN MENU (MENUPRINCIPAL) screen: confirms the baked
## ORIGINAL-art chrome (menu_bg.png) + PROMAN fonts load, the live career chrome wires
## in, the reversed hit rects resolve taps to the right actions (and don't overlap),
## and the money formatter is correct.
##   ~/godot462 --headless --path app --script res://tests/test_menu_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Money formatter (static, pure).
	ok = _assert(MenuScreen._fmt(8000000) == "8,000,000", "fmt millions") and ok
	ok = _assert(MenuScreen._fmt(0) == "0", "fmt zero") and ok
	ok = _assert(MenuScreen._fmt(-1500) == "-1,500", "fmt negative") and ok

	for path in ["res://art/screens/menu_bg.png", "res://art/fonts/proman14.fnt",
			"res://art/fonts/proman12.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Instantiate + feed the screen.
	var scr: MenuScreen = load("res://scenes/MenuScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(scr._bg != null, "menu_bg loaded into screen") and ok
	ok = _assert(scr._f14 != null and scr._f12 != null, "PROMAN fonts loaded") and ok
	scr.setup("MANCHESTER UTD.", "Premier League", "1997-98", 8_000_000, "1st", 38)
	await process_frame
	ok = _assert(scr._club == "MANCHESTER UTD." and scr._cash == 8_000_000,
		"screen received career chrome") and ok
	ok = _assert(scr._kit_tex != null, "managed club kit (escudo) loaded into the hub") and ok

	# All 12 icon + 4 control actions are present.
	ok = _assert(MenuScreen.ICON_HITS.size() == 12, "12 icon hit rects") and ok
	ok = _assert(MenuScreen.CTRL_HITS.size() == 4, "4 control hit rects") and ok

	# Hit-testing: centre of each rect resolves to its own action.
	var all_hits: Dictionary = {}
	for d in [MenuScreen.ICON_HITS, MenuScreen.CTRL_HITS]:
		for a in d:
			all_hits[a] = d[a]
	for a in all_hits:
		var r: Rect2 = all_hits[a]
		var c := r.position + r.size * 0.5
		ok = _assert(scr._hit(c) == a, "hit centre of '%s' -> '%s'" % [a, scr._hit(c)]) and ok

	# No two hit rects overlap (a tap is unambiguous).
	var keys := all_hits.keys()
	var clash := false
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			if (all_hits[keys[i]] as Rect2).intersects(all_hits[keys[j]]):
				clash = true
				print("    overlap: %s & %s" % [keys[i], keys[j]])
	ok = _assert(not clash, "hit rects do not overlap") and ok

	# A tap in the empty centre gap resolves to nothing.
	ok = _assert(scr._hit(Vector2(320, 230)) == "", "centre gap is not a hit") and ok

	# action_selected fires for a press+release on the same icon.
	var got: Array = []
	scr.action_selected.connect(func(a: String) -> void: got.append(a))
	var fr: Rect2 = MenuScreen.ICON_HITS["finance"]
	var fc := fr.position + fr.size * 0.5
	scr._on_input(_touch(fc, true))
	scr._on_input(_touch(fc, false))
	ok = _assert(got == ["finance"], "press+release emits action (%s)" % str(got)) and ok

	# A press on one icon released on another emits nothing.
	got.clear()
	scr._on_input(_touch(fr.position + fr.size * 0.5, true))
	scr._on_input(_touch(Vector2(320, 180), false))
	ok = _assert(got.is_empty(), "drag-off cancels (%s)" % str(got)) and ok

	# Transient toast (used by the persistent hub for save / news / next-match feedback).
	scr.toast("Game saved")
	ok = _assert(scr._toast_msg == "Game saved", "toast sets the message") and ok
	scr._clear_toast()
	ok = _assert(scr._toast_msg == "", "toast clears") and ok

	scr.queue_free()
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
