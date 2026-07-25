extends SceneTree
## Headless wiring test for the LINE-UP (ALINEACIÓN) screen after the frame-baked
## body rebuild (build_lineup_chrome_from_frames.py): confirms the baked chrome +
## row templates + band strips + star/marker sprites load, that a real club +
## auto-picked Tactics XI feed the screen without error, that the formation ->
## pitch marker mapping (raw*148/318, *88/198 + (4,3)) stays on the 152x92 CAMPO,
## and that the variable-height scroll model (16px rows + 23/22px section bands)
## pages and hit-tests correctly.
## (Headless can't rasterize; parity itself is shot_entry_parity + diff_entry_parity.)
##   ~/godot462 --headless --path app --script res://tests/test_lineup_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# The baked assets must import + load.
	for path in ["res://art/screens/lineup/chrome.png", "res://art/screens/lineup/campo.png",
			"res://art/screens/lineup/row_gk.png", "res://art/screens/lineup/row_def.png",
			"res://art/screens/lineup/row_mid.png", "res://art/screens/lineup/row_fwd.png",
			"res://art/screens/lineup/row_inj.png", "res://art/screens/lineup/row_sub.png",
			"res://art/screens/lineup/row_res.png", "res://art/screens/lineup/band_subs.png",
			"res://art/screens/lineup/band_res.png", "res://art/screens/lineup/plate_tis.png",
			"res://art/screens/lineup/attr_plate.png", "res://art/icons/lineup/dverde.png",
			"res://art/icons/lineup/dblanco.png", "res://art/fonts/proman10.fnt",
			"res://art/fonts/proman8.fnt", "res://data/lineup_chrome_samples.json"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	# A real club with a full squad from the shipped game database.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var club: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem" and (c.get("players", []) as Array).size() >= 14:
			club = c
			break
	ok = _assert(not club.is_empty(), "found a Premier club with a full squad") and ok

	var t := Tactics.auto_pick(club, "4-4-2")
	ok = _assert(t.xi.size() == 11, "auto-pick fills 11 (%d)" % t.xi.size()) and ok
	ok = _assert(t.validate(club) == "", "auto-picked XI is valid") and ok

	var screen: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._chrome != null and screen._campo_img != null,
		"baked chrome + CAMPO image loaded") and ok
	# 8 since the SUSPENDED row (row_ban: two yellow cards + MATCHES) joined the
	# INJURED one -- docs/re/lineup_screen_re.md.
	ok = _assert(screen._rows.size() == 8, "all 8 row templates loaded") and ok
	ok = _assert(screen._rows.get("ban") != null, "the suspended-row template loaded") and ok
	screen.setup(club, t, "", "Premier")
	await process_frame
	ok = _assert(screen._by_id.size() == (club["players"] as Array).size(),
		"screen indexed the full roster") and ok

	# Marker mapping: every formation slot's disc + arrow land on the CAMPO.
	var inside := true
	for form in Tactics.FORMATION_ORDER:
		var rec: Variant = screen._forms.get(form)
		ok = _assert(rec is Dictionary, "%s in formations.json" % form) and ok
		for s in (rec as Dictionary).get("slots", []):
			var raw: Array = (s as Dictionary).get("raw", [])
			for k in [[4, 5], [6, 7]]:
				var m: Vector2i = screen._mkmap(int(raw[k[0]]), int(raw[k[1]]))
				inside = inside and m.x >= 0 and m.x <= 152 - 10 and m.y >= 0 and m.y <= 92 - 10
	ok = _assert(inside, "every formation marker maps inside the 152x92 CAMPO") and ok

	# The pitch composite renders (campo-sized texture) with and without selection.
	var tex := screen._compose_pitch("4-4-2", -1)
	ok = _assert(tex != null and tex.get_width() == 152 and tex.get_height() == 92,
		"pitch composite is CAMPO-sized") and ok
	var tex2 := screen._compose_pitch("3-5-2", 9)
	ok = _assert(tex2 != null, "walked-zone composite (3-5-2 slot 9) renders") and ok
	var tex3 := screen._compose_pitch("5-3-2", 3)
	ok = _assert(tex3 != null, "un-walked-zone composite (LUT dim) renders") and ok

	# ---- variable-height scroll model (16px rows + 23/22px bands) -----------
	screen.size = Vector2(640, 480)
	var big := _synth_club(28)
	var tb := Tactics.new()
	tb.formation = "4-4-2"
	tb.xi = range(1, 12)            # ids 1..11 are the XI
	screen.setup(big, tb, "", "Premier")
	ok = _assert(screen._flat_items().size() == 30, "flat list = 28 rows + 2 bands") and ok
	# 378px pane: 11 rows + band(23) + 5 rows + band(22) + 4 reserves = 22 items
	ok = _assert(screen._layout(0).size() == 22, "layout fits 22 of 30 items (%d)"
		% screen._layout(0).size()) and ok
	ok = _assert(screen._max_scroll() == 8, "max scroll = 8 (%d)" % screen._max_scroll()) and ok
	ok = _assert(screen._scroll == 0, "setup resets scroll to top") and ok
	screen._scroll = 999
	screen._clamp_scroll()
	ok = _assert(screen._scroll == 8, "scroll clamps to max") and ok
	screen._scroll = -5
	screen._clamp_scroll()
	ok = _assert(screen._scroll == 0, "scroll clamps to top") and ok
	# Hit-test: both arrows live while overflowing (frame-walked rects).
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "down", "down arrow hit-tests") and ok
	ok = _assert(screen._hit(SCROLL_UP_C) == "up", "up arrow hit-tests") and ok
	var dismissed := [false]
	screen.back_pressed.connect(func() -> void: dismissed[0] = true)
	_tap(screen, SCROLL_DOWN_C)
	ok = _assert(screen._scroll == 3 and not dismissed[0], "down tap pages by step, consumed") and ok
	_tap(screen, SCROLL_UP_C)
	ok = _assert(screen._scroll == 0 and not dismissed[0], "up tap pages back, consumed") and ok
	# A tap on a player row selects him; RETURN dismisses.
	_tap(screen, Vector2(60, 200))
	ok = _assert(not dismissed[0] and screen._sel_pid >= 0, "row tap selects, does not dismiss") and ok
	_tap(screen, Vector2(595, 460))     # BTN_RETURN centre
	ok = _assert(dismissed[0], "RETURN tap emits back_pressed") and ok
	# A squad that fits (16 players -> 18 items) shows no arrows.
	var small := _synth_club(16)
	screen.setup(small, tb, "", "Premier")
	ok = _assert(screen._flat_items().size() == 18, "small squad = 16 rows + 2 bands") and ok
	ok = _assert(screen._max_scroll() == 0, "small squad does not overflow") and ok
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "", "no arrow hit when list fits") and ok

	# ---- toggle + UNDO state machine -----------------------------------------
	screen.setup(club, t, "", "Premier")
	ok = _assert(screen._rating_view, "RATING view is the default (chrome state)") and ok
	_tap(screen, Vector2(555, 79))      # PARAMETERS toggle
	ok = _assert(not screen._rating_view, "PARAMETERS tap flips the numeric view") and ok
	_tap(screen, Vector2(555, 103))     # RATING toggle
	ok = _assert(screen._rating_view, "RATING tap flips back") and ok
	ok = _assert(not screen._pending_change(), "fresh line-up has no pending change") and ok
	var xi0: Array = t.xi.duplicate()
	var bench_pid := -1
	for it in screen._flat_items():
		if it.get("t") == "row" and not t.xi.has(int(it["pid"])):
			var pd: Dictionary = screen._by_id[int(it["pid"])]
			if not bool(pd.get("isGK", false)):
				bench_pid = int(it["pid"])
				break
	screen._try_swap(bench_pid, int(t.xi[5]))
	ok = _assert(screen._pending_change(), "an XI edit arms UNDO") and ok
	screen._undo()
	ok = _assert(t.xi == xi0 and not screen._pending_change(), "UNDO restores the entry XI") and ok
	# an injured starter forces the pending state (frame 155's walked trigger)
	var inj: Dictionary = screen._by_id[int(t.xi[3])]
	inj["injured_weeks"] = 7
	ok = _assert(screen._pending_change(), "an injured starter arms UNDO") and ok
	# while UNDO owns the plate the T/I/S buttons are inert (no double-binding)
	ok = _assert(screen._hit(Vector2(555, 365)) == "undo", "pending state: plate is UNDO") and ok
	inj.erase("injured_weeks")

	# ---- T/I/S plate -> the three sub-screen signals -------------------------
	screen.setup(club, t, "", "Premier")
	ok = _assert(not screen._pending_change(), "fresh line-up shows the T/I/S plate") and ok
	ok = _assert(screen._hit(Vector2(555, 365)) == "training", "TRAINING row hit-tests") and ok
	ok = _assert(screen._hit(Vector2(555, 393)) == "injuries", "INJURIES row hit-tests") and ok
	ok = _assert(screen._hit(Vector2(555, 421)) == "statistics", "STATISTICS row hit-tests") and ok
	var tis := {"tr": false, "in": false, "st": false}
	screen.training_pressed.connect(func() -> void: tis["tr"] = true)
	screen.injuries_pressed.connect(func() -> void: tis["in"] = true)
	screen.statistics_pressed.connect(func() -> void: tis["st"] = true)
	_tap(screen, Vector2(555, 365))
	_tap(screen, Vector2(555, 393))
	_tap(screen, Vector2(555, 421))
	ok = _assert(tis["tr"] and tis["in"] and tis["st"], "each T/I/S row emits its signal") and ok

	# Force a paint pass (catches null-deref / API misuse even with the dummy driver).
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


const SCROLL_UP_C := Vector2(443 + 8, 388 + 8)    # centre of LineupScreen.SCROLL_UP
const SCROLL_DOWN_C := Vector2(443 + 8, 434 + 8)  # centre of LineupScreen.SCROLL_DOWN


## A synthetic N-man squad (player 1 a keeper, the rest outfield) with decoded attrs so
## the AV fallback / the row renderer have real numbers; ids are 1..N.
func _synth_club(n: int) -> Dictionary:
	var players: Array = []
	for i in n:
		var gk := i == 0
		players.append({
			"id": i + 1, "name": "P%d" % (i + 1), "isGK": gk,
			"pos": "GK" if gk else "OUT", "posFine": 1 if gk else 7,
			"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
				"PA": 70, "TI": 70, "EN": 70, "PO": 78 if gk else 12},
		})
	return {"id": 1, "name": "SYNTH FC", "players": players}


## Synthesize a press+release tap at a design-space point through the screen's own handler.
func _tap(screen: LineupScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	screen._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
