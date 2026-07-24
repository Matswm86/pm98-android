extends SceneTree
## Real-render both MONTHLY AWARDS sheets with the WITNESSED August 1997 winners,
## for a pixel diff against the original frames
## (screenshots/wine-captures-2026-07-18-goalscorers/76_after_drawcont.png and
## 77_after_motm.png) via tools/re/diff_awards_parity.py.
##   PM98_SHOT_DIR=out/aw ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_month_awards.gd

# frame 76: PREMIER Hodgson/Blackburn R., FIRST Walker/Norwich C,
#           SECOND Machin/Bournemouth, THIRD King/Shrewsbury T.
const MGR_ROWS := {
	1: {"club": "Blackburn R.", "manager": "Hodgson"},
	2: {"club": "Norwich C", "manager": "Walker"},
	3: {"club": "Bournemouth", "manager": "Machin"},
	4: {"club": "Shrewsbury T.", "manager": "King"},
}
# frame 77: the PREMIER LEAGUE column pair, in the frame's own order
const PLY_ROWS := [
	["Arsenal", "Wright"], ["Aston Villa", "Wright"], ["Barnsley", "De Zeeuw"],
	["Blackburn R.", "Sherwood"], ["Bolton W", "Holdsworth"], ["Chelsea", "Clarke"],
	["Coventry", "Williams"], ["Crystal Pal.", "Gordon"], ["Derby County", "Sturridge"],
	["Everton", "Oster"],
	["Leeds Utd", "Hopkin"], ["Leicester", "Heskey"], ["Liverpool", "Matteo"],
	["Manchester Utd.", "Sheringham"], ["Newcastle Utd", "Barnes"],
	["Sheffield W.", "Booth"], ["Southampton", "Lundekvam"], ["Tottenham H", "Ferdinand"],
	["West Ham Utd", "Ferdinand"], ["Wimbledon", "Pearce"],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver, not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var mgr: ManagersMonthScreen = load("res://scenes/ManagersMonthScreen.gd").new()
	_mount(mgr)
	await process_frame
	var rows: Dictionary = {}
	for t in MGR_ROWS:
		rows[int(t)] = {"club_id": -1, "club": str(MGR_ROWS[t]["club"]),
			"manager": str(MGR_ROWS[t]["manager"])}
	mgr.setup("AUGUST", rows)
	await _shot(dir, "awards_managers.png")
	mgr.queue_free()
	await process_frame

	var ply: PlayersMonthScreen = load("res://scenes/PlayersMonthScreen.gd").new()
	_mount(ply)
	await process_frame
	var prem: Array = []
	for r in PLY_ROWS:
		prem.append({"club_id": -1, "club": str(r[0]), "player": str(r[1])})
	ply.setup("AUGUST", {1: prem}, 1)
	await _shot(dir, "awards_players.png")
	print("AWARDS SHOTS DONE")
	quit(0)


func _mount(n: Control) -> void:
	get_root().add_child(n)
	n.set_anchors_preset(Control.PRESET_TOP_LEFT)
	n.position = Vector2.ZERO
	n.size = Vector2(640, 480)


func _shot(dir: String, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	print("SHOT %s err=%d" % [name, img.save_png(dir.path_join(name))])
