extends SceneTree
## Frame-parity captures of the RESULTS -> cup KNOCKOUT views -- the LIST in its two
## witnessed states and the BRACKET in both column sets -- for pixel-diffing with
## tools/re/diff_knockout_parity.py.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_knockout_parity.gd
##
## Every club name, score and aggregate below is transcribed off the frames themselves
## (tools/re/refs/knockout-2026-07-26/) -- this asserts the RENDERER, so the data has to be
## the original's own, not the port's sim. The bracket ties carry the club ids and dbcard
## countryCodes too, because that layout blits the MINIESC kit and the flag; every id was
## verified against its frame cell (flags 0 px, kits unique-best at the measured origin).

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

# ---- the BRACKET witnesses (docs/re/knockout_views_re.md, re-measured 2026-07-26) ----

# 03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png -- the same Bolton W career at the
# euro QTR FINALS with every first leg played.
const EURO_QTR_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "14", "month": "March", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 32",
}

# home, away, home_id, away_id, home_flag, away_flag, leg1
const EURO_QTR_TIES := [
	["Borussia D.", "Manchester Utd.", 1038, 40, 2, 30, [0, 0]],
	["Olympiakos", "F.C. Barcelona", 1189, 1000, 26, 22, [1, 1]],
	["Real Madrid C.F.", "Bayern M.", 1003, 1042, 22, 2, [1, 0]],
	["Parma", "Sporting Port.", 1024, 1076, 36, 47, [1, 2]],
]

# 01_euro_qtr_finals_decided.png (wine-captures-2026-07-28-knockout-decided) -- the
# BRACKET with every tie DECIDED: both legs played, the AGGR. cell filled, and the winner
# inked through with the arrow at his end. This is the cell the 07-26 build had to leave
# as an inference; the frame settles it, and it settles the aggregate's GRAMMAR too --
# leg 2 is printed HOST-first (so it reads the other way round from leg 1), while AGGR. is
# always (left club, right club). Oporto 0-2 then 0-2 = 2-2 with Borussia through on away
# goals; Man Utd 2-0 then 0-1 = 3-0. Same career, Saturday 11 April 1998, Week 36.
const EURO_QTR_DONE_HEADER := {
	"top": "mats", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "11", "month": "April", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 36",
}

# home, away, home_id, away_id, home_flag, away_flag, leg1, leg2 (host first), aggr, winner
const EURO_QTR_DONE_TIES := [
	["Oporto", "Borussia D.", 1075, 1038, 47, 2, [0, 2], [0, 2], [2, 2], 1],
	["Parma", "Juventus", 1024, 1021, 36, 36, [0, 1], [1, 1], [1, 2], 1],
	["Manchester Utd.", "Bayern M.", 40, 1042, 30, 2, [2, 0], [0, 1], [3, 0], 0],
	["F.C. Barcelona", "Mónaco", 1000, 1060, 22, 24, [2, 1], [0, 1], [3, 1], 0],
]

# 08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png -- the same career's second
# season (Bolton relegated: 1st Div., Week 31), F.A. Cup QTR FINALS drawn, unplayed.
const FA_QTR_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Thursday", "day": "4", "month": "March", "year": "1999",
	"status_top": "1st Div.", "status_bottom": "Week 31",
}

const FA_QTR_TIES := [
	["Sheffield Utd", "Aston Villa", 77, 45],
	["Crystal Pal.", "Manchester Utd.", 63, 40],
	["Charlton Ath", "Arsenal", 70, 46],
	["West Ham Utd", "Leicester", 48, 57],
]

# ---- the SEMIFINAL cards + FINAL witnesses (measured 2026-07-27) --------------------

# 04_euroleague_semifinals_LEG1_PLAYED_1998-04-04.png -- the Bolton W career at the euro
# Semifinals, both first legs played (SF1 0-0, SF2 1-2), second legs pending.
const EURO_SEMI_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "4", "month": "April", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 35",
}

# home, away, home_id, away_id, home_ground, away_ground, leg1 [hg, ag] or []
const EURO_SEMI_TIES := [
	["Manchester Utd.", "Olympiakos", 40, 1189, "Old Trafford", "Karaiskakis", [0, 0]],
	["Sporting Port.", "Real Madrid C.F.", 1076, 1003, "Jose Alvalade",
		"Santiago Bernabéu", [1, 2]],
]

