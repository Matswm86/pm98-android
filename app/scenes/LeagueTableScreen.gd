extends Control
class_name LeagueTableScreen
## PM98 LEAGUE TABLES screen rebuilt from the ORIGINAL game art: the RECURSOS FONDO
## background, the BARRA chrome bar, the real PROMAN raster font (WINFONTS, cracked to
## BMFont), and the beveled blue stat cells / red points cells of the original. Driven
## by a live standings table (Career or SeasonSim), so what you see is the real engine
## result in the real game's skin.
##
## Native canvas is 640x480 (the original screen); the node scales to fit its parent.
## Layout coordinates are reconstructed against the original LEAGUE TABLES screenshot.
## Asset provenance + the crackers: tools/re/{export_art,fnt_to_bmfont}.py.

const W := 640
const H := 480

# Palette-accurate colours read off the original screen.
const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_PTS := Color(0.59, 0.16, 0.12)
const C_PTS_HI := Color(0.78, 0.31, 0.24)
const C_PTS_TXT := Color(1.0, 0.92, 0.86)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_EURO := Color(0.16, 0.43, 0.27)
const C_RELEG := Color(0.51, 0.18, 0.16)

# Each MINIESC kit PNG is 48x64 holding home (left) + away (right); the home kit
# is the left ~31px (gap at col 30-32). We show the home kit only, as the original.
const KIT_SRC := Rect2(0, 0, 31, 64)

var _bg: Texture2D
var _bar: Texture2D
var _f24: Font
var _f18: Font
var _f12: Font
var _kits: Dictionary = {}     # club id -> Texture2D | null (cached, incl. misses)

var _rows: Array = []        # standings rows {id,name,P,W,D,L,GF,GA,Pts}
var _title_left: String = "" # manager club name
var _season: String = "1997-98"
var _week_label: String = ""
var _tier: int = 1
var _my_id: int = -1


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f24 = load("res://art/fonts/proman24.fnt")
	_f18 = load("res://art/fonts/proman18.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # crisp pixel kits when scaled
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Real club kit (home), keyed by club id; null + cached when no art exists for the id.
func _kit(id: int) -> Texture2D:
	if not _kits.has(id):
		var path := "res://art/kits/%d.png" % id
		_kits[id] = load(path) if ResourceLoader.exists(path) else null
	return _kits[id]


## Draw the home kit (left crop) of a club, fitted into a box, preserving aspect.
func _draw_kit(id: int, x: float, y: float, box_w: float, box_h: float) -> void:
	var tex := _kit(id)
	if tex == null:
		return
	var s: float = min(box_w / KIT_SRC.size.x, box_h / KIT_SRC.size.y)
	var w := KIT_SRC.size.x * s
	var h := KIT_SRC.size.y * s
	draw_texture_rect_region(tex, Rect2(x + (box_w - w) * 0.5, y + (box_h - h) * 0.5, w, h), KIT_SRC)


## Feed the screen a standings table + chrome labels, then repaint.
func setup(rows: Array, title_left: String, season: String, week_label: String,
		tier: int = 1, my_id: int = -1) -> void:
	_rows = rows
	_title_left = title_left
	_season = season
	_week_label = week_label
	_tier = tier
	_my_id = my_id
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(x: int, y: int, w: int, h: int, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(Rect2(x, y, w, h), base, true)
	draw_rect(Rect2(x, y, w, 1), hi, true)
	draw_rect(Rect2(x, y, 1, h), hi, true)
	draw_rect(Rect2(x, y + h - 1, w, 1), lo, true)
	draw_rect(Rect2(x + w - 1, y, 1, h), lo, true)


func _draw() -> void:
	# Scale the 640x480 native layout to whatever box we're given.
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f24, 200, 14, "LEAGUE TABLES", C_TITLE, 26)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _title_left.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, _div_name(_tier), C_TEXT, 13, true)
	_txt(_f12, 628, 26, _week_label, C_DIM, 13, true)

	_txt(_f18, 16, 68, _div_name(_tier).to_upper(), C_TITLE, 19)
	_txt(_f12, 410, 76, _season, C_DIM, 13)

	var hy := 96
	_txt(_f12, 16, hy, "POS", C_DIM, 13)
	_txt(_f12, 64, hy, "TEAM", C_DIM, 13)
	for col in _cols():
		_txt(_f12, col[1], hy, col[0], C_DIM, 13, true)

	var n := _rows.size()
	var releg := int(SeasonSim.ZONES.get(_tier, {"releg": 3}).get("releg", 3))
	var y0 := 112
	var rh := 17
	var row_w := 524
	for i in n:
		var r: Dictionary = _rows[i]
		var y := y0 + i * rh
		draw_rect(Rect2(14, y, row_w, rh - 1), C_ROW_A if i % 2 == 0 else C_ROW_B, true)
		if i < 5:
			draw_rect(Rect2(14, y, 3, rh - 1), C_EURO, true)
		elif i >= n - releg:
			draw_rect(Rect2(14, y, 3, rh - 1), C_RELEG, true)
		if int(r.get("id", -1)) == _my_id:
			draw_rect(Rect2(14, y, row_w, rh - 1), Color(1, 1, 1, 0.06), true)
		_txt(_f12, 36, y + 2, str(i + 1), C_TEXT, 13, true)
		_draw_kit(int(r.get("id", -1)), 42, y, 16, rh - 1)
		_txt(_f12, 64, y + 2, str(r.get("name", "?")).substr(0, 16), C_TEXT, 13)
		var vals := [r.get("P", 0), r.get("W", 0), r.get("D", 0), r.get("L", 0),
			r.get("GF", 0), r.get("GA", 0)]
		var xs := [320, 348, 376, 404, 438, 472]
		for c in 6:
			var x: int = xs[c]
			_cell(x - 24, y + 1, 22, rh - 3, C_CELL, C_CELL_HI, C_CELL_LO)
			_txt(_f12, x - 3, y + 2, str(vals[c]), C_TEXT, 13, true)
		_cell(508, y + 1, 28, rh - 3, C_PTS, C_PTS_HI, C_CELL_LO)
		_txt(_f12, 532, y + 2, str(r.get("Pts", 0)), C_PTS_TXT, 13, true)

	_leader_panel()


