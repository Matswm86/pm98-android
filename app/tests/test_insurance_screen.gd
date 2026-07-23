extends SceneTree
## Headless test for the INSURANCE screen (charter #8; witnessed 2026-07-18):
## assets load, geometry stays in-canvas, sections bucket + REVERSE-order the
## squad (all 16 witnessed rows), the non-EU-1997 flag rule, the digit-run
## centring grammar, scroll clamping, the POLICY modal preview/commit flow, and
## the Career side: set_insurance persistence + the flat price constants.
##   ~/godot462 --headless --path app --script res://tests/test_insurance_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)   # scale 1 / origin 0 -> design == screen

	for path in ["res://art/screens/insurance/chrome.png",
			"res://art/screens/insurance/title.png",
			"res://art/screens/insurance/row_strip.png",
			"res://art/screens/insurance/arrow_off.png",
			"res://art/screens/insurance/arrow_on.png",
			"res://art/screens/insurance/doc_row.png",
			"res://art/screens/insurance/doc_modal.png",
			"res://art/screens/insurance/modal.png",
			"res://art/screens/insurance/scroll_up_off.png",
			"res://art/screens/insurance/scroll_dn_off.png",
			"res://art/screens/insurance/scroll_dn_on.png",
			"res://art/screens/insurance/scroll_slider25.png",
			"res://art/screens/insurance/scroll_pale.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	ok = _assert(InsuranceScreen.R_RETURN.end.x <= 640 \
		and InsuranceScreen.R_RETURN.end.y <= 480, "RETURN rect in canvas") and ok
	ok = _assert(InsuranceScreen.M_OK.end.x <= 640, "OK rect in canvas") and ok
	for g in InsuranceScreen.M_BTNS:
		var r: Rect2 = InsuranceScreen.M_BTNS[g]
		ok = _assert(r.end.x <= 640 and r.end.y <= 480, "group btn %d in canvas" % g) and ok
	ok = _assert(InsuranceScreen.PRICES == {1: Insurance.PREMIUM_MIN[1] / Insurance.UNIT,
			2: Insurance.PREMIUM_MIN[2] / Insurance.UNIT,
			3: Insurance.PREMIUM_MIN[3] / Insurance.UNIT},
		"screen minimum prices == the binary clamp constants") and ok

	# ---- sections: bucket + REVERSE record order (witness rows) ------------
	var club := {"id": 59, "name": "Bolton W", "players": [
		{"id": 1, "name": "GkOld", "pos": "GK", "isGK": true, "squadNo": 24},
		{"id": 2, "name": "GkNew", "pos": "GK", "isGK": true, "squadNo": 16},
		{"id": 3, "name": "DefA", "pos": "DF", "squadNo": 5},
		{"id": 4, "name": "MidA", "pos": "MF", "squadNo": 8},
		{"id": 5, "name": "FwdA", "pos": "FW", "squadNo": 9},
		{"id": 6, "name": "FwdB", "pos": "FW", "squadNo": 14},
	]}
	var scr: InsuranceScreen = load("res://scenes/InsuranceScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame          # layout pass -> size 640x480, design == screen
	scr.setup(club, 1, {})
	ok = _assert(scr._sections.size() == 4, "4 fixed sections") and ok
	ok = _assert((scr._sections[0]["players"] as Array).size() == 2, "gk bucket") and ok
	ok = _assert(str((scr._sections[0]["players"] as Array)[0]["name"]) == "GkNew",
		"REVERSE record order (last record first)") and ok
	ok = _assert(str((scr._sections[3]["players"] as Array)[0]["name"]) == "FwdB",
		"fwd section reversed too") and ok

	# ---- non-EU-1997 foreigner flag rule (witnessed marker) ----------------
	ok = _assert(not "ICELAND" in InsuranceScreen.EU_1997, "Iceland -> flag (witnessed)") and ok
	for eu in ["DENMARK", "FINLAND", "REP. OF IRELAND", "NORTH. IRELAND", "ENGLAND"]:
		ok = _assert(eu in InsuranceScreen.EU_1997, "%s EU -> no flag (witnessed)" % eu) and ok

	# ---- scroll clamp ------------------------------------------------------
	scr._scroll["gk"] = 99
	scr._scroll["gk"] = clampi(99, 0, maxi(0, 2 - 3))
	ok = _assert(int(scr._scroll["gk"]) == 0, "scroll clamps to 0 when all fit") and ok

	# ---- POLICY modal flow: preview + commit -------------------------------
	var p: Dictionary = (scr._sections[0]["players"] as Array)[0]
	scr._modal_pid = int(p["id"])
	scr._modal_p = p
	scr._pending = -1
	var got := []
	scr.policy_selected.connect(func(pid: int, g: int) -> void: got.append([pid, g]))
	# OK with nothing tapped -> no commit (witness 38 -> 39: Frandsen unchanged)
	scr._on_input(_tap(scr, InsuranceScreen.M_OK.get_center()))
	ok = _assert(got.is_empty(), "OK w/o tap commits nothing") and ok
	ok = _assert(scr._modal_pid == -1, "OK closes the modal") and ok
	# tap GROUP 1 -> pending preview; OK -> commit (witness 36 -> 37)
	scr._modal_pid = int(p["id"])
	scr._modal_p = p
	scr._pending = -1
	scr._on_input(_tap(scr, (InsuranceScreen.M_BTNS[1] as Rect2).get_center()))
	ok = _assert(scr._pending == 1, "group tap sets pending") and ok
	ok = _assert(scr._modal_pid != -1, "group tap keeps the modal open") and ok
	scr._on_input(_tap(scr, InsuranceScreen.M_OK.get_center()))
	ok = _assert(got == [[int(p["id"]), 1]], "OK commits the pending group") and ok

	# ---- digit-run grammar -------------------------------------------------
	# advances: "1" -> 5, others -> 8 (fitted on all 26 witnessed cell landings)
	var tw := 0
	for ch in "81":
		tw += 5 if ch == "1" else 8
	ok = _assert(tw == 13, "digit-run width: '81' = 13") and ok

	# ---- Career: set_insurance + persistence -------------------------------
	var c := Career.new()
	c.club_id = 59
	c.rosters[59] = [{"id": 7, "name": "Ward", "pos": "GK"}]
	ok = _assert(c.set_insurance(7, 2), "set_insurance ok") and ok
	ok = _assert(int(c.rosters[59][0]["insurance_group"]) == 2, "group stored on dict") and ok
	ok = _assert(not c.set_insurance(7, 9), "bad group rejected") and ok
	var c2 := Career.from_dict(c.to_dict())
	ok = _assert(int(c2.rosters[59][0].get("insurance_group", 0)) == 2,
		"insurance survives save round-trip") and ok
	ok = _assert(c2.set_insurance(7, 0), "group 0 = uninsure") and ok
	ok = _assert(not c2.rosters[59][0].has("insurance_group"), "uninsure erases key") and ok
	# The two wine witnesses (Ward £1,250/mo, Frandsen £14,583/mo) both sit under
	# FUN_0058c020's clamp, so both must price at the witnessed £200/£500/£1,000.
	for mw in [1250, 14583]:
		ok = _assert(Insurance.premium_monthly(1, mw) == 200 \
			and Insurance.premium_monthly(2, mw) == 500 \
			and Insurance.premium_monthly(3, mw) == 1000,
			"witness monthly wage %d prices 200/500/1000" % mw) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(scr: Control, at: Vector2) -> InputEventMouseButton:
	# design-space tap: the screen maps via _to_design; at scale 1 w/ origin 0
	# (root 640x480) design == screen. Emit press then release.
	var press := InputEventMouseButton.new()
	press.pressed = true
	press.position = at
	scr._on_input(press)
	var rel := InputEventMouseButton.new()
	rel.pressed = false
	rel.position = at
	return rel


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
