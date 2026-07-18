extends SceneTree
## Headless test for the SAVE GAME 10-slot dialog (charter #8; witnessed
## 2026-07-18, captures 51/52/53/55): asset + geometry, Career slot API
## round-trip, the tap-slot -> type -> SAVE commit flow, CANCEL, and the
## NivelScreen load-modal row model (slots + legacy autosave row).
##   ~/godot462 --headless --path app --script res://tests/test_savegame_dialog.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	ok = _assert(ResourceLoader.exists("res://art/screens/savegame/dialog.png"),
		"dialog art present") and ok
	ok = _assert(SaveGameDialog.N_SLOTS == 10, "TEN slots (witness 51)") and ok
	ok = _assert(SaveGameDialog.R_SAVE.end.x <= 640 and SaveGameDialog.R_CANCEL.end.y <= 480,
		"button rects in canvas") and ok

	# ---- Career slot API round-trip ---------------------------------------
	for i in 10:
		Career.delete_save(Career.SLOT_PATH % i)
	Career.delete_save(Career.SLOT_INDEX_PATH)
	var c := Career.new()
	c.club_id = 59
	c.club_name = "Bolton W"
	c.manager_name = "mwm"
	c.week = 3
	c.rosters[59] = [{"id": 7, "name": "Ward", "pos": "GK", "insurance_group": 2}]
	c.save_slot(3, "wk3")
	var metas := Career.slot_metas()
	ok = _assert(metas.size() == 10, "10 metas") and ok
	ok = _assert((metas[0] as Dictionary).is_empty(), "slot 0 empty") and ok
	ok = _assert(str((metas[3] as Dictionary).get("game")) == "wk3" \
		and str((metas[3] as Dictionary).get("player")) == "mwm", "slot 3 meta") and ok
	var c2 := Career.load_slot(3)
	ok = _assert(c2 != null and c2.week == 3 and c2.club_name == "Bolton W",
		"slot loads the full career") and ok
	ok = _assert(int(c2.rosters[59][0].get("insurance_group", 0)) == 2,
		"slot save carries player state (insurance)") and ok
	ok = _assert(Career.load_slot(5) == null, "empty slot loads null") and ok
	# index self-heal: delete the sidecar, metas rebuild from the slot file
	Career.delete_save(Career.SLOT_INDEX_PATH)
	var metas2 := Career.slot_metas()
	ok = _assert(str((metas2[3] as Dictionary).get("game")) == "wk3",
		"index self-heals from slot files") and ok

	# ---- dialog flow -------------------------------------------------------
	var dlg: SaveGameDialog = load("res://scenes/SaveGameDialog.gd").new()
	dlg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(dlg)
	await process_frame
	dlg.setup(Career.slot_metas(), "mwm")
	var got := []
	var closed_n := [0]
	dlg.save_requested.connect(func(s: int, n: String) -> void: got.append([s, n]))
	dlg.closed.connect(func() -> void: closed_n[0] += 1)
	# SAVE with no slot armed -> nothing
	_tap(dlg, SaveGameDialog.R_SAVE.get_center())
	ok = _assert(got.is_empty() and closed_n[0] == 0, "SAVE w/o armed slot inert") and ok
	# tap slot 1 -> armed + editor visible (witness 52)
	_tap(dlg, Vector2(250, 144 + 16 + 6))
	ok = _assert(dlg._armed == 1, "slot 1 armed") and ok
	ok = _assert(dlg._edit.visible, "LineEdit mounts on arm") and ok
	dlg._edit.text = "wk3"
	_tap(dlg, SaveGameDialog.R_SAVE.get_center())
	ok = _assert(got == [[1, "wk3"]], "SAVE emits slot + typed name") and ok
	ok = _assert(closed_n[0] == 1, "SAVE closes") and ok
	# CANCEL path (witness 55)
	dlg._armed = -1
	_tap(dlg, SaveGameDialog.R_CANCEL.get_center())
	ok = _assert(closed_n[0] == 2, "CANCEL closes") and ok
	# re-arming a saved slot prefills its name
	dlg.setup([{}, {"game": "wk3", "player": "mwm"}], "mwm")
	_tap(dlg, Vector2(250, 144 + 16 + 6))
	ok = _assert(dlg._edit.text == "wk3", "arming a saved slot prefills the name") and ok

	# ---- NivelScreen load-row model ---------------------------------------
	var nv: NivelScreen = load("res://scenes/NivelScreen.gd").new()
	get_root().add_child(nv)
	nv.setup(true, {"club": "Bolton W", "name": "mwm"}, Career.slot_metas())
	ok = _assert(nv._row_kind(3) == "slot", "slot row listed") and ok
	ok = _assert(nv._row_kind(0) == "auto", "legacy autosave on row 0") and ok
	ok = _assert(nv._row_kind(5) == "", "empty row inert") and ok
	nv.setup(true, {}, [{"game": "x", "player": "y"}])
	ok = _assert(nv._row_kind(0) == "slot", "slot 0 takes precedence over autosave") and ok

	# cleanup the test slot files
	for i in 10:
		Career.delete_save(Career.SLOT_PATH % i)
	Career.delete_save(Career.SLOT_INDEX_PATH)

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(c: Control, at: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.pressed = true
	press.position = at
	c._on_input(press)
	var rel := InputEventMouseButton.new()
	rel.pressed = false
	rel.position = at
	c._on_input(rel)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
