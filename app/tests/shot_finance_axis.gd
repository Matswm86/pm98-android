extends SceneTree
## Render the FINANCES summary's BALANCE chart once per axis state, so the ±N K. labels
## can be diffed against the two frames that witness them.
##
## The scale is not fixed. `FUN_00509760` accumulates the largest |week-on-week balance
## delta| over the plotted weeks (@0x50994a..0x509990) and then picks the SMALLEST entry
## of a three-float table that is at least that — .data 0x659540 = 50,000,000f,
## 0x659544 = 100,000,000f, 0x659548 = 500,000,000f, walked down from the largest
## @0x509a31..0x509a57 — printing it × 5e-06 (the double at 0x62d930) between "+"/"-"
## (0x6587d4 / 0x654448) and " K." (0x659b2c), in the face the routine names at
## @0x509d92: "euro8" (0x6597a4).
##
## So the original draws exactly three axes, and two of them are on real frames:
##
##   k2500   013_164406.png              ±2,500 K.
##   k250    orig/51_finance_season.png  ±250 K.
##   k500    no capture — rendered so the middle step is exercised, never compared
##
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_finance_axis.gd

## One book each, whose balance forces the step under test. The plotted value is the
## week's own income − expense, so a single week is enough to set the peak.
const CASES := [
	["k250", 250_000],
	["k500", 400_000],
	["k2500", 900_000],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var node: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)
	for c in CASES:
		var books: Array = [{"week": 1, "income": {"TICKETS": int(c[1])}, "expense": {}}]
		node.setup({}, "Manchester Utd.", "MWM", "1997-98", 0, 1, {}, books)
		await process_frame
		await process_frame
		get_root().get_texture().get_image().save_png("%s/finance_axis_%s.png" % [dir, c[0]])
		print("SHOT finance_axis_%s.png  scale=%d" % [c[0], node.axis_scale()])
	quit(0)
