extends SceneTree
## The owner's 2026-07-24 report: "in match results screen the statistics button doesn't
## work on either team. Needs to work like in original."
##
## It didn't: `MatchResultScreen._on_input` only ever hit-tested CONTINUE, and the four
## button plates were baked chrome. The original's behaviour is captured in
## `screenshots/wine-captures-2026-07-24-statistics-live/` — a real MANAGER.EXE Charity
## Shield in RESULTS mode: 01 is the HALF TIME board and 04 the FULL TIME one, each with
## a STATISTICS button per team; 02/03 and 06/05 are the four tables they open. Each shows
## that side's ELEVEN, with the MATCH record (MP 1, MIN 45 then 90, RATING, MoM, G.,
## SHOTS/PASSES/TAC. as x/y pairs, S., cards) and RETURN.
##
## Drives the REAL Main UI end to end.
##   ~/godot462 --headless --path app --script res://tests/test_result_statistics.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# ---- unit: the engine's half-time snapshot is a PREFIX of full time -------
	# The live sheets show Man Utd SHOTS 7/9 at HT and 10/13 at FT, MIN 45 then 90 —
	# running totals, which is what Pm98StatStore.snapshot takes without zeroing.
	var xi_h := _xi(1)
	var xi_a := _xi(101)
	var mem := Pm98StatMatch.build_mem(xi_h, xi_a, 40, 61)
	var prng := Pm98StatMatch.Rng.new(20260724)
	var ft := Pm98StatStore.Report.new(40, 61)
	var ht := Pm98StatStore.Report.new(40, 61)
	var pids := MatchSim.pid_map(xi_h, xi_a)
	Pm98StatMatch.simulate(mem, prng, false, false, ft, pids,
		Pm98StatMatch.CADENCE_MATCH, ht)
	ok = _assert(ht.count(0) > 0 and ft.count(0) > 0,
		"both reports carry records (ht %d / ft %d)" % [ht.count(0), ft.count(0)]) and ok
	var ht_rows := Pm98StatStore.match_rows(ht, 0, xi_h)
	var ft_rows := Pm98StatStore.match_rows(ft, 0, xi_h)
	var prefix := true
	var moved := 0
	for i in ht_rows.size():
		var a: PackedInt32Array = ht_rows[i]
		var b: PackedInt32Array = ft_rows[i]
		for k in range(2, Pm98StatStore.REC_DWORDS):
			if a[k] > b[k]:
				prefix = false
			elif a[k] < b[k]:
				moved += 1
	ok = _assert(prefix, "no half-time column exceeds its full-time value") and ok
	ok = _assert(moved > 0, "and the second half added to %d of them" % moved) and ok
	var ht_min := int((ht_rows[0] as PackedInt32Array)[Pm98StatStore.R_MIN / 4])
	var ft_min := int((ft_rows[0] as PackedInt32Array)[Pm98StatStore.R_MIN / 4])
	ok = _assert(ht_min == 45 and ft_min == 90,
		"MIN reads 45 at half time and 90 at full time (got %d / %d)" % [ht_min, ft_min]) and ok
	var tot := Pm98StatStore.totals(ft_rows)
	ok = _assert(tot[Pm98StatStore.R_MP / 4] == 1,
		"TEAM TOTAL MP is the constant 1, not a column sum") and ok
	ok = _assert(tot[Pm98StatStore.R_MIN / 4] == 90, "and MIN is the max, not a sum") and ok

	# ---- e2e: both buttons open the table, on both boards --------------------
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 40:
		await process_frame
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload absent under --script")
		print("test_result_statistics: ", "PASS" if ok else "FAIL")
		quit(0 if ok else 1)
		return
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	main._begin_career("Test Mgr", league, gamedb.clubs_in_league("eng_prem")[0])
	for _i in 12:
		await process_frame
	for _s in 12:
		var n: Node = _top(main)
		if n == null or not _fire(n):
			break
		for _i in 5:
			await process_frame
	var c = main._career
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var res: Dictionary = {}
	for _w in 8:
		res = c.advance_week(rng)
		if not res.is_empty() and not (res.get("xi_home", []) as Array).is_empty():
			break
	ok = _assert(not res.is_empty(), "the manager played a fixture") and ok
	ok = _assert(res.get("report") != null, "and it produced a match report") and ok
	ok = _assert(res.get("report_ht") != null, "plus the half-time snapshot") and ok

	for board in ["fulltime", "halftime"]:
		var data := {
			"home": c.club_names.get(int(res["home_id"]), "?"),
			"away": c.club_names.get(int(res["away_id"]), "?"),
			"hg": int(res["hg"]), "ag": int(res["ag"]), "goals": res.get("goals", []),
			"home_id": int(res["home_id"]), "away_id": int(res["away_id"]),
			"header": {}, "stadium": {}, "motm": {},
			"xi_home": res.get("xi_home", []), "xi_away": res.get("xi_away", []),
			"report": res.get("report"), "report_ht": res.get("report_ht"),
		}
		if board == "halftime":
			data = main._halftime_data(data)
		main._open_result_readout(data, func() -> void: pass, board == "halftime")
		for _i in 8:
			await process_frame
		var rs: MatchResultScreen = _first(main, "MatchResultScreen") as MatchResultScreen
		ok = _assert(rs != null, "%s board mounted" % board) and ok
		if rs == null:
			continue
		rs.size = Vector2(640, 480)
		for _i in 3:
			await process_frame
		for side in 2:
			var r: Rect2 = MatchResultScreen.STATS_BTN[side]
			_tap(rs, r.get_center())
			for _i in 8:
				await process_frame
			var st: StatisticsScreen = _first(main, "StatisticsScreen") as StatisticsScreen
			ok = _assert(st != null, "%s: side %d STATISTICS opens the table" % [board, side]) and ok
			if st != null:
				ok = _assert(st._players.size() == 11,
					"  and it lists the ELEVEN (got %d)" % st._players.size()) and ok
				var want: String = str(data.get("home" if side == 0 else "away", ""))
				ok = _assert(str(st._club.get("name", "")) == want,
					"  for the right club (%s)" % st._club.get("name", "")) and ok
				var mp_ok := false
				for row in st._rows:
					if int((row as PackedInt32Array)[Pm98StatStore.R_MP / 4]) == 1:
						mp_ok = true
				ok = _assert(mp_ok, "  and the rows carry the match record") and ok
				st.back_pressed.emit()
				for _i in 4:
					await process_frame
				ok = _assert(_first(main, "StatisticsScreen") == null,
					"  RETURN drops back to the board") and ok
				ok = _assert(_first(main, "MatchResultScreen") != null,
					"  which is still mounted underneath") and ok
		rs.queue_free()
		for _i in 4:
			await process_frame

	print("test_result_statistics: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _xi(base: int) -> Array:
	var xi: Array = []
	for i in 11:
		var a := {}
		for k in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]:
			a[k] = 55 + (i % 7)
		xi.append({"id": base + i, "name": "P%d" % (base + i), "isGK": i == 0,
			"pos": "GK" if i == 0 else "MF", "attrs": a})
	return xi


func _first(main: Node, cls: String) -> Node:
	for ch in main.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("%s.gd" % cls) \
				and not ch.is_queued_for_deletion():
			return ch
	return null


func _top(main: Node) -> Node:
	var last: Node = null
	for ch in main.get_children():
		if ch is Control and ch != main._hub and is_instance_valid(ch) \
				and not ch.is_queued_for_deletion():
			last = ch
	return last


func _fire(n: Node) -> bool:
	for s in ["continue_pressed", "ok_pressed", "back_pressed", "done"]:
		if n.has_signal(s):
			n.emit_signal(s)
			return true
	return false


## Device-shaped: a finger press arrives as the emulated mouse event AND the touch.
func _tap(n: Control, p: Vector2) -> void:
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.pressed = pressed
		m.device = InputEvent.DEVICE_ID_EMULATION
		n.gui_input.emit(m)
		var t := InputEventScreenTouch.new()
		t.position = p
		t.pressed = pressed
		n.gui_input.emit(t)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
