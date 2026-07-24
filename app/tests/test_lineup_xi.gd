extends SceneTree
## Headless test for the LINE-UP XI editor: PM98's select-then-swap line-up edit.
## Tap a player to select (highlight), tap a second to swap him into / within the XI;
## the displaced man drops to SUBSTITUTES (the derived "not in xi" set). The GK slot only
## takes a keeper. Drives the screen's own interaction methods + one synthetic-tap round
## trip through `_hit` / `_on_input`, asserting the Tactics.xi mutation + xi_changed signal.
##   ~/godot462 --headless --path app --script res://tests/test_lineup_xi.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var club := _synth_club(16, [1])          # ids 1..16, id1 is the only keeper
	var t := Tactics.new()
	t.formation = "4-4-2"
	t.xi = Array(range(1, 12))                # ids 1..11 start
	ok = _assert(t.validate(club) == "", "seed XI valid") and ok

	var screen: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	get_root().add_child(screen)
	for _i in 2:
		await process_frame
	screen.size = Vector2(640, 480)           # native -> hit-tests map 1:1
	screen.setup(club, t, "", "Premier")
	var changed := [0]
	screen.xi_changed.connect(func() -> void: changed[0] += 1)

	# --- 1. sub a bench outfielder onto an XI outfield slot --------------------
	ok = _assert(screen._sel_pid == -1, "setup clears selection") and ok
	screen._tap_row(_fi(screen, 12))          # select bench id12
	ok = _assert(screen._sel_pid == 12, "first tap selects the player") and ok
	var slot5 := t.xi.find(5)                 # id5's XI slot (an outfield slot)
	screen._tap_row(_fi(screen, 5))           # tap XI id5 -> 12 subs on for 5
	ok = _assert(t.xi.has(12) and not t.xi.has(5), "bench player subbed into the XI") and ok
	ok = _assert(t.xi.find(12) == slot5, "new man takes the tapped slot") and ok
	ok = _assert(screen._sel_pid == -1, "completed swap clears selection") and ok
	ok = _assert(changed[0] == 1, "xi_changed fired once") and ok
	ok = _assert(t.validate(club) == "", "XI still valid after sub") and ok

	# --- 2. GK guard: an outfielder cannot take the keeper's slot --------------
	screen._sel_pid = -1
	screen._tap_row(_fi(screen, 5))           # id5 is now on the bench (outfielder)
	ok = _assert(screen._sel_pid == 5, "select displaced outfielder") and ok
	var before := t.xi.duplicate()
	screen._tap_row(_fi(screen, 1))           # id1 = keeper in the GK slot
	ok = _assert(t.xi == before, "outfielder->GK slot rejected (no change)") and ok
	ok = _assert(changed[0] == 1, "rejected swap does not emit") and ok
	ok = _assert(screen._sel_pid == 5, "rejected swap keeps the selection") and ok

	# --- 3. tapping the selected player again deselects ------------------------
	screen._sel_pid = -1
	screen._tap_row(_fi(screen, 3))
	ok = _assert(screen._sel_pid == 3, "re-select") and ok
	screen._tap_row(_fi(screen, 3))
	ok = _assert(screen._sel_pid == -1, "second tap on same player deselects") and ok

	# --- 4. XI<->XI swap exchanges two outfielders' slots ---------------------
	screen._sel_pid = -1
	var s3 := t.xi.find(3)
	var s7 := t.xi.find(7)
	var emits: int = changed[0]
	screen._tap_row(_fi(screen, 3))
	screen._tap_row(_fi(screen, 7))
	ok = _assert(t.xi[s3] == 7 and t.xi[s7] == 3, "two XI players swap slots") and ok
	ok = _assert(changed[0] == emits + 1, "XI<->XI swap emits") and ok
	ok = _assert(t.validate(club) == "", "XI valid after slot swap") and ok

	# --- 5. two NON-XI players exchange places, XI untouched ------------------
	# Live-witnessed on the real game 2026-07-24: a SUBSTITUTE selected and a RESERVE
	# tapped swap rows (Fairclough <-> Barlow). Before this the app only moved the
	# selection, so a substitute could never be swapped with a reserve.
	screen._sel_pid = -1
	var xi_snap := t.xi.duplicate()
	var benchA := _first_bench_pid(screen)
	var benchB := _first_bench_pid(screen, benchA)
	var order_before := screen._subs_order().map(func(p): return int(p.get("id", -1)))
	var ia := order_before.find(benchA)
	var ib := order_before.find(benchB)
	screen._tap_row(_fi(screen, benchA))
	screen._tap_row(_fi(screen, benchB))
	var order_after := screen._subs_order().map(func(p): return int(p.get("id", -1)))
	ok = _assert(order_after[ia] == benchB and order_after[ib] == benchA,
		"non-XI tap pair exchanges their rows") and ok
	ok = _assert(screen._sel_pid == -1, "the swap clears the selection") and ok
	ok = _assert(t.xi == xi_snap, "a non-XI swap leaves the XI untouched") and ok
	# A reserve swapped onto the bench is now a SUBSTITUTE (and vice versa).
	var last := screen._subs_order().size() - 1
	if last >= Tactics.BENCH_SLOTS:
		var sub0 := int(screen._subs_order()[0].get("id", -1))
		var res_last := int(screen._subs_order()[last].get("id", -1))
		screen._sel_pid = -1
		screen._tap_row(_fi(screen, sub0))
		screen._tap_row(_fi(screen, res_last))
		var tiers := screen._tiers()
		var bench_ids: Array = (tiers[0] as Array).map(func(p): return int(p.get("id", -1)))
		ok = _assert(bench_ids.has(res_last) and not bench_ids.has(sub0),
			"a reserve swapped with a substitute takes the bench slot") and ok

	# --- 6. a bench keeper MAY take the GK slot -------------------------------
	var club2 := _synth_club(16, [1, 16])     # id1 + id16 are keepers
	var t2 := Tactics.new()
	t2.formation = "4-4-2"
	t2.xi = Array(range(1, 12))               # id1 keeps goal; id16 is a bench keeper
	screen.setup(club2, t2, "", "Premier")
	screen._tap_row(_fi(screen, 16))          # select bench keeper
	screen._tap_row(_fi(screen, 1))           # tap the GK slot
	ok = _assert(t2.xi[0] == 16 and not t2.xi.has(1), "bench keeper subbed into goal") and ok
	ok = _assert(t2.validate(club2) == "", "keeper-for-keeper swap stays valid") and ok

	# --- 7. synthetic tap round-trip through _hit / _on_input -----------------
	screen.setup(club, Tactics.auto_pick(club, "4-4-2"), "", "Premier")
	var fi8 := _fi(screen, 8)
	var y := LineupScreen.XI_Y0 - 1 + fi8 * LineupScreen.ROW_PITCH + 4
	ok = _assert(screen._hit(Vector2(60, y)) == "row:%d" % fi8, "_hit maps a click to its row") and ok
	_tap(screen, Vector2(60, y))
	ok = _assert(screen._sel_pid == 8, "full press+release tap selects the row") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## Flat-list index of the row carrying `pid` (or -1). The interaction is keyed off pid, so