# 06_cocacola_semifinals_drawn_1998-01-10.png -- the same career, Coca-Cola Cup
# SEMIFINALS drawn, nothing played.
const CC_SEMI_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "10", "month": "January", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 23",
}

const CC_SEMI_TIES := [
	["WBA", "Manchester Utd.", 80, 40, "The Hawthorns", "Old Trafford", []],
	["Southampton", "Ipswich", 54, 66, "The Dell", "Portman Road", []],
]

# 05_euroleague_final_UNDECIDED_1998-04-25.png -- the euro Final at the neutral
# Das Antas, undecided.
const EURO_FINAL_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "25", "month": "April", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 38",
}


# ---- the KIT LIST witnesses (measured 2026-07-28) -----------------------------------

# 01_uefa_1_8finals_leg1_played_1997-12-07.png -- the same Bolton W career at the U.E.F.A.
# Cup 1/8 FINALS with every FIRST leg played and the other two columns still empty.
const UEFA_KL_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Sunday", "day": "7", "month": "December", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 19",
}

# home, away, home_id, away_id, leg1 (or [] for a drawn-but-unplayed round)
const UEFA_KL_TIES := [
	["Inter", "Estrasburgo", 1027, 1062, [1, 2]],
	["Jazz", "Vitesse", 1260, 1107, [0, 3]],
	["Twente", "Bastia", 1112, 1071, [0, 0]],
	["Auxerre", "Bochum", 1058, 1051, [1, 2]],
	["Munich 1860", "W.Lodz", 1047, 1147, [2, 0]],
	["R.C. Deportivo", "Lazio", 1001, 1023, [1, 0]],
	["Leicester", "Ajax", 57, 1103, [2, 0]],
	["Trabzonspor", "Udinese", 1141, 1032, [1, 1]],
]

# 09_comp_cwc.png -- the Cup Winner's Cup 1/8 FINALS, drawn, nothing played.
const CWC_KL_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "4", "month": "October", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 9",
}

const CWC_KL_TIES := [
	["Copenaghen", "G. Ekeren", 1171, 1125, []],
	["AIK Estoc.", "Vicenza", 1138, 1033, []],
	["Lokomotiv M.", "Kocaelispor", 1101, 1144, []],
	["AEK Atenas", "Beitar", 1188, 1270, []],
	["R. Betis B.", "Niza", 1015, 1068, []],
	["Boavista", "Chelsea", 1080, 49, []],
	["Stuttgart", "Roda", 1048, 1105, []],
	["Apoel Nic.", "Tromso", 1224, 1199, []],
]

# 13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png -- the DOMESTIC column set of the same
# layout, PLAYED: RES. filled, REPLAY empty, and the club going through inked yellow
# together with its own goal digit. Row 0 finished level, so neither club is inked.
const CC_KL_HEADER := {
	"top": "MATS", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Monday", "day": "1", "month": "December", "year": "1997",
	"status_top": "Premier", "status_bottom": "Week 18",
}

# home, away, home_id, away_id, res, winner (0 home / 1 away / -1 level)
const CC_KL_TIES := [
	["Crystal Pal.", "Manchester C", 63, 60, [1, 1], -1],
	["Oxford Utd", "Ipswich", 76, 66, [1, 3], 1],
	["Coventry", "Southend Utd", 53, 61, [3, 0], 0],
	["Reading", "Norwich C", 75, 71, [3, 1], 0],
	["WBA", "Derby County", 80, 56, [2, 1], 0],
	["Arsenal", "Tottenham H", 46, 47, [1, 0], 0],
	["Manchester Utd.", "Nottingham F.", 40, 41, [1, 0], 0],
	["Southampton", "Bournemouth", 54, 83, [2, 1], 0],
]


static func _kitlist_rows(ties: Array, euro: bool) -> Array:
	var rows: Array = []
	for t in ties:
		var cells: Array = [["", ""], ["", ""], ["", ""]] if euro else [["", ""], ["", ""]]
		var got: Array = t[4]
		if not got.is_empty():
			cells[0] = [str(int(got[0])), str(int(got[1]))]
		rows.append({"home": t[0], "away": t[1],
			"winner": int(t[5]) if t.size() > 5 else -1,
			"home_id": int(t[2]), "away_id": int(t[3]), "cells": cells})
	return rows


