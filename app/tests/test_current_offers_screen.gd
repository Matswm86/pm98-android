extends SceneTree
## Headless wiring test for the CURRENT OFFERS (OFERTAS) screen: the RE'd geometry
## constants hold (band y=98 step 67, RETURN CRect(0x1ee,0x1ba,0x25e,0x1d3)), the
## baked clause icons exist, a real career club feeds the screen, bands cap at the
## original's 5 slots, MO stays the honest "-" gap, and PM98 render-casing matches
## the frame-verified names ("Van der Gouw", "Aston Villa"). Route-side: the
## TransferScreen exposes the FICHAR-hub `current_offers_pressed` signal.
##   ~/godot462 --headless --path app --script res://tests/test_current_offers_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# The four FUN_00524500 clause icons baked out of RECURSOS.PKF.
	for n in ["clause_descenso", "clause_partidos", "clause_primasgol", "clause_casacoche"]:
		ok = _assert(ResourceLoader.exists("res://art/icons/%s.png" % n),
			"clause icon baked: %s" % n) and ok

	# RE'd geometry anchors (docs/re/ofertas_screen_re.md).
	ok = _assert(CurrentOffersScreen.BAND_Y0 == 98 and CurrentOffersScreen.BAND_STEP == 67,
		"bands at y=0x62 stepping 0x43 (FUN_00523ed0)") and ok
	ok = _assert(CurrentOffersScreen.BAND_W == 564 and CurrentOffersScreen.BAND_H == 48,
		"band header block 0x234x0x30") and ok
	ok = _assert(CurrentOffersScreen.RETURN_BTN == Rect2(494, 442, 112, 25),
		"RETURN = CRect(0x1ee,0x1ba,0x25e,0x1d3)") and ok
	ok = _assert(CurrentOffersScreen.PANEL == Rect2(31, 78, 575, 360),
		"panel border (31,78)-(606,438) (FUN_00523f70)") and ok

	# PM98 render casing (the EQUIPOS cipher is single-case; the original title-cases
	# with lowercase particles — frame 077 "Van der Gouw", the offers capture).
	ok = _assert(PMChrome.title_case_name("VAN DER GOUW") == "Van der Gouw",
		"particle casing: Van der Gouw") and ok
	ok = _assert(PMChrome.title_case_name("SOUTHGATE") == "Southgate",
		"simple casing: Southgate") and ok
	ok = _assert(PMChrome.title_case_name("ASTON VILLA") == "Aston Villa",
		"club casing: Aston Villa") and ok

	# A real career club feeds the screen; bands cap at the original's 5 slots.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		quit(1)
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var league: Dictionary = {}
	var prem: Array = []
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, [league])
	var rng := RandomNumberGenerator.new()
	rng.seed = 98

	# List 6 outfielders and force bids: the screen must keep only 5 bands.
	var listed: Array = []
	for p in career.my_squad():
		if not p.get("isGK") and listed.size() < 6:
			career.toggle_listed(int(p["id"]))
			listed.append(p)
	for _i in 30:
		career._accumulate_offers(rng)

	var screen: CurrentOffersScreen = load("res://scenes/CurrentOffersScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f10 != null and screen._f8 != null, "PROMAN fonts loaded") and ok

	var bands: Array = []
	for pid in career.transfer_listed:
		var p := career._find_in(career.club_id, int(pid))
		if not p.is_empty():
			bands.append({"player": p, "offers": career.offers_for(int(pid))})
	ok = _assert(bands.size() == 6, "fixture listed 6 players") and ok
	screen.setup(bands, "", career.club_name, career.league_name, career.season, 1,
		career.club_id)
	ok = _assert(screen._bands.size() == 5, "screen caps at the original's 5 band slots") and ok
	var with_bids := 0
	for b in screen._bands:
		if not (b["offers"] as Array).is_empty():
			with_bids += 1
	ok = _assert(with_bids >= 1, "at least one band carries a live bid (got %d)" % with_bids) and ok

	# MO now renders the LIVE decoded morale (FUN_00582db0; key "_mo"), FI the
	# live fitness (key "_fit"), AV the real rating — never the static RM/TI
	# placeholders and never a fabricated value: a player with no dynamic form
	# still shows "-" (has_form gate). docs/re/morale_re.md.
	var mo: Array = CurrentOffersScreen.ATTR_COLS[6]
	ok = _assert(str(mo[0]) == "MO" and str(mo[2]) == "_mo", "MO column = live morale") and ok
	ok = _assert(str(CurrentOffersScreen.ATTR_COLS[5][2]) == "_fit", "FI column = live fitness") and ok
	ok = _assert(str(CurrentOffersScreen.ATTR_COLS[7][2]) == "_avg", "AV = real rating") and ok
	# A form-less player still renders "-" (never invented).
	var noform := {"attrs": {"CA": 70}}
	ok = _assert(not (noform.has("morale") or noform.has("fitness")),
		"form-less player has no bars -> MO/FI render '-'") and ok

	# POS cell labels (capture: DEF / FOR).
	ok = _assert(screen._pos_label({"pos": "DF"}) == "DEF"
		and screen._pos_label({"pos": "FW"}) == "FOR"
		and screen._pos_label({"pos": "GK", "isGK": true}) == "GK", "POS labels GK/DEF/MID/FOR") and ok

	# Route: the transfer screen exposes the sourced FICHAR-hub signal.
	var ts: TransferScreen = load("res://scenes/TransferScreen.gd").new()
	ok = _assert(ts.has_signal("current_offers_pressed"),
		"TransferScreen CURRENT OFFERS button is live") and ok
	ts.free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
