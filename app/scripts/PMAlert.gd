extends RefCounted
class_name PMAlert
## The hub "PREMIER MANAGER 98" alert box (docs/re/alert_box_re.md).
##
## The original's modal message box over the MANAGER MENU hub (walkthrough frames
## 093/094/149 + 080/154/205/231): transfer signings, offer rejections, "Game
## saved"-class feedback. Reversed from MANAGER.EXE FUN_005e5050 / FUN_005f9070
## (measure + layout) and the frames (paint): black 2px border; checker-rail
## caption (light blue + a band of dark tiles counting down toward the centred
## Indust18 title, baked as art/screens/alert/title.png); the DAT.PKF ICOEXCL.BMP
## icon; white body with a 4-row grey gradient (rows 0/2 are (x+y) dithers);
## the Proman10 message (bold glyphs are baked into the font page) with a 3-layer
## drop shadow (+1 grey checker, +2 192-grey, +3 220-grey); the framework " OK "
## button anchored at (w-6, h-6). Boxes centre on (317, 237); w = max(msg,160)+31
## rounded up to even; h = 72 + 10*lines. Messages carry explicit \n (no wrap).
##
## The whole box is rendered ONCE into an ImageTexture — matching the original's
## draw-then-StretchBlt model — so the FUN_005c5fd0 case-5/6 grow-in animation is
## a plain scaled draw of the finished texture.
##
## While the alert is up the hub behind it is palette-dimmed: an exact per-colour
## LUT captured from clean-vs-dimmed frames (alert/dim_lut.json; menu_bg has a
## pre-dimmed bake). Colours not in the LUT fall back to a fitted multiply.

const LIGHT := Color8(42, 63, 170)     # caption field
const DARK := Color8(0, 0, 128)        # caption tiles
const CENTER := Vector2i(317, 237)     # every observed box centres here
const TITLE_W := 127
const ICON_W := 24
const SEP_W := 2

# Grey ramp of the body gradient rows (rows 0 / 2 are (x+y)-parity dithers).
const GRAD := [
	[Color8(100, 100, 100), Color8(114, 114, 114)],
	[Color8(144, 144, 144), Color8(144, 144, 144)],
	[Color8(192, 192, 192), Color8(170, 191, 170)],
	[Color8(220, 220, 220), Color8(220, 220, 220)],
]
# Message drop-shadow layers: offset -> colour; the +1 layer is an (x+y) checker.
const SH1_EVEN := Color8(144, 144, 144)
const SH1_ODD := Color8(160, 160, 164)
const SH2 := Color8(192, 192, 192)
const SH3 := Color8(220, 220, 220)

static var _title_img: Image
static var _icon_img: Image
static var _ok_img: Image
static var _ok_hot_img: Image
static var _glyphs := {}               # char code -> {rect: Rect2i, adv: int}
static var _font_page: Image
static var _dim := {}                  # "r,g,b" -> Color (exact palette dim)
static var _dim_tex_cache := {}        # Texture2D -> ImageTexture (dimmed copy)
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_title_img = (load("res://art/screens/alert/title.png") as Texture2D).get_image()
	_icon_img = (load("res://art/screens/alert/icoexcl.png") as Texture2D).get_image()
	_ok_img = (load("res://art/screens/alert/ok.png") as Texture2D).get_image()
	_ok_hot_img = (load("res://art/screens/alert/ok_hot.png") as Texture2D).get_image()
	# The font page is importer="skip" (the BMFont reads it), so load raw bytes.
	_font_page = Image.new()
	_font_page.load_png_from_buffer(
		FileAccess.get_file_as_bytes("res://art/fonts/proman10.png"))
	for img in [_title_img, _icon_img, _ok_img, _ok_hot_img, _font_page]:
		if img.is_compressed():
			img.decompress()
	var fnt := FileAccess.get_file_as_string("res://art/fonts/proman10.fnt")
	var re := RegEx.create_from_string(
		"char id=(\\d+) +x=(\\d+) +y=(\\d+) +width=(\\d+) +height=(\\d+) " +
		"+xoffset=(-?\\d+) +yoffset=(-?\\d+) +xadvance=(-?\\d+)")
	for m in re.search_all(fnt):
		var rect := Rect2i(int(m.get_string(2)), int(m.get_string(3)),
			int(m.get_string(4)), int(m.get_string(5)))
		# ink width = rightmost non-empty bitmap column + 1 (cells carry padding)
		var ink_w := 0
		for gx in range(rect.size.x - 1, -1, -1):
			for gy in rect.size.y:
				if _font_page.get_pixel(rect.position.x + gx, rect.position.y + gy).a >= 0.5:
					ink_w = gx + 1
					break
			if ink_w > 0:
				break
		_glyphs[int(m.get_string(1))] = {
			"rect": rect,
			"off": Vector2i(int(m.get_string(6)), int(m.get_string(7))),
			"adv": int(m.get_string(8)),
			"ink_w": ink_w,
		}
	var lut: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://art/screens/alert/dim_lut.json"))
	for k in lut:
		var d: PackedStringArray = (lut[k] as String).split(",")
		_dim[k] = Color8(int(d[0]), int(d[1]), int(d[2]))
	_loaded = true


