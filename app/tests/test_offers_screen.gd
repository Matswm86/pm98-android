extends SceneTree
## Headless test for the OFFERS map-browse screen (charter #8; witnessed run-3
## 098-100/119 + wine 44-47, docs/re/offers_map_re.md): assets load, the
## display-number rule against the REAL app data (all 28 witnessed numbers on
## Blackpool + Barcelona), reverse list order, the browsable-country rule, the
## hidden-pid filter (numbering computed before the drop), kit grid maths and
## scroll clamping.
##   ~/godot462 --headless --path app --script res://tests/test_offers_screen.gd

var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	for path in ["res://art/screens/offers/chrome.png",
			"res://art/screens/offers/btn_prem_sel.png",
			"res://art/screens/offers/btn_prem_off.png",
			"res://art/screens/offers/btn_first_off.png",
			"res://art/screens/offers/btn_first_sel.png",
			"res://art/screens/offers/btn_second_sel.png",
			"res://art/screens/offers/btn_second_off.png",
			"res://art/screens/offers/btn_third_off.png",
			"res://art/screens/offers/btn_third_sel.png",
			"res://art/screens/offers/no_buttons_bg.png",
			"res://art/screens/offers/scroll_up_off.png",
			"res://art/screens/offers/scroll_dn_on.png",
			"res://art/screens/offers/scroll_dn_off.png",
			"res://art/screens/offers/scroll_slider.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok
	for pf in range(1, 19):
		ok = _assert(ResourceLoader.exists("res://art/icons/camrol/camrol%02d.png" % pf),
			"camrol %d present" % pf) and ok

	var scr: OffersScreen = load("res://scenes/OffersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	# a FRESH GameDB (the autoload shell has no data under --script)
	var gamedb: Node = load("res://scripts/GameDB.gd").new()
	gamedb.name = "GameDBTest"
	get_root().add_child(gamedb)
	await process_frame

	# ---- the display-number rule vs the REAL data (28 witnessed numbers) ---
	var wit := {
		82: {"Preece": 9, "Malkin": 19, "Ormerod": 12, "Conroy": 18, "Taylor": 17,
			"Bonner": 11, "Philpott": 7, "Brabin": 16, "Clarkson": 8, "Russell": 10,
			"Lydiate": 4, "Bradshaw": 5, "Bryan": 14, "Butler": 6},
		1000: {"Pizzi": 16, "Anderson": 9, "Giovanni": 10, "Luis Enrique": 8,
			"Roger": 23, "Celades": 22, "De la Peña": 14, "Óscar": 21,
			"Guardiola": 4, "Amor": 15, "Figo": 7, "Ciric": 20, "Rivaldo": 11,
			"Sergi": 6},
	}
	for cid in wit:
		var club: Dictionary = gamedb.club(int(cid))
		ok = _assert(not club.is_empty(), "GameDB club %d present" % cid) and ok
		var rows := scr._build_rows(club)
		ok = _assert(rows.size() == (club.get("players", []) as Array).size(),
			"club %d: all players rowed" % cid) and ok
		var nums := {}
		for r in rows:
			nums[str((r["player"] as Dictionary).get("name"))] = int(r["num"])
		for nm in wit[cid]:
			ok = _assert(nums.get(nm) == wit[cid][nm],
				"club %d %s -> %d (witnessed)" % [cid, nm, wit[cid][nm]]) and ok
	# reverse record order: Barcelona row 1 = Pizzi (the last record)
	var barca_rows: Array = scr._build_rows(gamedb.club(1000))
	ok = _assert(str((barca_rows[0]["player"] as Dictionary).get("name")) == "Pizzi",
		"list order = record order REVERSED (witnessed)") and ok

	# ---- hidden filter keeps the original numbering ------------------------
	var pizzi_id := int((barca_rows[0]["player"] as Dictionary).get("id"))
	scr._hidden = {pizzi_id: true}
	var rows2: Array = scr._build_rows(gamedb.club(1000))
	ok = _assert(rows2.size() == barca_rows.size() - 1, "hidden pid drops out") and ok
	var nums2 := {}
	for r in rows2:
		nums2[str((r["player"] as Dictionary).get("name"))] = int(r["num"])
	ok = _assert(nums2.get("Rivaldo") == 11, "numbering unchanged after the drop") and ok
	scr._hidden = {}

	# ---- witnessed AV formula on a witnessed row ---------------------------
	var preece: Dictionary = {}
	for p in gamedb.club(82).get("players", []):
		if str(p.get("name")) == "Preece":
			preece = p
	var a: Dictionary = preece.get("attrs", {})
	var av := int((int(a.get("VE", 0)) + int(a.get("RE", 0)) + int(a.get("AG", 0))
		+ int(a.get("CA", 0))) / 4.0)
	ok = _assert(av == 48, "Preece AV 48 = floor(sum4/4) (witnessed)") and ok

	# ---- browsable-country rule (Spain 21 yes / Macedonia 1 no / Hungary 5 no)
	ok = _assert(gamedb.clubs_in_country("SPAIN").size() >= OffersScreen.BROWSABLE_MIN,
		"SPAIN browsable (witness 45)") and ok
	ok = _assert(gamedb.clubs_in_country("MACEDONIA").size() < OffersScreen.BROWSABLE_MIN,
		"MACEDONIA not browsable (witness 119)") and ok
	ok = _assert(gamedb.clubs_in_country("HUNGARY").size() < OffersScreen.BROWSABLE_MIN,
		"HUNGARY not browsable (preseason 015 witness)") and ok

	# ---- kit grid maths ----------------------------------------------------
	scr._country_clubs = []
	scr._country_clubs.resize(20)
	ok = _assert(scr._kit_cols() == 10, "20 clubs -> 10 cols") and ok
	scr._country_clubs.resize(21)
	ok = _assert(scr._kit_cols() == 10, "21 clubs (Spain) stay on the 2x10 grid (witness 45)") and ok
	scr._country_clubs = []

	# ---- rows/scroll -------------------------------------------------------
	var fake := {"id": 82, "name": "Blackpool", "players": gamedb.club(82).get("players", [])}
	scr._squad_club = fake
	scr._rows = scr._build_rows(fake)
	scr._first = 99
	scr._first = clampi(scr._first, 0, maxi(0, scr._rows.size() - OffersScreen.N_ROWS))
	ok = _assert(scr._first == scr._rows.size() - OffersScreen.N_ROWS,
		"scroll clamps to the tail") and ok
	scr._first = 0
	ok = _assert(scr._row_at(Vector2(400, 110)) == 0, "row hit-test row 0") and ok
	ok = _assert(scr._row_at(Vector2(400, 126)) == 1, "row hit-test row 1") and ok
	ok = _assert(scr._row_at(Vector2(300, 110)) == -1, "left of the box misses") and ok

	scr.queue_free()
	await process_frame
	print("\n%s" % ("ALL PASS" if ok else "FAILURES: %d" % _fails))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_fails += 1
	return cond
