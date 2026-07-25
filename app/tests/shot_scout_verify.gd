extends SceneTree
## Render-verify SCOUT vs the ORIGINAL wine witnesses (2026-07-18 run):
##   noscout   -> 43_scout            (washed criteria + gate text)
##   idle      -> 61_scout_with_scout (K. Burrowes strip, nothing selected)
##   premier   -> 63_premier_checked  (Premier LED ON)
##   position  -> 67_pos_enabled      (POSITION LED + GOALKEEPER + Premier)
##   searching -> 68_results3         (armed SEARCH ring + searching text)
##   results   -> 81_scout_found2     (headers + the 8 witnessed rows + scroll)
## Result rows are injected with the WITNESS values (names/AV/MO/fees/wages/
## years as captured) — fee/wage VALUES are the app model in live play
## (charter #10), but the witness figures render through the same formatter so
## the grammar verifies pixel-true. The live barra (y<62) is masked in the
## comparator as always.
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_scout_verify.gd
func _initialize() -> void:
	_run()


# the 8 visible witnessed rows (81): name, stars(ca), av, mo, fee, wage, years
const ROWS := [
	["Beeney", 70, 69, 89, 125000, 40000, 1],
	["Oakes", 70, 74, 82, 750000, 100000, 1],
	["Heald", 70, 73, 97, 650000, 100000, 2],
	["Filan", 70, 73, 79, 650000, 150000, 3],
	["Hislop", 80, 85, 80, 10000000, 1200000, 2],
	["Walker", 70, 75, 84, 1000000, 250000, 2],
	["Hoult", 70, 74, 88, 750000, 75000, 1],
	["Sullivan", 70, 74, 79, 650000, 100000, 1],
]


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var scr: ScoutScreen = load("res://scenes/ScoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame

	var barra := ["Bolton W", "mwm", "1997-98", 3, "Premier League", 59]

	# 1. no scout (witness 43)
	scr.setup({}, false, [], barra[0], barra[1], barra[2], barra[3], barra[4], barra[5])
	await _shot(dir, "shot_scout_noscout.png")

	# 2. hired idle (witness 61)
	var scout := {"name": "K. BURROWES", "stars": 3.0, "wage": 20000}
	scr.setup(scout, false, [], barra[0], barra[1], barra[2], barra[3], barra[4], barra[5])
	await _shot(dir, "shot_scout_idle.png")

	# 3. Premier checked (witness 63)
	scr._leagues["eng_prem"] = true
	scr.queue_redraw()
	await _shot(dir, "shot_scout_premier.png")

	# 4. POSITION enabled + GOALKEEPER (witness 67)
	scr._tog["pos"] = true
	scr._pos_idx = 0
	scr.queue_redraw()
	await _shot(dir, "shot_scout_position.png")

	# 4b. all LEFT-column criteria ON, showing the binary-exact band dropdowns
	# (AGE / QUALITY small fields = short band strings; ROLE / PRICE wide fields)
	scr._tog["age"] = true
	scr._age_idx = 2          # "27-30"
	scr._tog["role"] = true
	scr._role = 9             # CENTRAL MID.
	scr._tog["quality"] = true
	scr._quality_idx = 3      # "76-80"
	scr._tog["price"] = true
	scr._price_idx = 4        # "500 - 1,500 K."
	scr.queue_redraw()
	await _shot(dir, "shot_scout_criteria.png")

	# 5. searching + armed ring (witness 68)
	scr._tog["age"] = false
	scr._tog["role"] = false
	scr._tog["quality"] = false
	scr._tog["price"] = false
	scr._searching = true
	scr._armed_flash = true
	scr.queue_redraw()
	await _shot(dir, "shot_scout_searching.png")

	# 6. results (witness 81) — 8 witnessed rows + dummies to the witnessed
	# scrollbar total (slider 18px == floor(94*8/40) -> 40 results)
	var results: Array = []
	for r in ROWS:
		results.append({"pid": 0, "club_id": 0, "club_name": "", "name": r[0],
			"flagCode": 4 if r[0] == "Filan" else null,
			"nationality": "AUSTRALIA" if r[0] == "Filan" else "ENGLAND",
			"pos": "GK", "posFine": 1, "age": 30, "av": r[2], "ca": r[1], "mo": r[3],
			"fee": r[4], "wage": r[5], "years": r[6], "left": r[6], "key": false})
	for i in 32:
		results.append({"pid": 0, "club_id": 0, "club_name": "", "name": "Dummy",
			"flagCode": null, "nationality": "ENGLAND", "pos": "GK", "posFine": 1,
			"age": 30, "av": 50, "ca": 50, "mo": 50, "fee": 100000, "wage": 10000,
			"years": 1, "left": 1, "key": false})
	scr.setup(scout, false, results, barra[0], barra[1], barra[2], barra[3], barra[4], barra[5])
	scr._leagues["eng_prem"] = true
	scr._tog["pos"] = true
	scr._pos_idx = 0
	scr.queue_redraw()
	await _shot(dir, "shot_scout_results.png")

	# 7. the OURS panel (docs/SPEC_scout_attribute_search.md) — NOT a witness state:
	# the original has no such panel. It exists so the addition is eyeballed like every
	# other screen; the six shots above are the parity ones, and they are taken with it
	# CLOSED, which is how the screen ships.
	scr.setup(scout, false, results, barra[0], barra[1], barra[2], barra[3], barra[4],
		barra[5], 112)
	scr._activate("ours_open")
	scr._attr_idx["TI"] = 11        # SHOOTING >= 85
	scr._attr_idx["PA"] = 8         # PASSING >= 70
	scr._sort_i = 1                 # sort by AV
	scr.queue_redraw()
	await _shot(dir, "shot_scout_ours_panel.png")

	print("SCOUT verify shots -> %s" % dir)
	quit(0)


func _shot(dir: String, name: String) -> void:
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
