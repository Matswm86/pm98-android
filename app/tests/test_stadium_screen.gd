extends SceneTree
## Headless wiring test for the GROUND (ESTADIO) screen: confirms the reversed capacity
## -> tier formula matches MANAGER.EXE breakpoints, the int formatter is correct, every
## asset loads (management bg + frame-baked chrome.png + all 12 ESTADIO tiers + PROMAN
## fonts), the reversed action-grid rects stay inside the 640x480 canvas, setup() wires
## data + loads the matching tier scene, and the action grid hit-tests (WORKS/IMPROVE ->
## expansion lever, RETURN -> back, MATCH DAY + empty space inert).
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

	# Every cracked asset must exist + load: the frame-baked body chrome, the shared
	# management background, the PROMAN fonts the value/name text uses, all 12 tiers.
	var assets := ["res://art/screens/management_bg.png",
		"res://art/screens/stadium/chrome.png",
		"res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt"]
	for t in range(12):
		assets.append("res://art/screens/stadium/estadio%d.png" % t)
	for path in assets:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Action-grid rects must stay inside the native 640x480 canvas.
	var rects := {
		"BTN_IMPROVE": StadiumScreen.BTN_IMPROVE,
		"BTN_WORKS": StadiumScreen.BTN_WORKS, "BTN_MATCHDAY": StadiumScreen.BTN_MATCHDAY,
		"BTN_RETURN": StadiumScreen.BTN_RETURN,
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
	ok = _assert(screen._f12 != null and screen._f10 != null, "PROMAN fonts loaded") and ok
	ok = _assert(screen._chrome != null, "frame-baked GROUND chrome loaded") and ok
	ok = _assert(PMChrome.bg() != null, "PMChrome management background loads") and ok

	# setup() wires data, clamps negatives, and selects the matching tier scene. The invented
	# seated/standing/parking/ticket/board args are accepted (Main compat) but ignored.
	screen.setup("Arsenal", "", "1997-98", "Highbury", 24500, 18000, -5, 900)
	await process_frame
	ok = _assert(screen._capacity == 24500, "capacity wired") and ok
	ok = _assert(screen._ground == "Highbury", "ground wired") and ok
	ok = _assert(screen._tier == 2, "tier resolved from capacity") and ok
	ok = _assert(screen._scene != null, "tier scene loaded") and ok

	# Action grid: WORKS + IMPROVE both reach the expansion lever, RETURN leaves, MATCH DAY
	# and empty space are no-ops (they no longer bounce to the hub).
	ok = _assert(screen._hit(StadiumScreen.BTN_WORKS.get_center()) == "works", "WORKS hit-tests") and ok
	ok = _assert(screen._hit(StadiumScreen.BTN_IMPROVE.get_center()) == "improve", "IMPROVE hit-tests") and ok
	ok = _assert(screen._hit(StadiumScreen.BTN_RETURN.get_center()) == "return", "RETURN hit-tests") and ok
	ok = _assert(screen._hit(StadiumScreen.BTN_MATCHDAY.get_center()) == "", "MATCH DAY is inert") and ok
	ok = _assert(screen._hit(StadiumScreen.SCENE_BOX.get_center()) == "", "empty-space tap is a no-op") and ok

	# In the WORK-IN-PROGRESS view the offer cards are NOT live (only the action grid is).
	ok = _assert(screen._hit(StadiumScreen.CARDS[0].get_center()) == "", "cards inert in works view") and ok

	# IMPROVE view: cards + SEATS tab become live; the 3 fixed seat offers are game constants.
	screen.open_improve()
	ok = _assert(screen._view == "improve", "IMPROVE opens the picker in-screen") and ok
	ok = _assert(screen._hit(StadiumScreen.CARDS[0].get_center()) == "card0", "card 0 hit-tests in improve view") and ok
	ok = _assert(screen._hit(StadiumScreen.CARDS[2].get_center()) == "card2", "card 2 hit-tests in improve view") and ok
	ok = _assert(screen._hit(StadiumScreen.TAB_SEATS.get_center()) == "tab_seats", "SEATS tab hit-tests") and ok
	ok = _assert(StadiumScreen.OFFER_SEATS == [4000, 8000, 12000], "witnessed seat increments") and ok
	ok = _assert(StadiumScreen.OFFER_WEEKS == [20, 35, 50], "witnessed build weeks") and ok

	# Un-witnessed club (Arsenal) => no price => honest gap => a card tick can NOT purchase.
	var picked := [false]
	screen.improve_selected.connect(func(_a: int, _c: int, _w: int) -> void: picked[0] = true)
	screen._select_card(0)
	ok = _assert(not picked[0], "no objective label: SEATS card is an honest gap (no purchase)") and ok

	# Tiered prices (wine campaign 2026-07-19): the objective label picks the
	# witnessed price row — Avoid Relegation == the Bolton parity/21 numbers.
	screen.setup("Bolton W", "", "1997-98", "Reebok", 20500, 0, 0, 0, "",
		0, 0, 0, "", "Avoid Relegation")
	screen.open_improve()
	var got := [[]]
	screen.improve_selected.connect(func(a: int, c: int, w: int) -> void: got[0] = [a, c, w])
	screen._select_card(1)
	ok = _assert(got[0] == [8000, 4812499, 35], "Avoid Relegation tick emits the witnessed SEATS offer") and ok
	# All four witnessed tiers resolve to their frame prices.
	screen._objective = "Champion"
	ok = _assert(screen._prices() == [4250000, 7437500, 10624999], "Champion tier = Arsenal/ManU frames") and ok
	screen._objective = "U.E.F.A."
	ok = _assert(screen._prices() == [3750000, 6562499, 9375000], "U.E.F.A. tier = Villa s24") and ok
	screen._objective = "Mid Table"
	ok = _assert(screen._prices() == [3250000, 5687500, 8124999], "Mid Table tier = Wimbledon s28") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
