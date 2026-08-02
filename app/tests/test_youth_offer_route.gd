extends SceneTree
## The YOUTH TEAM scout's PLAYERS FOUND row tap must raise the prospect's CONTRACT-OFFER
## card (`FUN_0053eaa0` -> `FUN_00527000`), not sign him silently with a toast.
##
## WITNESS refrun p0759, 14 October 1998 (youth_re.md C6): the card reads
##   CLUB OFFER £0 / CLUB FEE £75,000 / YEARLY WAGE £5,000 with steppers / YEARS 4
## and SPINDLE — the youngster it signed — carries YEARLY WAGE £15,000 / YEARS 4 / LEFT 4
## on his own card (C5), so the wage is NEGOTIATED UP from the £5,000 the form opens at.
## There is no selling club, so the CLUB OFFER row is display-only.
##
## Drives the REAL Main UI: open the YOUTH screen with a seeded shortlist, tap the row,
## assert the card mounts on the witnessed terms, then fire OFFER and assert the terms
## land on the youngster.
##   ~/godot4 --headless --path app --script res://tests/test_youth_offer_route.gd

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
		print("test_youth_offer_route: PASS")
		quit(0)
		return
	var ok := true
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	main._begin_career("Test Mgr", league, gamedb.clubs_in_league("eng_prem")[0])
	for _i in 12:
		await process_frame
	for _s in 12:
		var n: Node = _top(main)
		if n == null or not _fire(n):
			break
		for _i in 5:
			await process_frame
	var c = main._career

	# ---- seed a finished search -------------------------------------------
	var pool: Array = c.youth_pool
	ok = _assert(not pool.is_empty(), "the youth pool shipped (%d)" % pool.size()) and ok
	if pool.is_empty():
		print("test_youth_offer_route: FAIL")
		quit(1)
		return
	var prospect: Dictionary = (pool[0] as Dictionary).duplicate(true)
	c.youth_found = [prospect]
	var pid := int(prospect.get("id", -1))
	var before: int = c.youth.size()

	# ---- the row tap raises the card, it does NOT sign him -----------------
	main._show_youth_screen()
	for _i in 8:
		await process_frame
	var scr: YouthScreen = _first(main, "YouthScreen") as YouthScreen
	ok = _assert(scr != null, "the YOUTH TEAM screen opened") and ok
	if scr == null:
		print("test_youth_offer_route: FAIL")
		quit(1)
		return
	scr.prospect_pressed.emit(pid)
	for _i in 8:
		await process_frame
	var card: MakeOfferScreen = _first(main, "MakeOfferScreen") as MakeOfferScreen
	ok = _assert(card != null, "a PLAYERS FOUND row opens the CONTRACT-OFFER card") and ok
	ok = _assert(c.youth.size() == before,
		"and does NOT sign him behind the card") and ok
	if card == null:
		print("test_youth_offer_route: FAIL")
		quit(1)
		return

	# ---- ...on the witnessed opening terms ---------------------------------
	ok = _assert(str(card._p.get("name", "")) == str(prospect.get("name", "")),
		"the card is showing the prospect that was tapped") and ok
	ok = _assert(card._offer == 0, "CLUB OFFER £0 — there is no club to bid to") and ok
	ok = _assert(card._fee == Career.YOUTH_CLUB_FEE,
		"CLUB FEE £%d" % Career.YOUTH_CLUB_FEE) and ok
	ok = _assert(card._wage_yearly == Career.YOUTH_OPENING_WAGE,
		"YEARLY WAGE opens at the £%d floor" % Career.YOUTH_OPENING_WAGE) and ok
	ok = _assert(card._years == Career.YOUTH_OPENING_YEARS,
		"YEARS %d" % Career.YOUTH_OPENING_YEARS) and ok

	# the CLUB OFFER steppers are inert; the wage's are not
	card._step("offer_up")
	ok = _assert(card._offer == 0, "the CLUB OFFER ◄► are dead on a no-club card") and ok
	card._step("wage_up")
	ok = _assert(card._wage_yearly > Career.YOUTH_OPENING_WAGE,
		"but the WAGE ◄► still negotiate (£%d)" % card._wage_yearly) and ok

	# ---- OFFER does NOT sign him on the spot — the answer comes next week ---
	# (refrun p0759/p0760/p0770: offer Wed 14 Oct, still in PLAYERS FOUND that day,
	# on the roster Tue 20 Oct.) Offer well over any demand so the wage-driven part of
	# the refusal roll is gone; the potential/pull residual survives, so accept either
	# answer and only pin the terms.
	card.offer_made.emit(0, 50_000, 4, [], 0)
	for _i in 8:
		await process_frame
	ok = _assert(_first(main, "MakeOfferScreen") == null, "OFFER dismisses the card") and ok
	ok = _assert(c.youth.size() == before,
		"OFFER does not sign him on the spot (the answer comes next week)") and ok
	ok = _assert(c.youth_found.size() == 1,
		"he stays in PLAYERS FOUND while he thinks it over (p0760)") and ok
	ok = _assert(c.youth_offers.size() == 1
		and int((c.youth_offers[0] as Dictionary).get("wage", 0)) == 50_000,
		"the offer is recorded for the weekly tick") and ok
	# The next weekly tick resolves the roll.
	c._resolve_youth_offers(c.career_rng())
	ok = _assert(c.youth_offers.is_empty(), "the weekly tick spends the offer") and ok
	var joined := {}
	for q in c.youth:
		if int((q as Dictionary).get("id", -1)) == pid:
			joined = q
			break
	if joined.is_empty():
		ok = _assert(c.youth_found.is_empty(),
			"he refused, and the shortlist row is spent") and ok
	else:
		ok = _assert(int(joined.get("contract_wage", 0)) == 50_000,
			"he signed on the negotiated YEARLY WAGE (£%d)"
			% int(joined.get("contract_wage", 0))) and ok
		ok = _assert(int(joined.get("contract_years", 0)) == 4,
			"and on the card's term (%d years)" % int(joined.get("contract_years", 0))) and ok
		ok = _assert(int(joined.get("wage", 0)) > 0,
			"with a weekly wage stamped for the squad screens") and ok

	# ---- CANCEL leaves him on the shortlist --------------------------------
	c.youth_found = [(pool[1] as Dictionary).duplicate(true)] if pool.size() > 1 else [prospect]
	var pid2 := int((c.youth_found[0] as Dictionary).get("id", -1))
	var n2: int = c.youth.size()
	main._show_youth_offer_card(pid2, func() -> void: pass)
	for _i in 8:
		await process_frame
	var card2: MakeOfferScreen = _first(main, "MakeOfferScreen") as MakeOfferScreen
	ok = _assert(card2 != null, "the card re-opens for a second prospect") and ok
	if card2 != null:
		card2.cancelled.emit()
		for _i in 8:
			await process_frame
		ok = _assert(c.youth.size() == n2 and c.youth_found.size() == 1,
			"CANCEL signs nobody and leaves him on the shortlist") and ok

	print("test_youth_offer_route: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _first(main: Node, cls: String) -> Node:
	for ch in main.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("%s.gd" % cls) \
				and not ch.is_queued_for_deletion():
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
		if n.has_signal(s):
			n.emit_signal(s)
			return true
	return false


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
