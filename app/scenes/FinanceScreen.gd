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
##
## THIRD + FOURTH VIEWS — the INCOME and EXPENSES detail tabs (added 2026-07-27).
## Both ARE captured — walkthrough frames 006 (INCOME / PER WEEK, the named
## `SALE Jordi Cruyff  £9,120,000` row), 008 (EXPENSES / PER WEEK, all £0) and
## 011==012 (EXPENSES / PER SEASON, wages/bonus/staff populated). Their chromes are
## baked from those frames by tools/re/build_finance_chrome_from_frames.py, and the
## other period of each is composited from the summary bakes over two rects proven
## 0 px across careers AND across views (P1 strip / P2 header — see the baker).
## Frames 010 vs 011 prove the detail BODY is pixel-identical across periods; the
## only un-witnessed combination (INCOME / PER SEASON) therefore invents nothing.
## Every font/pen below was solved the established way: rendered from the game's own
## BMFont atlases against the frames at ZERO differing pixels.

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

# ---- view + period axes ---------------------------------------------------
# Tab strip and stepper rects, read off the frames' own black button borders. The three
# VIEW tabs were measured off frame 013 by the same method that produced (and re-derives
# exactly) the two period-tab rects.
const VIEW_SUMMARY := 0
const VIEW_INCOME := 1
const VIEW_EXPENSES := 2
const PERIOD_WEEK := 0
const PERIOD_SEASON := 1
# legacy aliases (show_week / older tests): the summary view's two periods
const VIEW_SEASON := 0
const VIEW_WEEK := 1
const TAB_SUMMARY := Rect2(8, 7, 100, 25)
const TAB_INCOME := Rect2(116, 7, 100, 25)
const TAB_EXPENSES := Rect2(224, 7, 100, 25)
const TAB_PER_WEEK := Rect2(365, 7, 125, 25)
const TAB_PER_SEASON := Rect2(499, 7, 125, 25)

# ---- DETAIL view geometry (solved on frames 006 / 011 / 012) ---------------
# Values: euro8, right-aligned, pen END 299 (left column) / 596 (right), pen top =
# value-plate top + 1. The single TOTAL bar: proman10, pen END 605, pen top 381.
# Dynamic labels: euro8, pen x 43 (left label plates) / 340 (right), witnessed inks.
const DET_VAL_L_END := 299
const DET_VAL_R_END := 596
const DET_TOT_END := 605
const DET_TOT_TOP := 381
const DET_LBL_L_X := 43
const DET_LBL_R_X := 340
const DET_SALE_X := 341        # the green `SALE <name>` label's own pen
const DET_NP_X := 339          # `Not played`, on the white ground under the header
const C_GROSS := Color8(80, 110, 5)      # green sub-row ink (wage / hospital gross)
const C_SALE := Color8(60, 90, 0)        # the `SALE <name>` label's own darker green
const C_SUBBLUE := Color8(42, 95, 170)   # blue insurance sub-row ink
const C_NOTPLAYED := Color8(128, 128, 128)

# INCOME view rows: [plate top, "L"/"R", comp bucket, field]. The four left sections
# (LEAGUE + PRESEASON / F.A. CUP + COCA COLA CUP / EUROPEAN CUP / CHARITY SHIELD) and
# the right column's EUROPEAN SUPERCUP + INTERCONTINENTAL CUP, exactly frame 006's grid.
const INC_COMP_ROWS: Array = [
	[108, "L", "league", "TICKETS"], [124, "L", "league", "SPONSORS"],
	[140, "L", "league", "TELEVISION"],
	[186, "L", "domestic", "TICKETS"], [202, "L", "domestic", "SPONSORS"],
	[218, "L", "domestic", "TELEVISION"],
	[264, "L", "euro", "TICKETS"], [280, "L", "euro", "SPONSORS"],
	[296, "L", "euro", "POINTS"],
	[341, "L", "charity", "TICKETS"], [357, "L", "charity", "SPONSORS"],
	[373, "L", "charity", "TELEVISION"],
	[108, "R", "supercup", "TICKETS"], [124, "R", "supercup", "SPONSORS"],
	[140, "R", "supercup", "TELEVISION"],
	[186, "R", "intercontinental", "TICKETS"], [202, "R", "intercontinental", "TELEVISION"],
]
const INC_ROW_SALE := 237      # TRANSFERS row = the SALE + LOAN PLAY. line
const INC_ROW_INSGRP := 273    # INSURANCE COMPENSATION GROUP = the INSURANCE GROUP 3 line
const INC_ROWS_LOANS: Array = [309, 325, 341, 357]
const INC_NP_TOPS: Array = [96, 174]    # the two `Not played` pen tops (frame 006)

