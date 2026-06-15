extends SceneTree
## Headless wiring test for the SQUAD MANAGEMENT (PLANTILLA) screen: confirms the
## cracked ORIGINAL assets (FONDO, BARRA, PROMAN8/10/12/14 BMFonts) load, that a real
## club feeds the screen without error, and that the roster sections (goalkeepers /
## outfield) cover the whole squad with no player dropped or duplicated.
##   ~/godot462 --headless --path app --script res://tests/test_squad_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/fonts/proman14.fnt", "res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

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

	var screen: SquadScreen = load("res://scenes/SquadScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f14 != null and screen._f12 != null and screen._f10 != null
		and screen._f8 != null, "PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._bg != null and screen._bar != null, "FONDO + BARRA loaded") and ok
	screen.setup(club, "", "£10,000,000")
	await process_frame

	# Sections partition the squad: GK + outfield = the full roster, no dup/drop.
	var secs: Array = screen._sections()
	ok = _assert(secs.size() == 2, "two sections (GK / outfield)") and ok
	var total := 0
	var seen := {}
	var dup := false
	for sec in secs:
		for p in sec["players"]:
			total += 1
			var pid := int(p.get("id", -1))
			dup = dup or seen.has(pid)
			seen[pid] = true
	ok = _assert(total == (club["players"] as Array).size(),
		"sections cover all %d players (got %d)" % [(club["players"] as Array).size(), total]) and ok
	ok = _assert(not dup, "no player appears in two sections") and ok
	var gk_all_keepers := true
	for p in secs[0]["players"]:
		gk_all_keepers = gk_all_keepers and bool(p.get("isGK"))
	ok = _assert(gk_all_keepers, "GOALKEEPERS section holds only keepers") and ok

	# Sorted by ability within the outfield section (descending average).
	var sorted_ok := true
	var prev := 999
	for p in secs[1]["players"]:
		var a := screen._avg_of(p)
		sorted_ok = sorted_ok and a <= prev
		prev = a
	ok = _assert(sorted_ok, "outfield sorted by ability descending") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
