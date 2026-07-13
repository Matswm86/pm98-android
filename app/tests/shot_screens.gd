extends SceneTree
## Minimal REAL-render capture of the original-art screens — one PNG each, then quit.
## Deliberately tiny and Main-scene-free (no career, no season sim) so it cannot hang
## the screenshot CI the way the full devshot walk can. Renders each screen's own
## background + chrome through the actual Godot renderer (Xvfb + software GL in CI), so
## the PNGs are ground-truth device-equivalent captures, not Python mirror renders.
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_screens.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	# Requires a real renderer: `await RenderingServer.frame_post_draw` never fires on the
	# headless dummy driver, so a --headless run hangs forever. Fail loud instead.
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: shot_screens needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	# [scene script, png name]; both use the bezel + full-screen bg draw pattern, so a
	# grey result on either tells us the art-screen render path itself is broken.
	var screens := [
		["res://scenes/TitleScreen.gd", "title.png"],
		["res://scenes/MenuScreen.gd", "menu.png"],
		["res://scenes/SquadScreen.gd", "squad_demo.png"],
		["res://scenes/LineupScreen.gd", "lineup_demo.png"],
		["res://scenes/FinanceScreen.gd", "finance_demo.png"],
		["res://scenes/TransferScreen.gd", "transfer_demo.png"],
		["res://scenes/RivalScreen.gd", "rival_demo.png"],
		["res://scenes/TacticsBoardScreen.gd", "tactics_board_demo.png"],
		["res://scenes/PlayerInfoScreen.gd", "playerinfo_demo.png"],
		["res://scenes/CurrentOffersScreen.gd", "current_offers_demo.png"],
		["res://scenes/NivelScreen.gd", "nivel_demo.png"],
		["res://scenes/SeleccionScreen.gd", "seleccion_demo.png"],
		["res://scenes/PreseasonScreen.gd", "preseason_demo.png"],
		["res://scenes/LeagueTableScreen.gd", "leaguetable_demo.png"],
	]
	var club := _demo_club()
	var tactics := Tactics.auto_pick(club)
	# Render at the game's native 640x480 so each screen draws at scale 1, origin 0 (full,
	# centred, uncut). Pinning the window + node to 640x480 avoids the FULL_RECT-vs-window
	# race that drew screens offset/zoomed when sized to the OS window.
	get_root().size = Vector2i(640, 480)
	for s in screens:
		var node: Control = load(s[0]).new()
		get_root().add_child(node)
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 0.0
		node.anchor_bottom = 0.0
		node.position = Vector2.ZERO
		node.size = Vector2(640, 480)
		if node.has_method("setup") and s[1] == "menu.png":
			node.setup("SAMPLE FC", "Premier League", "1997-98", 1_000_000, "1st", 38)
		elif s[1] == "squad_demo.png":
			# Contract-view fixture: individuated squad numbers + contract fields so the
			# N°/WAGE/YEARS cells render populated (a bare GameDB club shows "-").
			var sq: Dictionary = club.duplicate(true)
			var i := 0
			for p in sq.get("players", []):
				i += 1
				p["squadNo"] = i
				p["contract_years"] = 1 + (i % 4)
				p["contract_term"] = 1 + (i % 4)
			node.setup(sq, "M. MJATVEDT", "1,000,000", false, "1997-98", 1)
		elif s[1] == "lineup_demo.png":
			node.setup(club, tactics, "M. MJATVEDT", "Premier League", "1997-98", 1)
		elif s[1] == "finance_demo.png":
			# Real ledger summary off the demo roster so the income ▲ / expense ▼ markers
			# render on populated rows (FinanceModel is GameDB-free). Tier is 1..4 (Premier..
			# Div3); its constant tables have no tier-0 key, so 1 is the valid demo tier.
			var fin := FinanceModel.summary(club, 1)
			node.setup(fin, "ARSENAL", "M. MJATVEDT", "1997-98", 1_000_000, 17)
		elif s[1] == "transfer_demo.png":
			node.setup(_demo_market(), "ARSENAL", "M. MJATVEDT", "1997-98", 8_500_000,
				"OPEN", 5, 1)
		elif s[1] == "rival_demo.png":
			# Scout the demo club as the rival, with a hired (5-star) assistant so the full
			# report renders: XI table + team rating + formation dots.
			node.setup(_demo_club(), {"id": 7, "name": "OUR CLUB"}, 5, "A. LEIGH",
				"Premier League", "1997-98", 1)
		elif s[1] == "tactics_board_demo.png":
			# The TACTICS board with an individuated squad (real shirt numbers) + a 3-5-2
			# so the pitch two-phase markers + fine-ROLE column render as frame 014.
			var tc: Dictionary = club.duplicate(true)
			var n := 0
			for p in tc.get("players", []):
				n += 1
				p["squadNo"] = n
			node.setup(tc, Tactics.auto_pick(tc, "3-5-2"), "M. MJATVEDT",
				"Premier League", "1997-98", 1)
		elif s[1] == "playerinfo_demo.png":
			# The PLAYER INFORMATION card for an OWN squad player -> the RENEW/TRANSFER/SACK/OK
			# button row is live (frame 081_154619).
			var dc := _demo_club()
			var pl: Dictionary = (dc["players"] as Array)[0]
			pl["contract_years"] = 2
			node.setup(pl, dc, 1, true)
		elif s[1] == "current_offers_demo.png":
			# CURRENT OFFERS mirroring the owner's capture: 2 listed players with a bid
			# each + 3 empty band slots (screenshots/transfer-offers-2026-07-02).
			var oc := _demo_club()
			var ps: Array = oc["players"]
			node.setup([
				{"player": ps[2], "offers": [{"buyer_name": "ASTON VILLA",
					"offer": 5000, "weekly_wage": 100, "years": 1, "week": 4}]},
				{"player": ps[13], "offers": [{"buyer_name": "ASTON VILLA",
					"offer": 5000, "weekly_wage": 100, "years": 1, "week": 4}]},
			], "M. MJATVEDT", "MANCHESTER UTD.", "Premier", "1997-98", 4, 40)
		elif s[1] == "nivel_demo.png":
			# SELECT LEVEL OF THE GAME over the title art (frame 003): a save exists so
			# LOAD GAME renders live.
			node.setup(true, {"club": "MANCHESTER UTD.", "name": "MWM"})
		elif s[1] == "seleccion_demo.png":
			# Frame-011 state: slot 1 locked, PLAYER 2 active. Synthetic 20-club division
			# (this harness is autoload-free; kit ids 1..20 hit the real baked kit art).
			node.setup(_demo_leagues(), true, func(_lid: String) -> Array: return _demo_division())
			node._slots[0] = {"name": "MWM", "club": _demo_division()[0],
				"league": _demo_leagues()[0]}
			node._active = 1
		elif s[1] == "preseason_demo.png":
			node.setup("Manchester Utd.", "MWM", _demo_leagues(),
				func(_lid: String) -> Array: return _demo_division(),
				func(_en: String) -> Array: return [])
		elif s[1] == "leaguetable_demo.png":
			# LEAGUE TABLES mirroring the real-gallery binding frame ma_10 (Premier, Week
			# 17): Man Utd (id 40) my club at the top, so the my-club highlight + EURO CUP /
			# U.E.F.A. / RELEGATION zone rows render exactly as the frame. Rows are pre-sorted
			# (the screen draws array order, as Career.standings() delivers).
			node.setup(_demo_standings(), "MANCHESTER UTD.", "1997-98", "Week 17", 1, 40, "Luis Silva")
		for _i in 14:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var err := img.save_png(dir.path_join(s[1]))
		print("SHOT %s err=%d %dx%d" % [s[1], err, img.get_width(), img.get_height()])
		# Second capture paged to the bottom: proves the LINE-UP ARROW buttons swap to the
		# up-on / down-off art and the starting XI scrolls off. (The TRANSFER MARKET list is
		# capped [3,5,5,5]=18 and always fits, so it has no scroll capture — frame 097.)
		var scrolled_name := ""
		if s[1] == "lineup_demo.png":
			scrolled_name = "lineup_scrolled.png"
		# Second RIVAL capture with NO assistant hired: proves the sourced hire-Assistant
		# message replaces the report (the defining reveal gate).
		if s[1] == "rival_demo.png":
			node.setup(_demo_club(), {"id": 7, "name": "OUR CLUB"}, 0, "",
				"Premier League", "1997-98", 1)
			node.queue_redraw()
			for _i in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			var imgn := get_root().get_texture().get_image()
			var errn := imgn.save_png(dir.path_join("rival_noassist.png"))
			print("SHOT rival_noassist.png err=%d %dx%d" % [errn, imgn.get_width(), imgn.get_height()])
		if scrolled_name != "":
			node._scroll = node._max_scroll()
			node.queue_redraw()
			for _i in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			var img2 := get_root().get_texture().get_image()
			var err2 := img2.save_png(dir.path_join(scrolled_name))
			print("SHOT %s err=%d %dx%d" % [scrolled_name, err2, img2.get_width(), img2.get_height()])
		node.queue_free()
		for _i in 3:
			await process_frame
	print("SHOTS DONE")
	quit(0)


