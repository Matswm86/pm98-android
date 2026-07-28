extends SceneTree
## Pins the JUG sprite-index port (`JugRender`) against MANAGER.EXE's own tables and the
## `FUN_005a5460` arithmetic, and the WATCH camera (`Pm98Camera`) against the projection form
## reversed out of `FUN_005eec60`.
##
## These are the two things AUDIT A7/A8 said were invented. A regression here means the WATCH
## view has quietly gone back to drawing a compass that the engine does not have.
##   ~/godot462 --headless --path app --script res://tests/test_jug_render.gd

# Straight from tools/re/dump_jug_kind_tables.py, which reads MANAGER.EXE .data live.
const THRESHOLDS := [3584, 13312, 19456, 29184, 36352, 46080, 52224, 61952]
const EXPECT_KINDS := 74
const EXPECT_FRAMES := 4211


func _initialize() -> void:
	var ok := true
	var b := JugRender.bank()
	ok = _assert(not b.is_empty(), "jug_bank.json loads") and ok
	if b.is_empty():
		print("\nFAILURES ABOVE")
		quit(1)
		return

	# --- the bake matches the binary --------------------------------------------------
	ok = _assert(JugRender.kind_count() == EXPECT_KINDS, "74 kinds, not the old 16") and ok
	ok = _assert((b["frames"] as Array).size() == EXPECT_FRAMES,
		"4211 frames — JUG.PGF's own header count") and ok
	# JSON gives floats; compare as ints so the check is about the VALUES, not the encoding.
	var thr: Array = []
	for t in (b["thresholds8"] as Array):
		thr.append(int(t))
	ok = _assert(thr == THRESHOLDS,
		"DAT_006653e0 thresholds are the binary's, and NON-uniform") and ok

	# FUN_005a2830: base[k] = running total, += fpd*mode only for mode > 0. Re-derive it
	# here so a re-bake that quietly changes the layout cannot pass.
	var run := 0
	var base_ok := true
	for k in EXPECT_KINDS:
		var row := JugRender.kind_row(k)
		if int(row["base"]) != run:
			base_ok = false
		if int(row["mode"]) > 0:
			run += int(row["fpd"]) * int(row["mode"])
	ok = _assert(base_ok, "every base[k] is FUN_005a2830's running total") and ok
	ok = _assert(run == EXPECT_FRAMES, "the reconstructed total is exactly 4211") and ok

	# The three kinds the port's own movement code sets most (diag_watch_axes.gd saw
	# 0,1,2,3,4,5,8,11,30,34,35,42,46,55 in one match) must all resolve.
	var reachable := true
	for k in [0, 1, 2, 3, 4, 5, 8, 11, 30, 34, 35, 42, 46, 55]:
		if JugRender.resolve(k, 0, 0).is_empty():
			reachable = false
	ok = _assert(reachable, "every kind a real match reaches resolves to a frame") and ok

	# --- direction bucketing ----------------------------------------------------------
	# Camera yaw is a quarter turn, so the term collapses to the facing word itself; a player
	# running AWAY from the camera (+Y) must land on a different stored direction from one
	# running TOWARD it (-Y), and toward-the-camera is direction 0 (the front-facing frame).
	ok = _assert(JugRender.octant(0xc000) == 6, "facing the camera buckets to octant 6") and ok
	var toward := JugRender.direction(3, 0xc000)
	var away := JugRender.direction(3, 0x4000)
	ok = _assert(int(toward["dir"]) == 0, "toward the camera = bank direction 0") and ok
	ok = _assert(int(away["dir"]) == 4, "away from the camera = bank direction 4") and ok
	ok = _assert(not bool(toward["flip"]) and not bool(away["flip"]),
		"neither pole is mirrored") and ok

	# mode 5 stores dirs 0..4 and MIRRORS 5..7; mode 8 stores all eight and mirrors none.
	var mirrored := JugRender.direction(3, 0x9000)      # a mode-5 kind, past the palindrome
	ok = _assert(bool(mirrored["flip"]) and int(mirrored["dir"]) <= 4,
		"a mode-5 kind mirrors instead of storing dirs 5..7") and ok
	var m8 := false
	for f in [0x0000, 0x2000, 0x6000, 0xa000, 0xe000]:
		if bool(JugRender.direction(4, f)["flip"]):      # kind 4 is mode 8
			m8 = true
	ok = _assert(not m8, "a mode-8 kind never mirrors — it stores all eight") and ok

	# mode < 0 is a mirror twin sharing its positive twin's base (kind 42 = -8 of kind 43).
	ok = _assert(int(JugRender.kind_row(42)["base"]) == int(JugRender.kind_row(43)["base"]),
		"a negative-mode kind reuses its twin's base") and ok
	ok = _assert(bool(JugRender.direction(42, 0x1000)["flip"]),
		"a negative-mode kind always draws flipped") and ok

	# --- frame index + phase ----------------------------------------------------------
	var row3 := JugRender.kind_row(3)
	ok = _assert(JugRender.frame_index(3, 2, 5)
		== int(row3["base"]) + int(row3["fpd"]) * 2 + 5,
		"frame = base + fpd*dir + phase") and ok
	ok = _assert(JugRender.frame_index(3, 0, 999) == int(row3["base"]) + int(row3["fpd"]) - 1,
		"phase is clamped to fpd-1, as the draw clamps it") and ok
	# FUN_005a50c0: step, and on wrap hand over to next[kind].
	var adv := JugRender.advance(3, int(row3["fpd"]) - 1)
	ok = _assert(int(adv["kind"]) == int(row3["next"]) and int(adv["phase"]) == 0,
		"a wrapped phase transitions to next[kind]") and ok
	ok = _assert(int(JugRender.advance(3, 0)["phase"]) == 1, "otherwise the phase steps") and ok
	# a mirrored 14-phase self-looping kind is drawn half a cycle on
	ok = _assert(JugRender.mirror_phase(3, 0) == 7, "mirrored 14-phase gait shifts by 7") and ok

	# --- the world scale is the draw's own --------------------------------------------
	# z span = (ay - H) .. ay times 0x1b333/0x30, so a 45px frame with ay=46 is ~1.63 m.
	var mz := JugRender.metres_per_pixel_z()
	ok = _assert(absf(mz - 0.03542) < 0.0002, "0x1b333/0x30 = 0.0354 m per sprite pixel") and ok
	ok = _assert(absf(46.0 * mz - 1.63) < 0.02, "a standing frame is ~1.63 m tall") and ok

	# --- the camera -------------------------------------------------------------------
	var cam := Pm98Camera.new()
	ok = _assert(absf(cam.focal - 640.0) < 0.001,
		"focal length = viewport width (SetCamera's k = width*256)") and ok
	# The three landmarks the pose was fitted to must come back where the capture put them.
	ok = _assert(absf(cam.project(Vector3(0, 38.0, 0)).y - 89.0) < 1.0,
		"the far touchline lands on the capture's grass seam (y=89)") and ok
	ok = _assert(absf(cam.project(Vector3(0, 9.15, 0)).y - 192.0) < 1.0,
		"the centre circle's far arc lands at y=192") and ok
	ok = _assert(absf(cam.project(Vector3(0, -9.15, 0)).y - 372.0) < 1.0,
		"the centre circle's near arc lands at y=372") and ok
	# Depth is world Y (the WIDTH axis) — the whole point of the correction.
	ok = _assert(cam.depth(Vector3(0, 38.0, 0)) > cam.depth(Vector3(0, -38.0, 0)),
		"depth increases toward the FAR touchline, i.e. along world Y") and ok
	ok = _assert(absf(cam.project(Vector3(20.0, 0, 0)).x - cam.project(Vector3(-20.0, 0, 0)).x)
		> 100.0, "world X (the length) spreads across the screen") and ok
	# Perspective: the same 1.63 m man is bigger when nearer.
	ok = _assert(cam.scale_at(20.0) > cam.scale_at(60.0), "nearer is larger") and ok

	# --- the kit recolour chain (docs/re/kit_palette_re.md) ----------------------------
	ok = _assert(JugKit.load_tables(), "the kit tables load") and ok
	var pal := JugKit.palette(0)
	ok = _assert(pal.size() == 256, "SIMUL0.PAL is 256 entries") and ok
	# The palette's six-entry colour bands are what make a pattern cell a RAMP BASE.
	ok = _assert(pal[0x8C] == Color8(2, 2, 247) and pal[0x91] == Color8(2, 2, 97),
		"0x8c..0x91 is the blue ramp, bright first") and ok
	ok = _assert(pal[0x80] == Color8(229, 0, 0) and pal[0x85] == Color8(79, 0, 0),
		"0x80..0x85 is the red ramp") and ok

	# Manchester Utd. (40) vs Liverpool (42): both first-choice kits are red, so the away
	# side must fall to its P96B change strip — FUN_005b63e0's own collision test.
	var mu := JugKit.team_kit(40)
	var lv := JugKit.team_kit(42, int(mu["cls"]))
	ok = _assert(not mu.is_empty() and not lv.is_empty(), "both clubs resolve a ramp") and ok
	ok = _assert(mu["lut"].size() == 256 and mu["pattern"].size() == 128,
		"a team kit is a 256-byte LUT and a 16x8 pattern") and ok
	ok = _assert(bool(lv["change"]), "the away side wears its change strip on a class clash") and ok
	ok = _assert(int(mu["ink"]) == 0x67 or int(mu["ink"]) == 0x7F,
		"the number ink is the palette-green test's 0x67 or 0x7f") and ok

	# The 48 club entries land on LUT slots 9..56 and nowhere else.
	var base := JugKit.team_kit(-1)          # no ramp -> the P96A0000 fallback
	var moved: Array = []
	for i in 256:
		if int(base["lut"][i]) != int(mu["lut"][i]):
			moved.append(i)
	var in_band := true
	for i in moved:
		if int(i) < 9 or int(i) > 56:
			in_band = false
	ok = _assert(in_band, "a club ramp only ever writes LUT slots 9..56") and ok

	# The number stamp must change the pattern's RIGHT half (the back of the shirt) only.
	var stamped := JugKit.stamp_number(mu["pattern"], 9, int(mu["cls"]), int(mu["ink"]))
	var left_same := true
	var right_diff := false
	for row in 8:
		for col in 16:
			var i := row * 16 + col
			if int(stamped[i]) != int(mu["pattern"][i]):
				if col < 8:
					left_same = false
				else:
					right_diff = true
	ok = _assert(left_same, "the number never touches the front of the shirt") and ok
	ok = _assert(right_diff, "the number does mark the back of the shirt") and ok

	# Skin and hair: three ramps, and hair index 1 is the BALD redirect to skin + 6.
	var sh1 := JugKit.skin_hair(1, 3)
	var sh2 := JugKit.skin_hair(2, 3)
	ok = _assert(sh1["skin"][0] == 72 and sh2["skin"][0] == 88,
		"the three skin ramps are 72../88../80..") and ok
	var bald := JugKit.skin_hair(1, 2)
	ok = _assert(bald["hair"] == JugKit.skin_hair(1, 7)["hair"],
		"hair index 1 is BALD and redirects to skin + 6") and ok
	ok = _assert(int(bald["skin"][6]) == int(bald["skin"][5])
		and int(bald["skin"][7]) == int(bald["skin"][5]),
		"the bald branch flattens the two darkest skin shades") and ok

	# The per-draw LUT: skin lands at 1..8, hair at 0x15..0x18, and the pattern pass writes
	# only slots JUGCAM names for this frame's map.
	var lut := JugKit.draw_lut(mu["lut"], stamped, sh1["skin"], sh1["hair"], 1, false)
	ok = _assert(int(lut[1]) == 72 and int(lut[8]) == 79, "skin lands on LUT 1..8") and ok
	ok = _assert(int(lut[0x15]) == int(sh1["hair"][0]), "hair lands on LUT 0x15") and ok
	# The mirror is a WITHIN-HALF column swap (`((col & 8) - (col & 7)) + 7`), applied to the
	# JUGCAM lookup only. A pattern that differs across a half must therefore recolour
	# differently when flipped; Man Utd's own solid shirt would not prove it.
	var asym := PackedByteArray()
	asym.resize(128)
	for row in 8:
		for col in 16:
			asym[row * 16 + col] = 0x80 if col in [0, 8] else 0x8C
	var lut_a := JugKit.draw_lut(mu["lut"], asym, sh1["skin"], sh1["hair"], 1, false)
	var lut_m := JugKit.draw_lut(mu["lut"], asym, sh1["skin"], sh1["hair"], 1, true)
	ok = _assert(lut_a != lut_m, "the mirrored draw remaps a different JUGCAM column") and ok

	# And the whole chain must produce a real sprite through the index bank.
	var res := JugRender.resolve(1, 0, 0)
	ok = _assert(not res.is_empty() and int(res["map"]) >= 0 and int(res["map"]) <= 71,
		"a resolved frame carries its JUGCAM map id") and ok
	var tex := JugRender.composite(int(res["frame"]), lut, pal)
	ok = _assert(tex != null, "the frame composites through the LUT") and ok
	if tex != null:
		var img := tex.get_image()
		var kit_px := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.r > 0.55 and c.g < 0.25 and c.b < 0.25:
					kit_px += 1
		ok = _assert(kit_px > 20, "United's sprite carries real RED kit pixels") and ok

	# --- the marking geometry is FUN_0059a8c0's own (docs/re/pitch_markings_re.md) ------
	var sim: MatchSimulador = load("res://scenes/MatchSimulador.gd").new()
	ok = _assert(absf(sim.LINE_W - 0.1) < 1e-9, "0x1999 = the 0.1 m line width") and ok
	ok = _assert(absf(rad_to_deg(sim.D_HALF_ANGLE) - 53.7890625) < 1e-4,
		"the D's half-angle is the binary's 0x2640, not acos((16.5-11)/9.15)") and ok
	ok = _assert(rad_to_deg(sim.D_HALF_ANGLE) > rad_to_deg(acos((16.5 - 11.0) / 9.15)),
		"and it is WIDER than the textbook construction") and ok
	ok = _assert(absf(sim.SPOT_W - 0.4) < 1e-9 and absf(sim.SPOT_H - 0.2) < 1e-9,
		"the spots are 0x6664 x 0x3332 quads") and ok
	for pair in [[sim.CIRCLE_R, 9.15], [sim.PEN_DEPTH, 16.5], [sim.PEN_HALF_W, 20.16],
			[sim.GOALAREA_DEPTH, 5.5], [sim.GOALAREA_HALF_W, 9.16], [sim.PEN_SPOT, 11.0],
			[sim.CORNER_R, 1.0]]:
		ok = _assert(absf(float(pair[0]) - float(pair[1])) < 0.005,
			"marking constant %s is FUN_0059a8c0's own" % pair[1]) and ok
	sim.free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
