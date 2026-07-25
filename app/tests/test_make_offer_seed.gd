extends SceneTree
## The MAKE-OFFER card's two opening states — the owner's "every bid starts at 0, a
## 14M player takes forever" (2026-07-24).
##
## Both states are witnessed, and which one you get depends on how the player was
## reached:
##   * COLD APPROACH (OFFERS map browse, nobody has listed him) — frame
##     `101_164714.png`: Scott Taylor, CLUB FEE £3,000,000 and the panel opens at the
##     FLOOR, CLUB OFFER £5,000 / YEARLY WAGE £5,000 / YEARS 1, no clause ticked.
##     ANDROID DEVIATION (owner decision 2026-07-24): the CLUB OFFER of this state is
##     seeded at the CLUB FEE instead, because the £5,000/£10,000/£25,000 stepper costs
##     ~640 taps to reach a £16M asking price. Everything else about the state is the
##     original's — wage at the floor, YEARS 1, no clause.
##   * PLACED ON TRANSFER MARKET (the TRANSFERS list) — wine `35_make_offer.png`:
##     Almeyda, CLUB FEE £8,500,000 and the panel opens pre-filled at CLUB OFFER
##     **£8,500,000**, YEARLY WAGE £575,000, YEARS 1, "Free if relegated" ticked.
##
##   ~/godot462 --headless --path app --script res://tests/test_make_offer_seed.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var card: MakeOfferScreen = load("res://scenes/MakeOfferScreen.gd").new()
	get_root().add_child(card)
	card.size = Vector2(640, 480)
	await process_frame

	var taylor := {"id": 1, "name": "TAYLOR", "pos": "FW", "attrs": {}}
	var club := {"id": 2, "name": "Blackpool"}

	# --- cold approach: fee-seeded offer, everything else the frame-101 rest ---
	card.setup(taylor, club, 3_000_000, 50_000_000)
	ok = _assert(card._offer == 3_000_000,
		"cold approach opens AT the club fee (got £%d)" % card._offer) and ok
	ok = _assert(card._wage_yearly == MakeOfferScreen.FLOOR, "wage still at the floor") and ok
	ok = _assert(card._years == MakeOfferScreen.YEARS_MIN, "YEARS 1") and ok
	ok = _assert(card.checked_clauses().is_empty(), "no clause ticked") and ok
	# A £16M cold approach — the owner's own example — must not open at £5,000.
	var ronaldo := {"id": 9, "name": "RONALDO", "pos": "FW", "attrs": {}}
	card.setup(ronaldo, club, 16_000_000, 50_000_000)
	ok = _assert(card._offer == 16_000_000,
		"a £16,000,000 cold approach opens at £16,000,000 (got £%d)" % card._offer) and ok
	# A fee UNDER the floor still clamps up to the floor.
	card.setup(taylor, club, 1_000, 50_000_000)
	ok = _assert(card._offer == MakeOfferScreen.FLOOR, "a sub-floor fee clamps up") and ok

	# --- a listed player: the seller's own asking terms ----------------------
	var almeyda := {"id": 3, "name": "ALMEYDA", "pos": "MF", "attrs": {}}
	card.setup(almeyda, club, 8_500_000, 50_000_000,
		{"offer": 8_500_000, "yearly_wage": 575_000, "years": 1, "clauses": [0]})
	ok = _assert(card._offer == 8_500_000,
		"a transfer-listed player opens AT his value (got £%d)" % card._offer) and ok
	ok = _assert(card._wage_yearly == 575_000, "and at his contract wage") and ok
	ok = _assert(card._years == 1, "and his contract length") and ok
	ok = _assert(card.checked_clauses() == [0], "with the contract's clause ticked") and ok

	# --- the seed is still clamped to the model's own bounds -----------------
	card.setup(almeyda, club, 100, 50_000_000, {"offer": 0, "years": 99})
	ok = _assert(card._offer == MakeOfferScreen.FLOOR, "a sub-floor seed clamps up") and ok
	ok = _assert(card._years == MakeOfferScreen.YEARS_MAX, "an over-long term clamps down") and ok

	# --- and the scoring clause stays player-gated ---------------------------
	card.setup(almeyda, club, 1000, 1000, {"clauses": [2]})
	ok = _assert(not card.checked_clauses().has(2),
		"the scoring-bonus clause cannot be seeded onto a non-forward") and ok
	card.setup(taylor, club, 1000, 1000, {"clauses": [2]})
	ok = _assert(card.checked_clauses().has(2), "but it can onto a forward") and ok

	print("test_make_offer_seed: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
