extends SceneTree
## Headless wiring test for the PLAYER INFORMATION (FICHA) popup: confirms the screen
## mounts on a real squad player, the decoded physical/identity fields (heightCm /
## weightKg / nationality / kind) feed it, a player WITH a photo resolves his BIGFOTO
## mugshot through PMChrome.face, and the derived readouts (rating / contract money) run
## without error. The SQUAD-row tap that raises it is asserted separately by the squad test.
##   ~/godot462 --headless --path app --script res://tests/test_player_info.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_finish(_assert(false, "game_db.json present"))
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())

	# A Premier club, and within it a player who carries a BIGFOTO photo + the decoded
	# physicals (Schmeichel 3371 is the canonical verified face; fall back to any).
	var club: Dictionary = {}
	var star: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") != "eng_prem":
			continue
		for p in c.get("players", []):
			if int(p.get("photoId", 0)) == 3371:
				club = c
				star = p
		if not star.is_empty():
			break
	if star.is_empty():
		# Any English player with a photo + height, if Schmeichel moved banks.
		for c in db.get("clubs", []):
			if c.get("leagueId") != "eng_prem":
				continue
			for p in c.get("players", []):
				if p.get("photoId") != null and p.get("heightCm") != null:
					club = c
					star = p
					break
			if not star.is_empty():
				break
	ok = _assert(not star.is_empty(), "found a Premier player with a photo + physicals") and ok

	# The decoded fields landed in game_db.
	ok = _assert(star.get("heightCm") != null and int(star["heightCm"]) >= 150,
		"player carries a plausible heightCm (got %s)" % str(star.get("heightCm"))) and ok
	ok = _assert(star.get("weightKg") != null and int(star["weightKg"]) >= 45,
		"player carries a plausible weightKg (got %s)" % str(star.get("weightKg"))) and ok
	ok = _assert(str(star.get("nationality", "")) != "", "player carries a nationality") and ok
	ok = _assert(str(star.get("kind", "")) in ["NATIONAL", "NON-NATIONAL"],
		"player carries a KIND flag (got %s)" % str(star.get("kind"))) and ok

	# The mugshot resolves to a real texture for a player with a photo.
	var face := PMChrome.face(star.get("photoId"))
	ok = _assert(face != null, "BIGFOTO mugshot resolves for photoId %s" % str(star.get("photoId"))) and ok
	if face != null:
		ok = _assert(face.get_width() == 124 and face.get_height() == 182,
			"mugshot is the 124x182 BIGFOTO (got %dx%d)" % [face.get_width(), face.get_height()]) and ok

	# The screen mounts, takes the player, and its derived readouts run clean.
	var screen: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f18 != null, "PROMAN fonts loaded into FICHA") and ok
	screen.setup(star, club, 1)
	await process_frame
	ok = _assert(screen._rating() > 0, "RATING derives a positive overall (got %d)" % screen._rating()) and ok
	ok = _assert(screen._attr("PO") >= 0 and screen._attr("PA") >= 0, "attr -> skill mapping reads") and ok
	ok = _assert(screen._money(14_000_000) == "14,000,000", "money formats thousands") and ok
	ok = _assert(screen._fitness() >= 0 and screen._moral() >= 0, "FITNESS / MORAL derive") and ok

	# A photo-less player draws a blank frame (face() returns null) without crashing.
	var blank := PlayerInfoScreen.new()
	get_root().add_child(blank)
	await process_frame
	var ghost := star.duplicate()
	ghost["photoId"] = null
	ghost["heightCm"] = null
	blank.setup(ghost, club, 1)
	await process_frame
	ok = _assert(PMChrome.face(null) == null, "null photoId -> no texture (blank frame, faithful)") and ok

	_finish(ok)


func _assert(cond: bool, label: String) -> bool:
	print(("PASS " if cond else "FAIL ") + label)
	return cond


func _finish(ok: bool) -> void:
	print("test_player_info: %s" % ("ALL PASS" if ok else "FAILURES"))
	quit(0 if ok else 1)
