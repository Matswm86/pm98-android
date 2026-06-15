extends SceneTree
## Headless wiring test for the TRANSFER MARKET (FICHAR) screen: confirms the cracked
## ORIGINAL assets (FONDO, BARRA, PROMAN8/10/12/14 BMFonts) load, that a real
## TransferMarket.market() feeds the screen, the money formatter is correct, and the
## screen's bands (KEEPERS capped / OUTFIELD) split the buyable rows faithfully.
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

	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman12.fnt",
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
	for key in ["pid", "name", "isGK", "ca", "fee", "wage", "club_name", "key"]:
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
	ok = _assert(screen._f14 != null and screen._f12 != null and screen._f10 != null
		and screen._f8 != null, "PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._bg != null and screen._bar != null, "FONDO + BARRA loaded") and ok
	screen.setup(market, names[my_id], "A. FERGUSON", "1997-98", 8_000_000, "OPEN", 3)
	await process_frame
	ok = _assert(screen._rows.size() == market.size(), "screen received the market") and ok

	# Bands: KEEPERS (capped, all keepers) + OUTFIELD (no keepers).
	var secs: Array = screen._sections()
	ok = _assert(secs.size() == 2, "two bands (KEEPERS / OUTFIELD)") and ok
	ok = _assert(secs[0]["section"] == "KEEPERS", "first band is KEEPERS") and ok
	ok = _assert((secs[0]["players"] as Array).size() <= TransferScreen.KEEP_CAP,
		"KEEPERS band capped at %d (got %d)" % [TransferScreen.KEEP_CAP, (secs[0]["players"] as Array).size()]) and ok
	var keepers_only := true
	for r in secs[0]["players"]:
		keepers_only = keepers_only and bool(r.get("isGK"))
	ok = _assert(keepers_only, "KEEPERS band holds only keepers") and ok
	var outfield_only := true
	for r in secs[1]["players"]:
		outfield_only = outfield_only and not bool(r.get("isGK"))
	ok = _assert(outfield_only, "OUTFIELD band holds no keepers") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
