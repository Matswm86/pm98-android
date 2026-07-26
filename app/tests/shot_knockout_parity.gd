extends SceneTree
## Frame-parity captures of the RESULTS -> cup KNOCKOUT list view, in the two states the
## live originals show, for pixel-diffing with tools/re/diff_knockout_parity.py.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_knockout_parity.gd
##
## Every club name, score and aggregate below is transcribed off the frames themselves
## (tools/re/refs/knockout-2026-07-26/) -- this asserts the RENDERER, so the data has to be
## the original's own, not the port's sim.

const EURO_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "9", "month": "August", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 1",
}

const FA_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "20", "month": "December", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 20",
}

# home, away, winner (0 home / 1 away), leg1, leg2 (leg-2 host first), aggregate
const EURO_TIES := [
	["Maribor B.", "Derry City", 1, [2, 1], [1, 0], [2, 2]],
	["Akranes", "Kosice", 0, [4, 2], [1, 1], [5, 3]],
	["Croatia Zag.", "Partizán", 0, [1, 1], [1, 2], [3, 2]],
	["Skonto", "Valletta", 1, [1, 3], [1, 1], [2, 4]],
	["MTK", "Pyunic", 0, [4, 0], [0, 4], [8, 0]],
	["Dinamo Tbilisi", "Crusaders", 0, [5, 1], [0, 2], [7, 1]],
	["Beitar", "Sileks", 0, [4, 1], [0, 3], [7, 1]],
	["CSKA Sofía", "Steaua B.", 1, [1, 2], [2, 2], [3, 4]],
	["Mozyr", "Constructorul", 1, [1, 3], [3, 1], [2, 6]],
	["Jazz", "Lantana", 0, [1, 1], [0, 4], [5, 1]],
	["G. Rangers", "Gotu", 1, [1, 1], [2, 1], [2, 3]],
	["W.Lodz", "Neftchi", 0, [4, 0], [1, 3], [7, 1]],
	["Barry Town", "S.Donetsk", 1, [1, 1], [1, 1], [2, 2]],
	["Jeunesse", "Sion", 1, [2, 4], [3, 2], [4, 7]],
	["Kareda S.", "Anorthosis", 0, [1, 0], [0, 4], [5, 0]],
]

# The F.A. Cup ROUND 3 draw, every tie unplayed -- the domestic column set with both cells
# empty and no club inked through.
const FA_TIES := [
	["Barrow", "Sheffield W."],
	["Wolverhampton", "Wrexham"],
	["Bristol Rovers", "Reading"],
	["Charlton Ath", "Plymouth Arg."],
	["Hartlepool U.", "Birmingham C"],
	["Hednesford T.", "Barnsley"],
	["Manchester C", "Port Vale"],
	["Crystal Pal.", "Leeds Utd"],
	["Peterborough", "Bolton W"],
	["Bradford City", "Burnley"],
	["Southend Utd", "Chelsea"],
	["Slough T.", "West Ham Utd"],
	["Huddersfield T", "Bury"],
	["Hull C.", "Doncaster R."],
	["Portsmouth", "Wigan Ath."],
	["Tranmere Rov", "Mansfield T."],
]

# The witnessed R3 frame carries a scrollbar, so the round is longer than the panel. Its
# thumb length implies ~20 ties; the tracking rule is an inference (see the RE doc), which
# is why diff_knockout_parity.py buckets the scrollbar column separately.
const FA_TOTAL := 20


func _init() -> void:
	var out := "res://out"
	if OS.has_environment("PM98_SHOT_DIR"):
		out = OS.get_environment("PM98_SHOT_DIR")
	DirAccess.make_dir_recursive_absolute(out)
	get_root().content_scale_size = Vector2i(640, 480)

	await process_frame
	await _shot(out, "knockout_euro_round1", EURO_HEADER, "euro", "ROUND 1", true,
		_euro_rows(), false, true, 0)
	await _shot(out, "knockout_facup_round3", FA_HEADER, "facup", "ROUND 3", false,
		_fa_rows(), true, false, 0)
	quit()


func _euro_rows() -> Array:
	var rows: Array = []
	for t in EURO_TIES:
		var cells: Array = []
		for k in [3, 4, 5]:
			var p: Array = t[k]
			cells.append([str(int(p[0])), str(int(p[1]))])
		rows.append({"home": t[0], "away": t[1], "winner": int(t[2]), "cells": cells})
	return rows


func _fa_rows() -> Array:
	var rows: Array = []
	for t in FA_TIES:
		# The manager's own tie takes the panel's third row style (Bolton W, R3 row 9).
		rows.append({"home": t[0], "away": t[1], "winner": -1,
			"mine": t[0] == "Bolton W" or t[1] == "Bolton W",
			"cells": [["", ""], ["", ""]]})
	# Pad to the total the scrollbar implies, so the thumb is the witnessed length. The
	# hidden ties are never drawn.
	while rows.size() < FA_TOTAL:
		rows.append({"home": "", "away": "", "winner": -1, "cells": [["", ""], ["", ""]]})
	return rows


func _shot(out: String, name: String, header: Dictionary, comp: String, label: String,
		euro_cols: bool, ties: Array, has_prev: bool, has_next: bool, offset: int) -> void:
	var scr: KnockoutScreen = load("res://scenes/KnockoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	scr.setup(header, comp, label, euro_cols, ties, has_prev, has_next, offset)
	await process_frame
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	scr.queue_free()
	await process_frame
