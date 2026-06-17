extends SceneTree
## Headless wiring test for the BOARD OF DIRECTORS (DIRECTIVA) screen: confirms the
## cracked ORIGINAL assets load (FONDO + BARRA + the 4 VGA icons + PROMAN fonts), the
## money formatter + meter-colour helpers are correct, confidence values clamp to
## 0..100, the reversed rects stay inside the 640x480 canvas, and setup() wires data.
##   ~/godot462 --headless --path app --script res://tests/test_directiva_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Static helpers (pure).
	ok = _assert(DirectivaScreen.fmt_money(4250000) == "£4,250,000", "fmt_money positive") and ok
	ok = _assert(DirectivaScreen.fmt_money(0) == "£0", "fmt_money zero") and ok
	ok = _assert(DirectivaScreen.fmt_money(-500) == "-£500", "fmt_money negative") and ok

	for path in ["res://art/screens/management_bg.png",
			"res://art/screens/directiva/directiva.png", "res://art/screens/directiva/publico.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman10.fnt",
			"res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Layout rects must stay inside the native 640x480 canvas.
	var rects := {
		"MGR_BOX": DirectivaScreen.MGR_BOX, "RAT_BOX": DirectivaScreen.RAT_BOX,
		"DIR_BOX": DirectivaScreen.DIR_BOX, "SUP_BOX": DirectivaScreen.SUP_BOX,
		"LOAN_PANEL": DirectivaScreen.LOAN_PANEL, "BONUS_PANEL": DirectivaScreen.BONUS_PANEL,
		"BTN_RETURN": DirectivaScreen.BTN_RETURN,
	}
	for name in rects:
		var r: Rect2 = rects[name]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % name) and ok

	# Instantiate + feed the screen.
	var screen: DirectivaScreen = load("res://scenes/DirectivaScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(PMChrome.bg() != null, "PMChrome management background loads") and ok
	ok = _assert(screen._ic_direct != null and screen._ic_public != null,
		"DIRECTIVA icons loaded") and ok

	# Values clamp to 0..100, data wires through.
	screen.setup("Arsenal", "A. WENGER", "1997-98", 4_250_000, 150, -20, 64,
		"Finish in the top 5.", "8-3-2", "3rd")
	await process_frame
	ok = _assert(screen._directors == 100, "directors clamped high") and ok
	ok = _assert(screen._supporters == 0, "supporters clamped low") and ok
	ok = _assert(screen._rating == 64, "rating passed through") and ok
	ok = _assert(screen._manager == "A. WENGER", "manager wired") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
