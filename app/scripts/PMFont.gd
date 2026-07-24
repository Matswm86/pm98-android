extends RefCounted
class_name PMFont
## Shared access to the PM98 BMFont atlases (char table + atlas page).
##
## The screens that draw text by blitting atlas cells themselves — PMAlert, the
## DATABASE card, the tactics board — need the BMFont CHAR TABLE and the RAW
## ATLAS PAGE, not a Godot `FontFile`. They used to read `art/fonts/<key>.fnt`
## and `<key>.png` back with `FileAccess` / `Image.load_from_file`.
##
## Neither file survives an export. Godot imports `.fnt` with `font_data_bmfont`
## and `.png` with `texture`, and an exported PCK carries only the `.import` stub
## plus the imported `.fontdata` / `.ctex` — verified by unzipping the shipped
## `pm98-6f2e598.apk`, which holds `assets/art/fonts/proman10.fnt.import` and
## `assets/.godot/imported/proman10.fnt-*.fontdata` but NO `proman10.fnt`.
## So on device every raw read returned nothing, the glyph table came up empty,
## and PMAlert drew its minimum 191x82 box with zero text: the "white box with no
## text" on the hub, for signings, rejections, "The scout has finished his
## search.", every message the game has.
##
## The char table therefore ships as `res://data/font_metrics.json`, baked from
## the same `.fnt` files by `tools/re/export_font_metrics.py` (plain data files
## under `res://data/` ARE exported — all 29 `assets/data/*.json` are in that
## same APK), and the page comes off the imported `Texture2D`. The raw `.fnt`
## parse stays as an editor-side fallback and `test_font_metrics.gd` fails if the
## baked JSON ever drifts from the `.fnt` sources.

const METRICS_PATH := "res://data/font_metrics.json"
const FONT_DIR := "res://art/fonts"

static var _metrics := {}          # key -> {line_height, base, scale_w, scale_h, chars}
static var _chars := {}            # key -> {int code -> {rect, off, adv, ink_w}}
static var _pages := {}            # key -> Image
static var _page_texs := {}        # key -> Texture2D
static var _json_loaded := false


static func _load_json() -> void:
	if _json_loaded:
		return
	_json_loaded = true
	var raw := FileAccess.get_file_as_string(METRICS_PATH)
	if raw.is_empty():
		push_error("PMFont: %s is missing — falling back to the raw .fnt files" % METRICS_PATH)
		return
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		_metrics = parsed


## Parse one `.fnt` source directly. Editor-side fallback only: the file is not
## in an exported build, so this returns an empty table on device.
static func _parse_fnt(key: String) -> Dictionary:
	var out := {"line_height": 0, "base": 0, "scale_w": 0, "scale_h": 0, "chars": {}}
	var text := FileAccess.get_file_as_string("%s/%s.fnt" % [FONT_DIR, key])
	if text.is_empty():
		return out
	for line in text.split("\n"):
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


## Raw baked record for one font: {line_height, base, scale_w, scale_h, chars}
## where `chars` maps the char code (as a String, JSON-style) to
## [x, y, width, height, xoffset, yoffset, xadvance].
static func metrics(key: String) -> Dictionary:
	_load_json()
	if not _metrics.has(key):
		_metrics[key] = _parse_fnt(key)
	return _metrics[key]


## The atlas page as an Image (decompressed, never null).
static func page(key: String) -> Image:
	if _pages.has(key):
		return _pages[key]
	var path := "%s/%s.png" % [FONT_DIR, key]
	var img: Image = null
	var tex: Variant = load(path) if ResourceLoader.exists(path) else null
	if tex is Texture2D:
		var ti := (tex as Texture2D).get_image()
		if ti != null and ti.get_width() > 0:
			if ti.is_compressed():
				ti.decompress()
			img = ti
	if img == null:
		# editor-side fallback; the source png is not in an exported build either
		var raw := FileAccess.get_file_as_bytes(path)
		var fi := Image.new()
		if raw.size() > 0 and fi.load_png_from_buffer(raw) == OK and fi.get_width() > 0:
			img = fi
	if img == null:
		push_error("PMFont: atlas page %s is missing — text cannot render" % path)
		img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	_pages[key] = img
	return img


## The atlas page as a Texture2D, for the screens that blit cells with
## `draw_texture_rect_region`.
static func page_texture(key: String) -> Texture2D:
	if _page_texs.has(key):
		return _page_texs[key]
	var path := "%s/%s.png" % [FONT_DIR, key]
	var tex: Variant = load(path) if ResourceLoader.exists(path) else null
	var out: Texture2D = tex as Texture2D
	if out == null:
		out = ImageTexture.create_from_image(page(key))
	_page_texs[key] = out
	return out


## Char table keyed by char CODE, with the cell rect, the draw offset, the
## advance and the measured INK width (rightmost non-empty column + 1 — the
## cells carry padding, so the advance is not the ink extent).
static func chars(key: String) -> Dictionary:
	if _chars.has(key):
		return _chars[key]
	var m := metrics(key)
	var src: Dictionary = m.get("chars", {})
	var img := page(key)
	var out := {}
	for k in src:
		var a: Array = src[k]
		var rect := Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))
		var ink_w := 0
		for gx in range(rect.size.x - 1, -1, -1):
			for gy in rect.size.y:
				var px := rect.position.x + gx
				var py := rect.position.y + gy
				if px >= img.get_width() or py >= img.get_height():
					continue
				if img.get_pixel(px, py).a >= 0.5:
					ink_w = gx + 1
					break
			if ink_w > 0:
				break
		out[int(k)] = {
			"rect": rect,
			"off": Vector2i(int(a[4]), int(a[5])),
			"adv": int(a[6]),
			"ink_w": ink_w,
		}
	_chars[key] = out
	return out