# EXPENSES view rows (frames 008 / 011 / 012).
const EXP_ROW_SIGN := 96       # TRANSFERS = SIGN PLAYER line
const EXP_ROW_CANCEL := 129    # COMPENSATIONS OF CONTRACT = CANCELLATION line
const EXP_ROW_WAGE_GROSS := 162
const EXP_ROW_WAGE_INS := 178
const EXP_ROW_WAGE_TOTAL := 194
const EXP_ROW_BONUS := 226
const EXP_ROW_INCENT := 258
const EXP_ROW_PLINS := 292
const EXP_ROW_HOSP: Array = [325, 341, 357, 373]   # gross / group2 / group3 / total
const EXP_ROW_STAFF := 96
const EXP_ROWS_GROUND: Array = [136, 152, 168, 184]  # SEATS / CAR PARK / FACILITIES / EXTRAS
const EXP_GROUND_CATS: Array = ["seats", "carpark", "facility", "service"]
const EXP_ROW_FINES := 224
const EXP_ROWS_LOANS: Array = [260, 276, 292, 308]   # LOANS AND INTEREST + three £0 slots
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
var _chrome_income: Texture2D          # INCOME / PER WEEK (frame 006)
var _chrome_income_season: Texture2D   # INCOME / PER SEASON (P1/P2 composite)
var _chrome_expenses: Texture2D        # EXPENSES / PER SEASON (frame 011)
var _chrome_expenses_week: Texture2D   # EXPENSES / PER WEEK (P1/P2 composite)
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
var _view: int = VIEW_SUMMARY
var _period: int = PERIOD_SEASON
var _sel_week: int = 0        # finance week the PER WEEK stepper is parked on
# The RUNNING week's record (Career.live_week_book): the CURRENT WEEK tile and the
# stepper's live week read it — witnessed on 004/006, where the Cruyff sale shows
# under CURRENT WEEK before the week has closed.
var _live: Dictionary = {}
# Cash at the close of the last completed week (the LAST WEEK / CASH tile) — a stored
# figure in the original (its £1 disagreement with the live cash on frame 006 proves
# it is not derived). NO_CASH_CLOSE -> derive from the live record.
const NO_CASH_CLOSE := -(1 << 62)
var _cash_close: int = NO_CASH_CLOSE
# {"supercup": bool, "intercontinental": bool} — drives the two `Not played` lines.
var _oneoff: Dictionary = {}


func _ready() -> void:
	_chrome = load("res://art/screens/finance/chrome.png")
	_chrome_week = load("res://art/screens/finance/chrome_perweek.png")
	_chrome_income = load("res://art/screens/finance/chrome_income.png")
	_chrome_income_season = load("res://art/screens/finance/chrome_income_perseason.png")
	_chrome_expenses = load("res://art/screens/finance/chrome_expenses.png")
	_chrome_expenses_week = load("res://art/screens/finance/chrome_expenses_perweek.png")
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
		cash: int = 0, week: int = 0, ledger: Dictionary = {}, books: Array = [],
		live_book: Dictionary = {}, cash_close: int = NO_CASH_CLOSE,
		oneoff: Dictionary = {}) -> void:
	_sum = summary
	_ledger = ledger
	_books = books
	_live = live_book
	_cash_close = cash_close
	_oneoff = oneoff
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


## Show the summary PER WEEK view parked on `fin_week` (render-diff harness / a test).
func show_week(fin_week: int) -> void:
	_view = VIEW_SUMMARY
	_period = PERIOD_WEEK
	_sel_week = clampi(fin_week, 1, current_finance_week())
	queue_redraw()


