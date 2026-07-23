extends SceneTree
## Render-verify the FINANCES ledger with a LIVE insurance economy: the three
## lines the 2026-07-23 port fills (INSURANCE GROUP 3 income, PLAYERS' INSURANCE
## and HOSPITALS expenses) plus the PLAYERS' WAGE netting the original applies at
## ledger slot +0x54. Eyeball against
## screenshots/original-walkthrough-2026-07-02/013_164406.png row order.
##   PM98_SHOT_DIR=out godot4 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_finance_insurance_verify.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	# Insure a slice of the squad and hurt three of them, then run 10 weeks of the
	# insurance pass so the season-to-date ledger carries real accumulated figures.
	var squad := career.my_squad()
	for i in squad.size():
		var p: Dictionary = squad[i]
		p["injured_weeks"] = 0
		if i % 3 == 0:
			p["insurance_group"] = 1 + (i / 3) % 3
	for i in [0, 3, 6]:   # one man on each of GROUP 1 / 2 / 3
		var p: Dictionary = squad[i]
		p["injured_weeks"] = 6
		p["injury_weeks_total"] = 6
		p["injury_type"] = 4
	for _w in 10:
		career._tick_insurance()
	print("ledger: %s" % career.insurance_ledger())

	var club := {"capacity": career.stadium_capacity, "players": squad,
		"ticket_price": career.ticket_price, "board_price": career.board_price}
	var sm := FinanceModel.summary(club, career.tier)
	var scr: FinanceScreen = load("res://scenes/FinanceScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(sm, career.club_name, "", career.season, career.cash, 11,
		career.insurance_ledger())
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("finance_insurance_live.png"))
	print("SHOT finance_insurance_live.png")
	quit(0)
