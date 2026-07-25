extends Control
class_name FinanceScreen
## PM98 FINANCES ("INCOME + EXPENSES") screen, rebuilt FRAME-TRUE from the real
## walkthrough (screenshots/original-walkthrough-2026-07-02/013_164406.png ==
## 014_164407.png), following the PreseasonScreen frame-bake precedent.
##
## The static chrome is the ORIGINAL frame's pixels, cut 1:1 by
## tools/re/build_finance_chrome_from_frames.py into art/screens/finance/chrome.png
## with ONLY the dynamic value cells blanked. This scene draws that chrome at
## 640x480 and redraws real numbers on top — nothing about the layout, labels,
## colours, tabs, sections or chart is hand-invented.
##
## Binding view = INC. + EXP. / PER SEASON summary (header "SEASON YYYY . YY"),
## chosen because FinanceModel.summary produces SEASON figures, so the model's
## numbers land on the frame whose semantics match. The frame's own totals verify
## the value mapping exactly (TICKETS 541,500 + PUBLICITY 9,750 + TELEVISION
## 187,500 + SALE 9,120,000 = 9,858,750; PLAYERS' WAGE 676,442 + BONUS 5,000 +
## STAFF WAGES 1,211 = 682,653).
##
## Model -> frame line mapping (docs/re/finance_screen_re.md):
##   INCOME:  TICKETS<-gate, PUBLICITY<-boards+sponsor, TELEVISION<-tv,
##            INSURANCE GROUP 3<-the season's group-3 policy income;
##            EUROPEAN CUP INCOME / SALE+LOAN PLAY. / LOANS = 0 (gap)
##   EXPENSES: PLAYERS' WAGE<-wages less the insured-injured refund,
##            PLAYERS' BONUS<-bonus, PLAYERS' INSURANCE<-premiums,
##            HOSPITALS<-injury bills net of the policy payouts; SIGN PLAYER /
##            CANCELLATION / PLAYERS' INCENTIVE / STAFF WAGES / REFORM GROUND /
##            FINES / LOANS AND INTEREST = 0 (gap)
## The three insurance lines and the PLAYERS' WAGE netting are the binary's own
## ledger slots (docs/re/insurance_economy_re.md: week record +0x60 / +0x64-0x68-0x6c
## / +0x70, and PLAYERS' WAGE = +0x50 - +0x54), fed by Career's season-to-date
## accumulator. The remaining gap lines show £0 (exactly as the frame shows them
## for a fresh save) — those per-line figures are a runtime float ledger the app
## has no save-game for (docs/re/finance_constants.md), never fabricated here.
##
## SECOND VIEW — INC. + EXP. / PER WEEK (REFRUN R5, added 2026-07-25). The original's
## own second tab: the SAME body, one WEEK's books instead of the season's, and a
## header that swaps the SEASON stamp for a `< CURRENT n >` stepper and the week's date
## span. Its chrome is a second bake (`chrome_perweek.png`) off the reference run's own
## frame, and the two header texts were pinned by rendering every shipped BMFont atlas
## against the frame at ZERO differing pixels: the week label is proman10 in (255,223,0)
## centred on field-sum 693, the date is proman8 in (128,128,128) with its pen at x=416,
## both with their pen top at y=62. Binding frames, all three reproduced verbatim:
##   p0495 week "CURRENT 31"  From 15-2-1998 to 21-2-1998
##   p0509 week "29"          From 1-2-1998 to 7-2-1998    (stepped back — no "CURRENT")
##   p0045 week "CURRENT 4"   From 10-8-1997 to 16-8-1997
## WITNESSED and therefore copied: the LAST WEEK / CURRENT WEEK tiles and the BALANCE
## chart do NOT follow the stepper — p0495 and p0509 are two different selected weeks
## with byte-identical tiles and chart.
## NOT witnessed and therefore NOT built: the INCOME and EXPENSES detail tabs have no
## captured frame, so tapping them does nothing (docs/re/finance_screen_re.md).

signal back_pressed      # RETURN button -> Main dismisses the screen
signal prices_pressed    # RETAINED for Main compatibility; NOT emitted (see WIRING note)
signal cheat_cash        # HIDDEN gesture: 5 taps on the CURRENT WEEK / CASH cell (user-requested cheat)

const W := 640
const H := 480
const SEASON_WEEKS := 52   # PM98 finance loops 0x34 = 52 weeks (finance_constants.md)

