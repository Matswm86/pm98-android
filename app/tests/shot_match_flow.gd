extends SceneTree
## Real GL render of the three match-flow scenes to PNG (proves they render in-engine,
## not just headless logic). Run under Xvfb:
##   PM98_SHOT_DIR=/tmp xvfb-run -a ~/godot462 --path app -s tests/shot_match_flow.gd
func _initialize() -> void:
	_run()
func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "": dir = "/tmp"
	await process_frame
	# RESULT (full time)
	var res: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	res.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(res)
	get_root().size = Vector2i(640, 480)
	var goals: Array = [{"minute":18,"side":1,"scorer":"Solskjaer"},
		{"minute":36,"side":0,"scorer":"Cole"},{"minute":59,"side":1,"scorer":"Solskjaer"}]
	var header := {"mode":"fixture","top":"Manchester Utd.","bottom":"Bolton W",
		"home_id":40,"away_id":1000,"weekday":"Friday","day":"1","month":"August","year":"1997",
		"status_top":"Preseason","status_bottom":"Preparation"}
	res.setup("Manchester Utd.","Bolton W",1,2,goals,40,1000,header,
		{"name":"Old Trafford","capacity":55300,"attendance":19355}, false)
	for _i in 8: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_result_ft.png" % dir)
	res.queue_free()
	# BRIEF
	var br: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	br.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(br)
	br.set_process(false)
	var lines: Array = [{"minute":23,"side":0,"text":"Goal by A","goal":true},
		{"minute":34,"side":1,"text":"Shot saved by B"},
		{"minute":58,"side":1,"text":"Goal by B","goal":true}]
	br.setup("F.C. Barcelona","Manchester Utd.",1,1,lines,1021,40)
	br.seek(58.0)
	for _i in 6: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_brief.png" % dir)
	br.queue_free()
	# MATCH OPTIONS
	var mo: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	mo.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(mo)
	for _i in 6: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_matchopts.png" % dir)
	print("SHOTS done -> %s" % dir)
	quit(0)
