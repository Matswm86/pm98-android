extends SceneTree
## Headless test for THE FINES (MULTAS) — the model (`Fines`), the exported art and the
## card (`FinesScreen`).
##
## Everything asserted here is a number read out of MANAGER.EXE, not a tuned figure:
## the three competition arms and their thresholds (`FUN_0057a980` @0x57ab85..0x57ad6a),
## the internal amounts (which are also the float32 immediates the debit pushes), the
## 200-internal-per-pound conversion, the competition-index bounds that make the three
## lower divisions / the Coca-Cola Cup / the Charity Shield fine nothing, the card's
## geometry (`FUN_00549d40` / `FUN_00549fe0`), and the two sizes at which the archive and
## the disassembly agree independently (418x316 panel, 40x26 icon).
##
##   ~/godot462 --headless --path app --script res://tests/test_fines.gd

const G0 := [2, 0, 1, 2, 1, 1, 0, 2, 2]   # GroundPreset 0 = Man Utd's witnessed grades
const G3 := [0, 0, 0, 0, 0, 0, 0, 0, 0]   # preset 2/3 = a Third Division ground


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	# ---- the art is the ORIGINAL's own files, and both sizes cross-check ----------
	for n in ["panel", "multa", "icon_floodlights", "icon_changing_rooms",
			"icon_score_board", "icon_access", "icon_medical"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/fines/%s.png" % n),
			"art present: %s.png" % n) and ok
	var panel: Texture2D = load("res://art/screens/fines/panel.png")
	ok = _assert(panel.get_size() == Vector2(418, 316),
		"MULTAS\\FONDO.BMP is 418x316 = the binary's own panel CRect") and ok
	ok = _assert(Vector2i(panel.get_size()) == FinesScreen.PANEL_SIZE,
		"the scene's panel size IS the archive entry's size") and ok
	var ic: Texture2D = load("res://art/screens/fines/icon_floodlights.png")
	ok = _assert(ic.get_size() == Vector2(40, 26),
		"ESTADIO\\EQUIPAM_0.BMP is 40x26 = the binary's own icon CRect") and ok
	ok = _assert(Vector2i(ic.get_size()) == FinesScreen.ICON_SIZE,
		"the scene's icon rect IS the archive entry's size") and ok
	var multa: Texture2D = load("res://art/screens/fines/multa.png")
	ok = _assert(multa.get_size() == Vector2(54, 58),
		"MULTA.GIF is 54x58 = the empty-string CRect it is blitted into") and ok

	# ---- the competition index, and the arms that hang off it ---------------------
	ok = _assert(Fines.comp_index("league", "eng_prem") == 0, "Premier -> index 0") and ok
	ok = _assert(Fines.comp_index("league", "eng_div1") == 1, "First -> index 1") and ok
	ok = _assert(Fines.comp_index("fa_cup", "eng_prem") == 4, "F.A. Cup -> index 4") and ok
	ok = _assert(Fines.comp_index("coca_cola", "eng_prem") == 5, "Coca-Cola -> index 5") and ok
	ok = _assert(Fines.comp_index("charity_shield", "eng_prem") == 6,
		"Charity Shield -> index 6") and ok
	ok = _assert(Fines.comp_index("uefa_cup", "eng_prem") == 7, "U.E.F.A. -> index 7") and ok
	ok = _assert(Fines.comp_index("intercontinental", "eng_prem") == 11,
		"Intercontinental -> index 11") and ok

	# The three lower divisions, the Coca-Cola Cup and the Charity Shield are OUTSIDE
	# {0} u {4} u {7..11}. That they fine nothing is a RESULT of the jb/ja bounds.
	for pair in [["league", "eng_div1"], ["league", "eng_div2"], ["league", "eng_div3"],
			["coca_cola", "eng_prem"], ["charity_shield", "eng_prem"]]:
		ok = _assert(Fines.arm_for(str(pair[0]), str(pair[1])).is_empty(),
			"%s (%s) fines nothing" % [pair[0], pair[1]]) and ok
	ok = _assert(Fines.arm_for("league", "eng_prem") == Fines.ARM_PREMIER,
		"a Premier league match takes the PREMIER arm") and ok
	ok = _assert(Fines.arm_for("fa_cup", "eng_prem") == Fines.ARM_FA_CUP,
		"an F.A. Cup tie takes the F.A. CUP arm") and ok
	for k in Fines.EUROPE_KEYS:
		ok = _assert(Fines.arm_for(str(k), "eng_prem") == Fines.ARM_EUROPE,
			"%s takes the shared EUROPE arm" % k) and ok

	# ---- the amounts ARE the imm32s, read two ways --------------------------------
	ok = _assert(FinanceModel.MONEY_PER_POUND == 200,
		"the engine's money unit is 200 internal per pound") and ok
	var expect := {
		"premier": {"floodlights": [2, 5_000_000], "changing_rooms": [1, 5_000_000],
			"score_board": [1, 5_000_000], "access": [1, 10_000_000],
			"medical": [1, 10_000_000]},
		"europe": {"floodlights": [2, 10_000_000], "changing_rooms": [1, 10_000_000],
			"score_board": [1, 10_000_000], "access": [1, 15_000_000],
			"medical": [1, 15_000_000]},
	}
	for id in expect["premier"]:
		var e: Array = expect["premier"][id]
		var got: Dictionary = Fines.ARM_PREMIER[id]
		ok = _assert(int(got["min"]) == int(e[0]) and int(got["internal"]) == int(e[1]),
			"PREMIER %s: grade >= %d else %d internal" % [id, e[0], e[1]]) and ok
	for id in expect["europe"]:
		var e2: Array = expect["europe"][id]
		var got2: Dictionary = Fines.ARM_EUROPE[id]
		ok = _assert(int(got2["min"]) == int(e2[0]) and int(got2["internal"]) == int(e2[1]),
			"EUROPE %s: grade >= %d else %d internal" % [id, e2[0], e2[1]]) and ok
	ok = _assert(Fines.ARM_FA_CUP.size() == 1
		and int(Fines.ARM_FA_CUP["floodlights"]["min"]) == 1
		and int(Fines.ARM_FA_CUP["floodlights"]["internal"]) == 3_000_000,
		"the F.A. CUP arm tests ONLY floodlights, grade >= 1, 3,000,000 internal") and ok
	# Every internal amount divides exactly by 200, and the £ figure is that quotient.
	for arm in [Fines.ARM_PREMIER, Fines.ARM_FA_CUP, Fines.ARM_EUROPE]:
		for id in arm:
			var raw := int((arm[id] as Dictionary)["internal"])
			ok = _assert(raw % 200 == 0, "%s imm32 %d divides by 200" % [id, raw]) and ok

	# ---- a real ground, evaluated ------------------------------------------------
	# Man Utd's preset 0 clears every standard in every arm -> no card, which is why five
	# driven careers never saw one.
	var manutd := func(cat: String, key: int) -> int:
		return int(G0[key + (5 if cat == "services" else 0)])
	for k2 in ["league", "fa_cup", "european_cup"]:
		ok = _assert(Fines.for_match(str(k2), "eng_prem", manutd).is_empty(),
			"preset 0 (Man Utd) is fined nothing in %s" % k2) and ok

	# A bare Third Division ground promoted into the Premier collects all five.
	var bare := func(cat: String, key: int) -> int:
		return int(G3[key + (5 if cat == "services" else 0)])
	var rows := Fines.for_match("league", "eng_prem", bare)
	ok = _assert(rows.size() == 5, "a bare ground collects all five Premier fines") and ok
	var total := 0
	for r in rows:
		total += int((r as Dictionary)["pounds"])
	ok = _assert(total == 25_000 + 25_000 + 25_000 + 50_000 + 50_000,
		"the five Premier fines total £175,000 (got £%d)" % total) and ok
	ok = _assert(str((rows[0] as Dictionary)["message"]).begins_with(
		"You have been fined £25,000 because you don"),
		"the message is MANAGER.EXE's own @0x65E5AC, with the £ figure formatted") and ok
	ok = _assert(str((rows[0] as Dictionary)["message"]).contains(
		"the floodlights needed to play"),
		"the floodlights line carries the binary's own noun phrase") and ok
	ok = _assert(str((rows[4] as Dictionary)["message"]).contains(
		"the medical equipment needed to play"),
		"the medical line carries the binary's own noun phrase") and ok
	# The same ground in Europe pays the bigger tariff.
	var euro_rows := Fines.for_match("european_cup", "eng_prem", bare)
	var euro_total := 0
	for r2 in euro_rows:
		euro_total += int((r2 as Dictionary)["pounds"])
	ok = _assert(euro_total == 50_000 * 3 + 75_000 * 2,
		"the five European fines total £300,000 (got £%d)" % euro_total) and ok
	# And in the F.A. Cup it is one fine, floodlights only.
	var fa := Fines.for_match("fa_cup", "eng_prem", bare)
	ok = _assert(fa.size() == 1 and int((fa[0] as Dictionary)["pounds"]) == 15_000,
		"an F.A. Cup tie on a bare ground is ONE £15,000 floodlight fine") and ok
	# A ground with floodlights at grade 1 still fails the Premier's >= 2 but passes the
	# F.A. Cup's >= 1 -- the one place the two thresholds differ.
	var g1 := func(cat: String, key: int) -> int:
		return 1
	ok = _assert(Fines.for_match("fa_cup", "eng_prem", g1).is_empty(),
		"floodlights grade 1 clears the F.A. Cup") and ok
	var p1 := Fines.for_match("league", "eng_prem", g1)
	ok = _assert(p1.size() == 1 and str((p1[0] as Dictionary)["id"]) == "floodlights",
		"floodlights grade 1 still fails the Premier's >= 2") and ok

	# ---- Career's own read: completed works CLEAR the fine (2026-08-26 regression) ----
	# The override ledger keys are begin_work's cats — "facility"/"service", SINGULAR. The
	# fine read used the plural and missed every completed upgrade, so a Third Division
	# club that BUILT floodlights kept paying the £15,000 F.A. Cup fine forever.
	var c := Career.new()
	c.league_id = "eng_div3"
	c.ground_seed = GroundPreset.grades_for_league(c.league_id)
	var pre := Fines.for_match("fa_cup", c.league_id, c._fine_grade_of)
	ok = _assert(pre.size() == 1 and int((pre[0] as Dictionary)["pounds"]) == 15_000,
		"an unimproved Third Division ground pays the F.A. Cup floodlight fine") and ok
	c._complete_work({"cat": "facility", "key": 0, "label": "FLOODLIGHTS",
		"effect": {"grade": 1}})
	ok = _assert(Fines.for_match("fa_cup", c.league_id, c._fine_grade_of).is_empty(),
		"BUILT floodlights clear the F.A. Cup fine (the plural-key read missed them)") and ok
	# Promotion must NOT re-seed the ground from the new division's preset: with the
	# career now in the Premier, the un-upgraded items still read their Third Division
	# zeros (four fines) and the built grade-1 floodlights still fail the >= 2 bar.
	c.league_id = "eng_prem"
	ok = _assert(Fines.for_match("league", c.league_id, c._fine_grade_of).size() == 5,
		"a promoted club keeps its own ground, not the new division's preset") and ok
	c._complete_work({"cat": "service", "key": 0, "label": "SICKROOM",
		"effect": {"grade": 1}})
	ok = _assert(Fines.for_match("league", c.league_id, c._fine_grade_of).size() == 4,
		"a completed SERVICE work (medical) clears its Premier fine too") and ok

	# ---- the card ----------------------------------------------------------------
	ok = _assert(FinesScreen.PANEL == Vector2i(111, 82),
		"panel origin (111,82) = FUN_00436fb0(0x6f,0x52)") and ok
	ok = _assert(FinesScreen.ROW_Y == [78, 122, 166, 210, 254],
		"row ladder 0x4e then +0x2c") and ok
	ok = _assert(FinesScreen.PANEL.x + FinesScreen.PANEL_SIZE.x <= 640
		and FinesScreen.PANEL.y + FinesScreen.PANEL_SIZE.y <= 480,
		"the panel fits the 640x480 surface") and ok
	var scr: FinesScreen = load("res://scenes/FinesScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame
	scr.setup(rows)
	await process_frame
	var okr := scr.ok_rect()
	ok = _assert(okr.end.x <= 640 and okr.end.y <= 480,
		"the OK plate is on the surface (got %s)" % okr) and ok
	var fired := [0]
	scr.ok_pressed.connect(func() -> void: fired[0] += 1)
	_tap(scr, okr.get_center())
	await process_frame
	ok = _assert(fired[0] == 1, "OK emits once from inside the plate") and ok
	_tap(scr, Vector2(5, 5))
	await process_frame
	ok = _assert(fired[0] == 1, "a tap outside the plate emits nothing") and ok
	scr.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(scr: FinesScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		scr._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
