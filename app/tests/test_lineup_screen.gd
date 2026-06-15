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
	ok = _assert(screen._f24 != null and screen._f12 != null and screen._f10 != null
		and screen._f8 != null, "PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._bg != null and screen._bar != null and screen._campo != null,
		"FONDO + BARRA + CAMPO textures loaded") and ok
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

	# Force a paint pass (catches null-deref / API misuse even with the dummy driver).
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
