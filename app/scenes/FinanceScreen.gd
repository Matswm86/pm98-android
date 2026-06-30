extends Control
class_name FinanceScreen
## PM98 FINANCES (CAJA — "INCOME + EXPENSES") screen, rebuilt to match the real game
## (og_12): the finance TAB chrome (INC.+EXP. / INCOME / EXPENSES | PER WEEK / PER SEASON,
## NOT the plaque header), two white ledger columns — a green INCOME panel and a brown
## EXPENSES panel each ending in a coloured TOTAL bar — the WEEKLY BALANCE chart with a
## zero axis, and the LAST WEEK / CURRENT WEEK boxes + RETURN along the bottom.
##
## Driven by FinanceModel.summary (income_lines / expense_lines / totals / weekly_balance).
## The weekly chart plots the model's per-week balance across the season (we hold no
## week-by-week history, so it is the honest constant our model produces, not invented
## variation). Native 640x480; scales to fit its parent.

signal prices_pressed   # the SET PRICES button -> Main opens the ticket/board control
signal back_pressed     # RETURN / a tap elsewhere -> dismiss
signal cheat_cash       # secret: 5 taps on the CURRENT WEEK cash box -> Main grants +100M

const CHEAT_TAPS := 5   # taps on the live-cash box that trigger the cash cheat

const W := 640
const H := 480
const SEASON_WEEKS := 38

const C_BLUE := Color(0.16, 0.30, 0.60)
const C_INCOME_HDR := Color(0.22, 0.50, 0.28)    # green INCOME header
const C_INCOME_ROW := Color(0.83, 0.90, 0.82)    # pale-green income rows
const C_EXPENSE_HDR := Color(0.52, 0.30, 0.18)   # brown EXPENSES header
const C_EXPENSE_ROW := Color(0.90, 0.84, 0.76)   # pale-brown expense rows
const C_ROW_TXT := Color(0.10, 0.13, 0.22)
const C_TOTAL_INC := Color(0.20, 0.40, 0.74)     # blue TOTAL INCOME bar
const C_TOTAL_EXP := Color(0.86, 0.78, 0.20)     # yellow TOTAL EXPENSES bar
const C_TAB := Color(0.08, 0.12, 0.24)
const C_TAB_HI := Color(0.30, 0.42, 0.66)
const C_TAB_LO := Color(0.03, 0.06, 0.14)
const C_TAB_SEL_INC := Color(0.66, 0.16, 0.14)   # selected view tab (red)
const C_TAB_SEL_PER := Color(0.20, 0.52, 0.24)   # selected period tab (green)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_CHART_BG := Color(0.06, 0.09, 0.18)
const C_BAR_POS := Color(0.36, 0.54, 0.92)
const C_BAR_NEG := Color(0.86, 0.80, 0.26)

const TITLE_Y := 30
const INC_PANEL := Rect2(6, 46, 308, 250)
const EXP_PANEL := Rect2(326, 46, 308, 250)
const CHART := Rect2(6, 304, 628, 96)
const BOX_LAST := Rect2(6, 408, 250, 58)
const BOX_CUR := Rect2(262, 408, 250, 58)
const BTN_RETURN := Rect2(520, 432, 114, 26)
const BTN_PRICES := Rect2(520, 408, 114, 20)

var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _sum: Dictionary = {}
var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _cash: int = 0
var _week: int = 0
var _press := ""
var _cash_taps := 0      # consecutive taps on the live-cash box (the hidden cheat counter)


func _ready() -> void:
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(summary: Dictionary, club: String, manager: String = "", season: String = "",
		cash: int = 0, week: int = 0) -> void:
	_sum = summary
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_week = week
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	var on_prices := BTN_PRICES.has_point(d)
	var on_return := BTN_RETURN.has_point(d) and not on_prices
	# The CURRENT WEEK box carries the live CASH figure; tapping it is the cheat target.
	var on_cash := BOX_CUR.has_point(d) and not on_prices
	if e.pressed:
		_press = "prices" if on_prices else ""
		queue_redraw()
	else:
		var was := _press
		_press = ""
		queue_redraw()
		if on_prices and was == "prices":
			prices_pressed.emit()
		elif on_cash:
			# Count consecutive taps on the cash box; the Nth fires the cheat (and is swallowed,
			# so the screen does not dismiss). Any tap elsewhere resets the run.
			_cash_taps += 1
			if _cash_taps >= CHEAT_TAPS:
				_cash_taps = 0
				cheat_cash.emit()
		elif on_return:
			_cash_taps = 0
			back_pressed.emit()
		else:
			# A tap on the ledger / chart is a no-op now (it was bouncing back to the hub).
			_cash_taps = 0


