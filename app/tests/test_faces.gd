extends SceneTree
## Headless test for the player-face bank (BIGFOTO/MINIFOTO extracted from the original
## EQUIPOS photoId, see docs/re/faces_re.md): confirms the exported art + manifest load,
## the PMChrome.face()/mini_face() loaders resolve real stars to the right-sized
## textures, a photo-less player falls back to null (blank frame, as the original drew),
## and the game_db photoId -> bank join is intact for the bulk of the English pyramid.
##   ~/godot462 --headless --path app --script res://tests/test_faces.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# 1. manifest + generic fallback present and parseable.
	var mf := FileAccess.open("res://data/face_index.json", FileAccess.READ)
	if mf == null:
		return _fail("face_index.json present")
	var manifest: Dictionary = JSON.parse_string(mf.get_as_text())
	var big_ids: Array = manifest.get("big", [])
	var mini_ids: Array = manifest.get("mini", [])
	ok = _assert(big_ids.size() > 500, "manifest lists the big faces (got %d)" % big_ids.size()) and ok
	ok = _assert(mini_ids.size() > 500, "manifest lists the mini faces (got %d)" % mini_ids.size()) and ok
	ok = _assert(ResourceLoader.exists("res://art/faces/_generic.png"),
		"generic fallback face exists") and ok

	# 2. PMChrome loaders resolve a known star (Schmeichel photoId 3371) at the right size.
	var big := PMChrome.face(3371)
	ok = _assert(big != null, "PMChrome.face(3371) loads (Schmeichel)") and ok
	if big != null:
		ok = _assert(big.get_width() > 100 and big.get_height() > 150,
			"big face is profile-sized (%dx%d)" % [big.get_width(), big.get_height()]) and ok
	var mini := PMChrome.mini_face(3371)
	ok = _assert(mini != null, "PMChrome.mini_face(3371) loads") and ok
	if mini != null:
		ok = _assert(mini.get_width() == 32 and mini.get_height() == 32,
			"mini face is 32x32 (%dx%d)" % [mini.get_width(), mini.get_height()]) and ok

	# 3. photo-less / unknown ids fall back to null (the original drew a blank frame).
	ok = _assert(PMChrome.face(null) == null, "null photoId -> null face") and ok
	ok = _assert(PMChrome.face(0) == null, "0 photoId -> null face") and ok
	ok = _assert(PMChrome.face(999999) == null, "unknown photoId -> null face") and ok

	# 4. game_db join: a strong majority of English players with a photoId resolve to a
	#    real bank texture (the rest are photo-less in the original -> blank, expected).
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _fail("game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var big_set := {}
	for id in big_ids:
		big_set[int(id)] = true
	var with_pid := 0
	var resolved := 0
	for c in db.get("clubs", []):
		if c.get("country") != "England":
			continue
		for p in c.get("players", []):
			var pid: Variant = p.get("photoId")
			if pid == null:
				continue
			with_pid += 1
			if big_set.has(int(pid)):
				resolved += 1
	ok = _assert(with_pid > 1500, "English players carry a photoId (got %d)" % with_pid) and ok
	# ~30% of squad slots have a real photo in the original; assert a meaningful floor.
	ok = _assert(resolved > 400,
		"%d English players resolve to a real face texture" % resolved) and ok
	# Every manifest big id must actually load (no dangling manifest entry).
	var sample_ok := true
	for id in [big_ids[0], big_ids[big_ids.size() / 2], big_ids[big_ids.size() - 1]]:
		sample_ok = sample_ok and PMChrome.face(int(id)) != null
	ok = _assert(sample_ok, "sampled manifest big ids all load as textures") and ok

	print("\nfaces resolved %d / %d photoId players" % [resolved, with_pid])
	print("%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _fail(label: String) -> void:
	_assert(false, label)
	quit(1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
