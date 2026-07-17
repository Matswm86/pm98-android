extends SceneTree
## Charter #6 verification render: the FULL TIME read-out for a manager-AWAY league match
## (The Dell, Southampton v Bolton, "Premier"/"Week 1") — proves the corrected score box,
## the ALWAYS-FILLED fixture-home stadium panel (real EQUIPOS capacity), and the in-season
## header chip. Compare vs screenshots/wine-captures-2026-07-17-matchflow/
## readout_fulltime_thedell_away_filled.png.
##   DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --path app -s tests/shot_readout_verify.gd
func _initialize() -> void:
	_run()
func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "": dir = "/tmp"
	await process_frame
	get_root().size = Vector2i(640, 480)
	# Southampton (home, id 54, The Dell 15200) 1-1 Bolton W (away, id 59).
	var goals: Array = [{"minute":57,"side":0,"scorer":"Hirst"},
		{"minute":63,"side":1,"scorer":"Blake"}]
	var header := {"mode":"fixture","top":"Southampton","bottom":"Bolton W",
		"home_id":54,"away_id":59,"weekday":"Saturday","day":"9","month":"August","year":"1997",
		"status_top":"Premier","status_bottom":"Week 1"}
	var res: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	res.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(res)
	# Stadium = fixture HOME (Southampton) real capacity 15200; attendance a projection.
	res.setup("Southampton","Bolton W",1,1,goals,54,59,header,
		{"name":"The Dell","capacity":15200,"attendance":12160}, false)
	for _i in 8: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_readout_dell_ft.png" % dir)
	print("SHOT done -> %s/shot_readout_dell_ft.png" % dir)
	quit(0)
