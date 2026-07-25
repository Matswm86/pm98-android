extends SceneTree
## Frame-parity captures of the EURO. LEAGUE GROUP screen in the six states the live
## originals show (Bolton W career, wk22, GROUP A..F after the final matchday) for
## pixel-diffing with tools/re/diff_euroleague_parity.py.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_euroleague_parity.gd
##
## The table numbers, the two fixtures and the clubs are transcribed off the frames
## themselves (tools/re/refs/euro-competitions-2026-07-25/10..15) -- this asserts the
## RENDERER, so the data must be the original's own, not the port's sim.

const HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Sunday", "day": "28", "month": "December", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 22",
}

# name, countryCode (the MINIBAND index), club_id (the kit), pts p w d l gf ga
const GROUPS := {
	"A": {
		"table": [
			["Göteborg", 53, 1135, 15, 6, 5, 0, 1, 14, 6],
			["Manchester Utd.", 30, 40, 13, 6, 4, 1, 1, 11, 3],
			["Borussia D.", 2, 1038, 5, 6, 1, 2, 3, 4, 10],
			["Anorthosis", 15, 1223, 1, 6, 0, 1, 5, 4, 14],
		],
		"res": [[40, "Manchester Utd.", 1038, "Borussia D.", 3, 0],
			[1135, "Göteborg", 1223, "Anorthosis", 4, 1]],
	},
	"B": {
		"table": [
			["Lierse", 12, 1124, 11, 6, 3, 2, 1, 7, 6],
			["PSV", 27, 1106, 10, 6, 2, 4, 0, 8, 5],
			["C.Salzburgo", 5, 1161, 7, 6, 2, 1, 3, 5, 9],
			["B. Leverkusen", 2, 1050, 4, 6, 1, 1, 4, 9, 9],
		],
		"res": [[1050, "B. Leverkusen", 1106, "PSV", 2, 2],
			[1124, "Lierse", 1161, "C.Salzburgo", 1, 0]],
	},
	"C": {
		"table": [
			["Parma", 36, 1024, 12, 6, 4, 0, 2, 10, 8],
			["Brondby", 18, 1172, 9, 6, 3, 0, 3, 11, 11],
			["Oporto", 47, 1075, 9, 6, 3, 0, 3, 13, 16],
			["Valletta", 40, 1274, 6, 6, 2, 0, 4, 11, 10],
		],
		"res": [[1075, "Oporto", 1024, "Parma", 1, 0],
			[1172, "Brondby", 1274, "Valletta", 3, 0]],
	},
	"D": {
		"table": [
			["Juventus", 36, 1021, 13, 6, 4, 1, 1, 12, 5],
			["Mónaco", 24, 1060, 11, 6, 3, 2, 1, 10, 8],
			["Olympiakos", 26, 1189, 6, 6, 2, 0, 4, 5, 9],
			["Barry Town", 45, 1262, 4, 6, 1, 1, 4, 8, 13],
		],
		"res": [[1060, "Mónaco", 1021, "Juventus", 1, 1],
			[1189, "Olympiakos", 1262, "Barry Town", 0, 2]],
	},
	"E": {
		"table": [
			["Newcastle Utd", 30, 44, 15, 6, 5, 0, 1, 12, 3],
			["Gotu", 34, 1278, 8, 6, 2, 2, 2, 7, 7],
			["Croatia Zag.", 17, 1131, 8, 6, 2, 2, 2, 5, 7],
			["Rosenborg", 44, 1193, 3, 6, 1, 0, 5, 3, 10],
		],
		"res": [[1131, "Croatia Zag.", 44, "Newcastle Utd", 0, 2],
			[1278, "Gotu", 1193, "Rosenborg", 1, 2]],
	},
	"F": {
		"table": [
			["Real Madrid C.F.", 22, 1003, 12, 6, 4, 0, 2, 11, 6],
			["Bayern M.", 2, 1042, 9, 6, 3, 0, 3, 9, 11],
			["Feyenoord", 27, 1104, 7, 6, 2, 1, 3, 10, 10],
			["MTK", 29, 1231, 7, 6, 2, 1, 3, 8, 11],
		],
		"res": [[1104, "Feyenoord", 1042, "Bayern M.", 1, 3],
			[1231, "MTK", 1003, "Real Madrid C.F.", 0, 2]],
	},
}


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var scr: EuroGroupScreen = load("res://scenes/EuroGroupScreen.gd").new()
	get_root().add_child(scr)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)

	for L in ["A", "B", "C", "D", "E", "F"]:
		var g: Dictionary = GROUPS[L]
		var rows: Array = []
		for t in (g["table"] as Array):
			rows.append({"name": t[0], "flag": t[1], "club_id": t[2], "pts": t[3],
				"p": t[4], "w": t[5], "d": t[6], "l": t[7], "gf": t[8], "ga": t[9]})
		var res: Array = []
		for r in (g["res"] as Array):
			res.append({"home_id": r[0], "home": r[1], "away_id": r[2], "away": r[3],
				"hg": r[4], "ag": r[5], "played": true})
		scr.setup(HEADER, L, 6, 6, rows, res)
		await _grab(dir, "euro_group_%s.png" % L)

	quit(0)


func _grab(dir: String, name: String) -> void:
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join(name))