## A synthetic 28-man roster whose posFine codes span the GK/DF/MF/FW role bands, so the
## SQUAD POS column and LINE-UP ROL column render the full CAMROL icon set (verify the
## role-icon wiring without booting a real career / GameDB). 28 players (11 XI + 5 subs +
## 12 reserves) overflow the LINE-UP panel so its ARROW scroll buttons render.
func _demo_leagues() -> Array:
	return [{"id": "L1", "name": "Premier League"}, {"id": "L2", "name": "First Division"},
		{"id": "L3", "name": "Second Division"}, {"id": "L4", "name": "Third Division"}]


func _demo_division() -> Array:
	# ids 100.. = the real English club id space, so the baked kit art renders.
	var out: Array = []
	for i in 20:
		out.append({"id": 100 + i, "name": "CLUB %02d" % (i + 1)})
	return out


## A 20-club Premier standings mirroring the real-gallery binding frame ma_10 (Week 17):
## same clubs, same ids, same P/W/D/L/GF/GA/Pts on the rows the frame legibly shows, so a
## render can be overlaid on ma_10 for a 0px column check. Keys match Career.standings().
func _demo_standings() -> Array:
	const T := [
		[40, "Manchester Utd.", 15, 9, 6, 0, 29, 16, 33],
		[46, "Arsenal", 15, 9, 4, 2, 23, 8, 31],
		[38, "Blackburn R.", 15, 7, 4, 4, 21, 13, 25],
		[45, "Aston Villa", 15, 7, 4, 4, 25, 18, 25],
		[43, "Leeds Utd", 15, 7, 1, 7, 18, 12, 22],
		[47, "Tottenham H", 15, 6, 4, 5, 14, 14, 22],
		[44, "Newcastle Utd", 13, 5, 5, 3, 19, 16, 20],
		[54, "Southampton", 15, 4, 8, 3, 20, 18, 20],
		[52, "Sheffield W.", 15, 5, 5, 5, 17, 20, 20],
		[49, "Chelsea", 15, 6, 2, 7, 20, 20, 20],
		[59, "Bolton W", 14, 6, 1, 7, 22, 22, 19],
		[53, "Coventry", 15, 4, 6, 5, 16, 21, 18],
		[42, "Liverpool", 15, 5, 3, 7, 17, 18, 18],
		[63, "Crystal Pal.", 15, 4, 5, 6, 15, 21, 17],
		[39, "Everton", 15, 4, 4, 7, 18, 22, 16],
		[48, "West Ham Utd", 15, 4, 4, 7, 13, 21, 16],
		[51, "Wimbledon", 15, 3, 6, 6, 15, 24, 15],
		[68, "Barnsley", 15, 4, 1, 10, 12, 33, 13],
		[57, "Leicester", 14, 3, 4, 7, 15, 18, 13],
		[56, "Derby County", 14, 2, 5, 7, 12, 21, 11],
	]
	var out: Array = []
	for r in T:
		out.append({"id": r[0], "name": r[1], "P": r[2], "W": r[3], "D": r[4],
			"L": r[5], "GF": r[6], "GA": r[7], "Pts": r[8]})
	return out


