extends SceneTree
## KNOCKOUT LIST PANEL — the row geometry, against the two panels the original was
## witnessed drawing (docs/re/knockout_views_re.md "Geometry banked 2026-07-26").
##
##   15 ties  black rules at y168,183,198..363, foot y378..380   (body 225, rows 15 px)
##   16 ties  black rules at y168,184,200..392, foot y408..410   (body 255)
##
## The two are NOT the same pitch, which is the whole reason this is a test and not a
## constant: the panel is sized to the round until it reaches its full height, and the
## rules then fall out of an integer division that has to match the original's exactly.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_knockout_layout.gd

const SEPS_15 := [168, 183, 198, 213, 228, 243, 258, 273, 288, 303, 318, 333, 348, 363]
const SEPS_16 := [168, 184, 200, 216, 232, 248, 264, 280, 296, 312, 328, 344, 360, 376, 392]

var _fail := 0


func _initialize() -> void:
	var scr: KnockoutScreen = load("res://scenes/KnockoutScreen.gd").new()
	get_root().add_child(scr)

	_case(scr, 15, 225, SEPS_15, 378)
	_case(scr, 16, 255, SEPS_16, 408)
	# A round longer than the panel keeps the panel's full height and shows 16 rows.
	_ties(scr, 23)
	_a(scr.visible_rows() == 16, "23 ties -> 16 visible rows")
	_a(scr.body_h() == 255, "23 ties -> the full 255 px body")

	# The column sets, as the two frames measure them.
	_ties(scr, 15)
	_a(scr.cols() == KnockoutScreen.COLS_EURO, "European ties -> 1ST LEG/2ND LEG/AGGR.")
	_ties(scr, 15, false)
	_a(scr.cols() == KnockoutScreen.COLS_DOM, "domestic ties -> RES./REPLAY")

	print("test_knockout_layout: %s" % ("ALL PASS" if _fail == 0 else "%d FAILED" % _fail))
	quit(1 if _fail > 0 else 0)


func _ties(scr: KnockoutScreen, n: int, euro := true) -> void:
	var rows: Array = []
	for i in n:
		rows.append({"home": "H%d" % i, "away": "A%d" % i, "winner": -1,
			"cells": [["", ""], ["", ""], ["", ""]] if euro else [["", ""], ["", ""]]})
	scr.setup({}, "euro", "ROUND 1", euro, rows, false, false)


func _case(scr: KnockoutScreen, n: int, body: int, seps: Array, foot: int) -> void:
	_ties(scr, n)
	_a(scr.body_h() == body, "%d ties -> body %d px" % [n, body])
	for i in seps.size():
		_a(scr._sep_y(i) == int(seps[i]),
			"%d ties -> rule %d at y%d (got %d)" % [n, i, int(seps[i]), scr._sep_y(i)])
	_a(KnockoutScreen.BODY_TOP + scr.body_h() - 1 == foot,
		"%d ties -> foot at y%d" % [n, foot])
	# Rows fill the gaps between the rules exactly, with no overlap and no hole.
	var prev := KnockoutScreen.BODY_TOP - 1
	for i in n:
		var span: Vector2i = scr._row_span(i)
		_a(span.x == prev + 1, "%d ties -> row %d starts at y%d" % [n, i, prev + 1])
		prev = span.y + (1 if i < n - 1 else 0)
	_a(prev == KnockoutScreen.BODY_TOP + scr.body_h() - 2,
		"%d ties -> the last row ends against the foot" % n)


func _a(cond: bool, label: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL  %s" % label)
