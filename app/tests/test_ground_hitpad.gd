extends SceneTree
## GROUND hit-target padding (owner 2026-07-23: "super sensitive / hard to find the exact
## click spot"). Proves the enlarged _hit() rects: (a) every target centre still resolves
## unchanged (no regression), (b) a near-miss just off a small target now selects it, (c) the
## former dead gaps between the 13px item/grade rows are now live, (d) padding never swallows a
## tap into a different semantic target. The baked art is unchanged — only _hit() grows.
##   ~/godot4 --headless --path app --script res://tests/test_ground_hitpad.gd

func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	scr.size = Vector2(640, 480)
	get_root().add_child(scr)
	for _i in 2:
		await process_frame
	var ok := true

	# --- FACILITIES / SERVICES tabs: the 13px item rows ---
	scr._view = "improve"
	scr._tab = "facilities"

	# (a) centres unchanged: every item bar centre resolves to its own index.
	for i in StadiumScreen.FAC_ITEMS.size():
		ok = _assert(scr._hit(scr._item_rect(i).get_center()) == "fac%d" % i,
			"FAC item %d centre still resolves" % i) and ok

	# (b)+(c) near-miss / dead-gap: a point 3px below an item bar's bottom edge (formerly a dead
	# 5px gap, since ITEM_BAR_H=13 < ITEM_BAR_PITCH=18) now resolves to an adjacent item, never "".
	for i in StadiumScreen.FAC_ITEMS.size() - 1:
		var r := scr._item_rect(i)
		var gap := Vector2(r.get_center().x, r.position.y + r.size.y + 3)   # in the old dead gap
		var hit := scr._hit(gap)
		ok = _assert(hit == "fac%d" % i or hit == "fac%d" % (i + 1),
			"FAC gap after item %d is now live (got '%s')" % [i, hit]) and ok

	# SERVICES rows likewise.
	scr._tab = "services"
	for i in StadiumScreen.SVC_ITEMS.size():
		ok = _assert(scr._hit(scr._item_rect(i).get_center()) == "svc%d" % i,
			"SVC item %d centre still resolves" % i) and ok

	# --- grade box near-miss (facilities, witnessed CHANGING ROOMS item 2) ---
	scr._tab = "facilities"
	scr._fac_sel = 2
	scr._fac_data = StadiumScreen.FAC_WITNESS
	scr._grades = {}                                   # current grade = witness default (1) -> next = 2
	var gr := scr._grade_rect(2)
	ok = _assert(scr._hit(gr.get_center()) == "facbuy", "grade box centre resolves to facbuy") and ok
	ok = _assert(scr._hit(Vector2(gr.get_center().x, gr.position.y - 3)) == "facbuy",
		"grade box near-miss (3px above) now resolves to facbuy") and ok

	# --- MATCH DAY arrows (19x17) near-miss ---
	scr._view = "matchday"
	scr.set_matchday_state(7, 750, "Manchester Utd.", "Southampton", true, false)
	var up := StadiumScreen.MD_TICKET_UP
	ok = _assert(scr._hit(up.get_center()) == "tkt_up", "ticket-up centre still resolves") and ok
	ok = _assert(scr._hit(Vector2(up.position.x - 3, up.get_center().y)) == "tkt_up",
		"ticket-up near-miss (3px left) now resolves") and ok

	# --- no cross-swallowing: a point in clear dead space resolves to nothing ---
	scr._view = "improve"
	scr._tab = "seats"
	ok = _assert(scr._hit(Vector2(300, 60)) == "", "clear dead space (300,60) stays inert") and ok
	# The gap BETWEEN the left improve panel and the right action grid is not swallowed by a
	# padded action button (BTN_IMPROVE starts x298; x285 is panel-side dead space).
	ok = _assert(scr._hit(Vector2(285, 419)) == "", "panel/action gutter (285,419) stays inert") and ok

	# Action buttons unchanged at centre.
	ok = _assert(scr._hit(StadiumScreen.BTN_RETURN.get_center()) == "return", "RETURN centre resolves") and ok
	ok = _assert(scr._hit(StadiumScreen.BTN_IMPROVE.get_center()) == "improve", "IMPROVE centre resolves") and ok

	print("ALL PASS" if ok else "FAILURES ABOVE")
	return ok


func _assert(cond: bool, msg: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])
	return cond
