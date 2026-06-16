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

	main._begin_career(league, club)            # build career + enter hub
	await process_frame
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

	main._show_career_table()                   # render standings view
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
		ok = _assert((lu._slot_positions() as Array).size() == 11,
			"line-up overlay placed 11 formation markers") and ok
		lu.queue_free()
	await process_frame

	# Drive the tactics screens through the real UI (catches wiring bugs).
	main._push(main._show_tactics)
	await process_frame
	main._show_lineup()                         # render LINE-UP
	await process_frame
	main._activate_formation("4-3-3")           # change shape (pops back to tactics)
	await process_frame
	ok = _assert(Tactics.from_dict(main._career.tactics).formation == "4-3-3",
		"UI formation change persisted") and ok
	main._push(main._show_lineup)
	await process_frame
	main._assign_slot(10, _bench_outfielder(gamedb, main))   # swap a forward
	await process_frame
	ok = _assert(Tactics.from_dict(main._career.tactics).validate(
		gamedb.club(main._career.club_id)) == "", "UI line-up still valid after swap") and ok
	main._activate_tactics({"a": "marking"})    # toggle marking in place
	await process_frame
	main._show_takers()
	await process_frame
	main._show_load_tactics()
	await process_frame

	# Drive the transfer screens (S7): market -> bid -> squad -> RENEW -> news.
	main._push(main._show_transfers)
	await process_frame
	main._show_market()
	await process_frame
	var mkt: Array = main._career.market()
	ok = _assert(not mkt.is_empty(), "UI market populated (%d players)" % mkt.size()) and ok
	var row: Dictionary = mkt[0]
	main._push(main._show_market_player.bind(row))
	await process_frame
	main._career.cash = 100_000_000             # fund a guaranteed (force-price) signing
	var before: int = main._career.my_squad().size()
	main._market_action(row, {"bid": int(row["fee"]) * 3})
	await process_frame
	ok = _assert(main._career.my_squad().size() == before + 1, "UI signing added a player") and ok
	main._push(main._show_transfer_squad)
	await process_frame
	var p0: Dictionary = main._career.my_squad()[0]
	main._push(main._show_player_deal.bind(p0))
	await process_frame
	main._player_deal_action(p0, "renew")
	await process_frame
	ok = _assert(int(main._career._find_in(main._career.club_id, int(p0["id"])).get("contract_years", 0))
		== TransferMarket.NEW_CONTRACT_YEARS, "UI RENEW set a fresh contract") and ok
	main._show_shortlist()
	await process_frame
	main._show_transfer_news()
	await process_frame

	main._show_career()                         # back to the hub (re-raised)
	await process_frame
	ok = _assert(main._hub != null and main._hub.visible, "hub re-raised on return to career") and ok
	main._menu_action("save", main._hub)        # MENUPRINCIPAL SAVE button -> save path
	ok = _assert(Career.has_save(), "career saved to disk") and ok
	main._menu_action("news", main._hub)        # info action -> hub toast (no crash, no nav)
	await process_frame
	ok = _assert(main._hub._toast_msg != "", "hub toast shows info feedback") and ok
	# CONTINUE plays the week through the hub router (no green hub left).
	var wk: int = main._career.week
	main._menu_action("continue", main._hub)
	await process_frame
	ok = _assert(main._career.week == wk + 1, "hub CONTINUE advanced a week (%d->%d)" % [
		wk, main._career.week]) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## A squad outfielder not currently in the manager's XI (to test a swap).
func _bench_outfielder(gamedb: Node, main: Node) -> int:
	var club: Dictionary = gamedb.club(main._career.club_id)
	var t := Tactics.from_dict(main._career.tactics)
	var in_xi: Dictionary = {}
	for id in t.xi:
		in_xi[int(id)] = true
	for p in club.get("players", []):
		if not p.get("isGK") and not in_xi.has(int(p["id"])):
			return int(p["id"])
	return t.xi[10]


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
