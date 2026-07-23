extends SceneTree
## Headless wiring test for the TEAMS IN CHAMPIONSHIPS screen (ChampsScreen.gd): confirms
## the frame-baked chrome + PROMAN10 font load, BTN_CONTINUE and every PANELS layout
## position stay inside the 640x480 canvas, setup() wires the entries Dictionary through
## unmodified, and CONTINUE hit-tests correctly (center hits, an empty point does not).
##   timeout 150 /home/mats/godot4 --headless --path app --script res://tests/test_champs_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# BTN_CONTINUE stays inside the 640x480 canvas.
	ok = _assert(ChampsScreen.BTN_CONTINUE.position.x >= 0 and ChampsScreen.BTN_CONTINUE.position.y >= 0
			and ChampsScreen.BTN_CONTINUE.end.x <= 640 and ChampsScreen.BTN_CONTINUE.end.y <= 480,
		"BTN_CONTINUE in canvas") and ok

	# Every PANELS entry's [key, club_x, mgr_x, [baselines]] stays inside the canvas. PANELS
	# carries text-draw x/y positions only (no width/height), so the real invariant is the
	# x columns and every row baseline landing in-bounds -- not a fabricated Rect2.
	for p in ChampsScreen.PANELS:
		var key: String = p[0]
		var club_x: int = p[1]
		var mgr_x: int = p[2]
		var bases: Array = p[3]
		ok = _assert(club_x >= 0 and club_x <= 640 and mgr_x >= 0 and mgr_x <= 640,
			"panel columns in canvas: %s" % key) and ok
		for b in bases:
			ok = _assert(int(b) >= 0 and int(b) <= 480, "panel baseline in canvas: %s @%s" % [key, b]) and ok

	# Frame-baked chrome + PROMAN10 font present and loadable.
	for path in ["res://art/screens/seasonflow/champs.png", "res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Instantiate + feed the screen.
	var screen: ChampsScreen = load("res://scenes/ChampsScreen.gd").new()
	get_root().add_child(screen)
	screen.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f10 != null, "PROMAN10 font loaded") and ok
	ok = _assert(screen._chrome != null, "baked champs chrome loaded") and ok

	# setup() wires entries straight into _entries (the six competition keys from PANELS,
	# each an Array of [club_name, manager_name]; manager "" is the honest-blank case per
	# the setup() doc comment).
	var entries := {
		"european_cup": [["Manchester Utd.", "MWM"], ["Real Madrid", "Capello"]],
		"uefa_cup": [["Newcastle", "Dalglish"], ["Barcelona", ""], ["Juventus", "Lippi"], ["PSV", "Advocaat"]],
		"cup_winners_cup": [["Chelsea", "Vialli"]],
		"charity_shield": [["Manchester Utd.", "MWM"], ["Chelsea", "Vialli"]],
		"supercup": [["Real Madrid", "Capello"], ["Barcelona", ""]],
		"intercontinental": [["Manchester Utd.", "MWM"], ["Vasco da Gama", "Rivellino"]],
	}
	screen.setup(entries)
	await process_frame
	ok = _assert(screen._entries == entries, "setup() wires entries unmodified") and ok

	# CONTINUE hit-test: center resolves to continue_pressed, an empty point does not.
	var cont: Array = []
	screen.continue_pressed.connect(func() -> void: cont.append(true))
	screen._on_input(_touch(ChampsScreen.BTN_CONTINUE.get_center(), true))
	screen._on_input(_touch(ChampsScreen.BTN_CONTINUE.get_center(), false))
	ok = _assert(cont.size() == 1, "BTN_CONTINUE center emits continue_pressed") and ok
	screen._on_input(_touch(Vector2(10, 10), true))
	screen._on_input(_touch(Vector2(10, 10), false))
	ok = _assert(cont.size() == 1, "empty point does not emit continue_pressed") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
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