func _demo_club() -> Dictionary:
	const NAMES := ["FLOWERS", "FETTIS", "ADAMS", "KEOWN", "DIXON", "BOULD", "WINTERBURN",
		"VIEIRA", "PETIT", "PARLOUR", "GRIMANDI", "PLATT", "WRIGHT", "OVERMARS",
		"ANELKA", "BERGKAMP", "MANNINGER", "TAYLOR", "UPSON", "GARDE", "HUGHES",
		"BLACK", "WREH", "MENDEZ", "MCGOWAN", "DAY", "RANKIN", "OMOYINMI"]
	# [posFine, broad pos, isGK]
	const ROLES := [[1, "GK", true], [1, "GK", true],
		[2, "DF", false], [3, "DF", false], [4, "DF", false], [5, "DF", false], [6, "DF", false],
		[7, "MF", false], [10, "MF", false], [11, "MF", false], [15, "MF", false], [8, "MF", false],
		[9, "FW", false], [12, "FW", false], [14, "FW", false], [17, "FW", false],
		[1, "GK", true], [1, "GK", true], [2, "DF", false], [3, "DF", false], [4, "DF", false],
		[5, "DF", false], [7, "MF", false], [10, "MF", false], [11, "MF", false],
		[9, "FW", false], [12, "FW", false], [14, "FW", false]]
	var players: Array = []
	for i in ROLES.size():
		var r: Array = ROLES[i]
		var base := 80 - i * 2
		players.append({
			"id": i + 1, "name": NAMES[i], "isGK": bool(r[2]),
			"pos": String(r[1]), "posFine": int(r[0]), "age": 20 + (i % 12),
			"attrs": {"EN": base, "VE": base - 2, "RE": base - 4, "AG": base - 1,
				"CA": base - 3, "TI": base - 5, "RM": base, "RG": base - 6,
				"PA": base - 2, "PO": (78 if r[2] else 12)},
		})
	return {"id": 1, "name": "ARSENAL", "players": players}


