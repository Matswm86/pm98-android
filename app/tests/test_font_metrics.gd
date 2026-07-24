extends SceneTree
## The baked BMFont char table must stay identical to the .fnt sources, and the
## alert box must actually measure text with it.
##
## `res://data/font_metrics.json` (tools/re/export_font_metrics.py) exists because
## Godot does NOT export the source `art/fonts/*.fnt` — verified by unzipping
## pm98-6f2e598.apk, which carries `proman10.fnt.import` + the imported
## `.fontdata` but no `proman10.fnt`. Every raw-`.fnt` reader therefore came up
## empty on device and PMAlert drew a blank white box for every message.
##
## This test fails if the bake drifts from the sources, if any glyph page is
## empty, or if PMAlert measures a known message wrong.
##   ~/godot462 --headless --path app --script res://tests/test_font_metrics.gd

const FONT_DIR := "res://art/fonts"


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var baked: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(PMFont.METRICS_PATH))
	ok = _assert(baked is Dictionary, "font_metrics.json parses") and ok
	var keys := PackedStringArray()
	for f in DirAccess.get_files_at(FONT_DIR):
		if f.ends_with(".fnt"):
			keys.append(f.get_basename())
	ok = _assert(keys.size() == 12, "12 .fnt sources, got %d" % keys.size()) and ok

	for key in keys:
		var b: Dictionary = (baked as Dictionary).get(key, {})
		ok = _assert(not b.is_empty(), "%s baked" % key) and ok
		# re-parse the source and compare, field by field
		var src := _parse_fnt("%s/%s.fnt" % [FONT_DIR, key])
		for field in ["line_height", "base", "scale_w", "scale_h"]:
			ok = _assert(int(b.get(field, -1)) == int(src[field]),
				"%s.%s %s == %s" % [key, field, b.get(field, -1), src[field]]) and ok
		var bc: Dictionary = b.get("chars", {})
		var sc: Dictionary = src["chars"]
		ok = _assert(bc.size() == sc.size(),
			"%s glyph count %d == %d" % [key, bc.size(), sc.size()]) and ok
		var mismatched := 0
		for cid in sc:
			# JSON numbers come back as floats — compare field by field as ints
			if not bc.has(cid):
				mismatched += 1
				continue
			var ba: Array = bc[cid]
			var sa: Array = sc[cid]
			for i in sa.size():
				if i >= ba.size() or int(ba[i]) != int(sa[i]):
					mismatched += 1
					break
		ok = _assert(mismatched == 0, "%s glyph rows match (%d off)" % [key, mismatched]) and ok
		# the atlas page must carry real ink, and PMFont must expose it
		var page := PMFont.page(key)
		ok = _assert(page.get_width() == int(src["scale_w"])
			and page.get_height() == int(src["scale_h"]),
			"%s page %dx%d == %sx%s" % [key, page.get_width(), page.get_height(),
				src["scale_w"], src["scale_h"]]) and ok
		var tbl := PMFont.chars(key)
		ok = _assert(tbl.size() == sc.size(), "%s PMFont.chars %d" % [key, tbl.size()]) and ok
		var inked := 0
		for cid in tbl:
			if int((tbl[cid] as Dictionary)["ink_w"]) > 0:
				inked += 1
		ok = _assert(inked > 50, "%s has %d inked glyphs" % [key, inked]) and ok

	# PMAlert must MEASURE, not just load: the two frame-witnessed boxes.
	# alert_box_re.md: frame 093 ink 257 -> w 288; frame 149 ink 188 -> w 220.
	var w093 := PMAlert.box_rect("Mats has signed for Bolton Wanderers.").size.x
	ok = _assert(w093 > 200, "PMAlert measures a real message (w=%d, not the 191 blank)" % w093) and ok
	var blank := PMAlert.box_rect("").size.x
	ok = _assert(blank == 192, "empty message falls back to the 160 minimum (w=%d)" % blank) and ok
	# and the rendered box must contain BLACK ink pixels (the ink pass)
	var img := PMAlert.render("The scout has finished his search.")
	var black := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.r8 == 0 and c.g8 == 0 and c.b8 == 0:
				black += 1
	# borders alone are ~2*(w+h)*2; the message adds hundreds of ink pixels
	var border := 2 * 2 * (img.get_width() + img.get_height())
	ok = _assert(black > border + 300,
		"rendered alert carries message ink (%d black px, border ~%d)" % [black, border]) and ok

	print("test_font_metrics: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _parse_fnt(path: String) -> Dictionary:
	var out := {"line_height": 0, "base": 0, "scale_w": 0, "scale_h": 0, "chars": {}}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var kv := {}
		for tok in line.split(" ", false):
			var eq := tok.find("=")
			if eq > 0:
				kv[tok.substr(0, eq)] = tok.substr(eq + 1)
		if line.begins_with("common "):
			out["line_height"] = int(kv.get("lineHeight", "0"))
			out["base"] = int(kv.get("base", "0"))
			out["scale_w"] = int(kv.get("scaleW", "0"))
			out["scale_h"] = int(kv.get("scaleH", "0"))
		elif line.begins_with("char id="):
			(out["chars"] as Dictionary)[str(int(kv.get("id", "-1")))] = [
				int(kv.get("x", "0")), int(kv.get("y", "0")),
				int(kv.get("width", "0")), int(kv.get("height", "0")),
				int(kv.get("xoffset", "0")), int(kv.get("yoffset", "0")),
				int(kv.get("xadvance", "0")),
			]
	return out


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
