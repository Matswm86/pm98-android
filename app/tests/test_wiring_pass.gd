extends SceneTree
## Focused check for the screen-wiring pass: mount LeagueTable / Directiva / Stadium,
## fire a synthetic tap on a row / RETURN / empty space, and assert the right signals
## fire (and crucially that empty/no-op taps do NOT dismiss). Headless, no GL needed.

func _ok(c: bool, msg: String) -> void:
	print(("PASS " if c else "FAIL ") + msg)
	if not c:
		_fail = true

var _fail := false

func _initialize() -> void:
	_run()
	quit(1 if _fail else 0)

func _press_at(node: Control, design: Vector2) -> void:
	# Native 640x480 with no parent scaling -> design == screen coords here.
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = design
	node._on_input(e)

func _run() -> void:
	var rows := [
		{"id": 11, "name": "ALPHA", "P": 1, "W": 1, "D": 0, "L": 0, "GF": 2, "GA": 0, "Pts": 3},
		{"id": 22, "name": "BETA",  "P": 1, "W": 0, "D": 0, "L": 1, "GF": 0, "GA": 2, "Pts": 0},
	]

	# --- LEAGUE TABLE: row tap -> club_selected; RETURN -> back; empty -> nothing ---
	var lt: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	lt.size = Vector2(640, 480)
	get_root().add_child(lt)
	lt._ready()
	lt.setup(rows, "ALPHA", "1997-98", "Week 2", 1, 11)
	var got_club := [-1]
	var got_back := [false]
	lt.club_selected.connect(func(id: int) -> void: got_club[0] = id)
	lt.back_pressed.connect(func() -> void: got_back[0] = true)
	# Row 0 sits at y = ROW_Y0 (110); x inside the panel.
	_press_at(lt, Vector2(200, 114))
	_ok(got_club[0] == 11, "league table: row tap emits club_selected(id) (got %d)" % got_club[0])
	_press_at(lt, Vector2(560, 458))      # RETURN_BTN (544,446,90,26)
	_ok(got_back[0], "league table: RETURN emits back_pressed")
	got_back[0] = false
	got_club[0] = -1
	_press_at(lt, Vector2(300, 300))      # empty panel area -> must be a no-op
	_ok(not got_back[0] and got_club[0] == -1, "league table: empty tap is a no-op (no bounce)")
	lt.free()

	# --- DIRECTIVA (board): RETURN -> back; content tap -> nothing ---
	var dv: DirectivaScreen = load("res://scenes/DirectivaScreen.gd").new()
	dv.size = Vector2(640, 480)
	get_root().add_child(dv)
	dv._ready()
	dv.setup("ALPHA", "M", "1997-98", 1000, 50, 50, 50, "obj", "0-0-0", "1st", 2, "Premier")
	var dv_back := [false]
	dv.back_pressed.connect(func() -> void: dv_back[0] = true)
	_press_at(dv, Vector2(100, 250))      # board content -> no-op
	_ok(not dv_back[0], "directiva: content tap is a no-op (no bounce)")
	_press_at(dv, Vector2(577, 446))      # BTN_RETURN (520,432,114,28)
	_ok(dv_back[0], "directiva: RETURN emits back_pressed")
	dv.free()

	# --- STADIUM (ground): empty tap -> no-op; RETURN -> back; WORKS -> works ---
	var st: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	st.size = Vector2(640, 480)
	get_root().add_child(st)
	st._ready()
	st.setup("ALPHA", "M", "1997-98", "Ground", 20000, 12000, 8000, 740, "", 12, 600, 2, "Premier")
	var st_back := [false]
	var st_works := [false]
	st.back_pressed.connect(func() -> void: st_back[0] = true)
	st.works_pressed.connect(func() -> void: st_works[0] = true)
	# Stadium needs a matching press+release (press records target, release fires).
	for ev in [[true, Vector2(100, 100)], [false, Vector2(100, 100)]]:   # empty space
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = ev[0]
		e.position = ev[1]
		st._on_input(e)
	_ok(not st_back[0], "stadium: empty tap is a no-op (no bounce)")
	for ev in [[true, Vector2(552, 452)], [false, Vector2(552, 452)]]:   # BTN_RETURN (470,438,164,28)
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = ev[0]
		e.position = ev[1]
		st._on_input(e)
	_ok(st_back[0], "stadium: RETURN emits back_pressed")
	st.free()

	# --- TRANSFER: RETURN -> back; player-row tap -> no-op (press+release pair) ---
	var tr: TransferScreen = load("res://scenes/TransferScreen.gd").new()
	tr.size = Vector2(640, 480)
	get_root().add_child(tr)
	tr._ready()
	tr.setup([], "ALPHA", "", "1997-98", 1000, "OPEN", 3, 2)
	var tr_back := [false]
	tr.back_pressed.connect(func() -> void: tr_back[0] = true)
	_tap(tr, Vector2(200, 200))            # list area -> no-op
	_ok(not tr_back[0], "transfer: list tap is a no-op (no bounce)")
	_tap(tr, Vector2(572, 452))            # BTN_RETURN (510,440,124,25)
	_ok(tr_back[0], "transfer: RETURN emits back_pressed")
	tr.free()

	# --- LINEUP: RETURN -> back; TACTICS -> tactics_pressed; squad tap -> no-op ---
	var lp: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	lp.size = Vector2(640, 480)
	get_root().add_child(lp)
	lp._ready()
	lp.setup({"players": []}, Tactics.new(), "", "Premier", "1997-98", 2)
	var lp_back := [false]
	var lp_tac := [false]
	lp.back_pressed.connect(func() -> void: lp_back[0] = true)
	lp.tactics_pressed.connect(func() -> void: lp_tac[0] = true)
	_tap(lp, Vector2(100, 200))            # squad list -> no-op
	_ok(not lp_back[0] and not lp_tac[0], "lineup: squad tap is a no-op (no bounce)")
	_tap(lp, Vector2(518, 458))            # BTN_TACTICS (481,448,75,24)
	_ok(lp_tac[0], "lineup: TACTICS emits tactics_pressed")
	_tap(lp, Vector2(595, 458))            # BTN_RETURN (558,448,75,24)
	_ok(lp_back[0], "lineup: RETURN emits back_pressed")
	lp.free()

	# --- FINANCE: RETURN -> back; ledger tap -> no-op ---
	var fn: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	fn.size = Vector2(640, 480)
	get_root().add_child(fn)
	fn._ready()
	fn.setup({}, "ALPHA", "", "1997-98", 1000, 2)
	var fn_back := [false]
	fn.back_pressed.connect(func() -> void: fn_back[0] = true)
	_tap(fn, Vector2(120, 200))            # ledger area -> no-op
	_ok(not fn_back[0], "finance: ledger tap is a no-op (no bounce)")
	_tap(fn, Vector2(577, 445))            # BTN_RETURN (520,432,114,26)
	_ok(fn_back[0], "finance: RETURN emits back_pressed")
	fn.free()

## A full press+release tap at one point (for screens that match press target on release).
func _tap(node: Control, design: Vector2) -> void:
	for p in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = p
		e.position = design
		node._on_input(e)
