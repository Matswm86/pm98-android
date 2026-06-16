extends SceneTree
## Headless wiring test for the PM98 TITLE / front-door screen: confirms the reversed
## ORIGINAL-art background (title/fondo7.png) + the PROMAN font load, the four reversed
## hit rects resolve taps to the right actions (and don't overlap), the title art is
## the expected 640x480, and a press+release emits action_selected.
##   ~/godot462 --headless --path app --script res://tests/test_title_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/title/fondo7.png", "res://art/fonts/proman12.fnt",
			"res://art/screens/fondo_marble.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# The background is the iconic 640x480 PREMIER\SININFO\FONDO7 title scene.
	var bg: Texture2D = load("res://art/screens/title/fondo7.png")
	ok = _assert(bg.get_width() == 640 and bg.get_height() == 480,
		"FONDO7 is 640x480 (%dx%d)" % [bg.get_width(), bg.get_height()]) and ok

	# Instantiate the screen.
	var scr: TitleScreen = load("res://scenes/TitleScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(scr._bg != null, "fondo7 loaded into screen") and ok
	ok = _assert(scr._f12 != null, "PROMAN font loaded") and ok

	# The four front-door actions are present.
	ok = _assert(TitleScreen.HITS.size() == 4, "4 hit rects") and ok
	for a in ["database", "career_league", "career_pro", "exit"]:
		ok = _assert(TitleScreen.HITS.has(a), "action present: %s" % a) and ok

	# Hit-testing: centre of each rect resolves to its own action.
	for a in TitleScreen.HITS:
		var r: Rect2 = TitleScreen.HITS[a]
		var c := r.position + r.size * 0.5
		ok = _assert(scr._hit(c) == a, "hit centre of '%s' -> '%s'" % [a, scr._hit(c)]) and ok

	# No two hit rects overlap (a tap is unambiguous).
	var keys := TitleScreen.HITS.keys()
	var clash := false
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			if (TitleScreen.HITS[keys[i]] as Rect2).intersects(TitleScreen.HITS[keys[j]]):
				clash = true
				print("    overlap: %s & %s" % [keys[i], keys[j]])
	ok = _assert(not clash, "hit rects do not overlap") and ok

	# A tap in the empty top-left (logo area) resolves to nothing.
	ok = _assert(scr._hit(Vector2(120, 40)) == "", "logo area is not a hit") and ok

	# action_selected fires for a press+release on the same button.
	var got: Array = []
	scr.action_selected.connect(func(a: String) -> void: got.append(a))
	var dr: Rect2 = TitleScreen.HITS["database"]
	var dc := dr.position + dr.size * 0.5
	scr._on_input(_touch(dc, true))
	scr._on_input(_touch(dc, false))
	ok = _assert(got == ["database"], "press+release emits action (%s)" % str(got)) and ok

	# A press on one button released on another emits nothing.
	got.clear()
	scr._on_input(_touch(dc, true))
	scr._on_input(_touch(Vector2(120, 40), false))
	ok = _assert(got.is_empty(), "drag-off cancels (%s)" % str(got)) and ok

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