# 13_cocacola_semifinals_TWOLEGS_1998-04-11.png (tools/re/refs/knockout-2026-07-28) --
# the FIRST witness of a DECIDED semifinal: both legs played, both FINALIST plates filled.
# It is what closed the port's invented FINALIST fill, and it refutes the port's other
# inference here -- nothing in this layout is inked yellow, not the winning club's name and
# not his goals.
const CC_SEMI_DONE_HEADER := {
	"top": "mats", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "11", "month": "April", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 36",
}

# home, away, home_id, away_id, home_ground, away_ground, leg1 [host, guest],
# leg2 [host, guest], winner
const CC_SEMI_DONE_TIES := [
	["Wimbledon", "Blackburn R.", 51, 38, "Selhurst Park", "Ewood Park",
		[1, 1], [1, 2], 0],
	["Arsenal", "Manchester Utd.", 46, 40, "Highbury", "Old Trafford",
		[2, 0], [0, 1], 0],
]


# 12_facup_semifinals_FINALISTS_1998-04-11.png (tools/re/refs/knockout-2026-07-28) --
# the FIRST witness of a SINGLE-LEG semifinal phase: the domestic cup plays its semis as one
# match at a neutral ground, so each card carries ONE block whose bar reads RESULT (the
# two-legged one reads 1ST LEG), the venue is that block's own first row, and the panel ENDS
# after it. Both FINALIST plates are filled.
const FA_SEMI_HEADER := {
	"top": "mats", "bottom": "Bolton W", "club_id": 59,
	"weekday": "Saturday", "day": "11", "month": "April", "year": "1998",
	"status_top": "Premier", "status_bottom": "Week 36",
}

# home, away, home_id, away_id, neutral ground, result [home, away], winner
const FA_SEMI_TIES := [
	["Ipswich", "Blackburn R.", 66, 38, "Hillsborough", [1, 3], 1],
	["Stoke C", "Southampton", 78, 54, "Anfield", [3, 0], 0],
]


static func _card_single_rows(ties: Array) -> Array:
	var rows: Array = []
	for t in ties:
		var res: Array = t[5]
		rows.append({"home": t[0], "away": t[1], "winner": int(t[6]),
			"home_id": int(t[2]), "away_id": int(t[3]),
			"home_ground": str(t[4]), "away_ground": str(t[4]),
			"two_legged": false,
			"cells": [[str(int(res[0])), str(int(res[1]))], ["", ""]]})
	return rows


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
	await _shot(out, "knockout_euro_qtr", EURO_QTR_HEADER, "euro", "QTR FINALS", true,
		_bracket_rows(EURO_QTR_TIES, true), true, false, 0, "bracket")
	# Both paginator arrows are LIT here: the frame was paged BACK from the semifinals, so
	# a later phase exists and the right arrow is enabled (it is greyed on the leg-1 frame,
	# which was the live phase).
	await _shot(out, "knockout_euro_qtr_done", EURO_QTR_DONE_HEADER, "euro", "QTR FINALS",
		true, _bracket_rows(EURO_QTR_DONE_TIES, true), true, true, 0, "bracket")
	await _shot(out, "knockout_facup_qtr", FA_QTR_HEADER, "facup", "QTR FINALS", false,
		_bracket_rows(FA_QTR_TIES, false), true, false, 0, "bracket")
	# The cards family prints the euro label AS the sequential scheme spells it
	# ("Semifinals" / "Final", witnessed mixed-case) and the domestic one uppercased
	# ("SEMIFINALS", witnessed) -- Main applies the same rule.
	await _shot(out, "knockout_euro_semis", EURO_SEMI_HEADER, "euro", "Semifinals", true,
		_card_rows(EURO_SEMI_TIES), true, false, 0, "cards")
	await _shot(out, "knockout_cocacola_semis", CC_SEMI_HEADER, "cocacola", "SEMIFINALS",
		false, _card_rows(CC_SEMI_TIES), true, false, 0, "cards")
	await _shot(out, "knockout_cocacola_semis_done", CC_SEMI_DONE_HEADER, "cocacola",
		"SEMIFINALS", false, _card_done_rows(CC_SEMI_DONE_TIES), true, true, 0, "cards")
	await _shot(out, "knockout_facup_semis", FA_SEMI_HEADER, "facup", "SEMIFINALS",
		false, _card_single_rows(FA_SEMI_TIES), true, true, 0, "cards")
	await _shot(out, "knockout_uefa_kitlist", UEFA_KL_HEADER, "uefa", "1/8 FINALS", true,
		_kitlist_rows(UEFA_KL_TIES, true), true, false, 0, "kitlist")
	await _shot(out, "knockout_cwc_kitlist", CWC_KL_HEADER, "cwc", "1/8 FINALS", true,
		_kitlist_rows(CWC_KL_TIES, true), true, false, 0, "kitlist")
	await _shot(out, "knockout_cocacola_kitlist", CC_KL_HEADER, "cocacola", "ROUND 4",
		false, _kitlist_rows(CC_KL_TIES, false), true, false, 0, "kitlist")
	await _shot(out, "knockout_euro_final", EURO_FINAL_HEADER, "euro", "Final", true,
		[{"home": "Real Madrid C.F.", "away": "Olympiakos", "home_id": 1003,
			"away_id": 1189, "home_flag": 22, "away_flag": 26, "venue": "Das Antas",
			"winner": -1, "cells": [["", ""]]}],
		true, false, 0, "final")
	quit()