# ---- overlay anchors (design 640x480) ------------------------------------
#
# EVERY anchor and font below was SOLVED against the original's own frames, not chosen:
# each string was rendered from every BMFont atlas the game ships and compared to the
# frame's pixels, and only the entries that came out at ZERO differing pixels are kept.
# Two frames of the same screen agree (013 = PER SEASON, p0509 = PER WEEK), so the fonts
# are the screen's, not one view's.
#
#   ledger values          euro8     right-aligned, pen END 306 / 602, pen top 99 + 16i
#   TOTAL INCOME/EXPENSES  proman10  right-aligned, pen END 307 / 605, pen top 284
#   SEASON header          proman10  right-aligned, pen END 601, pen top 60
#   LAST/CURRENT WEEK      proman8   right-aligned, pen END 226 / 459, tops 429/441/453
#
# This REPLACES the earlier calend8 / calend12 / proman8 guesses: those were never
# render-diffed, and all three are wrong against the frames.
const ROW_STEP := 16
const ROW_PEN_TOP := 99    # pen top of ledger row 0 (cell top 98 + the cell's 1px inset)
const INC_PEN_END := 306   # income value cells: the pen ENDS here
const EXP_PEN_END := 602   # expense value cells
const TOT_PEN_TOP := 284
const TOT_INC_PEN_END := 307
const TOT_EXP_PEN_END := 605
const SEASON_PEN_END := 601
const SEASON_PEN_TOP := 60
const LW_PEN_END := 226    # LAST WEEK values
const CW_PEN_END := 459    # CURRENT WEEK values
const CASH_BOX := Rect2(398, 452, 98, 18)  # CURRENT WEEK / CASH cell (frame 013) -- hidden cheat gesture
const BOT_PEN_TOP := [429, 441, 453]   # INCOME / EXPENSES / CASH pen tops
const BTN_RETURN := Rect2(515, 439, 118, 24)

# ---- PER WEEK view (REFRUN R5) -------------------------------------------
# Tab strip and stepper rects, read off the frames' own black button borders.
const VIEW_SEASON := 0
const VIEW_WEEK := 1
const TAB_PER_WEEK := Rect2(365, 7, 125, 25)
const TAB_PER_SEASON := Rect2(499, 7, 125, 25)
const BTN_WEEK_PREV := Rect2(278, 57, 22, 21)
const BTN_WEEK_NEXT := Rect2(392, 57, 22, 21)
# The week label centres on field-sum 693 (solves all three witnessed labels exactly)
# and the date's pen sits at x=416; both ink at pen top 62.
const WEEK_FIELD_SUM := 693
const WEEK_PEN_TOP := 60
const DATE_PEN_X := 416
const C_WEEK_LABEL := Color8(255, 223, 0)
const C_DATE := Color8(128, 128, 128)

# chart plot (the baked blue/yellow field): +2,500K at the top of blue, 0 at the
# axis, -2,500K at the bottom of yellow (the fixed axis the game bakes).
const CHART_L := 64
const CHART_R := 633
const CHART_ZERO_Y := 353
const CHART_TOP_Y := 333       # == +CHART_SCALE
const CHART_BOT_Y := 377       # == -CHART_SCALE
const CHART_SCALE := 2_500_000

# frame-sampled inks
const C_BLACK := Color(0, 0, 0)
const C_TOTAL_INC := Color8(30, 52, 98)
const C_TOTAL_EXP := Color8(170, 0, 0)
const C_GOLD := Color8(255, 223, 0)
const C_BAR_POS := Color8(60, 90, 200)
const C_BAR_NEG := Color8(190, 60, 30)

var _chrome: Texture2D
var _chrome_week: Texture2D
# Every string on this screen is blitted straight off the game's own BMFont atlases (the
# way CupDrawScreen does) rather than through a Godot FontFile, because the pen origins
# were solved to the pixel against the frames and that is the path that reproduces them.
var _pageV: Texture2D      # euro8    — the ledger value cells
var _page8: Texture2D      # proman8  — LAST / CURRENT WEEK tiles + the PER WEEK date
var _page10: Texture2D     # proman10 — the two totals, the SEASON stamp, the week label
var _gV: Dictionary = {}
var _g8: Dictionary = {}
var _g10: Dictionary = {}

var _sum: Dictionary = {}
var _ledger: Dictionary = {}  # season-to-date insurance figures (Career.insurance_ledger)
# The REAL per-week books (Career.week_ledgers), oldest first. Each entry is
# {"week": finance week, "income": {line: £}, "expense": {line: £}} -- the original's own
# lines, accrued as the season is played (REFRUN R5/R9). Empty for a legacy save, in which
# case the LAST/CURRENT WEEK tiles and the BALANCE chart fall back to the season average.
var _books: Array = []
var _club: String = ""       # not shown on this screen (kept for Main's setup call)
var _manager: String = ""    # ditto
var _season: String = ""
var _cash: int = 0
var _cheat_taps: int = 0
var _week: int = 0
var _view: int = VIEW_SEASON
var _sel_week: int = 0        # finance week the PER WEEK stepper is parked on


