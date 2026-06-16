extends Control
class_name BrowseScreen
## Reusable PM98-chrome list / select screen (Track B interim styling): the RECURSOS
## marble FONDO + the BARRA chrome bar + the real PROMAN raster font, with a navy
## beveled list panel of selectable rows. Used for the green-UI replacements that have
## no single reversed original screen of their own: the database browse (home / league /
## club / country lists), the new-career club & league pickers, and the match-feed
## read-out. The dedicated reversed screens (SQUAD, LEAGUE TABLES, etc.) stay separate;
## this is the connective chrome between them so the whole app reads as PM98, not green.
##
## Interactive like MenuScreen: drag to scroll, tap a row to select. Emits
## row_selected(index) and back_pressed; the calling Main routes them. Native 640x480,
## scales to fit its parent with a marble bezel in the landscape side margins.

signal row_selected(index: int)
signal back_pressed

const W := 640
const H := 480

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_VALUE := Color(0.98, 0.86, 0.45)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_SEL := Color(0.27, 0.43, 0.65, 0.85)
const C_PRESS := Color(1.0, 1.0, 1.0, 0.18)
const C_SECTION := Color(1.0, 0.87, 0.0)
const C_BTN := Color(0.16, 0.43, 0.27)
const C_BTN_HI := Color(0.27, 0.59, 0.39)

const PANEL := Rect2(12, 50, 616, 392)
const ROW_H := 26
const BACK_BTN := Rect2(523, 448, 112, 26)
const DRAG_SLOP := 6.0        # design px of travel before a tap becomes a scroll

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font

var _title: String = ""
var _subtitle: String = ""
var _rows: Array = []         # normalized: [{text,value,enabled,accent}]
var _show_back: bool = true
var _back_label: String = "RETURN"

var _scroll: float = 0.0
var _down: bool = false
var _moved: bool = false
var _start_y: float = 0.0
var _start_scroll: float = 0.0
var _press_target: int = -2   # row index, -1 = back button, -2 = none


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the list. `rows` accepts plain strings or dicts {text, value?, enabled?, accent?}.
## opts: {show_back:bool, back_label:String}.
func setup(title: String, subtitle: String, rows: Array, opts: Dictionary = {}) -> void:
	_title = title
	_subtitle = subtitle
	_rows = []
	for r in rows:
		if r is Dictionary:
			_rows.append({
				"text": str(r.get("text", "")),
				"value": str(r.get("value", "")),
				"enabled": bool(r.get("enabled", true)),
				"accent": r.get("accent"),
			})
		else:
			_rows.append({"text": str(r), "value": "", "enabled": true, "accent": null})
	_show_back = bool(opts.get("show_back", true))
	_back_label = str(opts.get("back_label", "RETURN"))
	_scroll = 0.0
	queue_redraw()


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _content_h() -> float:
	return float(_rows.size() * ROW_H)

func _max_scroll() -> float:
	return maxf(0.0, _content_h() - PANEL.size.y)

## Row index under a design-space point inside the panel, or -1.
func _row_at(d: Vector2) -> int:
	if not PANEL.has_point(d):
		return -1
	var idx := int((d.y - PANEL.position.y + _scroll) / ROW_H)
	return idx if idx >= 0 and idx < _rows.size() else -1

## What a design-space point targets: a row index, -1 for the back button, -2 for nothing.
func _target_at(d: Vector2) -> int:
	if _show_back and BACK_BTN.has_point(d):
		return -1
	var idx := _row_at(d)
	if idx >= 0 and bool(_rows[idx].get("enabled", true)):
		return idx
	return -2


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		var pressed: bool = e.pressed
		var d := _to_design(e.position)
		if pressed:
			_down = true
			_moved = false
			_start_y = float(e.position.y)
			_start_scroll = _scroll
			_press_target = _target_at(d)
			queue_redraw()
		else:
			var was := _press_target
			var down := _down
			_down = false
			_press_target = -2
			queue_redraw()
			if down and not _moved and was != -2 and was == _target_at(d):
				if was == -1:
					back_pressed.emit()
				else:
					row_selected.emit(was)
	elif (e is InputEventScreenDrag or e is InputEventMouseMotion) and _down:
		var s := _scale()
		var dy: float = (float(e.position.y) - _start_y) / (s if s > 0.0 else 1.0)
		if absf(dy) > DRAG_SLOP:
			_moved = true
			_press_target = -2
		_scroll = clampf(_start_scroll - dy, 0.0, _max_scroll())
		queue_redraw()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false, cw := 0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if right:
		px = x - w
	elif cw > 0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(r: Rect2, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), lo, true)
	draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), lo, true)


func _draw() -> void:
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 150, 13, _title.substr(0, 30), C_TITLE, 15)
	if _subtitle != "":
		_txt(_f12, 628, 26, _subtitle.substr(0, 40), C_DIM, 13, true)

	# List panel + rows (rows are vertically clamped to the panel; partial edge rows
	# show their bar but suppress text so nothing bleeds over the BARRA / back button).
	_cell(PANEL, C_CELL_LO, C_CELL_HI, Color(0.04, 0.08, 0.16))
	_draw_rows()
	if _show_back:
		_cell(BACK_BTN, C_BTN, C_BTN_HI, C_CELL_LO)
		_txt(_f12, int(BACK_BTN.position.x), int(BACK_BTN.position.y) + 6,
			_back_label, Color(0.92, 1.0, 0.94), 13, false, int(BACK_BTN.size.x))


func _draw_rows() -> void:
	var px := int(PANEL.position.x)
	var pw := int(PANEL.size.x)
	var top := int(PANEL.position.y)
	var bot := int(PANEL.position.y + PANEL.size.y)
	for i in _rows.size():
		var ry := top + i * ROW_H - int(_scroll)
		if ry + ROW_H <= top or ry >= bot:
			continue   # off-panel
		var row: Dictionary = _rows[i]
		var enabled: bool = bool(row.get("enabled", true))
		# Row background (alternating), clamped to the panel's vertical extent.
		var y0 := maxi(ry, top + 1)
		var y1 := mini(ry + ROW_H - 1, bot - 1)
		if y1 > y0:
			draw_rect(Rect2(px + 1, y0, pw - 2, y1 - y0),
				C_ROW_A if i % 2 == 0 else C_ROW_B, true)
		if i == _press_target and _down and not _moved and y1 > y0:
			draw_rect(Rect2(px + 1, y0, pw - 2, y1 - y0), C_PRESS, true)
		# Text only when the row's baseline area is on-panel.
		if ry >= top - 2 and ry + ROW_H <= bot + 2:
			var accent: Variant = row.get("accent")
			var col: Color = accent if accent is Color else (C_TEXT if enabled else C_DIM)
			_txt(_f12, px + 12, ry + 6, str(row.get("text", "")).substr(0, 46), col, 13)
			var val := str(row.get("value", ""))
			if val != "":
				_txt(_f12, px + pw - 12, ry + 6, val, C_VALUE, 13, true)
