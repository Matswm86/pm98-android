extends SceneTree
## Headless wiring test for the hub OPTIONS dropdown panel (OptionsPanel.gd): confirms the
## frame-measured BOX + control rects (both volume sliders, both channel X-boxes, the
## TRANSITIONS ON/OFF X-boxes, red OK) stay inside the 640x480 canvas and inside BOX, the
## three baked chrome PNGs referenced by _ready() exist and load, instantiating the panel
## wires _box/_checked/_empty, the drag/press state starts clean with positive slider
## geometry, and the panel's real collaborator (the AudioManager autoload its private
## _on_input/_slider_set handlers forward slider/box hits to, see OptionsPanel.gd:71,113,
## 115,117,119) actually applies music/sfx/transition values. OptionsPanel itself exposes
## no public mutator, so per the no-invention rule this test does not call a fabricated one.
##   ~/godot4 --headless --path app --script res://tests/test_options_panel.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Named control rects stay inside the 640x480 canvas and inside BOX (the frame-measured
	# dropdown chrome, app/data/dropdown_chrome_samples.json).
	var canvas := Rect2(0, 0, 640, 480)
	ok = _assert(canvas.encloses(OptionsPanel.BOX), "BOX in canvas") and ok
	var controls := [
		["R_MUSIC_SLIDER", OptionsPanel.R_MUSIC_SLIDER],
		["R_SFX_SLIDER", OptionsPanel.R_SFX_SLIDER],
		["R_MUSIC_BOX", OptionsPanel.R_MUSIC_BOX],
		["R_SFX_BOX", OptionsPanel.R_SFX_BOX],
		["R_TRANS_ON", OptionsPanel.R_TRANS_ON],
		["R_TRANS_OFF", OptionsPanel.R_TRANS_OFF],
		["R_OK", OptionsPanel.R_OK],
		["R_CHEAT_ON", OptionsPanel.R_CHEAT_ON],
		["R_CHEAT_OFF", OptionsPanel.R_CHEAT_OFF],
		["R_CHEAT_BAND", OptionsPanel.R_CHEAT_BAND],
	]
	for entry in controls:
		var r: Rect2 = entry[1]
		ok = _assert(canvas.encloses(r), "%s in canvas" % entry[0]) and ok
		ok = _assert(OptionsPanel.BOX.encloses(r), "%s inside BOX" % entry[0]) and ok

	# THREE UP FRONT is the ONE declared deviation from the original modal
	# (docs/re/hack_three_forwards.md). Its two X-boxes must live inside the band the
	# parity gate tools/re/diff_options_parity.py excludes, and the band must not touch
	# any control the original actually draws -- else the deviation stops being bounded.
	ok = _assert(OptionsPanel.R_CHEAT_BAND.encloses(OptionsPanel.R_CHEAT_ON),
		"R_CHEAT_ON inside the declared band") and ok
	ok = _assert(OptionsPanel.R_CHEAT_BAND.encloses(OptionsPanel.R_CHEAT_OFF),
		"R_CHEAT_OFF inside the declared band") and ok
	for entry in [["R_MUSIC_SLIDER", OptionsPanel.R_MUSIC_SLIDER],
			["R_SFX_SLIDER", OptionsPanel.R_SFX_SLIDER],
			["R_MUSIC_BOX", OptionsPanel.R_MUSIC_BOX], ["R_SFX_BOX", OptionsPanel.R_SFX_BOX],
			["R_TRANS_ON", OptionsPanel.R_TRANS_ON], ["R_TRANS_OFF", OptionsPanel.R_TRANS_OFF],
			["R_OK", OptionsPanel.R_OK]]:
		ok = _assert(not OptionsPanel.R_CHEAT_BAND.intersects(entry[1] as Rect2),
			"declared band clear of %s" % entry[0]) and ok

	# Baked chrome referenced by _ready() is present and loadable.
	for path in ["res://art/screens/dropdown/options_box.png",
			"res://art/screens/dropdown/box_checked.png",
			"res://art/screens/dropdown/box_empty.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# Instantiate + wire.
	var screen: OptionsPanel = load("res://scenes/OptionsPanel.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._box != null, "_box texture loaded") and ok
	ok = _assert(screen._checked != null, "_checked texture loaded") and ok
	ok = _assert(screen._empty != null, "_empty texture loaded") and ok

	# Clean initial interaction state; drag geometry (slider rects) is positive-sized (the
	# value math in _slider_set divides by r.size.x).
	ok = _assert(screen._drag == "", "initial _drag is empty") and ok
	ok = _assert(screen._ok_held == false, "initial _ok_held is false") and ok
	ok = _assert(OptionsPanel.R_MUSIC_SLIDER.size.x > 0.0 and OptionsPanel.R_MUSIC_SLIDER.size.y > 0.0,
		"R_MUSIC_SLIDER geometry positive") and ok
	ok = _assert(OptionsPanel.R_SFX_SLIDER.size.x > 0.0 and OptionsPanel.R_SFX_SLIDER.size.y > 0.0,
		"R_SFX_SLIDER geometry positive") and ok

	# OptionsPanel has no public mutator of its own -- box/slider/transition hits in
	# _on_input all forward to the AudioManager autoload (am.call("set_music_volume", ...)
	# etc.). Confirm that real collaborator is mounted and its public setters actually
	# apply the values the panel's private handlers would forward.
	var am: Node = get_root().get_node_or_null("AudioManager")
	ok = _assert(am != null, "AudioManager autoload mounted (OptionsPanel's collaborator)") and ok
	if am != null:
		var orig_mv: int = am.music_volume
		var orig_sv: int = am.sfx_volume
		var orig_trans: bool = am.transitions_enabled
		am.set_music_volume(37)
		ok = _assert(am.music_volume == 37, "AudioManager.set_music_volume applies value") and ok
		am.set_sfx_volume(64)
		ok = _assert(am.sfx_volume == 64, "AudioManager.set_sfx_volume applies value") and ok
		am.set_transitions(not orig_trans)
		ok = _assert(am.transitions_enabled == (not orig_trans), "AudioManager.set_transitions applies value") and ok
		# THREE UP FRONT: the panel's R_CHEAT_ON/OFF hits forward to set_three_up_front,
		# which must move BOTH the stored flag and the engine's own static.
		var orig_cheat: bool = am.cheat_three_up_front
		am.set_three_up_front(true)
		ok = _assert(am.cheat_three_up_front and Pm98StatMatch.cheat_three_up_front,
			"AudioManager.set_three_up_front arms the engine") and ok
		am.set_three_up_front(false)
		ok = _assert(not am.cheat_three_up_front and not Pm98StatMatch.cheat_three_up_front,
			"AudioManager.set_three_up_front disarms the engine") and ok
		am.set_three_up_front(orig_cheat)
		# Restore so this headless run doesn't leak state into user://settings.cfg for
		# other test scripts (test_audio.gd follows the same restore convention).
		am.set_music_volume(orig_mv)
		am.set_sfx_volume(orig_sv)
		am.set_transitions(orig_trans)

	# Redraw doesn't crash.
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
