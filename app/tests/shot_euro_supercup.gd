extends SceneTree
## Render the EUROPEAN SUPERCUP screen against the real MANAGER.EXE frame it was baked
## from. The shot reproduces the WITNESSED 1997-98 tie exactly as the original has it —
## Borussia D. v F.C. Barcelona, DRAWN BUT NOT PLAYED, leg 1 at Camp Nou (the Cup
## Winners' Cup holder at home), leg 2 at Westfalen — so the output diffs straight
## against screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_supercup.png.
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_euro_supercup.gd

const HEADER := {"mode": "manager", "top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "4", "month": "October", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 9"}

const BARCA := {"name": "F.C. Barcelona", "club_id": 1000, "flag": 34}
const DORTMUND := {"name": "Borussia D.", "club_id": 1038, "flag": 2}


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

	var node: EuroSupercupScreen = load("res://scenes/EuroSupercupScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)
	node.setup({"legs": [
		{"stadium": "Camp Nou", "home": BARCA, "away": DORTMUND},
		{"stadium": "Westfalen", "home": DORTMUND, "away": BARCA},
	]}, HEADER)
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("%s/euro_supercup.png" % dir)
	print("wrote %s/euro_supercup.png" % dir)
	quit(0)
