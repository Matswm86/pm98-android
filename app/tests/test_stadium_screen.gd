extends SceneTree
## Headless wiring test for the GROUND (ESTADIO) screen: confirms the reversed capacity
## -> tier formula matches MANAGER.EXE breakpoints, the int formatter is correct, every
## cracked asset loads (FONDO + BARRA + all 12 ESTADIO tiers + 3 button icons + PROMAN
## fonts), the reversed rects stay inside the 640x480 canvas, and setup() wires data +
## loads the matching tier scene.
##   ~/godot462 --headless --path app --script res://tests/test_stadium_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Reversed tier formula: tier = clamp(capacity*11/130000, 0, 11). Breakpoints from
	# the magic-division at FUN_0051a6e0 @0x51a728 (130000/11 ~= 11818 per tier).
	ok = _assert(StadiumScreen.tier_for(0) == 0, "tier(0)=0") and ok
	ok = _assert(StadiumScreen.tier_for(11818) == 0, "tier(11818)=0") and ok
	ok = _assert(StadiumScreen.tier_for(11819) == 1, "tier(11819)=1") and ok
	ok = _assert(StadiumScreen.tier_for(23637) == 2, "tier(23637)=2") and ok
	ok = _assert(StadiumScreen.tier_for(118182) == 10, "tier(118182)=10") and ok
	ok = _assert(StadiumScreen.tier_for(130000) == 11, "tier(130000)=11") and ok
	ok = _assert(StadiumScreen.tier_for(500000) == 11, "tier clamps high") and ok
	ok = _assert(StadiumScreen.tier_for(-50) == 0, "tier clamps low") and ok

	# Int formatter.
	ok = _assert(StadiumScreen.fmt_int(24500) == "24,500", "fmt_int thousands") and ok
	ok = _assert(StadiumScreen.fmt_int(0) == "0", "fmt_int zero") and ok
	ok = _assert(StadiumScreen.fmt_int(900) == "900", "fmt_int small") and ok

	# Every cracked asset must exist + load.
	var assets := ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
		"res://art/screens/stadium/obras.png", "res://art/screens/stadium/remodela.png",
		"res://art/screens/stadium/diapartido.png",
		"res://art/fonts/proman14.fnt", "res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]
	for t in range(12):
		assets.append("res://art/screens/stadium/estadio%d.png" % t)
	for path in assets:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Reversed rects must stay inside the native 640x480 canvas.
	var rects := {
		"PANEL_INFO": StadiumScreen.PANEL_INFO, "LBL_IMPROVE": StadiumScreen.LBL_IMPROVE,
		"LBL_WORKS": StadiumScreen.LBL_WORKS, "LBL_MATCHDAY": StadiumScreen.LBL_MATCHDAY,
		"LBL_RETURN": StadiumScreen.LBL_RETURN,
	}
	for name in rects:
		var r: Rect2 = rects[name]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % name) and ok

	# Instantiate + feed the screen.
	var screen: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded") and ok
	ok = _assert(screen._bg != null and screen._bar != null, "FONDO + BARRA loaded") and ok
	ok = _assert(screen._ic_works != null and screen._ic_improve != null and screen._ic_match != null,
		"button icons loaded") and ok

	# setup() wires data, clamps negatives, and selects the matching tier scene.
	screen.setup("Arsenal", "", "1997-98", "Highbury", 24500, 18000, -5, 900)
	await process_frame
	ok = _assert(screen._capacity == 24500, "capacity wired") and ok
	ok = _assert(screen._ground == "Highbury", "ground wired") and ok
	ok = _assert(screen._standing == 0, "negative standing clamped") and ok
	ok = _assert(screen._tier == 2, "tier resolved from capacity") and ok
	ok = _assert(screen._scene != null, "tier scene loaded") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