# ---- helpers -------------------------------------------------------------

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


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	_draw_tabs()

	_txt(_f12, 12, TITLE_Y, "INCOME + EXPENSES", C_BLUE.lightened(0.3), 13)
	_txt(_f12, W - 12, TITLE_Y, "SEASON %s" % _season, C_PANEL_TXT, 13, true)

	_draw_ledger(INC_PANEL, "INCOME", _sum.get("income_lines", []), C_INCOME_HDR, C_INCOME_ROW,
		"TOTAL INCOME", int(_sum.get("total_income", 0)), C_TOTAL_INC, "fin_up")
	_draw_ledger(EXP_PANEL, "EXPENSES", _sum.get("expense_lines", []), C_EXPENSE_HDR, C_EXPENSE_ROW,
		"TOTAL EXPENSES", int(_sum.get("total_expense", 0)), C_TOTAL_EXP, "fin_down")
	_draw_chart()
	_draw_week_boxes()


func _draw_tabs() -> void:
	var view := ["INC. + EXP.", "INCOME", "EXPENSES"]
	for i in 3:
		var r := Rect2(6 + i * 116, 4, 114, 18)
		PMChrome.bevel(self, r, C_TAB_SEL_INC if i == 0 else C_TAB, C_TAB_HI, C_TAB_LO)
		_centre(_f10, r, view[i], C_GOLD if i == 0 else C_PANEL_TXT, 10)
	var per := ["PER WEEK", "PER SEASON"]
	for i in 2:
		var r := Rect2(406 + i * 116, 4, 114, 18)
		PMChrome.bevel(self, r, C_TAB_SEL_PER if i == 1 else C_TAB, C_TAB_HI, C_TAB_LO)
		_centre(_f10, r, per[i], C_GOLD if i == 1 else C_PANEL_TXT, 10)


func _draw_ledger(panel: Rect2, title: String, lines: Array, hdr: Color, row_col: Color,
		total_label: String, total: int, total_col: Color, marker := "") -> void:
	PMChrome.draw_table_panel(self, panel)
	# coloured header bar
	var hb := Rect2(panel.position.x + 2, panel.position.y + 2, panel.size.x - 4, 18)
	PMChrome.bevel(self, hb, hdr, hdr.lightened(0.25), hdr.darkened(0.4))
	_centre(_f12, hb, title, Color(0.98, 1.0, 0.96), 13)
	# rows: original FLECHAGREEN ▲ / FLECHARED ▼ marker, then label, then right £amount.
	var y := int(panel.position.y) + 24
	var rh := 22
	for i in lines.size():
		var line: Array = lines[i]
		var rr := Rect2(panel.position.x + 4, y, panel.size.x - 8, rh - 2)
		draw_rect(rr, row_col if i % 2 == 0 else row_col.darkened(0.06), true)
		_draw_marker(marker, Rect2(panel.position.x + 8, y + 3, 12, 12), title == "INCOME")
		_txt(_f10, int(panel.position.x) + 26, y + 5, str(line[0]).substr(0, 21), C_ROW_TXT, 11)
		_txt(_f10, int(panel.end.x) - 12, y + 5, fmt_money(int(line[1])), C_ROW_TXT, 11, true)
		y += rh
	# total bar at the panel foot
	var tb := Rect2(panel.position.x + 2, panel.end.y - 24, panel.size.x - 4, 20)
	PMChrome.bevel(self, tb, total_col, total_col.lightened(0.3), total_col.darkened(0.4))
	var tcol: Color = Color(0.06, 0.10, 0.20) if total_col == C_TOTAL_EXP else Color.WHITE
	_txt(_f10, int(tb.position.x) + 8, int(tb.position.y) + 4, total_label, tcol, 11)
	_txt(_f14, int(tb.end.x) - 10, int(tb.position.y) + 3, fmt_money(total), tcol, 14, true)


## The income/expense row marker: the original FLECHAGREEN/FLECHARED sprite when baked,
## else a drawn triangle (green ▲ up for income, red ▼ down for expense) so the row still
## reads correctly in CI before the art is present.
func _draw_marker(name: String, r: Rect2, up: bool) -> void:
	if name == "" or PMChrome.draw_icon(self, name, r):
		return
	var col := C_INCOME_HDR.lightened(0.15) if up else Color(0.78, 0.16, 0.14)
	var cx := r.position.x + r.size.x * 0.5
	if up:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, r.position.y),
			Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)]), col)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.position.y),
			Vector2(r.end.x, r.position.y), Vector2(cx, r.end.y)]), col)


