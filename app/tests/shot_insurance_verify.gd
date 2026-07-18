extends SceneTree
## Render-verify INSURANCE vs the ORIGINAL wine witnesses (2026-07-18 run):
##   resting        -> 34_insure_ward (all uninsured; 33 minus the PARAM. focus ring)
##   insured        -> 37_after_ok    (Ward GROUP 1: green arrow + doc + 1 + 200)
##   modal fresh    -> 35_insure_ward2 (POLICY modal on Ward, UNINSURED, LUT dim)
##   modal selected -> 36_group1_sel   (pending "1": red border + preview GROUP 1/200)
##   modal Frandsen -> 38_frandsen_policy (name/wage swap, same flat prices)
## The squad is the REAL GameDB Bolton roster; the witness run's live fields
## (fitness / morale / age) are frame-injected per player — the same doctrine as
## the RivalScreen `av` levers. WAGE cells are masked in the comparator (app
## wages are the calibrated model, not the original's undecoded per-player
## wages — charter #10). The live barra (y<62) is masked as always.
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_insurance_verify.gd
func _initialize() -> void:
	_run()


# witness live fields per player (capture 34, rows top->bottom per section)
const LIVE := {
	"Ward": [70, 90, 27], "Branagan": [73, 84, 31], "Jaaskelainen": [69, 95, 22],
	"Todd": [69, 92, 23], "Taggart": [70, 97, 27], "Phillips": [73, 84, 31],
	"Fairclough": [70, 95, 33], "Bergsson": [73, 84, 32],
	"Sellars": [69, 92, 32], "Thompson": [73, 84, 24], "Frandsen": [73, 99, 27],
	"Sheridan": [69, 90, 33],
	"Johansen": [73, 84, 26], "Blake": [73, 99, 25], "Holdsworth": [73, 99, 29],
	"Gunnlaugsson": [73, 83, 24],
}


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	# Always bring up a FRESH GameDB: under windowed -s an autoload shell can
	# exist with no data loaded (club() returns {} -> empty sections).
	var gamedb: Node = load("res://scripts/GameDB.gd").new()
	gamedb.name = "GameDBShot"
	get_root().add_child(gamedb)
	await process_frame

	var club: Dictionary = gamedb.club(59).duplicate()   # Bolton W
	var players: Array = []
	for p in club.get("players", []):
		var pd: Dictionary = (p as Dictionary).duplicate(true)
		var nm := str(pd.get("name", ""))
		if LIVE.has(nm):
			pd["fitness"] = LIVE[nm][0]
			pd["morale"] = LIVE[nm][1]
			pd["age"] = LIVE[nm][2]
		players.append(pd)
	club["players"] = players

	var scr: InsuranceScreen = load("res://scenes/InsuranceScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	scr.setup(club, 1, {"mode": "manager", "top": "Coventry", "bottom": "Bolton W",
		"club_id": 59})
	print("sections: ", scr._sections.map(func(s): return [s["key"], (s["players"] as Array).size()]))
	await _shot(dir, "shot_ins_resting.png")

	# Ward -> GROUP 1 (witness 37)
	var ward := _find(players, "Ward")
	ward["insurance_group"] = 1
	scr.queue_redraw()
	await _shot(dir, "shot_ins_insured.png")

	# POLICY modal on Ward, fresh-open (witness 35: opened BEFORE he was insured)
	ward.erase("insurance_group")
	scr._modal_pid = int(ward.get("id", -1))
	scr._modal_p = ward
	scr._pending = -1
	scr.queue_redraw()
	await _shot(dir, "shot_ins_modal.png")

	# GROUP 1 tapped (witness 36: red pending border + header preview)
	scr._pending = 1
	scr.queue_redraw()
	await _shot(dir, "shot_ins_modal_sel.png")

	# Frandsen's modal, fresh (witness 38; Ward already GROUP 1 in the witness
	# but his row is behind the modal except the masked-out right strip)
	ward["insurance_group"] = 1
	var frandsen := _find(players, "Frandsen")
	scr._modal_pid = int(frandsen.get("id", -1))
	scr._modal_p = frandsen
	scr._pending = -1
	scr.queue_redraw()
	await _shot(dir, "shot_ins_modal_frandsen.png")

	print("INSURANCE verify shots -> %s" % dir)
	quit(0)


func _find(players: Array, nm: String) -> Dictionary:
	for p in players:
		if str((p as Dictionary).get("name", "")) == nm:
			return p
	return {}


func _shot(dir: String, name: String) -> void:
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
