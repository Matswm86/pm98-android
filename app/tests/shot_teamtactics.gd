extends SceneTree
## Render the TEAM TACTICS modal in the two WITNESSED states, for the render-diff
## against the parity-run frames (`tools/re/diff_teamtactics_parity.py`):
##   A `shot_teamtactics_resting.png`  = fresh Bolton (.DBC levers [45,50,2,1,0,0,0])
##                                       -> orig/25_team_tactics.png
##   B `shot_teamtactics_mantoman.png` = the same after MARKING -> MAN TO MAN
##                                       -> orig/26_mantoman.png
##   DISPLAY=:1 PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_teamtactics.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIPPED: needs a rendering driver, not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	var win := get_root()
	win.size = Vector2i(640, 480)
	win.transparent_bg = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(640, 480)
	win.add_child(bg)
	var scr: TeamTacticsScreen = load("res://scenes/TeamTacticsScreen.gd").new()
	scr.size = Vector2(640, 480)
	win.add_child(scr)
	var t := Tactics.new()
	t.apply_club_levers([45, 50, 2, 1, 0, 0, 0])   # Bolton's shipped stream = frame 25
	scr.setup(t)
	await _shot(win, "%s/shot_teamtactics_resting.png" % dir)
	t.set_marking("Man-to-man")                     # the 74-px toggle = frame 26
	scr.queue_redraw()
	await _shot(win, "%s/shot_teamtactics_mantoman.png" % dir)
	print("TEAMTACTICS shots -> %s" % dir)
	quit(0)


func _shot(win: Window, path: String) -> void:
	for _i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	win.get_texture().get_image().save_png(path)
