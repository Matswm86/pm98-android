extends Control
class_name StaffScreen
## PM98 STAFF (EMPLE / employees) screen, on the Main Menu's EMPLE icon. Two sections --
## CURRENT STAFF (the backroom team you've hired, tap to SACK) and STAFF AVAILABLE (the pool,
## tap to HIRE) -- with each member's role, a quality star rating and a yearly wage, plus a
## STAFF WAGES total and the live effect of the staff on development / injuries / youth.
##
## Faithful surface (MANAGER.EXE strings): STAFF / STAFF WAGES / STAFF AVAILABLE /
## CURRENT TRAINING STAFF / TRAINER / PHYSIOTHERAPIST / YOUTH (TEAM) MANAGER, HIRE
## (contratar.bmp) / SACK (despedir.bmp), YEARLY WAGE, COMPENSATIONS OF CONTRACT,
## "Are you sure you want to sack him ?". The effects + wages model is ours (Staff.gd);
## the surface is PM98's. A general transfer SCOUT and the ASSISTANT MANAGER are deferred.
##
## INTERACTIVE like MenuScreen: tapping a hired member emits `sack_requested(id)`, a pool
## candidate emits `hire_requested(id)`; the TRAINING button emits `training_requested`,
## RETURN (or a tap on empty space) emits `back_pressed`. Native 640x480, self-scales +
## marble-bezels to fit the landscape frame. Driven by Career.staff + Career.staff_pool.

signal hire_requested(cand_id: int)
signal sack_requested(member_id: int)
signal training_requested
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
const C_SECTION := Color(1.0, 0.87, 0.0)
const C_NAME := Color(1.0, 1.0, 1.0)
const C_STAR := Color(0.98, 0.82, 0.36)
const C_STAR_OFF := Color(0.30, 0.36, 0.50)
const C_WAGE := Color(0.96, 0.87, 0.47)
const C_HIRE := Color(0.34, 0.86, 0.46)
const C_SACK := Color(0.92, 0.55, 0.40)
const C_BTN := Color(0.16, 0.43, 0.27)
const C_BTN_HI := Color(0.27, 0.59, 0.39)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.20)

# {label, x} columns in the reversed full-width list panel (x 8..516).
const COL_NAME := 38
const COL_ROLE := 188
const COL_STARS := 322
const COL_ACT := 400

const PANEL := Rect2(8, 48, 508, 421)
const HDR_Y := 52
const ROW0_Y := 70
const ROW_H := 18
const TRAIN_BTN := Rect2(523, 408, 112, 25)
const RETURN_BTN := Rect2(523, 440, 112, 25)

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _staff: Array = []
var _pool: Array = []
var _manager: String = ""
var _club: String = ""
var _cash: String = ""
var _press := ""                 # token held down (for the highlight)
var _arm_sack := -1              # a sack tapped once is "armed"; a 2nd tap confirms it
var _row_rects: Array = []       # [{token, rect}] built each _draw for hit-testing


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


## Feed the hired staff + the available pool + chrome, then repaint.
func setup(staff: Array, pool: Array, manager := "", club := "", cash := "") -> void:
	_staff = staff
	_pool = pool
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

func _hit(d: Vector2) -> String:
	if TRAIN_BTN.has_point(d):
		return "train"
	if RETURN_BTN.has_point(d):
		return "return"
	for r in _row_rects:
		if (r["rect"] as Rect2).has_point(d):
			return str(r["token"])
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
		var prev_arm := _arm_sack
		_press = ""
		_arm_sack = -1               # any release disarms unless the sack branch re-arms
		queue_redraw()
		if a == "" or a != was:
			if was == "":
				back_pressed.emit()
			return
		if a == "return":
			back_pressed.emit()
		elif a == "train":
			training_requested.emit()
		elif a.begins_with("hire:"):
			hire_requested.emit(int(a.substr(5)))
		elif a.begins_with("sack:"):
			# "Are you sure you want to sack him ?" -- arm on the first tap, sack on the second.
			var sid := int(a.substr(5))
			if prev_arm == sid:
				sack_requested.emit(sid)
			else:
				_arm_sack = sid
				queue_redraw()


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


