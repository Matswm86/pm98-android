extends SceneTree
## Headless wiring test for the MAKE-OFFER card (MakeOfferScreen; walkthrough
## run-3 101-118, docs/re/make_offer_re.md): the baked chrome + state art exist,
## the frame-measured geometry anchors hold, the stepper model behaves (floor,
## cash cap, years clamp), the scoring-bonus clause is player-gated (FW active /
## others washed), the corrected star rule ((v+1) div 10) matches the frame
## observations, and the buy path carries the card's terms into Career
## (sign_player weekly/years/clauses + sign_loan). Route-side: TransferScreen
## exposes `player_pressed`.
##   ~/godot462 --headless --path app --script res://tests/test_make_offer_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# ---- baked art ------------------------------------------------------------
	for n in ["chrome", "check_on", "spin_l_on", "spin_r_on", "offer_pr", "scoring_washed"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/makeoffer/%s.png" % n),
			"baked art exists: %s" % n) and ok
	ok = _assert(ResourceLoader.exists("res://art/kits/ficha/82.png"),
		"BLACKPOOL ficha kit patch baked") and ok

	# ---- frame-measured anchors (make_offer_re.md) ------------------------------
	ok = _assert(MakeOfferScreen.CARD_POS == Vector2(76, 48), "card at (76,48)") and ok
	ok = _assert(MakeOfferScreen.NAME_XY == Vector2(171, 69), "name ink-left x171") and ok
	ok = _assert(MakeOfferScreen.NAT_FLAG == Vector2(141, 145), "MINIBAND mini at (141,145)") and ok
	ok = _assert(MakeOfferScreen.CAMROL_XY == Vector2(182, 160), "camrol at (182,160)") and ok
	ok = _assert(MakeOfferScreen.STAR_X0 == 450 and MakeOfferScreen.STAR_PITCH == 14,
		"star grid x450+14j") and ok
	ok = _assert(MakeOfferScreen.CB_YS == [290, 306, 339, 372], "checkbox rows") and ok
	ok = _assert(MakeOfferScreen.BTN["offer"] == Rect2(405, 396, 146, 29), "OFFER button rect") and ok
	ok = _assert(MakeOfferScreen.STEP == 5000 and MakeOfferScreen.FLOOR == 5000,
		"£5,000 base step + floor (frame-observed)") and ok

	# ---- the corrected star rule: halves = (value+1) div 10 ---------------------
	# frame observations — 101: 19->1 full, 79->4 full, 75->3.5, 57->2.5, 73->3.5;
	# team-offer 090: 79->4 full, 77->3.5, 63->3; 086: 17->0.5, 47->2
	var star_cases := {19: 2, 79: 8, 75: 7, 57: 5, 73: 7, 17: 1, 47: 4, 63: 6, 77: 7, 84: 8}
	for v in star_cases:
		ok = _assert((int(v) + 1) / 10 == star_cases[v],
			"star halves for %d = %d" % [v, star_cases[v]]) and ok

	# ---- card model: steppers, gates, clauses -----------------------------------
	var taylor := {"id": 1075, "name": "TAYLOR", "legalName": "SCOTT TAYLOR",
		"pos": "FW", "posFine": 12, "age": 21, "nationality": "ENGLAND",
		"kind": "NATIONAL", "flagCode": 30, "weightKg": 75, "heightCm": 180,
		"attrs": {"VE": 98, "RE": 95, "AG": 79, "CA": 92, "RM": 75, "RG": 75,
			"PA": 79, "TI": 73, "EN": 57, "PO": 19}}
	var card: MakeOfferScreen = MakeOfferScreen.new()
	card.setup(taylor, {"id": 82, "name": "BLACKPOOL"}, 3000000, 3200000)
	ok = _assert(card._offer == 5000 and card._wage_yearly == 5000 and card._years == 1,
		"frame-constant initial values £5,000 / £5,000 / 1") and ok
	ok = _assert(card._scoring_enabled(), "Scoring bonus active for a forward") and ok
	card._step("offer_dn", 1)
	ok = _assert(card._offer == 5000, "offer floors at £5,000") and ok
	card._step("offer_up", 1000)
	ok = _assert(card._offer == 3200000, "offer caps at available funds (3.2M, frame 107)") and ok
	card._step("years_up", 1)
	card._step("years_up", 1)
	ok = _assert(card._years == 3, "years step to 3 (frame 118)") and ok
	for i in 9:
		card._step("years_up", 1)
	ok = _assert(card._years == MakeOfferScreen.YEARS_MAX, "years clamp") and ok
	card._toggle("scoring")
	ok = _assert(card._checked["scoring"] and card._bonus == 5000,
		"scoring check activates its stepper at £5,000 (frame 113)") and ok
	card._toggle("house")
	ok = _assert(card.checked_clauses() == [2, 3], "checked clause indices") and ok
	# card-name rule now shared (PMChrome.card_name; surname = the `name` field
	# suffix — frame truth incl. "Raimond VAN DER GOUW" / "Ole Gunnar SOLSKJAER")
	ok = _assert(PMChrome.card_name(taylor) == "Scott TAYLOR", "card name form") and ok
	ok = _assert(PMChrome.card_name({"name": "VAN DER GOUW",
		"legalName": "RAIMOND VAN DER GOUW"}) == "Raimond VAN DER GOUW",
		"compound surname card name (081)") and ok
	ok = _assert(PMChrome.card_name({"name": "SOLSKJAER",
		"legalName": "OLE GUNNAR SOLSKJAER"}) == "Ole Gunnar SOLSKJAER",
		"two given names card name (084)") and ok
	ok = _assert(PMChrome.card_name({"name": "McKINLAY",
		"legalName": "WILLIAM MCKINLAY"}) == "William McKINLAY",
		"Mc surname keeps inner capital") and ok
	card.free()

	# non-forward: scoring gated off (McKinlay MF, washed label)
	var mck := {"name": "McKINLAY", "pos": "MF", "attrs": {}}
	var card2: MakeOfferScreen = MakeOfferScreen.new()
	card2.setup(mck, {"id": 1, "name": "BLACKBURN R."}, 650000, 1000000)
	ok = _assert(not card2._scoring_enabled(), "Scoring bonus washed for a midfielder") and ok
	card2._toggle("scoring")
	ok = _assert(not card2._checked["scoring"], "gated checkbox stays unchecked") and ok
	card2.free()

	# ---- route: TransferScreen exposes the row tap -------------------------------
	ok = _assert(TransferScreen.new().has_signal("player_pressed"),
		"TransferScreen.player_pressed exists") and ok

	# ---- Career carries the card's terms -----------------------------------------
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		quit(1)
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var league: Dictionary = {}
	for lg in db.get("leagues", []):
		if str(lg.get("id", "")) == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if str(c.get("leagueId", "")) == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, [league])
	# pick a buyable player from another club
	var target: Dictionary = {}
	for row in career.market():
		# a non-key fringe player bid generously (evaluate_offer is stochastic;
		# key players carry the KEY_PREMIUM and resist even full-price bids)
		if not bool(row["key"]) and int(row["fee"]) * 2 <= career.cash:
			target = row
	ok = _assert(not target.is_empty(), "an affordable market target exists") and ok
	if not target.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var res := {}
		for i in 40:
			res = career.sign_player(int(target["pid"]), int(target["club_id"]),
				int(target["fee"]) * 2, rng, 480, 3, [2, 3])
			if res["ok"]:
				break
			career.offers_left = 5
		ok = _assert(bool(res["ok"]), "sign_player accepts a generous bid (%s)" % res.get("msg", "")) and ok
		if res["ok"]:
			var signed := career._find_in(career.club_id, int(target["pid"]))
			ok = _assert(int(signed.get("wage", 0)) == 480, "card wage honoured (weekly 480)") and ok
			ok = _assert(int(signed.get("contract_years", 0)) == 3, "card years honoured") and ok
			ok = _assert(signed.get("clauses", []) == [2, 3], "card clauses stored") and ok

	print("MAKE-OFFER: ALL GREEN" if ok else "MAKE-OFFER: FAILURES")
	quit(0 if ok else 1)


func _assert(cond: bool, what: String) -> bool:
	print(("  ok  " if cond else "  FAIL ") + what)
	return cond