func _ready() -> void:
	_chrome = load("res://art/screens/finance/chrome.png")
	_chrome_week = load("res://art/screens/finance/chrome_perweek.png")
	_pageV = PMFont.page_texture("euro8")
	_page8 = PMFont.page_texture("proman8")
	_page10 = PMFont.page_texture("proman10")
	_gV = PMFont.chars("euro8")
	_g8 = PMFont.chars("proman8")
	_g10 = PMFont.chars("proman10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(summary: Dictionary, club: String, manager: String = "", season: String = "",
		cash: int = 0, week: int = 0, ledger: Dictionary = {}, books: Array = []) -> void:
	_sum = summary
	_ledger = ledger
	_books = books
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_week = week
	_sel_week = current_finance_week()
	queue_redraw()


## The live finance week (the one the stepper opens on). The finance year runs
## Sunday..Saturday from 20 July 1997, two weeks ahead of the league calendar.
func current_finance_week() -> int:
	return FinanceModel.finance_week(maxi(_week, 1))


## Show the PER WEEK view parked on `fin_week` (render-diff harness / a test).
func show_week(fin_week: int) -> void:
	_view = VIEW_WEEK
	_sel_week = clampi(fin_week, 1, current_finance_week())
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if e.pressed:
		return
	var d := _to_design(e.position)
	# The RETURN control is the only dismiss affordance the frame shows.
	if BTN_RETURN.has_point(d):
		back_pressed.emit()
		return
	# The two view tabs whose chrome is baked off a real frame. INCOME and EXPENSES
	# have no captured frame, so their tabs are inert rather than invented.
	if TAB_PER_SEASON.has_point(d):
		_view = VIEW_SEASON
		queue_redraw()
		return
	if TAB_PER_WEEK.has_point(d):
		_view = VIEW_WEEK
		queue_redraw()
		return
	if _view == VIEW_WEEK and (BTN_WEEK_PREV.has_point(d) or BTN_WEEK_NEXT.has_point(d)):
		# The stepper walks the finance year and stops at the live week: the original
		# has no books past it, and week 1 is the floor.
		_sel_week = clampi(_sel_week + (-1 if BTN_WEEK_PREV.has_point(d) else 1),
			1, current_finance_week())
		queue_redraw()
		return
	# HIDDEN cheat (user-requested): 5 consecutive taps on the CURRENT WEEK / CASH cell.
	if CASH_BOX.has_point(d):
		_cheat_taps += 1
		if _cheat_taps >= 5:
			_cheat_taps = 0
			cheat_cash.emit()
	else:
		_cheat_taps = 0


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


## One right-aligned value: the original ends every value cell's PEN at a fixed x, so
## that is what this anchors on (not the ink, which varies with the last glyph).
func _txt_right(page: Texture2D, glyphs: Dictionary, pen_end: int, y_top: int, s: String,
		col: Color) -> void:
	_blit(page, glyphs, pen_end - _advance(glyphs, s), y_top, s, col)


