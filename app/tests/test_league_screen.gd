extends SceneTree
## Headless wiring test for the LEAGUE TABLES screen: confirms the cracked ORIGINAL
## assets (FONDO background, BARRA bar, PROMAN BMFonts) load as real resources and the
## screen accepts a live SeasonSim standings table without error. (Headless can't
## rasterize, so this asserts asset loading + setup wiring, not pixels.)
##   ~/godot462 --headless --path app --script res://tests/test_league_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Real assets must import + load.
	for path in ["res://art/screens/fondo_marble.png", "res://art/screens/barra0.png",
			"res://art/fonts/proman24.fnt", "res://art/fonts/proman18.fnt",
			"res://art/fonts/proman12.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		var res: Resource = load(path)
		ok = _assert(res != null, "asset loads: %s" % path) and ok

	# A real Premier standings table from the engine.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	ok = _assert(prem.size() == 20, "20 Premier clubs (%d)" % prem.size()) and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rows: Array = SeasonSim.simulate_season(rng, prem)["table"]
	ok = _assert(rows.size() == 20, "season table has 20 rows") and ok
	ok = _assert(int(rows[0]["Pts"]) >= int(rows[19]["Pts"]), "table sorted by points") and ok

	# Instantiate the real screen and feed it the live table.
	var screen: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f24 != null and screen._f18 != null and screen._f12 != null,
		"PROMAN fonts loaded into screen") and ok
	ok = _assert(screen._bg != null and screen._bar != null, "background + bar textures loaded") and ok
	screen.setup(rows, prem[0]["name"], db.get("meta", {}).get("season", "1997-98"),
		"Week 38", 1, int(prem[0]["id"]))
	await process_frame
	ok = _assert(screen._rows.size() == 20, "screen received 20 standings rows") and ok

	# Real club kits (extracted from MINIESC.PKF, id-named) must load for every row.
	var kits_ok := true
	for c in prem:
		var id := int(c["id"])
		var kpath := "res://art/kits/%d.png" % id
		kits_ok = kits_ok and ResourceLoader.exists(kpath) and screen._kit(id) != null
	ok = _assert(kits_ok, "all 20 Premier club kits load (res://art/kits/<id>.png)") and ok
	ok = _assert(screen._kit(-1) == null, "missing-kit id resolves to null (no crash)") and ok

	# Force a paint pass (RenderingServer is the dummy driver headless, but _draw
	# running without error still catches null-deref / API-misuse bugs).
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