func _draw_chart() -> void:
	PMChrome.bevel(self, CHART, C_CHART_BG, Color(0.2, 0.3, 0.5), Color(0.02, 0.03, 0.08))
	_txt(_f10, int(CHART.position.x) + 8, int(CHART.position.y) + 4, "BALANCE", C_PANEL_TXT, 11)
	_txt(_f10, int(CHART.position.x) + 200, int(CHART.position.y) + 4, "WEEKLY BALANCE TABLE",
		C_PANEL_TXT, 11)
	var plot := Rect2(CHART.position.x + 56, CHART.position.y + 20, CHART.size.x - 70, CHART.size.y - 30)
	var zero_y := plot.position.y + plot.size.y * 0.5
	# axis
	draw_rect(Rect2(plot.position.x, zero_y, plot.size.x, 1), Color(0.5, 0.6, 0.8, 0.8), true)
	var wk: int = int(_sum.get("weekly_balance", 0))
	var scale := maxi(2_500_000, absi(wk) * 2)
	_txt(_f8, int(plot.position.x) - 52, int(plot.position.y) - 2, "+%dK" % int(scale / 1000), C_BAR_POS, 9)
	_txt(_f8, int(plot.position.x) - 52, int(zero_y) + 4, "-%dK" % int(scale / 1000), C_BAR_NEG, 9)
	# bars: the model's constant weekly balance across the elapsed weeks
	var weeks := clampi(_week if _week > 0 else SEASON_WEEKS, 1, SEASON_WEEKS)
	var bw := plot.size.x / float(SEASON_WEEKS)
	var hh := (plot.size.y * 0.5) * clampf(float(wk) / float(scale), -1.0, 1.0)
	for i in weeks:
		var bx := plot.position.x + i * bw
		if hh >= 0:
			draw_rect(Rect2(bx, zero_y - hh, bw - 1, hh), C_BAR_POS, true)
		else:
			draw_rect(Rect2(bx, zero_y, bw - 1, -hh), C_BAR_NEG, true)
	# week ticks
	for t in [1, 10, 20, 30, 40, 50]:
		if t <= SEASON_WEEKS:
			_txt(_f8, int(plot.position.x + t * bw), int(plot.end.y) + 1, str(t), Color(0.6, 0.7, 0.9), 9)


func _draw_week_boxes() -> void:
	var inc := int(_sum.get("total_income", 0))
	var exp := int(_sum.get("total_expense", 0))
	var w_inc := inc / SEASON_WEEKS
	var w_exp := exp / SEASON_WEEKS
	_week_box(BOX_LAST, "LAST WEEK", w_inc, w_exp, _cash - (w_inc - w_exp))
	_week_box(BOX_CUR, "CURRENT WEEK", w_inc, w_exp, _cash)

	PMChrome.bevel(self, BTN_PRICES, C_TAB_HI if _press == "prices" else C_TAB, C_TAB_HI, C_TAB_LO)
	_centre(_f10, BTN_PRICES, "SET PRICES", C_GOLD, 10)
	PMChrome.bevel(self, BTN_RETURN, C_TAB, C_TAB_HI, C_TAB_LO)
	_centre(_f12, BTN_RETURN, "RETURN", C_GOLD, 13)


func _week_box(box: Rect2, title: String, inc: int, exp: int, cash: int) -> void:
	PMChrome.bevel(self, box, Color(0.10, 0.16, 0.34), C_TAB_HI, C_TAB_LO)
	_txt(_f10, int(box.position.x) + 8, int(box.position.y) + 3, title, C_GOLD, 11)
	_txt(_f10, int(box.position.x) + 8, int(box.position.y) + 18, "INCOME", C_PANEL_TXT, 10)
	_txt(_f10, int(box.end.x) - 8, int(box.position.y) + 18, fmt_money(inc), C_PANEL_TXT, 10, true)
	_txt(_f10, int(box.position.x) + 8, int(box.position.y) + 30, "EXPENSES", C_PANEL_TXT, 10)
	_txt(_f10, int(box.end.x) - 8, int(box.position.y) + 30, fmt_money(exp), C_PANEL_TXT, 10, true)
	_txt(_f10, int(box.position.x) + 8, int(box.position.y) + 43, "CASH", C_PANEL_TXT, 10)
	_txt(_f12, int(box.end.x) - 8, int(box.position.y) + 42, fmt_money(cash),
		C_GOLD if cash >= 0 else C_BAR_NEG, 12, true)


func _centre(f: Font, r: Rect2, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)),
		s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