static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((glyphs.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


## Blit one string off a PM98 BMFont atlas page. The pages are white masks, so the colour
## is a modulate; `x` is the PEN origin and `y_top` the pen's top row.
func _blit(page: Texture2D, glyphs: Dictionary, x: int, y_top: int, s: String,
		col: Color) -> void:
	if page == null:
		return
	var pen := x
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	var chrome: Texture2D = _chrome_week if _view == VIEW_WEEK else _chrome
	if chrome != null:
		draw_texture(chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	if _view == VIEW_WEEK:
		_draw_week_header()
	else:
		_draw_season()
	_draw_ledger()
	_draw_bottom_boxes()
	_draw_chart()


## The PER WEEK header: the stepper's own label and the week's date span. The original
## prefixes "CURRENT " only while the stepper is parked on the live week (witnessed on
## all three frames), and the date span is FinanceModel's, which reproduces every one of
## them verbatim.
func _draw_week_header() -> void:
	var live := current_finance_week()
	var label := ("CURRENT %d" % _sel_week) if _sel_week >= live else str(_sel_week)
	@warning_ignore("integer_division")
	var pen := (WEEK_FIELD_SUM - _advance(_g10, label)) / 2
	_blit(_page10, _g10, pen, WEEK_PEN_TOP, label, C_WEEK_LABEL)
	var start_year := 1997
	var parts := _season.split("-")
	if parts.size() == 2 and parts[0].is_valid_int():
		start_year = int(parts[0])
	_blit(_page8, _g8, DATE_PEN_X, WEEK_PEN_TOP,
		FinanceModel.finance_week_span(_sel_week, start_year), C_DATE)


## "1997-98" -> "SEASON 1997 - 98". The separator, the spacing and the font are the
## frame's own: proman10 rendering exactly this string reproduces frame 013's header at
## ZERO differing pixels, which retired the earlier proman8 "SEASON 1997 (middle dot) 98".
func _draw_season() -> void:
	var txt := "SEASON"
	var parts := _season.split("-")
	if parts.size() == 2:
		txt = "SEASON %s - %s" % [parts[0], parts[1]]
	elif _season != "":
		txt = "SEASON %s" % _season
	_txt_right(_page10, _g10, SEASON_PEN_END, SEASON_PEN_TOP, txt, C_BLACK)


## Season-to-date total of one ledger line across the banked books.
func _book_total(side: String, line: String) -> int:
	var t := 0
	for rec in _books:
		t += int(((rec as Dictionary).get(side, {}) as Dictionary).get(line, 0))
	return t


## The book for the week the PER WEEK stepper is on, or {} when nothing has been posted
## to it. A week with no record reads £0 on every line -- which is exactly what the
## original shows for the live, not-yet-posted week (binding frame p0495).
func _selected_book() -> Dictionary:
	for rec in _books:
		if int((rec as Dictionary).get("week", 0)) == _sel_week:
			return rec
	return {}


## One side's values in the frame's own row order, for whichever view is up.
func _line_vals(side: String, lines: Array) -> Array:
	var out: Array = []
	if _view == VIEW_WEEK:
		var rec := _selected_book()
		var col: Dictionary = rec.get(side, {}) if not rec.is_empty() else {}
		for line in lines:
			out.append(int(col.get(line, 0)))
		return out
	for line in lines:
		out.append(_book_total(side, line))
	return out


## The 7 INCOME rows, in frame order.
##
## With real books (Career.week_ledgers) these are the SEASON-TO-DATE accruals off the
## original's own lines -- which is precisely what the binding PER SEASON view shows.
## Without them (a legacy save) it falls back to the old FinanceModel projection, where
## INSURANCE GROUP 3 came from the insurance ledger and three lines stayed £0 gaps.
func _income_vals() -> Array:
	if _view == VIEW_WEEK or not _books.is_empty():
		return _line_vals("income", FinanceModel.INCOME_LINES)
	var inc: Array = _sum.get("income_lines", [])
	var tickets := int(inc[0][1]) if inc.size() > 0 else 0
	var publicity := (int(inc[1][1]) if inc.size() > 1 else 0) + (int(inc[2][1]) if inc.size() > 2 else 0)
	var television := int(inc[3][1]) if inc.size() > 3 else 0
	return [tickets, publicity, television, 0, 0, int(_ledger.get("group3_income", 0)), 0]


## The 11 EXPENSE rows, in frame order. Same rule as _income_vals: real accruals when the
## books exist, the projection (PLAYERS' WAGE net of the insured-injured refund the
## original subtracts at week-record +0x54, PLAYERS' BONUS, PLAYERS' INSURANCE, HOSPITALS)
## otherwise.
func _expense_vals() -> Array:
	if _view == VIEW_WEEK or not _books.is_empty():
		return _line_vals("expense", FinanceModel.EXPENSE_LINES)
	var exp: Array = _sum.get("expense_lines", [])
	var players_wage := (int(exp[0][1]) if exp.size() > 0 else 0) - int(_ledger.get("wage_refund", 0))
	var players_bonus := int(exp[1][1]) if exp.size() > 1 else 0
	return [0, 0, players_wage, players_bonus, 0,
		int(_ledger.get("premiums", 0)), int(_ledger.get("hospitals", 0)), 0, 0, 0, 0]


static func _sum_of(vals: Array) -> int:
	var t := 0
	for v in vals:
		t += int(v)
	return t


func _draw_ledger() -> void:
	var income_vals := _income_vals()
	for i in income_vals.size():
		_txt_right(_pageV, _gV, INC_PEN_END, ROW_PEN_TOP + i * ROW_STEP,
			fmt_money(int(income_vals[i])), C_BLACK)
	var expense_vals := _expense_vals()
	for i in expense_vals.size():
		_txt_right(_pageV, _gV, EXP_PEN_END, ROW_PEN_TOP + i * ROW_STEP,
			fmt_money(int(expense_vals[i])), C_BLACK)
	# totals = the summed columns (the frame's own arithmetic, verified on 013)
	_txt_right(_page10, _g10, TOT_INC_PEN_END, TOT_PEN_TOP,
		fmt_money(_sum_of(income_vals)), C_TOTAL_INC)
	_txt_right(_page10, _g10, TOT_EXP_PEN_END, TOT_PEN_TOP,
		fmt_money(_sum_of(expense_vals)), C_TOTAL_EXP)


## LAST WEEK / CURRENT WEEK, from the real books.
##
## WITNESSED (REFRUN R5/R9, the two PER WEEK frames): the CURRENT WEEK tile reads £0 /
## £0 while the week is still running and only the CASH figure is live, and the LAST WEEK
## tile carries the completed week's totals -- Man Utd's away week 30 shows income £0,
## expenses £233,942, cash £3,283,406, and the SAME cash appears in both tiles because
## nothing has been posted yet this week. That is exactly what this now draws.
func _draw_bottom_boxes() -> void:
	var last_inc := 0
	var last_exp := 0
	var cur_inc := 0
	var cur_exp := 0
	if _books.is_empty():
		# Legacy save with no per-week history: the season figures spread evenly, flagged.
		last_inc = int(round(_sum_of(_income_vals()) / float(SEASON_WEEKS)))
		last_exp = int(round(_sum_of(_expense_vals()) / float(SEASON_WEEKS)))
		cur_inc = last_inc
		cur_exp = last_exp
	else:
		var last: Dictionary = _books[-1]
		last_inc = FinanceModel.ledger_total(last, "income")
		last_exp = FinanceModel.ledger_total(last, "expense")
	# LAST WEEK -- cash as it stood at the close of that week is the live figure less
	# anything posted since, which for a settled hub view is nothing.
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[0], fmt_money(last_inc), C_BLACK)
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[1], fmt_money(last_exp), C_BLACK)
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[2],
		fmt_money(_cash - (cur_inc - cur_exp)), C_GOLD)
	# CURRENT WEEK
	_txt_right(_page8, _g8, CW_PEN_END, BOT_PEN_TOP[0], fmt_money(cur_inc), C_BLACK)
	_txt_right(_page8, _g8, CW_PEN_END, BOT_PEN_TOP[1], fmt_money(cur_exp), C_BLACK)
	_txt_right(_page8, _g8, CW_PEN_END, BOT_PEN_TOP[2], fmt_money(_cash), C_GOLD)


