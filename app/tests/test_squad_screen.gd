extends SceneTree
## Headless wiring test for the SQUAD MANAGEMENT (PLANTILLA) screen: confirms the
## cracked ORIGINAL assets (FONDO, BARRA, PROMAN8/10/12/14 BMFonts) load, that a real
## club feeds the screen without error, and that the decoded position sections
## (GK/DF/MF/FW) cover the whole squad with no player dropped or duplicated.
##   ~/godot462 --headless --path app --script res://tests/test_squad_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/management_bg.png",
			"res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	# Man Utd (id 40): the club walkthrough frame 077_154612 verifies, so its decoded
	# squad numbers + display order can be asserted against the real screen.
	var club: Dictionary = {}
	for c in db.get("clubs", []):
		if int(c.get("id", -1)) == 40:
			club = c
			break
	ok = _assert(not club.is_empty() and (club.get("players", []) as Array).size() >= 14,
		"found Man Utd (id 40) with a full squad") and ok

	var screen: SquadScreen = load("res://scenes/SquadScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null and screen._f8 != null,
		"PROMAN fonts loaded into screen") and ok
	ok = _assert(PMChrome.bg() != null, "PMChrome management background loads") and ok
	screen.setup(club, "", "£10,000,000")
	await process_frame
	ok = _assert(screen._kit_tex != null, "club kit (escudo) loaded for the squad screen") and ok

	# Sections partition the squad by the decoded demarcación (GK/DF/MF/FW): every
	# label valid, the union = the full roster with no dup/drop, and each section in
	# REVERSE roster order (frame 077: the original lists every group file-reversed).
	# Name literals = the exact-cipher mixed case (2026-07-06 game_db rebuild).
	var secs: Array = screen._sections()
	var valid_labels := ["KEEPERS", "DEFENDERS", "MIDFIELDERS", "FORWARDS", "OUTFIELD"]
	ok = _assert(secs.size() >= 3, "at least three position sections (got %d)" % secs.size()) and ok
	ok = _assert(secs[0]["section"] == "KEEPERS", "first section is KEEPERS") and ok
	var total := 0
	var seen := {}
	var dup := false
	var labels_ok := true
	for sec in secs:
		labels_ok = labels_ok and valid_labels.has(str(sec["section"]))
		for p in sec["players"]:
			total += 1
			var pid := int(p.get("id", -1))
			dup = dup or seen.has(pid)
			seen[pid] = true
	ok = _assert(labels_ok, "every section carries a valid position label") and ok
	ok = _assert(total == (club["players"] as Array).size(),
		"sections cover all %d players (got %d)" % [(club["players"] as Array).size(), total]) and ok
	ok = _assert(not dup, "no player appears in two sections") and ok
	var gk_all_keepers := true
	for p in secs[0]["players"]:
		gk_all_keepers = gk_all_keepers and screen._pos_of(p) == "GK"
	ok = _assert(gk_all_keepers, "GOALKEEPERS section holds only keepers") and ok

	# Reverse-roster order = the frame-077 display order. Man Utd truth (visible rows):
	# KEEPERS Schmeichel,Van der Gouw · MID Beckham,Scholes,Giggs,Keane,Butt,McClair ·
	# FWD Cole,Jordi Cruyff,Solskjaer,Sheringham,Nevland.
	var by_key := {}
	for sec in secs:
		by_key[str(sec["key"])] = sec["players"]
	var gk_names: Array = (by_key.get("GK", []) as Array).map(func(p): return str(p["name"]))
	var mf_names: Array = (by_key.get("MF", []) as Array).map(func(p): return str(p["name"]))
	var fw_names: Array = (by_key.get("FW", []) as Array).map(func(p): return str(p["name"]))
	ok = _assert(gk_names.slice(0, 2) == ["Schmeichel", "Van der Gouw"],
		"KEEPERS order matches frame 077 (%s)" % str(gk_names.slice(0, 2))) and ok
	ok = _assert(mf_names.slice(0, 6) == ["Beckham", "Scholes", "Giggs", "Keane", "Butt", "McClair"],
		"MIDFIELDERS order matches frame 077 (%s)" % str(mf_names.slice(0, 6))) and ok
	ok = _assert(fw_names.slice(0, 5) == ["Cole", "Jordi Cruyff", "Solskjaer", "Sheringham", "Nevland"],
		"FORWARDS order matches frame 077 (%s)" % str(fw_names.slice(0, 5))) and ok

	# Decoded squad numbers (EQUIPOS byte after the photo-id u16): frame-077 truth.
	ok = _assert(screen._nos_ok, "Man Utd squad numbers are individuated -> N° shown") and ok
	var no_by_name := {}
	for p in club.get("players", []):
		no_by_name[str(p["name"])] = p.get("squadNo")
	for pair in [["Schmeichel", 1], ["Gary Neville", 2], ["Beckham", 7], ["Giggs", 11],
			["Keane", 16], ["Van der Gouw", 17], ["Solskjaer", 20], ["Berg", 21]]:
		ok = _assert(int(no_by_name.get(pair[0], -1)) == int(pair[1]),
			"squadNo %s = %d" % [pair[0], pair[1]]) and ok

	# WAGE column formatter matches the frame's "£1,000,000" style.
	ok = _assert(screen._money(1000000) == "1,000,000", "money formatter groups thousands") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
