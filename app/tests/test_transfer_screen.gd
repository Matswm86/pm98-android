extends SceneTree
## Headless wiring test for the FRAME-TRUE TRANSFER MARKET (FICHAR) screen (rebuilt
## from screenshots/original-walkthrough-2026-07-02/097_164707.png). Confirms the baked
## chrome + [+] sprite + PROMAN8/10/12 fonts load, that a real TransferMarket.market()
## feeds the screen, the money formatter is correct, the four SINGULAR position bands
## KEEPER/DEFENDER/MIDFIELDER/FORWARD split the rows under their fixed [3,5,5,5] slot
## caps (DAT_0065c020, dearest first), and the nav-button / row hit-testing emits the
## right signals. The rebuilt screen has NO scrolling list (the 18-slot grid always fits
## the panel, frame 097) — the old ARROW-scroll test is gone with the invented model.
##   ~/godot462 --headless --path app --script res://tests/test_transfer_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Money formatter (static, pure).
	ok = _assert(TransferScreen.fmt_money(11900000) == "£11,900,000", "fmt_money positive") and ok
	ok = _assert(TransferScreen.fmt_money(0) == "£0", "fmt_money zero") and ok
	ok = _assert(TransferScreen.fmt_money(25000) == "£25,000", "fmt_money thousands") and ok
	ok = _assert(TransferScreen.fmt_money(999) == "£999", "fmt_money sub-thousand") and ok

	# The screen's real assets: the frame-baked chrome + [+] sprite + PROMAN fonts.
	for path in ["res://art/screens/transfer/chrome.png",
			"res://art/screens/transfer/plus.png",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt",
			"res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Build a real cross-club market from the bundled database (dearest first).
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var rosters: Dictionary = {}
	var names: Dictionary = {}
	var my_id := -1
	for c in db.get("clubs", []):
		if c.get("leagueId") != "eng_prem":
			continue
		var cid := int(c.get("id", -1))
		rosters[cid] = c.get("players", [])
		names[cid] = c.get("name", "?")
		if my_id < 0 and (c.get("players", []) as Array).size() >= 14:
			my_id = cid
	ok = _assert(my_id >= 0, "found a Premier club to exclude") and ok
	var market := TransferMarket.market(rosters, names, 1, my_id)
	ok = _assert(market.size() > 20, "market has buyable players (%d)" % market.size()) and ok

	# Row shape + dearest-first ordering.
	var row0: Dictionary = market[0]
	for key in ["pid", "name", "isGK", "pos", "ca", "fee", "wage", "club_name", "key"]:
		ok = _assert(row0.has(key), "market row has '%s'" % key) and ok
	var sorted_ok := true
	var prev := 1 << 60
	for r in market:
		sorted_ok = sorted_ok and int(r["fee"]) <= prev
		prev = int(r["fee"])
	ok = _assert(sorted_ok, "market sorted by fee descending") and ok
	# The excluded club appears nowhere in the buyable market.
	var mine_leaked := false
	for r in market:
		mine_leaked = mine_leaked or int(r["club_id"]) == my_id
	ok = _assert(not mine_leaked, "own club not in the buyable market") and ok

	# Instantiate + feed the screen.
	var screen: TransferScreen = load("res://scenes/TransferScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._chrome != null, "frame-baked chrome texture loaded") and ok
	ok = _assert(screen._plus != null, "[+] expand-box sprite loaded") and ok
	screen.setup(market, names[my_id], "A. FERGUSON", "1997-98", 8_000_000, "OPEN", 3, 1)
	await process_frame
	ok = _assert(screen._rows.size() == market.size(), "screen received the market") and ok

	# Bands: the original's 4 SINGULAR position bands KEEPER/DEFENDER/MIDFIELDER/FORWARD
	# (frame 097), each capped to its [3,5,5,5] slot count, each holding only rows of that
	# decoded position, in dearest-first (fee desc) order because the input is fee-sorted.
	var secs: Array = screen._sections()
	var band_labels := ["KEEPER", "DEFENDER", "MIDFIELDER", "FORWARD"]
	ok = _assert(secs.size() == 4, "four position bands (got %d)" % secs.size()) and ok
	var order_ok := true
	for i in mini(secs.size(), band_labels.size()):
		order_ok = order_ok and str(secs[i]["section"]) == band_labels[i]
	ok = _assert(order_ok, "bands in frame order KEEPER/DEFENDER/MIDFIELDER/FORWARD") and ok
	var caps_ok := true
	var pos_ok := true
	var feeorder_ok := true
	var pos_of := {"KEEPER": "GK", "DEFENDER": "DF", "MIDFIELDER": "MF", "FORWARD": "FW"}
	for sec in secs:
		var want: String = pos_of.get(str(sec["section"]), "")
		var players: Array = sec["players"]
		caps_ok = caps_ok and players.size() <= int(TransferScreen.BAND_CAPS[want])
		var pf := 1 << 60
		for r in players:
			pos_ok = pos_ok and (str(r.get("pos")) == want or (want == "GK" and bool(r.get("isGK"))))
			feeorder_ok = feeorder_ok and int(r.get("fee")) <= pf
			pf = int(r.get("fee"))
	ok = _assert(caps_ok, "each band within its [3,5,5,5] slot cap") and ok
	ok = _assert(pos_ok, "each band holds only its own decoded position") and ok
	ok = _assert(feeorder_ok, "each band is dearest-first within the slots") and ok

	# ---- deterministic hit-testing (native 640x480 so design maps 1:1) ---------
	screen.size = Vector2(640, 480)
	# A synthetic fee-desc market: a known GK lands in KEEPER slot 0, a 6th DF overflows
	# the 5-slot cap, and a positionless outfielder is skipped (never fabricated).
	var syn: Array = [
		_row(1, "ALPHA", "FW", false, 90, 9_000_000),
		_row(2, "BRAVO", "MF", false, 88, 8_000_000),
		_row(3, "CHARLIE", "DF", false, 86, 7_000_000),
		_row(4, "DELTA", "GK", true, 85, 6_000_000),   # dearest keeper -> KEEPER slot 0
		_row(5, "ECHO", "GK", true, 80, 5_000_000),
		_row(6, "FOXTROT", "DF", false, 79, 4_500_000),
		_row(7, "GOLF", "DF", false, 78, 4_000_000),
		_row(8, "HOTEL", "DF", false, 77, 3_500_000),
		_row(9, "INDIA", "DF", false, 76, 3_000_000),
		_row(10, "JULIET", "DF", false, 75, 2_500_000),  # 6th DF -> dropped past cap 5
		_row(11, "NOPOS", "", false, 60, 2_000_000),     # positionless outfielder -> skipped
	]
	screen.setup(syn, "ME", "MGR", "1997-98", 5_000_000, "OPEN", 3, 1)
	var s2: Array = screen._sections()
	ok = _assert((s2[0]["players"] as Array).size() == 2, "KEEPER band = 2 GK") and ok
	ok = _assert((s2[1]["players"] as Array).size() == 5, "DEFENDER band clamped to 5 of 6") and ok
	var no_nopos := true
	for sec in s2:
		for r in sec["players"]:
			no_nopos = no_nopos and int(r.get("pid")) != 11
	ok = _assert(no_nopos, "positionless outfielder is skipped, not fabricated into a band") and ok

	# _hit returns a Dictionary (the rebuilt model, not the old String scroll verb).
	var h_ret := screen._hit(TransferScreen.BTN_RETURN.get_center())
	ok = _assert(h_ret is Dictionary and str(h_ret.get("a")) == "return", "RETURN hit-tests") and ok
	ok = _assert(str(screen._hit(TransferScreen.BTN_CURRENT.get_center()).get("a")) == "current",
		"CURRENT OFFERS hit-tests") and ok
	ok = _assert(str(screen._hit(TransferScreen.BTN_SCOUT.get_center()).get("a")) == "scout",
		"SCOUT hit-tests") and ok
	ok = _assert(str(screen._hit(TransferScreen.BTN_OFFERS.get_center()).get("a")) == "offers",
		"OFFERS hit-tests") and ok
	var row_pt := Vector2(120, TransferScreen.BANDS[0]["slot_y"][0] + 4)  # KEEPER slot 0
	var h_row := screen._hit(row_pt)
	ok = _assert(str(h_row.get("a")) == "row" and int((h_row.get("row") as Dictionary).get("pid")) == 4,
		"row hit-test resolves the dearest keeper (DELTA)") and ok
	ok = _assert(str(screen._hit(Vector2(200, 128)).get("a")) == "", "empty slot is no hit") and ok

	# Signals: RETURN -> back_pressed; CURRENT -> current_offers_pressed; row -> player_pressed;
	# SCOUT / OFFERS are sourced but unwired (no-op); an empty tap emits nothing.
	var got := {"back": false, "current": false, "row_pid": -1, "any_scout": false}
	screen.back_pressed.connect(func() -> void: got["back"] = true)
	screen.current_offers_pressed.connect(func() -> void: got["current"] = true)
	screen.player_pressed.connect(func(r: Dictionary) -> void: got["row_pid"] = int(r.get("pid", -1)))

	_tap(screen, TransferScreen.BTN_RETURN.get_center())
	ok = _assert(got["back"], "RETURN emits back_pressed") and ok
	_tap(screen, TransferScreen.BTN_CURRENT.get_center())
	ok = _assert(got["current"], "CURRENT OFFERS emits current_offers_pressed") and ok
	_tap(screen, row_pt)
	ok = _assert(got["row_pid"] == 4, "a row tap emits player_pressed with that row") and ok
	# SCOUT / OFFERS taps are no-ops (not yet wired to a screen).
	got["back"] = false; got["current"] = false; got["row_pid"] = -1
	_tap(screen, TransferScreen.BTN_SCOUT.get_center())
	_tap(screen, TransferScreen.BTN_OFFERS.get_center())
	_tap(screen, Vector2(200, 128))  # empty slot
	ok = _assert(not got["back"] and not got["current"] and got["row_pid"] == -1,
		"SCOUT / OFFERS / empty taps emit nothing") and ok

	# Redraw once with the real market so the draw path is exercised headless.
	screen.setup(market, names[my_id], "A. FERGUSON", "1997-98", 8_000_000, "OPEN", 3, 1)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _row(pid: int, name: String, pos: String, is_gk: bool, ca: int, fee: int) -> Dictionary:
	return {"pid": pid, "name": name, "pos": pos, "isGK": is_gk, "ca": ca, "mo": 66,
		"age": 25, "fee": fee, "wage": int(fee / 40), "club_id": -1, "club_name": "FC", "key": false}


## Synthesize a press+release tap at a design-space point through the screen's own handler.
func _tap(screen: TransferScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	screen._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
