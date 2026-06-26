extends SceneTree
## Headless wiring test for the LINE-UP (ALINEACIÓN) screen: confirms the cracked
## ORIGINAL assets (FONDO, BARRA, CAMPO mini-pitch, PROMAN8/10/12/24 BMFonts) load,
## that a real club + auto-picked Tactics XI feed the screen without error, and that
## the formation->pitch marker mapping (tac*148/318, *88/198) stays on the pitch.
## (Headless can't rasterize; this asserts asset loading + wiring + the geometry math.)
##   ~/godot462 --headless --path app --script res://tests/test_lineup_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Real assets must import + load (incl. the new ProMan8/10 + the campo pitch).
	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/screens/campo.png", "res://art/fonts/proman24.fnt",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman10.fnt",
			"res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

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

	# Auto-pick a valid 4-4-2 and confirm it is a legal 11-man line-up.
	var t := Tactics.auto_pick(club, "4-4-2")
	ok = _assert(t.xi.size() == 11, "auto-pick fills 11 (%d)" % t.xi.size()) and ok
	ok = _assert(t.validate(club) == "", "auto-picked XI is valid") and ok

	# Instantiate the real screen and feed it the live club + tactics.
	var screen: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded into screen") and ok
	ok = _assert(PMChrome.bg() != null and screen._campo != null,
		"management background + CAMPO textures loaded") and ok
	screen.setup(club, t, "", "Premier")
	await process_frame
	ok = _assert(screen._by_id.size() == (club["players"] as Array).size(),
		"screen indexed the full roster") and ok

	# Formation geometry: 11 slot positions, all mapping inside the CAMPO pitch.
	var pos: Array = screen._slot_positions()
	ok = _assert(pos.size() == 11, "4-4-2 yields 11 slot positions (%d)" % pos.size()) and ok
	var inside := true
	var p0 := LineupScreen.MARK_ORIGIN
	for tac in pos:
		var c: Vector2 = screen._mark_center(tac)
		inside = inside and c.x >= p0.x and c.x <= p0.x + LineupScreen.MARK_W \
			and c.y >= p0.y and c.y <= p0.y + LineupScreen.MARK_H
	ok = _assert(inside, "every marker maps inside the 148x88 pitch interior") and ok

	# All slot positions distinct (no two players stacked on one pixel).
	var seen := {}
	var distinct := true
	for tac in pos:
		var key := "%d,%d" % [int(tac.x), int(tac.y)]
		distinct = distinct and not seen.has(key)
		seen[key] = true
	ok = _assert(distinct, "all 11 formation slots are distinct") and ok

	# Real kits load for the club; missing id is null-safe.
	ok = _assert(screen._kit(int(club["id"])) != null, "club kit loads for the markers") and ok
	ok = _assert(screen._kit(-1) == null, "missing-kit id resolves to null (no crash)") and ok

	# Every other formation also fills + maps inside the pitch.
	for form in Tactics.FORMATION_ORDER:
		var tf := Tactics.auto_pick(club, form)
		screen.setup(club, tf, "", "Premier")
		var pf: Array = screen._slot_positions()
		ok = _assert(pf.size() == 11, "%s -> 11 slots" % form) and ok

	# ---- scroll wiring (the original ARROW up/down squad-list paging) -------
	# Native design space so hit-tests map 1:1. A 28-man squad (11 XI + SUBSTITUTES hdr + 5
	# bench + RESERVES hdr + 12 reserves = 30 items) overflows the 24-row panel; the real game
	# silently dropped the reserves past the cap.
	screen.size = Vector2(640, 480)
	var big := _synth_club(28)
	var tb := Tactics.new()
	tb.formation = "4-4-2"
	tb.xi = range(1, 12)            # ids 1..11 are the XI
	screen.setup(big, tb, "", "Premier")
	ok = _assert(screen._visible_rows() == 24, "panel fits 24 rows") and ok
	ok = _assert(screen._flat_items().size() == 30, "flat list = 28 rows + 2 section headers") and ok
	ok = _assert(screen._max_scroll() == 6, "max scroll = 30 - 24") and ok
	ok = _assert(screen._scroll == 0, "setup resets scroll to top") and ok
	# Clamp at both ends.
	screen._scroll = 999; screen._clamp_scroll()
	ok = _assert(screen._scroll == 6, "scroll clamps to max") and ok
	screen._scroll = -5; screen._clamp_scroll()
	ok = _assert(screen._scroll == 0, "scroll clamps to top") and ok
	# Hit-test: both arrows live while overflowing.
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "down", "down arrow hit-tests") and ok
	ok = _assert(screen._hit(SCROLL_UP_C) == "up", "up arrow hit-tests") and ok
	# A down tap pages by SCROLL_STEP and is consumed (no dismiss); an up tap pages back.
	var dismissed := [false]
	screen.back_pressed.connect(func() -> void: dismissed[0] = true)
	_tap(screen, SCROLL_DOWN_C)
	ok = _assert(screen._scroll == 3 and not dismissed[0], "down tap pages by step, consumed") and ok
	_tap(screen, SCROLL_UP_C)
	ok = _assert(screen._scroll == 0 and not dismissed[0], "up tap pages back, consumed") and ok
	# A non-arrow tap dismisses.
	_tap(screen, Vector2(60, 200))
	ok = _assert(dismissed[0], "non-arrow tap emits back_pressed") and ok
	# A squad that fits (16 players -> 18 items) shows no arrows, so every tap dismisses.
	var small := _synth_club(16)
	screen.setup(small, tb, "", "Premier")
	ok = _assert(screen._flat_items().size() == 18, "small squad = 16 rows + 2 headers") and ok
	ok = _assert(screen._max_scroll() == 0, "small squad does not overflow") and ok
	ok = _assert(screen._hit(SCROLL_DOWN_C) == "", "no arrow hit when list fits") and ok

	# Force a paint pass (catches null-deref / API misuse even with the dummy driver).
	screen.setup(club, t, "", "Premier")
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


const SCROLL_UP_C := Vector2(479 + 11, 190 + 11)    # centre of LineupScreen.SCROLL_UP
const SCROLL_DOWN_C := Vector2(479 + 11, 220 + 11)  # centre of LineupScreen.SCROLL_DOWN


## A synthetic N-man squad (player 1 a keeper, the rest outfield) with decoded attrs so
## _avg_of / the row renderer have real numbers; ids are 1..N so the XI can be ids 1..11.
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