func _money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _draw() -> void:
	var s := _scale()
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 150, 13, "STAFF", C_TITLE, 15)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, _club.substr(0, 18), C_TEXT, 13, true)
	if _cash != "":
		_txt(_f12, 628, 26, _cash, C_DIM, 13, true)

	# Column header.
	_txt(_f8, COL_NAME, HDR_Y, "NAME", C_HEAD, 11)
	_txt(_f8, COL_ROLE, HDR_Y, "ROLE", C_HEAD, 11)
	_txt(_f8, COL_STARS, HDR_Y, "QUALITY", C_HEAD, 11)
	_txt(_f8, 506, HDR_Y, "WAGE/yr", C_HEAD, 11, true)

	_draw_list()
	_draw_side()


func _draw_list() -> void:
	_row_rects = []
	var y := ROW0_Y
	var row := 0
	for sec in [{"title": "CURRENT STAFF", "members": _staff, "act": "sack"},
			{"title": "STAFF AVAILABLE", "members": _pool, "act": "hire"}]:
		_txt(_f8, COL_NAME, y + 2, str(sec["title"]), C_SECTION, 11)
		y += ROW_H
		var members: Array = sec["members"]
		if members.is_empty():
			var none := "No staff hired -- tap one below to HIRE" if sec["act"] == "sack" \
				else "No staff on the market"
			_txt(_f8, COL_NAME, y + 2, none, C_DIM, 11)
			y += ROW_H
			continue
		for m in members:
			if y + ROW_H > int(PANEL.position.y + PANEL.size.y):
				return
			var token := "%s:%d" % [sec["act"], int(m.get("id", -1))]
			var rect := Rect2(int(PANEL.position.x), y, int(PANEL.size.x), ROW_H - 1)
			draw_rect(rect, C_ROW_A if row % 2 == 0 else C_ROW_B, true)
			if _press == token:
				draw_rect(rect, C_HILITE, true)
			_row_member(m, y, str(sec["act"]))
			_row_rects.append({"token": token, "rect": rect})
			y += ROW_H
			row += 1


func _row_member(m: Dictionary, y: int, act: String) -> void:
	var ty := y + 3
	_txt(_f8, COL_NAME, ty, str(m.get("name", "?")).substr(0, 20), C_NAME, 11)
	_txt(_f8, COL_ROLE, ty, str(m.get("role", "")), C_TEXT, 11)
	_stars(COL_STARS, ty, clampi(int(m.get("quality", 0)), 0, 5))
	_txt(_f8, 506, ty, "£" + _money(int(m.get("wage", 0))), C_WAGE, 11, true)
	if act == "sack":
		var armed := int(m.get("id", -1)) == _arm_sack
		_txt(_f8, COL_ACT, ty, "SURE? SACK" if armed else "SACK", C_SACK, 11)
	else:
		_txt(_f8, COL_ACT, ty, "HIRE", C_HIRE, 11)


## Right column: the STAFF WAGES total, the live effect summary, TRAINING + RETURN buttons.
func _draw_side() -> void:
	_cell(523, 60, 112, 46, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, 529, 64, "STAFF WAGES", C_HEAD, 11)
	var n := _staff.size()
	_txt(_f8, 631, 80, "%d %s" % [n, "member" if n == 1 else "members"], C_TEXT, 10, true)
	_txt(_f8, 631, 92, "£%s/wk" % _money(Staff.weekly_wage(_staff)), C_WAGE, 10, true)

	# Live effect of the current staff on the three systems.
	_cell(523, 116, 112, 70, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f8, 529, 120, "EFFECT", C_HEAD, 10)
	_txt(_f8, 529, 136, Staff.effect_label(Staff.TRAINER, Staff.training_factor(_staff)), C_TEXT, 10)
	_txt(_f8, 529, 150, Staff.effect_label(Staff.PHYSIO, Staff.physio_factor(_staff)), C_TEXT, 10)
	_txt(_f8, 529, 164, Staff.effect_label(Staff.YOUTH_COACH, Staff.youth_factor(_staff)), C_TEXT, 10)

	var tb := TRAIN_BTN
	_cell(int(tb.position.x), int(tb.position.y), int(tb.size.x), int(tb.size.y),
		C_BTN if _press != "train" else C_BTN_HI, C_BTN_HI, C_CELL_LO)
	_txt(_f10, int(tb.position.x) + 10, int(tb.position.y) + 6, "TRAINING", Color(0.92, 1.0, 0.94), 11)

	var rb := RETURN_BTN
	_cell(int(rb.position.x), int(rb.position.y), int(rb.size.x), int(rb.size.y),
		C_CELL_HI if _press == "return" else C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(rb.position.x) + 6, int(rb.position.y) + 6, "RETURN", C_TEXT, 11)