static func _card_rows(ties: Array) -> Array:
	var rows: Array = []
	for t in ties:
		var leg1: Array = t[6]
		var cells: Array = [["", ""], ["", ""], ["", ""]]
		if not leg1.is_empty():
			cells[0] = [str(int(leg1[0])), str(int(leg1[1]))]
		rows.append({"home": t[0], "away": t[1], "winner": -1,
			"home_id": int(t[2]), "away_id": int(t[3]),
			"home_ground": str(t[4]), "away_ground": str(t[5]),
			"two_legged": true, "cells": cells})
	return rows


static func _card_done_rows(ties: Array) -> Array:
	var rows: Array = []
	for t in ties:
		var l1: Array = t[6]
		var l2: Array = t[7]
		rows.append({"home": t[0], "away": t[1], "winner": int(t[8]),
			"home_id": int(t[2]), "away_id": int(t[3]),
			"home_ground": str(t[4]), "away_ground": str(t[5]),
			"two_legged": true,
			"cells": [[str(int(l1[0])), str(int(l1[1]))],
				[str(int(l2[0])), str(int(l2[1]))], ["", ""]]})
	return rows


static func _bracket_rows(ties: Array, euro: bool) -> Array:
	var rows: Array = []
	for t in ties:
		var row := {"home": t[0], "away": t[1], "winner": -1,
			"home_id": int(t[2]), "away_id": int(t[3])}
		if euro:
			row["home_flag"] = int(t[4])
			row["away_flag"] = int(t[5])
			var leg1: Array = t[6]
			row["cells"] = [[str(int(leg1[0])), str(int(leg1[1]))], ["", ""], ["", ""]]
			if t.size() > 9:      # a DECIDED tie also carries leg 2, the aggregate and the winner
				var leg2: Array = t[7]
				var aggr: Array = t[8]
				row["cells"] = [
					[str(int(leg1[0])), str(int(leg1[1]))],
					[str(int(leg2[0])), str(int(leg2[1]))],
					[str(int(aggr[0])), str(int(aggr[1]))],
				]
				row["winner"] = int(t[9])
		else:
			# every F.A. Cup QTR club is English (flag 30), and the round is unplayed
			row["home_flag"] = 30
			row["away_flag"] = 30
			row["cells"] = [["", ""], ["", ""]]
		rows.append(row)
	return rows


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
		euro_cols: bool, ties: Array, has_prev: bool, has_next: bool, offset: int,
		layout := "list") -> void:
	var scr: KnockoutScreen = load("res://scenes/KnockoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	scr.setup(header, comp, label, euro_cols, ties, has_prev, has_next, offset, layout)
	await process_frame
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	scr.queue_free()
	await process_frame
