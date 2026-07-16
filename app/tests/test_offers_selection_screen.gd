extends SceneTree
## OFFERS SELECTION screen (frame-true rebuild, 2026-07-16) — headless asserts
## for the baked art, the accept/popup/CONTINUE state machine and the witnessed
## palette-dim LUT. The pixel gate lives in
## tools/re/diff_offers_selection_parity.py (witnessed states vs frames 03-07).

var _back := 0
var _accepted_sig := -1
var _confirmed_sig := -1


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# --- baked art present ---
	for n in ["body", "body_dim", "popup", "offers_plate_off", "offers_plate_on",
			"offers_plate_off_r1", "slot_chip1", "arrow_chip", "continue_on",
			"offer_chip_01", "offer_chip_10"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/offers_selection/%s.png" % n),
			"art exists: %s" % n) and ok
	ok = _assert(ResourceLoader.exists("res://art/screens/offers_selection/dim_lut.json"),
		"dim_lut.json exists") and ok
	ok = _assert(ResourceLoader.exists("res://art/kits/offers/107.png"),
		"witnessed Brighton kit patch exists") and ok

	# --- screen logic ---
	var scr: OffersSelectionScreen = load("res://scenes/OffersSelectionScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	scr.back_pressed.connect(func() -> void: _back += 1)
	scr.offer_accepted.connect(func(i: int) -> void: _accepted_sig = i)
	scr.accept_confirmed.connect(func(i: int) -> void: _confirmed_sig = i)

	var offers: Array = []
	for i in 3:
		offers.append({"team": "Club %d" % i, "division": "3rd Div.",
			"division_full": "Third Division", "objective": "Avoid relegation",
			"club_id": 107 if i == 0 else -1, "stadium": "S", "capacity": "1 seats",
			"members": "-", "cash": "£1"})
	scr.setup("mwm", offers)
	ok = _assert(scr._manager == "mwm", "manager set") and ok
	ok = _assert(scr._offers.size() == 3, "offers listed") and ok
	ok = _assert(scr._accepted.is_empty(), "nothing accepted on mount") and ok

	# CONTINUE before an accept: no signal (witnessed: the plate is washed).
	scr._on_input(_tap(560, 452))
	ok = _assert(_confirmed_sig == -1, "CONTINUE inert before accept") and ok

	# Row-2 arrow -> popup for that offer, witnessed dim active.
	scr._on_input(_tap(135, 287))
	ok = _assert(scr._popup_i == 1, "arrow opens the club popup") and ok
	var white_dim := scr._dc(Color.WHITE)
	ok = _assert(white_dim.is_equal_approx(Color8(160, 160, 164)),
		"dim LUT maps white to the witnessed 160,160,164") and ok
	# Screen taps outside OK stay inert while modal.
	scr._on_input(_tap(80, 452))
	ok = _assert(_back == 0, "RETURN blocked under the modal") and ok
	scr._on_input(_tap(438, 286))     # OK
	ok = _assert(scr._popup_i == -1, "OK dismisses the popup") and ok
	ok = _assert(scr._dc(Color.WHITE).is_equal_approx(Color.WHITE),
		"no dim once the popup is closed") and ok

	# Brighton row arrow resolves the witnessed 47x59 patch.
	scr.show_popup(0)
	ok = _assert(scr._kit_tex != null and scr._kit_tex.get_size() == Vector2(47, 59),
		"witnessed kit patch resolved for club 107") and ok
	scr.close_popup()

	# Row tap (off the arrow) accepts: slot fills, list empties (frame 05 -> 07).
	scr._on_input(_tap(300, 272))
	ok = _assert(_accepted_sig == 0, "row tap emits offer_accepted") and ok
	ok = _assert(str(scr._accepted.get("team", "")) == "Club 0", "slot filled") and ok
	ok = _assert(scr._offers.is_empty(), "offer list empties on accept") and ok

	# CONTINUE now confirms with the original index.
	scr._on_input(_tap(560, 452))
	ok = _assert(_confirmed_sig == 0, "CONTINUE confirms the accepted offer") and ok

	# RETURN emits back.
	scr._on_input(_tap(80, 452))
	ok = _assert(_back == 1, "RETURN emits back_pressed") and ok

	# Title rule: entry rows keep the name out of the title (frames 03/04/07).
	scr.setup("mwm", [])
	ok = _assert(scr.entry_row == -1 and scr.entry_text == "", "setup clears entry state") and ok

	print("test_offers_selection_screen: %s" % ("ALL OK" if ok else "FAILURES"))
	quit(0 if ok else 1)


func _tap(x: float, y: float) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.pressed = true
	e.position = Vector2(x, y)
	e.button_index = MOUSE_BUTTON_LEFT
	return e


func _assert(cond: bool, what: String) -> bool:
	print("  %s %s" % ["OK " if cond else "FAIL", what])
	return cond
