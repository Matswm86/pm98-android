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

	# --- per-row chip hit-testing (the OTHER half of the owner bug) ----------
	# The chip rects used to be 17 tall against a 14 pitch, so they OVERLAPPED and
	# `_target_at` returned the FIRST match: a tap on offer #2's chip flipped #1 and #2
	# could never be accepted. Fill a card with the full five rows and assert each chip
	# centre resolves to its OWN row, and that OK still wins over row 4.
	var full: TeamOfferScreen = load("res://scenes/TeamOfferScreen.gd").new()
	get_root().add_child(full)
	full.size = Vector2(640, 480)
	var rows: Array = []
	for i in TeamOfferScreen.N_ROWS:
		rows.append({"buyer_id": i, "buyer_name": "Club %d" % i, "offer": 1000 * (i + 1)})
	full.setup(target, main._mgr_club(), rows, 1, 1, 1, 1)
	for _i in 2:
		await process_frame
	for row in TeamOfferScreen.N_ROWS:
		var probe := Vector2(full.CHIP_X + 40, full.CHIP_Y0 + full.ROW_PITCH * row + 7)
		ok = _assert(full._target_at(probe) == "row%d" % row,
			"row %d chip centre hit-tests to its own row (got '%s')"
				% [row, full._target_at(probe)]) and ok
	ok = _assert(full._target_at(TeamOfferScreen.OK_RECT.get_center()) == "ok",
		"OK still hit-tests below the five rows") and ok
	# and one device-shaped tap on row 3 must flip row 3 ONLY
	_tap(full, Vector2(full.CHIP_X + 40, full.CHIP_Y0 + full.ROW_PITCH * 3 + 7))
	for _i in 2:
		await process_frame
	var flipped: Array = []
	for i in TeamOfferScreen.N_ROWS:
		if bool((full._accept as Array)[i]):
			flipped.append(i)
	ok = _assert(flipped == [3], "a tap on row 3 flips row 3 alone (flipped %s)" % str(flipped)) and ok
	full.queue_free()
	for _i in 2:
		await process_frame

	# --- ACCEPT row 1, then OK ----------------------------------------------
	var cash0: int = c.cash
	_tap(card, Vector2(card.CHIP_X + 40, card.CHIP_Y0 + 8))
	for _i in 3:
		await process_frame
	ok = _assert(bool((card._accept as Array)[0]),
		"a device-shaped tap toggles the chip to ACCEPT (and stays there)") and ok
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


## A DEVICE-SHAPED tap. Godot 4.6 with the project default
## `input_devices/pointing/emulate_mouse_from_touch = true` delivers ONE finger press
## to `gui_input` TWICE — an emulated `InputEventMouseButton` (device -1) AND the real
## `InputEventScreenTouch` (device 0), in that order (measured, see
## `tests/test_pointer_dup.gd`). The old helper sent the touch alone, which is exactly
## why this test went green while the owner could not flip a chip on his phone: the
## card toggles on press, so the second event flipped it straight back. Every UI test
## that taps must send the pair.
func _tap(n: Control, p: Vector2) -> void:
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.pressed = pressed
		m.device = InputEvent.DEVICE_ID_EMULATION
		n._on_input(m)
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = pressed
		n._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