## Advance width of one message line in Proman10 (bold is baked into the glyphs).
static func line_width(s: String) -> int:
	_load()
	var w := 0
	for i in s.length():
		var g: Dictionary = _glyphs.get(s.unicode_at(i), {})
		w += int(g.get("adv", 0))
	return w


## INK extent of one line: to the last glyph's last ink column, + the 3px shadow
## overhang. This — not the advance sum — is what sizes the original's box
## (both known-string frames confirm it: 093 ink 257 -> w 288; 149 ink 188 -> w 220).
static func line_ink(s: String) -> int:
	_load()
	var pen := 0
	var last_end := 0
	for i in s.length():
		var g: Dictionary = _glyphs.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		if int(g.get("ink_w", 0)) > 0:
			last_end = pen + int((g["off"] as Vector2i).x) + int(g["ink_w"])
		pen += int(g["adv"])
	return last_end + 3 if last_end > 0 else 0


## The box rect for a message (design space). EXE: content = max(extent, 160);
## empirical (frames 093/149): w = ink + 31 rounded up to even,
## h = 72 + 10*lines, centred on (317, 237).
static func box_rect(msg: String) -> Rect2i:
	var lines := msg.split("\n")
	var mw := 160
	for l in lines:
		mw = maxi(mw, line_ink(l))
	var w := mw + 31
	w += w & 1
	var h := 72 + 10 * lines.size()
	@warning_ignore("integer_division")
	return Rect2i(CENTER.x - w / 2, CENTER.y - h / 2, w, h)


## Caption checker-rail runs for one rail of width R (edge toward title field):
## tiles W0, W0-step, ... with gaps 1,2,3..., clipped at the field. Fitted on the
## 9 observed rails (alert_box_re.md); W0 = round(R/10.5 + 6.2), step 2 iff W0>=16.
static func _rail_pattern(rail_w: int) -> Array[bool]:
	var w0 := roundi(rail_w / 10.5 + 6.2)
	var step := 2 if w0 >= 16 else 1
	var flags: Array[bool] = []
	var tile := w0
	var gap := 1
	while flags.size() < rail_w and tile > 0:
		for i in tile:
			flags.append(true)
		for i in gap:
			flags.append(false)
		tile -= step
		gap += 1
	flags.resize(rail_w)   # pads false if the series ran dry (never in-range)
	return flags


