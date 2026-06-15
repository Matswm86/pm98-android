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

var _bg: Texture2D
var _bar: Texture2D
var _f24: Font
var _f18: Font
var _f12: Font

var _rows: Array = []        # standings rows {id,name,P,W,D,L,GF,GA,Pts}
var _title_left: String = "" # manager club name
var _season: String = "1997-98"
var _week_label: String = ""
var _tier: int = 1
var _my_id: int = -1


func _ready() -> void:
	_bg = load("res://art/screens/fondo_blue.png")
	_bar = load("res://art/screens/barra0.png")
	_f24 = load("res://art/fonts/proman24.fnt")
	_f18 = load("res://art/fonts/proman18.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


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

	_txt(_f24, 215, 14, "LEAGUE TABLES", C_TITLE, 26)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _title_left.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, _div_name(_tier), C_TEXT, 13, true)
	_txt(_f12, 628, 26, _week_label, C_DIM, 13, true)

	_txt(_f18, 16, 68, _div_name(_tier).to_upper(), C_TITLE, 19)
	_txt(_f12, 470, 76, _season, C_DIM, 13)

	var hy := 96
	_txt(_f12, 16, hy, "POS", C_DIM, 13)
	_txt(_f12, 60, hy, "TEAM", C_DIM, 13)
	for col in _cols():
		_txt(_f12, col[1], hy, col[0], C_DIM, 13, true)

	var n := _rows.size()
	var releg := int(SeasonSim.ZONES.get(_tier, {"releg": 3}).get("releg", 3))
	var y0 := 112
	var rh := 17
	for i in n:
		var r: Dictionary = _rows[i]
		var y := y0 + i * rh
		draw_rect(Rect2(14, y, 612, rh - 1), C_ROW_A if i % 2 == 0 else C_ROW_B, true)
		if i < 5:
			draw_rect(Rect2(14, y, 3, rh - 1), C_EURO, true)
		elif i >= n - releg:
			draw_rect(Rect2(14, y, 3, rh - 1), C_RELEG, true)
		if int(r.get("id", -1)) == _my_id:
			draw_rect(Rect2(14, y, 612, rh - 1), Color(1, 1, 1, 0.06), true)
		_txt(_f12, 36, y + 2, str(i + 1), C_TEXT, 13, true)
		_txt(_f12, 60, y + 2, str(r.get("name", "?")).substr(0, 18), C_TEXT, 13)
		var vals := [r.get("P", 0), r.get("W", 0), r.get("D", 0), r.get("L", 0),
			r.get("GF", 0), r.get("GA", 0)]
		var xs := [348, 380, 412, 444, 480, 516]
		for c in 6:
			var x: int = xs[c]
			_cell(x - 26, y + 1, 24, rh - 3, C_CELL, C_CELL_HI, C_CELL_LO)
			_txt(_f12, x - 4, y + 2, str(vals[c]), C_TEXT, 13, true)
		_cell(532, y + 1, 28, rh - 3, C_PTS, C_PTS_HI, C_CELL_LO)
		_txt(_f12, 556, y + 2, str(r.get("Pts", 0)), C_PTS_TXT, 13, true)

	_cell(548, 452, 84, 22, C_EURO, Color(0.27, 0.59, 0.39), Color(0.08, 0.24, 0.16))
	_txt(_f12, 560, 457, "RETURN", Color(0.92, 1.0, 0.94), 13)


func _cols() -> Array:
	return [["P", 348], ["W", 380], ["D", 412], ["L", 444], ["GF", 480], ["GA", 516], ["PTS", 560]]


func _div_name(tier: int) -> String:
	return {1: "Premier", 2: "Division One", 3: "Division Two", 4: "Division Three"}.get(tier, "League")
