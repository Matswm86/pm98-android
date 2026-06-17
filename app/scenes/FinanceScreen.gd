extends Control
class_name FinanceScreen
## PM98 FINANCES (CAJA — "INCOME + EXPENSES") screen rebuilt from the ORIGINAL game
## art at the coordinates reversed out of MANAGER.EXE (FUN_00501c2a + FUN_00502120).
## See docs/re/finance_screen_re.md.
##
## Reversed: content header bar (21,51)..(613,78) reading "INCOME + EXPENSES" in
## ProMan10; the ledger list area (21,78)..(613,401); the bottom total boxes
## INCOME (8,415)..(229,465) and EXPENSES (241,415)..(462,465); green/red row markers
## (recursos\iconos\caja\flechaGreen/flechaRed). Driven by FinanceModel.summary.
##
## Native 640x480; scales to fit its parent.

signal prices_pressed   # the SET PRICES button -> Main opens the ticket/board control
signal back_pressed     # RETURN / a tap elsewhere -> dismiss

const W := 640
const H := 480
const BTN_PRICES := Rect2(250, 31, 150, 17)   # "SET PRICES" entry, in the empty top strip

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_CELL := Color(0.16, 0.27, 0.47)
const C_CELL_HI := Color(0.27, 0.43, 0.65)
const C_CELL_LO := Color(0.08, 0.16, 0.31)
const C_ROW_A := Color(0.11, 0.17, 0.31)
const C_ROW_B := Color(0.086, 0.14, 0.26)
const C_INCOME := Color(0.36, 0.78, 0.45)   # flechaGreen
const C_EXPENSE := Color(0.85, 0.34, 0.30)  # flechaRed
const C_HDR_BAR := Color(0.16, 0.25, 0.42)
const C_TITLE_BLUE := Color(0.16, 0.25, 0.67)  # FUN_00437020(0x2a,0x3f,0xaa)

# Reversed rects (left,top,right,bottom) -> Rect2(x,y,w,h).
const HDR_BAR := Rect2(21, 51, 592, 27)
const LIST := Rect2(21, 78, 592, 323)
const BOX_INCOME := Rect2(8, 415, 221, 50)
const BOX_EXPENSE := Rect2(241, 415, 221, 50)
const BOX_BALANCE := Rect2(470, 415, 162, 50)   # our add (free right area)
const ROW_H := 22

var _bg: Texture2D
var _bar: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font

var _sum: Dictionary = {}
var _club: String = ""
var _manager: String = ""
var _season: String = ""


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


var _press := false   # SET PRICES held down (for the highlight)

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var on_prices := BTN_PRICES.has_point(_to_design(e.position))
	if e.pressed:
		_press = on_prices
		queue_redraw()
	else:
		var was := _press
		_press = false
		queue_redraw()
		if on_prices and was:
			prices_pressed.emit()
		elif not on_prices:
			back_pressed.emit()


## Feed the screen a FinanceModel.summary() dict + chrome labels, then repaint.
func setup(summary: Dictionary, club: String, manager: String = "", season: String = "") -> void:
	_sum = summary
	_club = club
	_manager = manager
	_season = season
	queue_redraw()


# ---- helpers -------------------------------------------------------------

## £ with thousands separators, e.g. 21500000 -> "£21,500,000".
static func fmt_money(v: int) -> String:
	var neg := v < 0
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return "%s£%s" % ["-" if neg else "", out]


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _cell(r: Rect2, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), lo, true)
	draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), lo, true)