## Render the finished alert into an Image (the original draws once, then blits).
static func render(msg: String, ok_hot := false) -> Image:
	_load()
	var box := box_rect(msg)
	var w := box.size.x
	var h := box.size.y
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color8(0, 0, 0))            # borders / separators / divider base
	# ---- caption (2 border + 24 interior + 2 divider) --------------------
	var iy := 2                           # caption interior top (local)
	var inner_l := 2
	var inner_r := w - 2
	@warning_ignore("integer_division")
	var field_l := w / 2 - 50            # title strip left (title centred after icon)
	var rail_l := inner_l + ICON_W + SEP_W
	for yy in range(iy, iy + 24):
		for xx in range(rail_l, inner_r):
			img.set_pixel(xx, yy, LIGHT)
	var left := _rail_pattern(field_l - rail_l)
	var right := _rail_pattern(inner_r - (field_l + TITLE_W))
	for row in range(5, 19):              # the 14-row tile band
		for i in left.size():
			if left[i]:
				img.set_pixel(rail_l + i, iy + row, DARK)
		for i in right.size():
			if right[i]:
				img.set_pixel(inner_r - 1 - i, iy + row, DARK)
	img.blit_rect(_title_img, Rect2i(0, 0, TITLE_W, 24), Vector2i(field_l, iy))
	img.blit_rect(_icon_img, Rect2i(0, 0, ICON_W, ICON_W), Vector2i(inner_l, iy))
	# ---- body -------------------------------------------------------------
	var body_t := iy + 26                 # below the 2px divider
	var body_b := h - 2
	for yy in range(body_t, body_b):
		for xx in range(inner_l, inner_r):
			img.set_pixel(xx, yy, Color8(255, 255, 255))
	# the row-0 / row-2 dithers are anchored to SCREEN (x+y) parity, not box-local
	for k in GRAD.size():
		var yy := body_t + k
		for xx in range(inner_l, inner_r):
			img.set_pixel(xx, yy,
				GRAD[k][(xx + box.position.x + yy + box.position.y) & 1])
	# message: left-aligned block; pen = 320 - ink//2 (-1 when ink is even) in
	# design space, both known-string frames confirm; cell top = body + 6
	var lines := msg.split("\n")
	var block_ink := 0
	for l in lines:
		block_ink = maxi(block_ink, line_ink(l))
	@warning_ignore("integer_division")
	var pen_x := (CENTER.x + 3) - block_ink / 2 - box.position.x
	if block_ink & 1 == 0:
		pen_x -= 1
	for li in lines.size():
		_draw_line(img, lines[li], pen_x, body_t + 6 + li * 10, box.position)
	# OK button at the EXE's (w-6, h-6) bottom-right anchor
	var ok := _ok_hot_img if ok_hot else _ok_img
	img.blit_rect(ok, Rect2i(0, 0, 39, 16), Vector2i(w - 45, h - 22))
	return img


## One Proman10 message line at cell (x, y). Shadow layer k (k = 3 lightest .. 1)
## is the glyph mask stamped TWICE, at (+k,+k) and (+k,+k+1) — the frame's shadow
## offset histogram resolves each layer to that 2x2-spread pair — then black ink
## on top. `origin` = the box's design position (the +1 checker is screen-anchored).
static func _draw_line(img: Image, s: String, x: int, y: int, origin: Vector2i) -> void:
	for pass_n in 4:   # +3 lightest first, ink last
		var off: int = [3, 2, 1, 0][pass_n]
		var stamps: Array[Vector2i] = [Vector2i(off, off)]
		if off > 0:
			stamps.append(Vector2i(off, off + 1))
		var pen := x
		for i in s.length():
			var g: Dictionary = _glyphs.get(s.unicode_at(i), {})
			if g.is_empty():
				continue
			var r: Rect2i = g["rect"]
			var go: Vector2i = g["off"]
			for gy in r.size.y:
				for gx in r.size.x:
					if _font_page.get_pixel(r.position.x + gx, r.position.y + gy).a < 0.5:
						continue
					for st in stamps:
						var px: int = pen + go.x + gx + st.x
						var py: int = y + go.y + gy + st.y
						if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
							continue
						var par := (px + origin.x + py + origin.y) & 1
						match off:
							0: img.set_pixel(px, py, Color8(0, 0, 0))
							1: img.set_pixel(px, py, SH1_EVEN if par == 0 else SH1_ODD)
							2: img.set_pixel(px, py, SH2)
							3: img.set_pixel(px, py, SH3)
			pen += int(g["adv"])


## Exact palette dim of one colour (the modal backdrop remap); colours outside
## the captured LUT fall back to the fitted multiply.
static func dim_color(c: Color) -> Color:
	_load()
	var key := "%d,%d,%d" % [c.r8, c.g8, c.b8]
	if _dim.has(key):
		var d: Color = _dim[key]
		return Color(d.r, d.g, d.b, c.a)
	return Color(c.r * 0.63, c.g * 0.63, c.b * 0.65, c.a)


## A dimmed copy of a texture (kits / crests under the modal), cached.
static func dim_texture(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	_load()
	if _dim_tex_cache.has(tex):
		return _dim_tex_cache[tex]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, dim_color(c))
	var out := ImageTexture.create_from_image(img)
	_dim_tex_cache[tex] = out
	return out