## A synthetic transfer market (dearest first) that fills all four [3,5,5,5] position bands
## so the SCOUT / OFFERS nav glyphs, the row table AND the ARROW scroll buttons render (18
## shown + 4 headers = 22 rows overflow the 21-row panel) without a career boot.
func _demo_market() -> Array:
	const M := [
		["RONALDO", "FW", 92, 21, 18_000_000, "Inter"],
		["ZIDANE", "MF", 90, 25, 15_000_000, "Juventus"],
		["MALDINI", "DF", 90, 29, 13_000_000, "Milan"],
		["SHEARER", "FW", 88, 27, 12_000_000, "Newcastle"],
		["BATISTUTA", "FW", 88, 28, 11_500_000, "Fiorentina"],
		["NESTA", "DF", 86, 21, 10_000_000, "Lazio"],
		["FIGO", "MF", 87, 24, 9_500_000, "Barcelona"],
		["STAM", "DF", 85, 25, 9_000_000, "PSV"],
		["KLUIVERT", "FW", 84, 21, 8_500_000, "Milan"],
		["DAVIDS", "MF", 83, 24, 7_500_000, "Juventus"],
		["THURAM", "DF", 84, 25, 7_000_000, "Parma"],
		["VERON", "MF", 83, 22, 6_500_000, "Sampdoria"],
		["KAHN", "GK", 86, 28, 6_000_000, "Bayern"],
		["CAFU", "DF", 83, 27, 5_500_000, "Roma"],
		["REDONDO", "MF", 82, 28, 5_000_000, "Real Madrid"],
		["TONI", "FW", 80, 20, 4_500_000, "Brescia"],
		["BUFFON", "GK", 84, 19, 4_000_000, "Parma"],
		["DEL PIERO", "FW", 85, 23, 3_500_000, "Juventus"],
		["MATAUS", "MF", 79, 30, 3_000_000, "Inter"],
		["BARTHEZ", "GK", 82, 26, 2_500_000, "Monaco"],
		["TALDEA", "DF", 76, 24, 2_000_000, "Espanyol"]]
	var out: Array = []
	for i in M.size():
		var m: Array = M[i]
		out.append({"id": i + 1, "name": m[0], "pos": m[1], "isGK": m[1] == "GK", "ca": m[2],
			"mo": m[2] - 4, "age": m[3], "fee": m[4], "wage": int(m[4] / 200), "club_id": -1,
			"club_name": m[5]})
	return out