func _marker(x: int, cy: int, up: bool, col: Color) -> void:
	# A small ▲ (income) / ▼ (expense) triangle, standing in for flechaGreen/flechaRed.
	var pts := PackedVector2Array()
	if up:
		pts.append_array([Vector2(x, cy + 4), Vector2(x + 8, cy + 4), Vector2(x + 4, cy - 4)])
	else:
		pts.append_array([Vector2(x, cy - 4), Vector2(x + 8, cy - 4), Vector2(x + 4, cy + 4)])
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	_txt(_f14, 120, 13, "FINANCES", C_TITLE, 15)
	_txt(_f12, 12, 9, "Manager", C_TEXT, 13)
	_txt(_f12, 12, 26, _manager.substr(0, 18), C_DIM, 13)
	_txt(_f12, 628, 9, _club.substr(0, 18), C_TEXT, 13, true)
	if _season != "":
		_txt(_f12, 628, 26, _season, C_DIM, 13, true)

	# Content header bar with the reversed title + column hint.
	_cell(HDR_BAR, C_HDR_BAR, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(HDR_BAR.position.x) + 10, int(HDR_BAR.position.y) + 7, "INCOME + EXPENSES",
		C_TITLE, 11)
	_txt(_f10, int(HDR_BAR.end.x) - 12, int(HDR_BAR.position.y) + 7, "AMOUNT (season)",
		C_HEAD, 11, true)

	# SET PRICES entry (the board ticket / advertising-board control), in the empty strip
	# under the title. Tap it to open the control; tap anywhere else dismisses.
	_cell(BTN_PRICES, C_CELL_HI if _press else C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(BTN_PRICES.position.x) + 10, int(BTN_PRICES.position.y) + 3, "SET PRICES",
		Color(0.95, 0.86, 0.55), 11)

	_draw_ledger()
	_draw_totals()


func _draw_ledger() -> void:
	var y := int(LIST.position.y) + 6
	var row := 0
	y = _section("INCOME", _sum.get("income_lines", []), true, C_INCOME, y, row)
	row += 1 + (_sum.get("income_lines", []) as Array).size()
	y += 6
	_section("EXPENDITURE", _sum.get("expense_lines", []), false, C_EXPENSE, y, row)


func _section(title: String, lines: Array, up: bool, mark: Color, y0: int, row0: int) -> int:
	var y := y0
	_txt(_f10, int(LIST.position.x) + 8, y + 4, title, C_HEAD, 11)
	y += ROW_H
	var row := row0 + 1
	for line in lines:
		if y + ROW_H > int(LIST.end.y):
			break
		draw_rect(Rect2(LIST.position.x, y, LIST.size.x, ROW_H - 2),
			C_ROW_A if row % 2 == 0 else C_ROW_B, true)
		_marker(int(LIST.position.x) + 12, y + ROW_H / 2 - 1, up, mark)
		_txt(_f12, int(LIST.position.x) + 30, y + 3, str(line[0]), C_TEXT, 13)
		_txt(_f12, int(LIST.end.x) - 16, y + 3, fmt_money(int(line[1])), C_TEXT, 13, true)
		y += ROW_H
		row += 1
	return y


func _draw_totals() -> void:
	var inc := int(_sum.get("total_income", 0))
	var exp := int(_sum.get("total_expense", 0))
	var bal := int(_sum.get("season_balance", inc - exp))

	_cell(BOX_INCOME, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(BOX_INCOME.position.x) + 10, int(BOX_INCOME.position.y) + 6, "TOTAL INCOME",
		C_INCOME, 11)
	_txt(_f14, int(BOX_INCOME.end.x) - 12, int(BOX_INCOME.position.y) + 24, fmt_money(inc),
		C_TEXT, 15, true)

	_cell(BOX_EXPENSE, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(BOX_EXPENSE.position.x) + 10, int(BOX_EXPENSE.position.y) + 6, "TOTAL EXPENSES",
		C_EXPENSE, 11)
	_txt(_f14, int(BOX_EXPENSE.end.x) - 12, int(BOX_EXPENSE.position.y) + 24, fmt_money(exp),
		C_TEXT, 15, true)

	_cell(BOX_BALANCE, C_CELL, C_CELL_HI, C_CELL_LO)
	_txt(_f10, int(BOX_BALANCE.position.x) + 10, int(BOX_BALANCE.position.y) + 6, "BALANCE",
		C_HEAD, 11)
	_txt(_f14, int(BOX_BALANCE.end.x) - 12, int(BOX_BALANCE.position.y) + 24, fmt_money(bal),
		C_INCOME if bal >= 0 else C_EXPENSE, 15, true)
