extends SceneTree
## Render the CHARITY SHIELD and INTERCONTINENTAL CUP competition screens against the
## real MANAGER.EXE frames they were baked from. Both shots reproduce the WITNESSED
## fixtures (Man Utd 1-0 Chelsea at Wembley; Borussia D. v Cruzeiro at Tokyo, un-played)
## so the output can be diffed straight against
## screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_{charity,intercont}.png
## by tools/re/diff_compresult_parity.py.
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_comp_result.gd

const HEADER := {"mode": "manager", "top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "4", "month": "October", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 9"}


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

	var shots := [
		["charity", {"stadium": "Wembley",
			"home": {"name": "Manchester Utd.", "club_id": 40, "flag": 30},
			"away": {"name": "Chelsea", "club_id": 49, "flag": 30},
			"hg": 1, "ag": 0,
			"winner": {"name": "Manchester Utd.", "club_id": 40, "flag": 30}}],
		["intercont", {"stadium": "Tokyo",
			"home": {"name": "Borussia D.", "club_id": 1038, "flag": 2},
			"away": {"name": "Cruzeiro", "club_id": 1306, "flag": 10}}],
	]
	for shot in shots:
		var node: CompResultScreen = load("res://scenes/CompResultScreen.gd").new()
		get_root().add_child(node)
		node.position = Vector2.ZERO
		node.size = Vector2(640, 480)
		node.setup(str(shot[0]), shot[1], HEADER)
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png("%s/comp_%s.png" % [dir, str(shot[0])])
		print("wrote %s/comp_%s.png" % [dir, str(shot[0])])
		node.queue_free()
		await process_frame
	quit(0)
