extends SceneTree
## Headless test for T2 #6 — board price controls. Asserts the FinanceModel demand
## response (ticket price <-> attendance, board price <-> boards sold), backward
## compatibility (no override == old figures), the Career price setters + preview + save
## round-trip, and the FinanceScreen SET PRICES hit-testing.
##   ~/godot462 --headless --path app --script res://tests/test_finance_control.gd


func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var ok := true
	var club := {"capacity": 40000}   # tier-1 club, no price override

	# Backward compatibility: no override reproduces the old attendance (cap * fill).
	var base := FinanceModel.summary(club, 1)
	ok = _assert(int(base["attendance"]) == int(round(40000 * 0.85)),
		"default attendance unchanged (%d)" % int(base["attendance"])) and ok

	# Ticket price <-> attendance (dearer thins the crowd; cheaper fills it, capped at cap).
	var dear := FinanceModel.summary({"capacity": 40000, "ticket_price": 30}, 1)
	var cheap := FinanceModel.summary({"capacity": 40000, "ticket_price": 8}, 1)
	ok = _assert(int(dear["attendance"]) < int(base["attendance"]),
		"dearer ticket thins the crowd (%d < %d)" % [int(dear["attendance"]), int(base["attendance"])]) and ok
	ok = _assert(int(cheap["attendance"]) > int(base["attendance"])
		and int(cheap["attendance"]) <= 40000, "cheaper ticket fills it, capped at capacity (%d)"
		% int(cheap["attendance"])) and ok

	# Board price: income is a parabola peaking ~1.5x default. £1800 (1.5x £1200) beats the
	# default; £3600 (3x, past the peak, demand collapsed) earns less than at the peak.
	var b_base := _line(base, "SPONSOR BOARDS SOLD")
	var b_opt := _line(FinanceModel.summary({"capacity": 40000, "board_price": 1800}, 1), "SPONSOR BOARDS SOLD")
	var b_over := _line(FinanceModel.summary({"capacity": 40000, "board_price": 3600}, 1), "SPONSOR BOARDS SOLD")
	ok = _assert(b_opt > b_base and b_opt > b_over,
		"board income peaks at a mid price (base %d, peak %d, over %d)" % [b_base, b_opt, b_over]) and ok

	# Career price setters + live preview + weekly_net refresh.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var prem: Array = []
	var league: Dictionary = {}
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, db.get("leagues", []))
	ok = _assert(career.ticket_price > 0 and career.board_price > 0,
		"career seeded default prices (£%d / £%d)" % [career.ticket_price, career.board_price]) and ok

	var net0: int = career.weekly_net
	career.set_ticket_price(35)   # well above the £15 default -> thinner crowd, different net
	ok = _assert(career.ticket_price == 35 and career.weekly_net != net0,
		"set_ticket_price applied + refreshed weekly_net") and ok
	var pv := career.finance_preview()
	ok = _assert(int(pv["ticket"]) == 35 and int(pv["attendance"]) <= int(pv["capacity"]),
		"preview reflects the new price (att %d / cap %d)" % [int(pv["attendance"]), int(pv["capacity"])]) and ok

	career.set_board_price(2400)
	var path := "user://finance_control_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.ticket_price == 35 and loaded.board_price == 2400,
		"prices survived save/load") and ok

	# FinanceScreen SET PRICES hit-testing.
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 2:
		await process_frame
	scr.setup(base, "ARSENAL", "", "1997-98")
	var got: Array = []
	scr.prices_pressed.connect(func() -> void: got.append("prices"))
	scr.back_pressed.connect(func() -> void: got.append("back"))
	scr._on_input(_touch(_design_to_local(scr, FinanceScreen.BTN_PRICES.get_center()), true))
	scr._on_input(_touch(_design_to_local(scr, FinanceScreen.BTN_PRICES.get_center()), false))
	ok = _assert(got == ["prices"], "SET PRICES button emits prices_pressed (%s)" % str(got)) and ok
	scr.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _line(summary: Dictionary, label: String) -> int:
	for ln in summary.get("income_lines", []):
		if ln[0] == label:
			return int(ln[1])
	return 0


## Map a 640x480 design point to the node's local space (scr.size == 640x480 here, so 1:1).
func _design_to_local(scr: Control, d: Vector2) -> Vector2:
	var s: float = min(scr.size.x / 640.0, scr.size.y / 480.0)
	return d * s + Vector2((scr.size.x - 640.0 * s) * 0.5, (scr.size.y - 480.0 * s) * 0.5)


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