## The WEEKLY BALANCE chart -- now the REAL per-week books, one bar per banked week at
## its own finance-week slot on the frame's fixed +/-2,500K axis. This is what the
## original's chart is (REFRUN R9's frame: blue bars of differing heights above the axis,
## red bars below it, and weeks with no bar at all). It used to be a single constant
## drawn flat across the elapsed weeks, because there were no per-week books to plot.
func _draw_chart() -> void:
	var wpp := float(CHART_R - CHART_L) / float(SEASON_WEEKS)
	if _books.is_empty():
		# Legacy save: the one constant the projection yields, flat, as before.
		var wk := int(_sum.get("weekly_balance", 0))
		if wk == 0:
			return
		var weeks := clampi(_week if _week > 0 else 1, 1, SEASON_WEEKS)
		for i in weeks:
			_bar(CHART_L + i * wpp, wpp, wk)
		return
	for rec in _books:
		var slot := clampi(int((rec as Dictionary).get("week", 1)) - 1, 0, SEASON_WEEKS - 1)
		_bar(CHART_L + slot * wpp, wpp, FinanceModel.ledger_balance(rec))


## One balance bar: up from the axis in blue for a week in profit, down in red for a week
## in the red, clipped to the frame's baked +/-2,500K scale.
func _bar(bx: float, wpp: float, value: int) -> void:
	if value == 0:
		return
	var up: bool = value > 0
	var span: int = (CHART_ZERO_Y - CHART_TOP_Y) if up else (CHART_BOT_Y - CHART_ZERO_Y)
	var hh: float = clampf(absf(float(value)) / float(CHART_SCALE), 0.0, 1.0) * span
	if up:
		draw_rect(Rect2(bx, CHART_ZERO_Y - hh, maxf(1.0, wpp - 1.0), hh), C_BAR_POS, true)
	else:
		draw_rect(Rect2(bx, CHART_ZERO_Y + 1, maxf(1.0, wpp - 1.0), hh), C_BAR_NEG, true)
