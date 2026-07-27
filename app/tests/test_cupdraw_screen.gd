extends SceneTree
## Headless test for the SORTEO cup-draw screen (CupDrawScreen), the original's own.
##
## Pins the things the render-diff cannot: that every asset MANAGER.EXE names for this
## screen actually ships, that the measured geometry stays on the 640x480 canvas, that
## the text FIELDS reproduce the pen origins measured on the two binding frames, that the
## proportional thumb solves both witnessed tie counts, and that a mid-draw tie (away club
## not yet pulled) is accepted rather than dropped.
##   ~/godot462 --headless --path app -s tests/test_cupdraw_screen.gd

const F74 := {  # 74_after_wk4.png — Coca-Cola Cup ROUND 2, 4 of 25 ties
	"key": "league_cup", "title": "Coca-Cola Cup", "round": "ROUND 2", "total": 25,
	"legs": ["1ST LEG", "2ND LEG"], "thumb_h": 305,
}
const F10 := {  # 10_fa_cup_draw_round1.png — F.A. Cup ROUND 1, 4 of 40 ties
	"key": "fa_cup", "title": "F.A. Cup", "round": "ROUND 1", "total": 40,
	"legs": ["MATCH", "REPLAY"], "thumb_h": 190,
}

var _fail := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	# 1. Every asset the EXE names for this screen ships, plus the chrome bake.
	var assets: Array[String] = ["res://art/screens/cupdraw/chrome.png",
		"res://art/screens/cupdraw/fondo.png", "res://art/screens/cupdraw/stop0.png"]
	for i in 12:
		assets.append("res://art/screens/cupdraw/bombo%02d_opaque.png" % i)
	for stem in CupDrawScreen.STRIPS.values():
		assets.append("res://art/screens/cupdraw/%s.png" % stem)
	for path in assets:
		_check(ResourceLoader.exists(path) and load(path) != null, "asset ships: %s" % path)

	# 2. The measured geometry stays on the canvas.
	for entry in [["PICTURE", CupDrawScreen.PICTURE], ["BTN_FINISH", CupDrawScreen.BTN_FINISH],
			["BTN_CONTINUE", CupDrawScreen.BTN_CONTINUE]]:
		var r: Rect2 = entry[1]
		_check(r.position.x >= 0 and r.position.y >= 0
			and r.end.x <= CupDrawScreen.W and r.end.y <= CupDrawScreen.H,
			"rect on canvas: %s" % entry[0])
	_check(CupDrawScreen.PICTURE.size == Vector2(260, 144), "picture window is 260x144")
	_check(CupDrawScreen.STRIP_AT == Vector2(31, 76), "strip at (31,76)")
	_check(CupDrawScreen.FONDO_AT == Vector2(103, 76), "drum backdrop at (103,76)")
	_check(CupDrawScreen.BOMBO_AT == Vector2(136, 76), "drum at (136,76)")
	_check(CupDrawScreen.LIST_Y0 + CupDrawScreen.LIST_PITCH * (CupDrawScreen.LIST_ROWS - 1)
		+ 15 == 418, "23 rows at a 16px pitch end on the frame's last separator (y=418)")

	var scr: CupDrawScreen = load("res://scenes/CupDrawScreen.gd").new()
	scr.size = Vector2(CupDrawScreen.W, CupDrawScreen.H)
	get_root().add_child(scr)
	for _i in 3:
		await process_frame
	_check(scr._chrome != null and scr._fondo != null, "chrome + drum backdrop loaded")
	_check(scr._bombo.size() == 12, "all twelve drum frames loaded (got %d)" % scr._bombo.size())

	# 3. Text fields reproduce the pen origins measured on the real frames.
	var g14: Dictionary = PMFont.chars("proman14")
	var g10: Dictionary = PMFont.chars("proman10")
	_check(not g14.is_empty() and not g10.is_empty(), "ProMan10/14 char tables load")
	for row in [["Coca-Cola Cup", 96], ["F.A. Cup", 121]]:
		_check(_pen(CupDrawScreen.TITLE_SUM, g14, str(row[0])) == int(row[1]),
			"title pen for %s == %d" % [row[0], int(row[1])])
	for row in [["ROUND 2", 113], ["ROUND 1", 116]]:
		_check(_pen(CupDrawScreen.ROUND_SUM, g14, str(row[0])) == int(row[1]),
			"round pen for %s == %d" % [row[0], int(row[1])])
	for row in [["1ST LEG", 30], ["2ND LEG", 27], ["MATCH", 33], ["REPLAY", 30]]:
		_check(_pen(CupDrawScreen.LEG_SUM, g10, str(row[0])) == int(row[1]),
			"leg pen for %s == %d" % [row[0], int(row[1])])
	# The home club is right-aligned so its pen ENDS at 465: "Preston NE" (adv 80) -> 385.
	_check(CupDrawScreen.HOME_RIGHT - _adv(g10, "Preston NE") == 385,
		"home club pen starts at 385 for Preston NE")
	_check(CupDrawScreen.AWAY_LEFT == 475 and CupDrawScreen.DASH_X == 467,
		"away club starts at 475, the dash sits at 467")

	# 4. The proportional thumb solves both witnessed tie counts.
	for w in [F74, F10]:
		var h := int(round(float(CupDrawScreen.TROUGH_H) * float(CupDrawScreen.LIST_ROWS)
			/ float(w["total"])))
		_check(h == int(w["thumb_h"]),
			"thumb height for %d ties == %d (got %d)" % [int(w["total"]), int(w["thumb_h"]), h])

	# 5. setup() takes the witnessed states, including a tie mid-draw.
	for w in [F74, F10]:
		scr.setup(str(w["key"]), str(w["title"]), str(w["round"]), [
			{"home": "Preston NE", "away": "Stockport C"},
			{"home": "Coventry", "away": ""},
		], int(w["total"]), w["legs"])
		await process_frame
		_check(scr._strip != null, "%s strip loaded" % w["key"])
		_check(scr._ties.size() == 2 and str((scr._ties[1] as Dictionary)["away"]) == "",
			"%s keeps the mid-draw tie with no away club yet" % w["key"])
		_check(scr._total == int(w["total"]), "%s tie total wired" % w["key"])
		_check(scr._legs == w["legs"], "%s leg plates wired" % w["key"])

	# 6. pin_drum holds one frame; the buttons emit.
	scr.pin_drum(8)
	_check(not scr.is_processing(), "pin_drum stops the drum animation")
	var fired := {"continue": false, "finish": false}
	scr.continue_pressed.connect(func() -> void: fired["continue"] = true)
	scr.finish_pressed.connect(func() -> void: fired["finish"] = true)
	_tap(scr, CupDrawScreen.BTN_CONTINUE.get_center())
	_tap(scr, CupDrawScreen.BTN_FINISH.get_center())
	await process_frame
	_check(bool(fired["continue"]), "CONTINUE emits")
	_check(bool(fired["finish"]), "FINISH emits")
	# A tap outside both buttons emits nothing.
	fired["continue"] = false
	_tap(scr, Vector2(200, 300))
	await process_frame
	_check(not bool(fired["continue"]), "a tap off the buttons emits nothing")

	# 7. The one-by-one reveal (p0125->p0131): clubs land home-first, one at a time;
	# a tap skips to the finished, parked draw; buttons come back afterwards.
	scr.setup("league_cup", "Coca-Cola Cup", "ROUND 3", [
		{"home": "Aston Villa", "away": "Carlisle U."},
		{"home": "Bradford City", "away": "Manchester Utd."},
	], 16, ["MATCH", "REPLAY"])
	scr.reveal()
	_check(scr.is_processing(), "reveal() starts the draw")
	var m0: Array = scr._masked_ties()
	_check(str((m0[0] as Dictionary)["home"]) == "", "step 0: nothing landed yet")
	scr._reveal_step = 1
	var m1: Array = scr._masked_ties()
	_check(str((m1[0] as Dictionary)["home"]) == "Aston Villa"
		and str((m1[0] as Dictionary)["away"]) == "",
		"step 1: tie 1's HOME alone (p0126's grammar)")
	scr._reveal_step = 3
	var m3: Array = scr._masked_ties()
	_check(str((m3[1] as Dictionary)["home"]) == "Bradford City"
		and str((m3[1] as Dictionary)["away"]) == "",
		"step 3: tie 2 mid-reveal exactly as p0127 shows it")
	var slip: Texture2D = scr._slip_name_tex("Bradford City")
	_check(slip != null, "the slip name renders (calend12 + the p0127 ink rule)")
	fired["continue"] = false
	_tap(scr, CupDrawScreen.BTN_CONTINUE.get_center())
	await process_frame
	_check(not scr._reveal_on and not scr.is_processing(),
		"a tap during the reveal skips to the parked draw")
	_check(not bool(fired["continue"]), "the skipping tap is swallowed")
	var mf: Array = scr._masked_ties()
	_check(str((mf[1] as Dictionary)["away"]) == "Manchester Utd.",
		"after the skip every club has landed")
	_tap(scr, CupDrawScreen.BTN_CONTINUE.get_center())
	await process_frame
	_check(bool(fired["continue"]), "CONTINUE works again once the draw is parked")

	print("\n%s" % ("ALL PASS" if _fail == 0 else "%d FAILED" % _fail))
	quit(0 if _fail == 0 else 1)


func _adv(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		w += int(g.get("adv", 0))
	return w


@warning_ignore("integer_division")
func _pen(field_sum: int, glyphs: Dictionary, s: String) -> int:
	return (field_sum - _adv(glyphs, s)) / 2


func _tap(scr: CupDrawScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		scr._on_input(e)


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fail += 1
	print("  [%s] %s" % ["PASS" if cond else "FAIL", what])
