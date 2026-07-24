extends SceneTree
## END-TO-END SELL LOOP through the REAL Main UI — the owner's "not possible to
## accept offers on own players I list on transfer list" (2026-07-24).
##
## Drives exactly what a player does: list a squad member from his FICHA, press
## CONTINUE, walk the whole match presentation the way a tap would, and assert the
## TEAM OFFER card pops, that its ACCEPT chip + OK commit the sale, and that the
## hub raises the binary's own "%s has been signed by %s." message WITH TEXT
## (the blank-alert regression: PMAlert measured 0 ink when the glyph table was
## missing from the export, so every confirmation was an empty white box).
##   ~/godot462 --headless --path app --script res://tests/test_sell_loop.gd

const MAX_CONTINUES := 10


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 40:
		await process_frame
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload absent under --script")
		print("test_sell_loop: PASS")
		quit(0)
		return
	var ok := true
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var club: Dictionary = gamedb.clubs_in_league("eng_prem")[0]
	main._begin_career("Test Mgr", league, club)
	for _i in 12:
		await process_frame
	# clear the season-open chain (CHAMPIONSHIPS -> shield -> START OF SEASON)
	for _s in 12:
		var n: Node = _top(main)
		if n == null:
			break
		if not _fire(n):
			break
		for _i in 5:
			await process_frame
	var c = main._career

	# --- list a player through the FICHA, exactly as the owner does -----------
	var squad: Array = c.my_squad()
	var target: Dictionary = squad[squad.size() - 1]
	var pid := int(target.get("id", -1))
	main._open_player_info(target, main._mgr_club())
	for _i in 6:
		await process_frame
	var fi: PlayerInfoScreen = _first(main, "PlayerInfoScreen") as PlayerInfoScreen
	ok = _assert(fi != null, "FICHA opened for %s" % target.get("name", "?")) and ok
	if fi != null:
		var tr: Rect2 = PlayerInfoScreen.BTN["transfer"]
		_tap(fi, tr.get_center())
		for _i in 4:
			await process_frame
	ok = _assert(c.is_listed(pid), "TRANSFER placed him on the list") and ok
	for ch in main.get_children():
		if ch is Control and ch != main._hub:
			ch.queue_free()
	for _i in 4:
		await process_frame

	# --- CONTINUE until the TEAM OFFER card pops -----------------------------
	var card: TeamOfferScreen = null
	for _w in MAX_CONTINUES:
		main._career_advance()
		for _i in 5:
			await process_frame
		for _s in 30:
			var n: Node = _top(main)
			if n == null:
				break
			if n is TeamOfferScreen:
				card = n
				break
			if not _fire(n):
				break
			for _i in 5:
				await process_frame
		if card != null:
			break
	ok = _assert(card != null,
		"the TEAM OFFER card pops during CONTINUE (offers=%d)" % c.offers_for(pid).size()) and ok
	if card == null:
		print("test_sell_loop: FAIL")
		quit(1)
		return
	card.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert((card._offers as Array).size() > 0, "the card carries offer rows") and ok

	# --- ACCEPT row 1, then OK ----------------------------------------------
	var cash0: int = c.cash
	_tap(card, Vector2(card.CHIP_X + 40, card.CHIP_Y0 + 8))
	for _i in 3:
		await process_frame
	ok = _assert(bool((card._accept as Array)[0]), "the chip toggled to ACCEPT") and ok
	_tap(card, card.OK_RECT.get_center())
	for _i in 10:
		await process_frame
	ok = _assert(c._find_in(c.club_id, pid).is_empty(), "the player left the squad") and ok
	ok = _assert(c.cash > cash0, "the fee landed (+£%d)" % (c.cash - cash0)) and ok
	ok = _assert(not c.is_listed(pid), "the listing cleared") and ok

	# --- the hub message must carry INK, not be a blank box ------------------
	var hub = main._hub
	var msg := ""
	if hub != null and "_alert_msg" in hub:
		msg = str(hub._alert_msg)
	ok = _assert(msg.find("signed by") >= 0,
		"hub raised the signing message ('%s')" % msg) and ok
	if msg != "":
		# the exact blank-box regression: an empty glyph table collapses the box to
		# its 160px minimum and draws nothing.
		var box := PMAlert.box_rect(msg)
		ok = _assert(box.size.x > 192, "the alert box is measured, not the blank minimum (w=%d)"
			% box.size.x) and ok
		var img := PMAlert.render(msg)
		var black := 0
		for y in img.get_height():
			for x in img.get_width():
				var col := img.get_pixel(x, y)
				if col.r8 == 0 and col.g8 == 0 and col.b8 == 0:
					black += 1
		var border := 2 * 2 * (img.get_width() + img.get_height())
		ok = _assert(black > border + 300,
			"the message renders real ink (%d black px vs ~%d border)" % [black, border]) and ok

	print("test_sell_loop: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _first(main: Node, cls: String) -> Node:
	for ch in main.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("%s.gd" % cls):
			return ch
	return null


func _top(main: Node) -> Node:
	var last: Node = null
	for ch in main.get_children():
		if ch is Control and ch != main._hub and is_instance_valid(ch) \
				and not ch.is_queued_for_deletion():
			last = ch
	return last


func _fire(n: Node) -> bool:
	for s in ["continue_pressed", "ok_pressed", "back_pressed", "done"]:
		if n.has_signal(s) and not n.get_signal_connection_list(s).is_empty():
			n.emit_signal(s)
			return true
	return false


func _tap(n: Control, p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = pressed
		n._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
