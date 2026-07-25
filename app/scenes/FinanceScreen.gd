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

signal back_pressed      # RETURN button -> Main dismisses the screen
signal prices_pressed    # RETAINED for Main compatibility; NOT emitted (see WIRING note)
signal cheat_cash        # HIDDEN gesture: 5 taps on the CURRENT WEEK / CASH cell (user-requested cheat)

const W := 640
const H := 480
const SEASON_WEEKS := 52   # PM98 finance loops 0x34 = 52 weeks (finance_constants.md)

# ---- overlay anchors (design 640x480; measured off frame 013, and exactly the
# cells build_finance_chrome_from_frames.py blanked) -----------------------
const ROW_Y0 := 98
const ROW_STEP := 16
const VAL_DY := 0          # nudges the value text baseline inside its cell
const INC_RIGHT := 305     # income value right edge
const EXP_RIGHT := 601     # expense value right edge
const TOT_Y := 283
const TOT_INC_RIGHT := 305
const TOT_EXP_RIGHT := 601
const SEASON_RIGHT := 600
const SEASON_Y := 60
const LW_RIGHT := 245      # LAST WEEK value right edge
const CW_RIGHT := 495      # CURRENT WEEK value right edge
const CASH_BOX := Rect2(398, 452, 98, 18)  # CURRENT WEEK / CASH cell (frame 013) -- hidden cheat gesture
const BOT_ROW_Y := [428, 442, 454]   # INCOME / EXPENSES / CASH value tops
const BTN_RETURN := Rect2(515, 439, 118, 24)

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
# The real screen renders values in the narrow WINFONTS the game ships, NOT proman:
# ledger lines = Calend8 (5px digits), bottom boxes = Calend12 (7px), totals + the
# SEASON header = Proman8 (8px). Verified glyph-width against frame 013.
var _fval: Font        # Calend8  — income/expense ledger values
var _fbot: Font        # Calend12 — LAST/CURRENT WEEK values
var _ftot: Font        # Proman8  — the two totals + SEASON
const SZ_VAL := 15     # Calend8 native size
const SZ_BOT := 15     # Calend12 native size
const SZ_TOT := 11     # Proman8 native size

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


func _ready() -> void:
	_chrome = load("res://art/screens/finance/chrome.png")
	_fval = load("res://art/fonts/calend8.fnt")
	_fbot = load("res://art/fonts/calend12.fnt")
	_ftot = load("res://art/fonts/proman8.fnt")
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


func _txt(f: Font, x_right: int, y_top: int, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(x_right - w, y_top + f.get_ascent(sz)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	_draw_season()
	_draw_ledger()
	_draw_bottom_boxes()
	_draw_chart()


func _draw_season() -> void:
	# "1997-98" -> "SEASON 1997 · 98" (the frame's middle dot, U+00B7; the proman
	# font carries glyph 183, so this matches the baked header exactly).
	var txt := "SEASON"
	var parts := _season.split("-")
	if parts.size() == 2:
		txt = "SEASON %s · %s" % [parts[0], parts[1]]
	elif _season != "":
		txt = "SEASON %s" % _season
	_txt(_ftot, SEASON_RIGHT, SEASON_Y, txt, C_BLACK, SZ_TOT)


## Season-to-date total of one ledger line across the banked books.
func _book_total(side: String, line: String) -> int:
	var t := 0
	for rec in _books:
		t += int(((rec as Dictionary).get(side, {}) as Dictionary).get(line, 0))
	return t


## The 7 INCOME rows, in frame order.
##
## With real books (Career.week_ledgers) these are the SEASON-TO-DATE accruals off the
## original's own lines -- which is precisely what the binding PER SEASON view shows.
## Without them (a legacy save) it falls back to the old FinanceModel projection, where
## INSURANCE GROUP 3 came from the insurance ledger and three lines stayed £0 gaps.
func _income_vals() -> Array:
	if not _books.is_empty():
		var out: Array = []
		for line in FinanceModel.INCOME_LINES:
			out.append(_book_total("income", line))
		return out
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
	if not _books.is_empty():
		var out: Array = []
		for line in FinanceModel.EXPENSE_LINES:
			out.append(_book_total("expense", line))
		return out
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
		_txt(_fval, INC_RIGHT, ROW_Y0 + i * ROW_STEP + VAL_DY, fmt_money(int(income_vals[i])), C_BLACK, SZ_VAL)
	var expense_vals := _expense_vals()
	for i in expense_vals.size():
		_txt(_fval, EXP_RIGHT, ROW_Y0 + i * ROW_STEP + VAL_DY, fmt_money(int(expense_vals[i])), C_BLACK, SZ_VAL)
	# totals = the summed columns (the frame's own arithmetic, verified on 013)
	_txt(_ftot, TOT_INC_RIGHT, TOT_Y, fmt_money(_sum_of(income_vals)), C_TOTAL_INC, SZ_TOT)
	_txt(_ftot, TOT_EXP_RIGHT, TOT_Y, fmt_money(_sum_of(expense_vals)), C_TOTAL_EXP, SZ_TOT)


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
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[0], fmt_money(last_inc), C_BLACK, SZ_BOT)
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[1], fmt_money(last_exp), C_BLACK, SZ_BOT)
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[2], fmt_money(_cash - (cur_inc - cur_exp)), C_GOLD, SZ_BOT)
	# CURRENT WEEK
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[0], fmt_money(cur_inc), C_BLACK, SZ_BOT)
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[1], fmt_money(cur_exp), C_BLACK, SZ_BOT)
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[2], fmt_money(_cash), C_GOLD, SZ_BOT)


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
