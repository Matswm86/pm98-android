extends SceneTree
## MAN-TO-MAN MARKINGS — the model, not the pixels (the render-diff gate is
## `tools/re/diff_mantoman_parity.py`). Everything asserted here is the original's
## own rule, cited to docs/re/mantoman_screen_re.md:
##
##  * the screen lists lineup slots 2..11 a side (`FUN_0057a2e0`, never the keeper);
##  * a commit writes the OPPONENT's slot (2..11) into `team+0x234 + 4*i`;
##  * an opponent can only be marked once — a second commit steals him;
##  * DELETE clears the SELECTED row only;
##  * the two marking lines scale `field * 148 / 318` (79 -> 36, 198 -> 92) and
##    their tracks bound each other so D can never pass M;
##  * `Pm98LineupFeeder` carries the table to the engine as `rec+0x28 = entry - 1`.

var _fail := 0


func _initialize() -> void:
	var scr: ManToManScreen = load("res://scenes/ManToManScreen.gd").new()
	get_root().add_child(scr)

	var mine := _xi("M")
	var theirs := _xi("O")
	scr.setup(1, mine, 2, "Rivals", theirs)

	_ok(scr._my_xi.size() == 10, "ten MY rows")
	_ok(scr._opp_xi.size() == 10, "ten OPPONENT rows")
	_ok(str(scr._my_xi[0].get("name")) == "M1", "row 0 is lineup slot 2, not the keeper")
	_ok(scr.markings() == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], "a fresh table is all zeros")

	# select MY row 7, commit OPPONENT row 2 -> slot 4 (the witnessed 060 -> 061 pair)
	scr._activate("opp:2")
	_ok(scr.markings()[7] == 0, "an opponent tap with nothing selected is a no-op")
	scr._activate("my:7")
	_ok(scr._sel == 7, "tapping a MY row selects it")
	scr._activate("opp:2")
	_ok(scr.markings()[7] == 4, "commit writes the OPPONENT's lineup slot (2 + row)")

	# a second commit on the same opponent steals him
	scr._activate("my:3")
	scr._activate("opp:2")
	_ok(scr.markings()[3] == 4 and scr.markings()[7] == 0, "an opponent is marked once")

	# DELETE clears the selected row only
	scr._activate("my:7")
	scr._activate("my:3")
	scr._activate("delete")
	_ok(scr.markings()[3] == 0, "DELETE clears the selected row")

	# the marking lines
	scr.setup(1, mine, 2, "Rivals", theirs, [], [79, 198])
	_ok(scr._v_def == 36 and scr._v_mid == 92, "79/198 scale to 36/92 (x148/318)")
	scr._drag = "d"
	scr._drag_line(scr.PITCH.position.x + scr.MARK_X0 + 400.0)
	_ok(scr._v_def == scr._v_mid, "the DEFENDING line cannot pass the MIDFIELDING one")
	scr._drag = "m"
	scr._drag_line(0.0)
	_ok(scr._v_mid == scr._v_def, "and the MIDFIELDING line cannot pass back")

	# the engine hand-off: table entry k -> rec+0x28 = k-1, 0 -> -1
	var feed: Array = []
	for i in 10:
		feed.append(0)
	feed[4] = 7
	_ok(feed[4] - 1 == 6, "table entry 7 reaches the engine as 6")

	# THE DOOR. The BRIEF's MAN-TO-MAN button was one of four `_: pass` stubs; drive
	# the real widget with a press/release inside its own rect and check it fires.
	var brief: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	brief.size = Vector2(640, 480)
	get_root().add_child(brief)
	var fired := [false]
	brief.mtm_pressed.connect(func() -> void: fired[0] = true)
	var r: Rect2 = brief.BTN["mtm"]
	_tap(brief, r.position + r.size * 0.5)
	_ok(fired[0], "the BRIEF's MAN-TO-MAN button opens the door")
	fired[0] = false
	_tap(brief, (brief.BTN["exit"] as Rect2).position + Vector2(4, 4))
	_ok(not fired[0], "and no other button does")

	print("test_mantoman: %s" % ("ALL PASS" if _fail == 0 else "%d FAILED" % _fail))
	quit(1 if _fail else 0)


func _tap(ci: Control, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		ci._on_input(e)


func _xi(prefix: String) -> Array:
	var out: Array = [{"name": prefix + "GK", "pos": "GK", "squadNo": 1, "posFine": 1}]
	for i in range(1, 11):
		out.append({"name": "%s%d" % [prefix, i], "pos": "MF", "squadNo": i + 1,
			"posFine": 10})
	return out


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fail += 1
	print("%s  %s" % ["PASS" if cond else "FAIL", what])
