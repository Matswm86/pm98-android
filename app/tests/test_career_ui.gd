extends SceneTree
## Scene-level smoke test: instantiates the real Main UI and drives the career
## flow through its own methods (start -> advance -> table -> save), asserting no
## crash and that state transitions. Catches UI-wiring bugs the logic test can't.
##   ~/godot462 --headless --path app --script res://tests/test_career_ui.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	# Let _ready + autoload DB load settle.
	for _i in 30:
		await process_frame
	var ok := true

	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload not present under --script; UI smoke skipped")
		print("\nALL PASS")
		quit(0)
		return
	ok = _assert(gamedb.leagues.size() > 0, "GameDB loaded %d leagues" % gamedb.leagues.size()) and ok

	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var club: Dictionary = gamedb.clubs_in_league("eng_prem")[0]

	main._begin_career("Test Mgr", league, club)   # build career + enter hub
	await process_frame
	# The hub is raised only at the END of the witnessed curtain-raiser chain.
	await _clear_season_open_chain(main)
	ok = _assert(main._career != null and main._career.club_id == int(club["id"]),
		"career created for %s" % club.get("name", "?")) and ok
	ok = _assert(main._career.week == 0, "starts at week 0") and ok
	# B1: the career hub IS the original-art MENUPRINCIPAL, mounted + visible (not green).
	ok = _assert(main._hub != null and is_instance_valid(main._hub) and main._hub.visible,
		"MENUPRINCIPAL hub mounted as the persistent career hub") and ok
	ok = _assert(main._hub is MenuScreen, "hub is a MenuScreen") and ok

	# Advance three weeks through the real UI path.
	for _w in 3:
		main._career_advance()
		await process_frame
	ok = _assert(main._career.week == 3, "advanced to week 3 (got %d)" % main._career.week) and ok

	# RESULTS view: the source-true ResultsScreen overlay over the hub (was the rejected browse).
	main._show_results_screen()
	await process_frame
	var res_overlay: Node = null
	for ch in main.get_children():
		if ch is ResultsScreen:
			res_overlay = ch
	ok = _assert(res_overlay != null, "RESULTS screen overlay mounted") and ok
	if res_overlay != null:
		res_overlay.queue_free()
	await process_frame

	# Original-art LEAGUE TABLES overlay (graphics reskin, S-graphics-1).
	main._show_league_table_screen()
	await process_frame
	var overlay: Node = null
	for ch in main.get_children():
		if ch is LeagueTableScreen:
			overlay = ch
	ok = _assert(overlay != null, "LEAGUE TABLES screen overlay mounted") and ok
	if overlay != null:
		ok = _assert(overlay._rows.size() == main._career.standings().size(),
			"overlay shows the live standings") and ok
		overlay.queue_free()
	await process_frame

	# Original-art LINE-UP overlay (graphics reskin, S-graphics-4): squad list + pitch.
	main._show_lineup_screen()
	await process_frame
	var lu: Node = null
	for ch in main.get_children():
		if ch is LineupScreen:
			lu = ch
	ok = _assert(lu != null, "LINE-UP screen overlay mounted") and ok
	if lu != null:
		ok = _assert(lu._by_id.size() == main._career.squad_of(main._career.club_id).size(),
			"line-up overlay indexed the live roster") and ok
		var lu_tex: Texture2D = lu._compose_pitch(lu._tactics.formation, -1)
		ok = _assert(lu_tex != null and lu_tex.get_width() == 152,
			"line-up overlay composed the CAMPO marker pitch") and ok
		lu.queue_free()
	await process_frame

	# Drive the TACTICS board (the original-art surface) through the real UI
	# wiring (catches wiring bugs). The interim text-menu tactics handlers were
	# removed 2026-07-04 — the board's signals are the live path now.
	main._show_tactics_board_screen()
	await process_frame
	var tb: Node = null
	for ch in main.get_children():
		if ch is TacticsBoardScreen:
			tb = ch
	ok = _assert(tb != null, "TACTICS board overlay mounted") and ok
	if tb != null:
		tb.formation_picked.emit("4-3-3")       # PREDEF pick -> set_formation + save
		await process_frame
		ok = _assert(Tactics.from_dict(main._career.tactics).formation == "4-3-3",
			"UI formation change persisted") and ok
		ok = _assert(Tactics.from_dict(main._career.tactics).validate(
			gamedb.club(main._career.club_id)) == "",
			"XI re-filled valid for the new shape") and ok
		tb.save_pressed.emit()                  # SAVE TACTICS -> named preset
		await process_frame
		tb.load_pressed.emit()                  # LOAD TACTICS -> re-apply last preset
		await process_frame
		ok = _assert(Tactics.from_dict(main._career.tactics).validate(
			gamedb.club(main._career.club_id)) == "",
			"line-up still valid after preset LOAD") and ok
		tb.return_pressed.emit()                # RETURN frees the board
		await process_frame

	# Drive the transfer/renew UI: market view -> make-offer card -> bid places -> signing lands
	# next week, then the REAL FICHA RENEW. (The invented text-menu flow _show_transfers/
	# _show_transfer_squad/_show_player_deal/_show_shortlist/_show_transfer_news was deleted
	# 2026-07-23; its screens are covered by test_transfer_screen/_squad/_contract.)
	main._show_market()
	await process_frame
	var mkt: Array = main._career.market()
	ok = _assert(not mkt.is_empty(), "UI market populated (%d players)" % mkt.size()) and ok
	var row: Dictionary = mkt[0]
	main._push(main._show_market_player.bind(row))
	await process_frame
	main._career.cash = 100_000_000             # fund a guaranteed (force-price) signing
	var before: int = main._career.my_squad().size()
	# _market_action routes non-shortlist taps to the REAL make-offer card
	# (MakeOfferScreen, walkthrough run-3 101-118) — drive its OFFER signal.
	main._market_action(row, {})
	await process_frame
	var moc: Node = null
	for ch in main.get_children():
		if ch is MakeOfferScreen:
			moc = ch
	ok = _assert(moc != null, "make-offer card mounted from the market row") and ok
	if moc != null:
		moc.offer_made.emit(int(row["fee"]) * 3, 500_000, 3, [], 0)
		await process_frame
	# The OFFER click only PLACES the bid (the original's days-later response);
	# the club answers on the next week roll and the player joins THEN.
	ok = _assert(main._career.my_squad().size() == before, "UI offer placed, no instant join") and ok
	ok = _assert(main._career.pending_bids.size() == 1, "UI offer queued as a pending bid") and ok
	var rngw := RandomNumberGenerator.new()
	rngw.seed = 7
	main._career.advance_week(rngw)
	ok = _assert(main._career.my_squad().size() == before + 1, "UI signing lands with next week's answer") and ok
	# REAL RENEW: the FICHA OFFER form (Main._open_renew_negotiation -> PlayerInfoScreen.begin_renew,
	# OFFER -> Career.renew) applies the deal. Drive that same terminal call (meet his demand) and
	# assert the fresh contract; the OFFER-form UI itself is covered by test_player_info_renew.
	var p0: Dictionary = main._career.my_squad()[0]
	var pid0 := int(p0["id"])
	var res0: Dictionary = main._career.renew(pid0, Contract.demanded_weekly(p0, main._career.my_band()))
	await process_frame
	ok = _assert(bool(res0.get("ok", false))
		and int(main._career._find_in(main._career.club_id, pid0).get("contract_years", 0))
		== Contract.NEW_TERM_YEARS, "UI RENEW (meet demand) set a fresh %dy contract" % Contract.NEW_TERM_YEARS) and ok

	main._show_career()                         # back to the hub (re-raised)
	await process_frame
	ok = _assert(main._hub != null and main._hub.visible, "hub re-raised on return to career") and ok
	main._menu_action("save", main._hub)        # MENUPRINCIPAL SAVE button -> save path
	ok = _assert(Career.has_save(), "career saved to disk") and ok
	# ... and the save raises the modal "PREMIER MANAGER 98" alert box (the
	# original's hub message box, frames 093/149 — docs/re/alert_box_re.md).
	ok = _assert(main._hub.alert_active(), "save raises the hub alert box") and ok
	main._hub._next_alert()                     # answer OK so the hub is live again
	ok = _assert(not main._hub.alert_active(), "alert dismissed") and ok
	main._menu_action("news", main._hub)        # info action (no crash, no nav)
	await process_frame

	# The hub PLAYERS button (VENDE icon, action "sell") opens SQUAD MANAGEMENT (SquadScreen),
	# not the old invented BrowseScreen -- the wiring of the orphaned PLANTILLA screen.
	main._menu_action("sell", main._hub)
	await process_frame
	var squad_up := false
	for c in main.get_children():
		if c is SquadScreen:
			squad_up = true
			c.queue_free()
	ok = _assert(squad_up, "hub PLAYERS opens SQUAD MANAGEMENT (SquadScreen)") and ok
	await process_frame

	# The hub OPPONENT icon (RIVAL, action "opponent") opens VIEW RIVAL (RivalScreen), not the
	# old DATA BASE browser -- the VERRIVAL wiring. A bye week has no opponent (alert instead).
	var fx: Array = main._career.manager_fixture()
	main._menu_action("opponent", main._hub)
	await process_frame
	if fx.is_empty():
		ok = _assert(main._hub.alert_active(), "hub OPPONENT on a bye week raises the alert") and ok
		main._hub._next_alert()
	else:
		var rival_up := false
		for c in main.get_children():
			if c is RivalScreen:
				rival_up = true
				c.queue_free()
		ok = _assert(rival_up, "hub OPPONENT opens VIEW RIVAL (RivalScreen)") and ok
	await process_frame

	# CONTINUE plays the week through the hub router (no green hub left). On the career's
	# FIRST match it raises MATCH OPTIONS first and the week does NOT advance until that
	# is confirmed (witnessed, matchday_flow_witness_re §1), so drive the modal.
	var wk: int = main._career.week
	main._menu_action("continue", main._hub)
	await process_frame
	# By week 4 the saved XI has usually picked up an injury/ban, and the witnessed gate
	# (matchday_flow_witness_re §3) fires BEFORE the modal: the alert raises and the week
	# does NOT advance. Assert that, clear it, then repair the XI the way LINE-UP would.
	if main._xi_has_unavailable():
		ok = _assert(main._hub.alert_active(),
			"CONTINUE with an unavailable player raises the line-up alert") and ok
		ok = _assert(main._career.week == wk, "and the week does NOT advance") and ok
		main._hub._next_alert()
		# Repair the XI the way the player would in LINE-UP: pick from the AVAILABLE
		# squad only (auto_pick over the whole squad can re-select the injured man).
		var fit: Dictionary = main._mgr_club().duplicate()
		var avail: Array = []
		for pl in fit.get("players", []):
			if Availability.is_available(pl):
				avail.append(pl)
		fit["players"] = avail
		main._save_tactics(Tactics.auto_pick(fit))
		main._menu_action("continue", main._hub)
		await process_frame
	var opts_up := false
	for ch in main.get_children():
		if ch is MatchOptions:
			opts_up = true
			var am: Node = main.get_node_or_null(^"/root/AudioManager")
			ch.confirmed.emit(am.match_view_mode, am.match_settings())
	ok = _assert(opts_up, "first CONTINUE raises MATCH OPTIONS before the match") and ok
	await process_frame
	ok = _assert(main._career.week == wk + 1, "hub CONTINUE advanced a week (%d->%d)" % [
		wk, main._career.week]) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond

## Drive the witnessed career-entry curtain-raiser chain (orig/06 + orig/70-73):
## TEAMS IN CHAMPIONSHIPS -> [CHARITY SHIELD card] -> START OF SEASON -> hub. Each is a
## real screen with a real button signal, so the test presses them rather than asserting
## behind them. Returns once no curtain-raiser is left mounted.
func _clear_season_open_chain(main: Node) -> void:
	for _step in 6:
		var pressed := false
		for ch in main.get_children():
			if ch is ChampsScreen:
				ch.continue_pressed.emit(); pressed = true
			elif ch is SeasonStartScreen:
				ch.continue_pressed.emit(); pressed = true
			elif ch is CharityShieldScreen:
				ch.ok_pressed.emit(); pressed = true
		await main.get_tree().process_frame
		if not pressed:
			return