## Show any view/period combination (render-diff harness / a test).
func show_view(view: int, period: int, fin_week: int = -1) -> void:
	_view = clampi(view, VIEW_SUMMARY, VIEW_EXPENSES)
	_period = clampi(period, PERIOD_WEEK, PERIOD_SEASON)
	if fin_week > 0:
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
	# The five tabs of the original's own strip: three views x two periods, every one
	# of them baked off a captured frame (006 / 008 / 011 / 012 / 013 / p0495).
	if TAB_SUMMARY.has_point(d):
		_view = VIEW_SUMMARY
		queue_redraw()
		return
	if TAB_INCOME.has_point(d):
		_view = VIEW_INCOME
		queue_redraw()
		return
	if TAB_EXPENSES.has_point(d):
		_view = VIEW_EXPENSES
		queue_redraw()
		return
	if TAB_PER_SEASON.has_point(d):
		_period = PERIOD_SEASON
		queue_redraw()
		return
	if TAB_PER_WEEK.has_point(d):
		_period = PERIOD_WEEK
		queue_redraw()
		return
	if _period == PERIOD_WEEK and (BTN_WEEK_PREV.has_point(d) or BTN_WEEK_NEXT.has_point(d)):
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

	var chrome := _pick_chrome()
	if chrome != null:
		draw_texture(chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	if _period == PERIOD_WEEK:
		_draw_week_header()
	else:
		_draw_season()
	match _view:
		VIEW_INCOME:
			_draw_income_detail()
		VIEW_EXPENSES:
			_draw_expense_detail()
		_:
			_draw_ledger()
			_draw_chart()
	_draw_bottom_boxes()


func _pick_chrome() -> Texture2D:
	match _view:
		VIEW_INCOME:
			return _chrome_income if _period == PERIOD_WEEK else _chrome_income_season
		VIEW_EXPENSES:
			return _chrome_expenses_week if _period == PERIOD_WEEK else _chrome_expenses
		_:
			return _chrome_week if _period == PERIOD_WEEK else _chrome


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


## Every record in season scope: the banked books PLUS the running week's record.
## WITNESSED: frame 013's season totals include the Cruyff sale posted that same,
## still-open week, so the season aggregates must see the live record too.
func _season_recs() -> Array:
	var recs := _books.duplicate()
	if not _live.is_empty():
		recs.append(_live)
	return recs


## Season-to-date total of one ledger line across the banked books + the live record.
func _book_total(side: String, line: String) -> int:
	var t := 0
	for rec in _season_recs():
		t += int(((rec as Dictionary).get(side, {}) as Dictionary).get(line, 0))
	return t


## The book for the week the PER WEEK stepper is on, or {} when nothing has been posted
## to it. The LIVE week reads the running record (frames 004/006: the sale shows on the
## CURRENT week before it closes); a week with no record reads £0 on every line — which
## is exactly what the original shows for an un-posted live week (binding frame p0495).
func _selected_book() -> Dictionary:
	for rec in _books:
		if int((rec as Dictionary).get("week", 0)) == _sel_week:
			return rec
	if _sel_week >= current_finance_week():
		return _live
	return {}


## One side's values in the frame's own row order, for whichever period is up.
func _line_vals(side: String, lines: Array) -> Array:
	var out: Array = []
	if _period == PERIOD_WEEK:
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
	if _period == PERIOD_WEEK or not _season_recs().is_empty():
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
	if _period == PERIOD_WEEK or not _season_recs().is_empty():
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


# ---- the DETAIL views (frames 006 / 008 / 011 / 012) ----------------------

## Records in the selected period's scope: the stepper's week, or the whole season
## (banked books + the running record — frame 013's totals include the open week).
func _scope_recs() -> Array:
	if _period == PERIOD_WEEK:
		var rec := _selected_book()
		return [] if rec.is_empty() else [rec]
	return _season_recs()


## One canonical ledger line in the period scope.
func _line_in_scope(side: String, line: String) -> int:
	var t := 0
	for rec in _scope_recs():
		t += int(((rec as Dictionary).get(side, {}) as Dictionary).get(line, 0))
	return t


## One scalar detail field (wage_gross, hosp_pay2, bonus_n, ...) in scope.
func _det_sum(field: String) -> int:
	var t := 0
	for rec in _scope_recs():
		t += int(FinanceModel.ledger_detail(rec).get(field, 0))
	return t


## One competition-section cell (frame 006's own sections) in scope.
func _det_comp(bucket: String, field: String) -> int:
	var t := 0
	for rec in _scope_recs():
		var comp: Dictionary = FinanceModel.ledger_detail(rec).get("comp", {})
		t += int((comp.get(bucket, {}) as Dictionary).get(field, 0))
	return t


## Every named sale in scope, [[player name, fee], ...].
func _det_sales() -> Array:
	var out: Array = []
	for rec in _scope_recs():
		out.append_array(FinanceModel.ledger_detail(rec).get("sales", []))
	return out


## One GROUND IMPROVEMENTS category (begin_work's cat key) in scope.
func _det_ground(cat: String) -> int:
	var t := 0
	for rec in _scope_recs():
		t += int((FinanceModel.ledger_detail(rec).get("ground", {}) as Dictionary).get(cat, 0))
	return t


## One right-aligned detail value cell. `y0` is the value plate's top row; the ink pen
## sits one row inside it (solved at 0 px on every measured cell).
func _det_val(right_col: bool, y0: int, v: int, col: Color = C_BLACK) -> void:
	_txt_right(_pageV, _gV, DET_VAL_R_END if right_col else DET_VAL_L_END,
		y0 + 1, fmt_money(v), col)


## The INCOME detail view (frame 006). Un-posted cells read £0 exactly as the frame's
## fresh sections do; the two one-off European sections carry the witnessed grey
## `Not played` line until their tie has actually been played.
func _draw_income_detail() -> void:
	for row in INC_COMP_ROWS:
		_det_val(str(row[1]) == "R", int(row[0]), _det_comp(str(row[2]), str(row[3])))
	if not bool(_oneoff.get("supercup", false)):
		_blit(_pageV, _gV, DET_NP_X, INC_NP_TOPS[0], "Not played", C_NOTPLAYED)
	if not bool(_oneoff.get("intercontinental", false)):
		_blit(_pageV, _gV, DET_NP_X, INC_NP_TOPS[1], "Not played", C_NOTPLAYED)
	# TRANSFERS: the SALE + LOAN PLAY. line, with the witnessed green `SALE <name>`
	# label when exactly one sale is in scope (the only captured grammar; several
	# sales in one scope have no witnessed label form, so the cell stays bare).
	_det_val(true, INC_ROW_SALE, _line_in_scope("income", "SALE + LOAN PLAY."))
	var sales := _det_sales()
	if sales.size() == 1:
		_blit(_pageV, _gV, DET_SALE_X, INC_ROW_SALE + 1,
			"SALE %s" % str((sales[0] as Array)[0]), C_SALE)
	_det_val(true, INC_ROW_INSGRP, _line_in_scope("income", "INSURANCE GROUP 3"))
	# The four LOANS slots: no loan mechanic exists, so slot 1 carries the (always £0)
	# LOANS line and the rest read £0 — precisely the frame's own fresh-save state.
	_det_val(true, INC_ROWS_LOANS[0], _line_in_scope("income", "LOANS"))
	for i in range(1, INC_ROWS_LOANS.size()):
		_det_val(true, int(INC_ROWS_LOANS[i]), 0)
	var total := 0
	for line in FinanceModel.INCOME_LINES:
		total += _line_in_scope("income", line)
	_txt_right(_page10, _g10, DET_TOT_END, DET_TOT_TOP, fmt_money(total), C_TOTAL_INC)


## The EXPENSES detail view (frames 008 / 011 / 012). The three data-driven labels
## (Players´ Wage / N bonuses / Staff Wages) appear only beside a posted figure —
## witnessed: empty label cells in 008's £0 week, filled in 012's season.
func _draw_expense_detail() -> void:
	_det_val(false, EXP_ROW_SIGN, _line_in_scope("expense", "SIGN PLAYER"))
	_det_val(false, EXP_ROW_CANCEL, _line_in_scope("expense", "CANCELLATION"))
	var gross := _det_sum("wage_gross")
	_det_val(false, EXP_ROW_WAGE_GROSS, gross, C_GROSS)
	if gross != 0:
		_blit(_pageV, _gV, DET_LBL_L_X, EXP_ROW_WAGE_GROSS + 1, "Players´ Wage", C_BLACK)
	_det_val(false, EXP_ROW_WAGE_INS, _det_sum("wage_refund"), C_SUBBLUE)
	_det_val(false, EXP_ROW_WAGE_TOTAL, _line_in_scope("expense", "PLAYERS' WAGE"))
	_det_val(false, EXP_ROW_BONUS, _line_in_scope("expense", "PLAYERS' BONUS"))
	var bonus_n := _det_sum("bonus_n")
	if bonus_n > 0:
		_blit(_pageV, _gV, DET_LBL_L_X, EXP_ROW_BONUS + 1, "%d bonuses" % bonus_n, C_BLACK)
	_det_val(false, EXP_ROW_INCENT, _line_in_scope("expense", "PLAYERS' INCENTIVE"))
	_det_val(false, EXP_ROW_PLINS, _line_in_scope("expense", "PLAYERS' INSURANCE"))
	_det_val(false, EXP_ROW_HOSP[0], _det_sum("hosp_gross"), C_GROSS)
	_det_val(false, EXP_ROW_HOSP[1], _det_sum("hosp_pay2"), C_SUBBLUE)
	_det_val(false, EXP_ROW_HOSP[2], _det_sum("hosp_pay3"), C_SUBBLUE)
	_det_val(false, EXP_ROW_HOSP[3], _line_in_scope("expense", "HOSPITALS"))
	var staff := _line_in_scope("expense", "STAFF WAGES")
	_det_val(true, EXP_ROW_STAFF, staff)
	if staff != 0:
		_blit(_pageV, _gV, DET_LBL_R_X, EXP_ROW_STAFF + 1, "Staff Wages", C_BLACK)
	for i in EXP_ROWS_GROUND.size():
		_det_val(true, int(EXP_ROWS_GROUND[i]), _det_ground(str(EXP_GROUND_CATS[i])))
	_det_val(true, EXP_ROW_FINES, _line_in_scope("expense", "FINES"))
	_det_val(true, EXP_ROWS_LOANS[0], _line_in_scope("expense", "LOANS AND INTEREST"))
	for i in range(1, EXP_ROWS_LOANS.size()):
		_det_val(true, int(EXP_ROWS_LOANS[i]), 0)
	var total := 0
	for line in FinanceModel.EXPENSE_LINES:
		total += _line_in_scope("expense", line)
	_txt_right(_page10, _g10, DET_TOT_END, DET_TOT_TOP, fmt_money(total), C_TOTAL_EXP)


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
	# CURRENT WEEK = the RUNNING record (frames 004/006: the sale is on the tile before
	# the week closes; p0495: an un-posted live week reads £0 / £0).
	var cur_inc := FinanceModel.ledger_total(_live, "income") if not _live.is_empty() else 0
	var cur_exp := FinanceModel.ledger_total(_live, "expense") if not _live.is_empty() else 0
	if _books.is_empty() and _live.is_empty():
		# Legacy save with no per-week history: the season figures spread evenly, flagged.
		last_inc = int(round(_sum_of(_income_vals()) / float(SEASON_WEEKS)))
		last_exp = int(round(_sum_of(_expense_vals()) / float(SEASON_WEEKS)))
		cur_inc = last_inc
		cur_exp = last_exp
	elif not _books.is_empty():
		var last: Dictionary = _books[-1]
		last_inc = FinanceModel.ledger_total(last, "income")
		last_exp = FinanceModel.ledger_total(last, "expense")
	# LAST WEEK / CASH is the original's own STORED close-of-week figure (frame 006's £1
	# disagreement with the live cash proves it is not derived); derive only without one.
	var close := _cash_close if _cash_close != NO_CASH_CLOSE else _cash - (cur_inc - cur_exp)
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[0], fmt_money(last_inc), C_BLACK)
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[1], fmt_money(last_exp), C_BLACK)
	_txt_right(_page8, _g8, LW_PEN_END, BOT_PEN_TOP[2], fmt_money(close), C_GOLD)
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
