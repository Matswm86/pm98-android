extends SceneTree
## Headless assert test for the FICHA RENEW OFFER form (PlayerInfoScreen renew mode) — the
## source negotiation witnessed live at TOTAL level (docs/re/renew_negotiation_re.md, frame
## 25_renew). Proves: the baked overlay + checkbox textures load; every OFFER-panel geometry
## const stays in the 640x480 canvas; begin_renew seeds the offer at his current terms; the
## ◄/► steppers move wage/years within bounds; OFFER emits offer_made(weekly, years) and CANCEL
## emits renew_cancelled; end_renew leaves renew mode. The OFFER-chrome pixel placement is
## separately verified 0px vs frame 25 (renew_negotiation_re.md "BUILT" note).
##   ~/godot4 --headless --path app --script res://tests/test_player_info_renew.gd


func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var ok := true

	# Assets baked for the OFFER panel are present and load.
	for path in ["res://art/screens/ficha/renew_overlay.png",
			"res://art/screens/ficha/renew_check_on.png",
			"res://art/screens/ficha/renew_check_off.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Every OFFER-panel geometry const stays inside the canvas.
	var rects := {
		"OFF_CANCEL": PlayerInfoScreen.OFF_CANCEL, "OFF_OFFER": PlayerInfoScreen.OFF_OFFER,
		"OFF_WAGE_DN": PlayerInfoScreen.OFF_WAGE_DN, "OFF_WAGE_UP": PlayerInfoScreen.OFF_WAGE_UP,
		"OFF_YEARS_DN": PlayerInfoScreen.OFF_YEARS_DN, "OFF_YEARS_UP": PlayerInfoScreen.OFF_YEARS_UP,
	}
	for k in rects:
		var r: Rect2 = rects[k]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % k) and ok
	# Overlay draw pos + clause box rows land in the top-half OFFER zone.
	ok = _assert(PlayerInfoScreen.RENEW_OVERLAY_XY.x >= 76 and PlayerInfoScreen.RENEW_OVERLAY_XY.y >= 58,
		"overlay pos inside the card") and ok
	for by in PlayerInfoScreen.OFF_CB_YS:
		ok = _assert(int(by) >= 58 and int(by) + 11 <= 260, "clause box row in OFFER zone: %d" % by) and ok

	# Mount + enter renew mode.
	var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	for _i in 3:
		await process_frame
	ok = _assert(scr._renew_overlay != null and scr._check_on != null and scr._check_off != null,
		"renew textures loaded on the screen") and ok

	var player := {"id": 42, "name": "Tester", "pos": "MF", "contract_term": 2, "contract_years": 2,
		"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70}, "clauses": [0]}
	scr.setup(player, {"id": 40, "name": "Club", "players": []}, 1, true, false)
	await process_frame

	var cur := 5000
	var demand := 6000
	scr.begin_renew(cur, demand, 2)
	await process_frame
	ok = _assert(scr._renew, "begin_renew entered renew mode") and ok
	ok = _assert(scr._offer_weekly == cur and scr._offer_years == 2, "offer seeded at current terms") and ok

	# _hit resolves the OFFER-form controls at their rect centres; empty space -> "".
	ok = _assert(scr._hit(PlayerInfoScreen.OFF_WAGE_UP.get_center()) == "wage_up", "hit wage_up") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OFF_WAGE_DN.get_center()) == "wage_dn", "hit wage_dn") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OFF_YEARS_UP.get_center()) == "years_up", "hit years_up") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OFF_OFFER.get_center()) == "offer", "hit offer") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OFF_CANCEL.get_center()) == "cancel", "hit cancel") and ok
	ok = _assert(scr._hit(Vector2(320, 60)) == "", "empty space inert") and ok

	# Steppers: a press fires the step immediately (repeatable).
	_press(scr, PlayerInfoScreen.OFF_WAGE_UP.get_center())
	ok = _assert(scr._offer_weekly == cur + PlayerInfoScreen.OFF_WAGE_STEP_WK, "wage_up steps up") and ok
	_press(scr, PlayerInfoScreen.OFF_WAGE_DN.get_center())
	_press(scr, PlayerInfoScreen.OFF_WAGE_DN.get_center())
	ok = _assert(scr._offer_weekly == cur, "wage_dn floors at current wage") and ok
	_press(scr, PlayerInfoScreen.OFF_YEARS_UP.get_center())
	ok = _assert(scr._offer_years == 3, "years_up steps up") and ok
	for _k in 10:
		_press(scr, PlayerInfoScreen.OFF_YEARS_UP.get_center())
	ok = _assert(scr._offer_years == PlayerInfoScreen.OFF_YEARS_MAX, "years_up capped at max") and ok

	# OFFER: a full press+release emits offer_made with the offered figures.
	var made := [false, 0, 0]
	scr.offer_made.connect(func(w: int, y: int) -> void:
		made[0] = true; made[1] = w; made[2] = y)
	_click(scr, PlayerInfoScreen.OFF_OFFER.get_center())
	ok = _assert(made[0] and made[1] == scr._offer_weekly and made[2] == scr._offer_years,
		"OFFER emits offer_made(weekly, years)") and ok

	# CANCEL: emits renew_cancelled.
	scr.begin_renew(cur, demand, 2)
	var cancelled := [false]
	scr.renew_cancelled.connect(func() -> void: cancelled[0] = true)
	_click(scr, PlayerInfoScreen.OFF_CANCEL.get_center())
	ok = _assert(cancelled[0], "CANCEL emits renew_cancelled") and ok

	scr.end_renew()
	ok = _assert(not scr._renew, "end_renew leaves renew mode") and ok

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _press(scr: PlayerInfoScreen, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	scr._on_input(e)


func _click(scr: PlayerInfoScreen, at: Vector2) -> void:
	_press(scr, at)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = at
	scr._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
