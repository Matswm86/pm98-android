extends SceneTree
## Headless wiring test for the PREDEF. TACTICS picker (PredefTacticsScreen —
## frame-true modal cut from 140_154820, selection witness 142_154825). Confirms
## it mounts, loads the frame-baked chrome + the 10-cell grid geometry from the
## bake's samples json (in Tactics.FORMATION_ORDER), builds a hit-rect per cell +
## CANCEL, that picking a cell emits formation_picked, and that CANCEL / an
## outside tap emit cancelled.
##   ~/godot462 --headless --path app --script res://tests/test_predef_tactics_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var screen: PredefTacticsScreen = load("res://scenes/PredefTacticsScreen.gd").new()
	screen.size = Vector2(640, 480)
	get_root().add_child(screen)
	for _i in 3:
		await process_frame

	ok = _assert(screen._chrome != null, "frame-baked predef_chrome loaded") and ok
	ok = _assert(screen._cells.size() == 10, "10 formation cells loaded (%d)" % screen._cells.size()) and ok

	# grid order matches the source table / Tactics.FORMATION_ORDER exactly.
	var got_names := []
	for c in screen._cells:
		got_names.append(str(c["name"]))
	ok = _assert(got_names == Tactics.FORMATION_ORDER,
		"cell order == Tactics.FORMATION_ORDER (%s)" % str(got_names)) and ok

	screen.setup("3-5-2")   # mark 3-5-2 selected (the frame-142 witness case)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	# hit-rects: one per formation + CANCEL.
	var picks := 0
	var has_cancel := false
	for h in screen._hits:
		if str(h["kind"]).begins_with("pick:"):
			picks += 1
		if str(h["kind"]) == "cancel":
			has_cancel = true
	ok = _assert(picks == 10, "picker built 10 pick hit-rects (%d)" % picks) and ok
	ok = _assert(has_cancel, "picker has a CANCEL hit-rect") and ok

	# Signals: a pick emits formation_picked; CANCEL / outside emit cancelled.
	var picked := {"form": ""}
	var cancels := {"n": 0}
	screen.formation_picked.connect(func(fm: String): picked["form"] = fm)
	screen.cancelled.connect(func(): cancels["n"] += 1)

	screen._activate("pick:4-3-3")
	ok = _assert(picked["form"] == "4-3-3", "pick emitted formation_picked (%s)" % picked["form"]) and ok
	screen._activate("cancel")
	ok = _assert(cancels["n"] == 1, "CANCEL emitted cancelled") and ok

	# every cell rect sits inside the frame-baked modal rect.
	var inside := true
	for c in screen._cells:
		if not screen._modal.encloses(c["cell"] as Rect2):
			inside = false
	ok = _assert(inside, "every cell rect lies inside the modal rect") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
