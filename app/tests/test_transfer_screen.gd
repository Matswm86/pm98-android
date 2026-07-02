extends SceneTree
## Headless wiring test for the TRANSFER MARKET (FICHAR) screen: confirms the cracked
## ORIGINAL assets (FONDO, BARRA, PROMAN8/10/12/14 BMFonts) load, that a real
## TransferMarket.market() feeds the screen, the money formatter is correct, and the
## screen's 4 position bands (KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS) split the rows.
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

	for path in ["res://art/screens/management_bg.png",
			"res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]:
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
	ok = _assert(PMChrome.bg() != null, "PMChrome management background loads") and ok
	screen.setup(market, names[my_id], "A. FERGUSON", "1997-98", 8_000_000, "OPEN", 3)
	await process_frame
	ok = _assert(screen._rows.size() == market.size(), "screen received the market") and ok

	# Bands: the original's 4 position bands KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS, each
	# capped to its [3,5,5,5] slot count, each holding only rows of that decoded position.
	var secs: Array = screen._sections()
	var band_labels := ["KEEPERS", "DEFENDERS", "MIDFIELDERS", "FORWARDS"]
	ok = _assert(secs.size() == 4, "four position bands (got %d)" % secs.size()) and ok
	ok = _assert(secs[0]["section"] == "KEEPERS", "first band is KEEPERS") and ok
	var labels_ok := true
	var caps_ok := true
	var pos_ok := true
	var pos_of := {"KEEPERS": "GK", "DEFENDERS": "DF", "MIDFIELDERS": "MF", "FORWARDS": "FW"}
	for sec in secs:
		var label := str(sec["section"])
		labels_ok = labels_ok and band_labels.has(label)
		var want: String = pos_of.get(label, "")
		caps_ok = caps_ok and (sec["players"] as Array).size() <= int(TransferScreen.BAND_CAPS[want])
		for r in sec["players"]:
			pos_ok = pos_ok and str(r.get("pos")) == want
	ok = _assert(labels_ok, "every band carries an original position label") and ok
	ok = _assert(caps_ok, "each band within its [3,5,5,5] slot cap") and ok
	ok = _assert(pos_ok, "each band holds only its own decoded position") and ok

	# ---- scroll wiring (the original ARROW up/down list paging) -------------
	# Native design space so hit-tests map 1:1; a forced oversized market (all 5 bands at
	# their slot cap = 23 rows + 5 headers = 28 items) overflows the 21-row panel.
	screen.size = Vector2(640, 480)
	var big: Array = []
	var pid := 1
	for pair in [["GK", 3], ["DF", 5], ["MF", 5], ["FW", 5], ["", 5]]:
		for _k in int(pair[1]):
			big.append({"id": pid, "name": "P%d" % pid, "pos": String(pair[0]),
				"isGK": pair[0] == "GK", "ca": 70, "mo": 66, "age": 25, "fee": 1_000_000,
				"wage": 20_000, "club_id": -1, "club_name": "FC"})
			pid += 1
	screen.setup(big, "ME", "MGR", "1997-98", 5_000_000, "OPEN", 3)
	ok = _assert(screen._visible_rows() == 21, "panel fits 21 rows") and ok
	ok = _assert(screen._flat_items().size() == 28, "flat list = 23 rows + 5 headers") and ok
	ok = _assert(screen._max_scroll() == 7, "max scroll = 28 - 21") and ok
	ok = _assert(screen._scroll == 0, "setup resets scroll to top") and ok
	# Clamp at both ends.
	screen._scroll = 999; screen._clamp_scroll()
	ok = _assert(screen._scroll == 7, "scroll clamps to max") and ok
	screen._scroll = -5; screen._clamp_scroll()
	ok = _assert(screen._scroll == 0, "scroll clamps to top") and ok
	# Hit-test: both arrows live while overflowing.
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "down", "down arrow hit-tests") and ok
	ok = _assert(screen._hit(SCROLL_UP_C) == "up", "up arrow hit-tests") and ok
	# A down tap pages by SCROLL_STEP and is consumed (no dismiss); an up tap pages back.
	var dismissed := [false]
	screen.back_pressed.connect(func() -> void: dismissed[0] = true)
	_tap(screen, SCROLL_DOWN_C)
	ok = _assert(screen._scroll == 3 and not dismissed[0], "down tap pages by step, consumed") and ok
	_tap(screen, SCROLL_UP_C)
	ok = _assert(screen._scroll == 0 and not dismissed[0], "up tap pages back, consumed") and ok
	# A non-arrow tap is a no-op (RETURN exits; row/empty taps no longer bounce to the hub).
	_tap(screen, Vector2(60, 200))
	ok = _assert(not dismissed[0], "non-arrow tap is a no-op") and ok
	# RETURN emits back_pressed.
	_tap(screen, TransferScreen.BTN_RETURN.get_center())
	ok = _assert(dismissed[0], "RETURN emits back_pressed") and ok
	# A market that fits shows no arrows, so every tap dismisses.
	screen.setup([big[0], big[3]], "ME", "MGR", "1997-98", 5_000_000, "OPEN", 3)
	ok = _assert(screen._max_scroll() == 0, "small market does not overflow") and ok
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "", "no arrow hit when list fits") and ok

	screen.setup(market, names[my_id], "A. FERGUSON", "1997-98", 8_000_000, "OPEN", 3)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


const SCROLL_UP_C := Vector2(606 + 12, 150 + 11)    # centre of TransferScreen.SCROLL_UP
const SCROLL_DOWN_C := Vector2(606 + 12, 206 + 11)  # centre of TransferScreen.SCROLL_DOWN


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
