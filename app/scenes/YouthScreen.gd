extends Control
class_name YouthScreen
## PM98 YOUTH TEAM screen: the academy crop, reached from the SQUAD MANAGEMENT screen's
## reversed "YOUTH TEAM" button (recursos\iconos\plantilla\juveniles.bmp). Lists the
## youngsters with their current ability + a projected-potential star rating, badges the
## ones the youth manager has flagged READY, and promotes a ready youngster into the
## first team on a tap.
##
## Faithful surface (MANAGER.EXE strings): YOUTH TEAM / YOUTH PLAYER / PROMOTE / PROMOTED,
## "Your youth manager has informed you that %s is ready to be promoted to the first team
## squad.". The development/potential model itself is ours (Youth.gd) -- PM98's youth
## ratings are data-driven, not code constants.
##
## INTERACTIVE like MenuScreen: tapping a READY youngster emits `promote_requested(pid)`;
## the RETURN button (or a tap on empty space) emits `back_pressed`. Native 640x480,
## self-scales + marble-bezels to fit the landscape frame. Driven by Career.youth.

signal promote_requested(pid: int)
signal back_pressed

const W := 640
const H := 480

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_NAME := Color(1.0, 1.0, 1.0)
const C_READY := Color(1.0, 0.87, 0.0)        # gold READY badge (matches squad sections)
const C_STAR := Color(0.98, 0.82, 0.36)
const C_STAR_OFF := Color(0.30, 0.36, 0.50)
const C_BTN := Color(0.16, 0.43, 0.27)
const C_BTN_HI := Color(0.27, 0.59, 0.39)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.20)

# {code, x_left} columns laid into the reversed full-width list panel (x 8..516).
const COLS := [
	["N.", 12], ["PLAYER", 38], ["AGE", 196], ["AB", 244], ["POTENTIAL", 286], ["", 392],
]

const PANEL := Rect2(8, 48, 508, 421)
const HDR_Y := 52
const ROW0_Y := 70
const ROW_H := 18
const RETURN_BTN := Rect2(523, 440, 112, 25)

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _youth: Array = []
var _manager: String = ""
var _club: String = ""
var _cash: String = ""
var _press := ""                 # "return" or "row:<pid>" held down (for the highlight)
var _row_rects: Array = []       # [{pid, ready, rect:Rect2}] built each _draw for hit-testing


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the live youth team + chrome, then repaint. Ready players sort to the top.
func setup(youth: Array, manager := "", club := "", cash := "") -> void:
	_youth = youth.duplicate()
	_youth.sort_custom(func(a, b):
		var ra := Youth.is_ready(a)
		var rb := Youth.is_ready(b)
		if ra != rb:
			return ra                       # ready first
		return Youth.ability(a) > Youth.ability(b))
	_manager = manager
	_club = club
	_cash = cash
	queue_redraw()


# ---- geometry / input ----------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


## The token under a design-space point: "return", "row:<pid>" (ready only), or "".
func _hit(d: Vector2) -> String:
	if RETURN_BTN.has_point(d):
		return "return"
	for r in _row_rects:
		if bool(r["ready"]) and (r["rect"] as Rect2).has_point(d):
			return "row:%d" % int(r["pid"])
	return ""


