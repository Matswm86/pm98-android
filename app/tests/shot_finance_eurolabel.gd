extends SceneTree
## Render the FINANCES summary's 4th income row once per European competition, so the
## label the original picks at draw time can be diffed against the frames that witness
## it. The row is `FUN_0050812e` @0x5081B0..0x50838F — a three-arm ladder:
##
##   (*DAT_0066b1b4)->vt[0x48]() != 0  -> EUROPEAN CUP INCOME     0x659B0C
##   (*DAT_0066b1b0)->vt[0x48]() != 0  -> CUP WINNERS CUP INCOME  0x659AF4 + 0x659B00
##   otherwise                         -> U.E.F.A. CUP INCOME     0x659AE0   (fall-through)
##
## Two of the three arms are witnessed and gated by `diff_finance_eurolabel_parity.py`:
##
##   european_cup     013_164406.png            Manchester Utd., in the European Cup
##   uefa_cup         orig/51_finance_season.png a non-European lower-club career
##
## The CUP WINNERS arm has no capture; it renders here so the string and its pen are
## still exercised, and the gate only asserts it differs from the other two.
##
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --resolution 640x480 --path app --script res://tests/shot_finance_eurolabel.gd

const KEYS := ["european_cup", "uefa_cup", "cup_winners_cup"]


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
	for key in KEYS:
		node.setup({}, "Manchester Utd.", "MWM", "1997-98", 0, 1, {}, [], {},
			FinanceScreen.NO_CASH_CLOSE, {"euro_comp": key})
		await process_frame
		await process_frame
		get_root().get_texture().get_image().save_png("%s/finance_eurolabel_%s.png" % [dir, key])
		print("SHOT finance_eurolabel_%s.png" % key)
	quit(0)