# Right-side LEADER panel: leader's kit + name, division tabs, GOAL SCORERS, RETURN.
func _leader_panel() -> void:
	var px := 548
	var pw := 84
	_cell(px, 92, pw, 110, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f12, px + pw / 2 + 24, 96, "LEADER", C_TITLE, 13, true)
	if _rows.size() > 0:
		var lead: Dictionary = _rows[0]
		_draw_kit(int(lead.get("id", -1)), px + 18, 112, 48, 70)
		_txt(_f12, px + 4, 186, str(lead.get("name", "?")).substr(0, 13), C_DIM, 12)

	var tabs := ["Premier", "First", "Second", "Third"]
	for t in 4:
		var ty := 214 + t * 26
		var sel := (t + 1) == _tier
		_cell(px, ty, pw, 22, C_PTS if sel else C_CELL,
			C_PTS_HI if sel else C_CELL_HI, C_CELL_LO)
		_txt(_f12, px + 8, ty + 4, tabs[t], C_PTS_TXT if sel else C_TEXT, 13)

	_cell(px, 422, pw, 22, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f12, px + 8, 426, "GOAL SCORERS", C_TEXT, 11)
	_cell(px, 452, pw, 22, C_EURO, Color(0.27, 0.59, 0.39), Color(0.08, 0.24, 0.16))
	_txt(_f12, px + 12, 457, "RETURN", Color(0.92, 1.0, 0.94), 13)


func _cols() -> Array:
	return [["P", 320], ["W", 348], ["D", 376], ["L", 404], ["GF", 438], ["GA", 472], ["PTS", 532]]


func _div_name(tier: int) -> String:
	return {1: "Premier", 2: "Division One", 3: "Division Two", 4: "Division Three"}.get(tier, "League")