func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		pos = (e as InputEventMouseButton).position
		pressed = (e as InputEventMouseButton).pressed
		tap = true
	elif e is InputEventScreenTouch:
		pos = (e as InputEventScreenTouch).position
		pressed = (e as InputEventScreenTouch).pressed
		tap = true
	if not tap:
		return
	if pressed:
		_press = _hit(_to_design(pos))
		queue_redraw()
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		queue_redraw()
		if a == "" or a != was:
			# A tap that didn't land on a live control (or wandered off) returns, like the
			# other display screens' tap-to-dismiss -- but never if it began on a control.
			if was == "":
				back_pressed.emit()
			return
		if a == "return":
			back_pressed.emit()
		elif a.begins_with("row:"):
			promote_requested.emit(int(a.substr(4)))


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(x: int, y: int, w: int, h: int, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(Rect2(x, y, w, h), base, true)
	draw_rect(Rect2(x, y, w, 1), hi, true)
	draw_rect(Rect2(x, y, 1, h), hi, true)
	draw_rect(Rect2(x, y + h - 1, w, 1), lo, true)
	draw_rect(Rect2(x + w - 1, y, 1, h), lo, true)


func _stars(x: int, y: int, n: int) -> void:
	for i in 5:
		_txt(_f8, x + i * 9, y, "*", C_STAR if i < n else C_STAR_OFF, 12)


func _draw() -> void:
	var s := _scale()
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 150, 13, "YOUTH TEAM", C_TITLE, 15)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, _club.substr(0, 18), C_TEXT, 13, true)
	if _cash != "":
		_txt(_f12, 628, 26, _cash, C_DIM, 13, true)

	# Column header row.
	for c in COLS:
		var code: String = c[0]
		if code == "":
			continue
		var x: int = c[1]
		if code == "PLAYER" or code == "N." or code == "POTENTIAL":
			_txt(_f8, x, HDR_Y, code, C_HEAD, 11)
		else:
			_txt(_f8, x + 18, HDR_Y, code, C_HEAD, 11, true)

	_draw_list()
	_draw_side()


func _draw_list() -> void:
	_row_rects = []
	var y := ROW0_Y
	var row := 0
	var number := 1
	if _youth.is_empty():
		_txt(_f10, COLS[1][1], y + 2, "No youth players -- the scout is searching.", C_DIM, 12)
		return
	for p in _youth:
		if y + ROW_H > int(PANEL.position.y + PANEL.size.y):
			break
		var ready := Youth.is_ready(p)
		var rect := Rect2(int(PANEL.position.x), y, int(PANEL.size.x), ROW_H - 1)
		draw_rect(rect, C_ROW_A if row % 2 == 0 else C_ROW_B, true)
		if ready and _press == "row:%d" % int(p.get("id", -1)):
			draw_rect(rect, C_HILITE, true)
		_row_player(p, number, y, ready)
		_row_rects.append({"pid": int(p.get("id", -1)), "ready": ready, "rect": rect})
		y += ROW_H
		row += 1
		number += 1


func _row_player(p: Dictionary, number: int, y: int, ready: bool) -> void:
	var ty := y + 3
	_txt(_f8, COLS[0][1] + 16, ty, str(number), C_TEXT, 11, true)
	var tag := " (GK)" if p.get("isGK") else ""
	_txt(_f8, COLS[1][1], ty, (str(p.get("name", "?")) + tag).substr(0, 18), C_NAME, 11)
	_txt(_f8, COLS[2][1] + 18, ty, str(p.get("age", "")), C_TEXT, 11, true)
	_txt(_f8, COLS[3][1] + 18, ty, str(Youth.ability(p)), C_TEXT, 11, true)
	_stars(COLS[4][1], ty, Youth.potential_stars(p))
	if ready:
		_txt(_f8, COLS[5][1], ty, "READY - PROMOTE", C_READY, 11)
	else:
		_txt(_f8, COLS[5][1], ty, "developing", C_DIM, 11)


## Right column: a ready-count box, a star legend and the RETURN button.
func _draw_side() -> void:
	var ready := 0
	for p in _youth:
		if Youth.is_ready(p):
			ready += 1
	_cell(523, 60, 112, 54, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, 529, 64, "ACADEMY", C_HEAD, 11)
	_txt(_f8, 631, 80, "%d in youth" % _youth.size(), C_TEXT, 10, true)
	_txt(_f8, 631, 96, "%d ready" % ready, C_READY if ready > 0 else C_DIM, 10, true)

	_cell(523, 124, 112, 64, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f8, 529, 128, "POTENTIAL", C_HEAD, 10)
	_stars(529, 144, 5)
	_txt(_f8, 529, 162, "projected ceiling", C_DIM, 10)

	var rb := RETURN_BTN
	_cell(int(rb.position.x), int(rb.position.y), int(rb.size.x), int(rb.size.y),
		C_BTN if _press != "return" else C_BTN_HI, C_BTN_HI, C_CELL_LO)
	_txt(_f10, int(rb.position.x) + 10, int(rb.position.y) + 6, "RETURN", Color(0.92, 1.0, 0.94), 11)
