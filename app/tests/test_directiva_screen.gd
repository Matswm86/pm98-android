extends SceneTree
## Headless wiring test for the frame-baked BOARD OF DIRECTORS (DIRECTIVA) screen: confirms
## the baked body chrome + PROMAN fonts load, the money formatter is correct, the confidence
## values clamp to 0..100, the live-draw geometry (name box, RETURN hit rect, the three meter
## descriptors) stays inside the 640x480 canvas, and setup() wires data.
##   ~/godot462 --headless --path app --script res://tests/test_directiva_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Static helpers (pure).
	ok = _assert(DirectivaScreen.fmt_money(4250000) == "£4,250,000", "fmt_money positive") and ok
	ok = _assert(DirectivaScreen.fmt_money(0) == "£0", "fmt_money zero") and ok
	ok = _assert(DirectivaScreen.fmt_money(-500) == "-£500", "fmt_money negative") and ok

	# Frame-baked chrome + fonts present and loadable.
	for path in ["res://art/screens/directiva/body.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# The body PNG is the frame cropped from y=44, so it must be 640x436.
	var body: Texture2D = load("res://art/screens/directiva/body.png")
	ok = _assert(body.get_width() == 640 and body.get_height() == 480 - int(DirectivaScreen.BODY_Y),
		"body.png is 640x436") and ok

	# MANAGER name box + RETURN hit rect stay inside the canvas.
	for entry in [["MGR_BOX", DirectivaScreen.MGR_BOX], ["BTN_RETURN", DirectivaScreen.BTN_RETURN]]:
		var r: Rect2 = entry[1]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % entry[0]) and ok

	# Meter descriptors: block strips + value-tab digit centres stay in canvas, block palette
	# covers the widest meter.
	for entry in [["M_RATING", DirectivaScreen.M_RATING], ["M_DIRECTORS", DirectivaScreen.M_DIRECTORS],
			["M_SUPPORTERS", DirectivaScreen.M_SUPPORTERS]]:
		var m: Dictionary = entry[1]
		var last_x: float = float(m["bx"]) + (int(m["maxb"]) - 1) * DirectivaScreen.BLOCK_PITCH + DirectivaScreen.BLOCK_W
		ok = _assert(last_x <= 640 and float(m["dx"]) <= 640 and float(m["dy"]) <= 480,
			"meter in canvas: %s" % entry[0]) and ok
		ok = _assert(int(m["maxb"]) <= DirectivaScreen.BLOCK_COLS.size(),
			"meter maxb <= palette: %s" % entry[0]) and ok

	# Instantiate + feed the screen.
	var screen: DirectivaScreen = load("res://scenes/DirectivaScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(screen._body != null, "baked body chrome loaded") and ok

	# Values clamp to 0..100, data wires through.
	screen.setup("Manchester Utd.", "MWM", "1997-98", 4_250_000, 150, -20, 71,
		"", "0-0-0", "1st")
	await process_frame
	ok = _assert(screen._directors == 100, "directors clamped high") and ok
	ok = _assert(screen._supporters == 0, "supporters clamped low") and ok
	ok = _assert(screen._rating == 71, "rating passed through") and ok
	ok = _assert(screen._manager == "MWM", "manager wired") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