## the test is independent of the bench's by-ability ordering.
func _fi(screen: LineupScreen, pid: int) -> int:
	var items: Array = screen._flat_items()
	for i in items.size():
		if items[i].get("t") == "row" and int(items[i]["pid"]) == pid:
			return i
	return -1


## The pid of the first bench (non-XI) row, optionally skipping `skip`.
func _first_bench_pid(screen: LineupScreen, skip: int = -1) -> int:
	var xi: Array = screen._tactics.xi
	for it in screen._flat_items():
		if it.get("t") == "row":
			var pid := int(it["pid"])
			if not xi.has(pid) and pid != skip:
				return pid
	return -1


## An N-man synth club; ids 1..N, the ids in `gks` are keepers (the rest outfield), all with
## decoded attrs so the screen + Tactics have real numbers.
func _synth_club(n: int, gks: Array) -> Dictionary:
	var players: Array = []
	for i in n:
		var pid := i + 1
		var gk: bool = gks.has(pid)
		players.append({
			"id": pid, "name": "P%d" % pid, "isGK": gk,
			"pos": "GK" if gk else "OUT", "posFine": 1 if gk else 7,
			"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
				"PA": 70, "TI": 70, "EN": 70, "PO": 78 if gk else 12},
		})
	return {"id": 1, "name": "SYNTH FC", "players": players}


func _tap(screen: LineupScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	screen._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
