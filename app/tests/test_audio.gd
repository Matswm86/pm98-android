extends SceneTree
## Headless test for T1 #1 — audio. Asserts the extracted Ogg assets are present, the
## AudioManager autoload exposes the music/crowd/SFX channels, the SFX key table all
## resolves to real files, play_music is idempotent + forces the stream to loop, and the
## MatchScreen commentary->SFX mapping is correct (goal roar / yellow / red).
##   ~/godot462 --headless --path app --script res://tests/test_audio.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# All exported assets present.
	for path in ["res://audio/music/menu.ogg", "res://audio/sfx/crowd.ogg",
			"res://audio/sfx/whistle.ogg", "res://audio/sfx/whistle_final.ogg",
			"res://audio/sfx/goal.ogg", "res://audio/sfx/card_yellow.ogg",
			"res://audio/sfx/card_red.ogg", "res://audio/sfx/select.ogg",
			"res://audio/sfx/nav.ogg", "res://audio/sfx/tackle.ogg", "res://audio/sfx/post.ogg"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	# Autoload is mounted and every SFX key resolves to a real file.
	await process_frame   # let the autoload's _ready() build its players
	var am: Node = root.get_node_or_null("AudioManager")
	ok = _assert(am != null, "AudioManager autoload mounted") and ok
	if am != null:
		var keys_ok := true
		for k in am.SFX:
			keys_ok = keys_ok and ResourceLoader.exists(am.SFX[k])
		ok = _assert(keys_ok, "every SFX key resolves to a file (%d keys)" % am.SFX.size()) and ok

		# Menu stream loads and is forced to loop.
		var s: AudioStream = am._load_looped(am.MUSIC_MENU)
		ok = _assert(s is AudioStreamOggVorbis and (s as AudioStreamOggVorbis).loop,
			"menu music loads and loops") and ok

		# play_music is idempotent on the same track (no restart spam).
		am.play_music()
		var first_playing: bool = am._music.playing
		am.play_music()
		ok = _assert(first_playing and am._cur_music == am.MUSIC_MENU,
			"play_music starts + records the current track") and ok

		# Disabling music stops + clears it; disabling SFX is honoured by sfx().
		am.set_music_enabled(false)
		ok = _assert(not am._music.playing and am._cur_music == "", "music toggle off stops it") and ok
		am.set_music_enabled(true)

	# MatchScreen commentary -> SFX mapping.
	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	get_root().add_child(scr)
	scr.set_process(false)
	await process_frame
	ok = _assert(scr._line_sfx({"goal": true, "text": "Goal by A"}) == "goal", "goal -> goal roar") and ok
	ok = _assert(scr._line_sfx({"text": "Yellow card: A (X)"}) == "card_yellow", "yellow -> card_yellow") and ok
	ok = _assert(scr._line_sfx({"text": "A (X) sent off"}) == "card_red", "sent off -> card_red") and ok
	ok = _assert(scr._line_sfx({"text": "Corner taken by A"}) == "", "plain line -> no SFX") and ok
	scr.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
