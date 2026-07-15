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
##   INCOME:  TICKETS<-gate, PUBLICITY<-boards+sponsor, TELEVISION<-tv;
##            EUROPEAN CUP INCOME / SALE+LOAN PLAY. / INSURANCE GROUP 3 / LOANS = 0 (gap)
##   EXPENSES: PLAYERS' WAGE<-wages, PLAYERS' BONUS<-bonus; SIGN PLAYER /
##            CANCELLATION / PLAYERS' INCENTIVE / PLAYERS' INSURANCE / HOSPITALS /
##            STAFF WAGES / REFORM GROUND / FINES / LOANS AND INTEREST = 0 (gap)
## The gap lines show £0 (exactly as the frame shows them for a fresh save) — the
## real per-line figures are a runtime float ledger the app has no save-game for
## (docs/re/finance_constants.md), never fabricated here.

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


func _draw_ledger() -> void:
	var inc: Array = _sum.get("income_lines", [])
	var exp: Array = _sum.get("expense_lines", [])
	# INCOME column: TICKETS, PUBLICITY, TELEVISION, then 4 honest-gap zeros.
	var tickets := int(inc[0][1]) if inc.size() > 0 else 0
	var publicity := (int(inc[1][1]) if inc.size() > 1 else 0) + (int(inc[2][1]) if inc.size() > 2 else 0)
	var television := int(inc[3][1]) if inc.size() > 3 else 0
	var income_vals := [tickets, publicity, television, 0, 0, 0, 0]
	for i in income_vals.size():
		_txt(_fval, INC_RIGHT, ROW_Y0 + i * ROW_STEP + VAL_DY, fmt_money(int(income_vals[i])), C_BLACK, SZ_VAL)

	# EXPENSES column: PLAYERS' WAGE (row 2), PLAYERS' BONUS (row 3); rest gaps.
	var players_wage := int(exp[0][1]) if exp.size() > 0 else 0
	var players_bonus := int(exp[1][1]) if exp.size() > 1 else 0
	var expense_vals := [0, 0, players_wage, players_bonus, 0, 0, 0, 0, 0, 0, 0]
	for i in expense_vals.size():
		_txt(_fval, EXP_RIGHT, ROW_Y0 + i * ROW_STEP + VAL_DY, fmt_money(int(expense_vals[i])), C_BLACK, SZ_VAL)

	# totals (equal the summed columns; verified against the frame)
	_txt(_ftot, TOT_INC_RIGHT, TOT_Y, fmt_money(int(_sum.get("total_income", 0))), C_TOTAL_INC, SZ_TOT)
	_txt(_ftot, TOT_EXP_RIGHT, TOT_Y, fmt_money(int(_sum.get("total_expense", 0))), C_TOTAL_EXP, SZ_TOT)


func _draw_bottom_boxes() -> void:
	var inc := int(_sum.get("total_income", 0))
	var exp := int(_sum.get("total_expense", 0))
	# We hold no per-week history, so LAST/CURRENT weekly income+expenses are the
	# season figures spread evenly (a flagged approximation). CASH is the real
	# Career figure; LAST WEEK cash backs out this week's net.
	var w_inc := int(round(inc / float(SEASON_WEEKS)))
	var w_exp := int(round(exp / float(SEASON_WEEKS)))
	# LAST WEEK
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[0], fmt_money(w_inc), C_BLACK, SZ_BOT)
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[1], fmt_money(w_exp), C_BLACK, SZ_BOT)
	_txt(_fbot, LW_RIGHT, BOT_ROW_Y[2], fmt_money(_cash - (w_inc - w_exp)), C_GOLD, SZ_BOT)
	# CURRENT WEEK
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[0], fmt_money(w_inc), C_BLACK, SZ_BOT)
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[1], fmt_money(w_exp), C_BLACK, SZ_BOT)
	_txt(_fbot, CW_RIGHT, BOT_ROW_Y[2], fmt_money(_cash), C_GOLD, SZ_BOT)


## The WEEKLY BALANCE chart. HONEST GAP: PM98's chart is a per-week float ledger
## (finance_constants.md); the app has no save-game, so FinanceModel yields only a
## single constant `weekly_balance`. We plot that one real figure flat across the
## elapsed weeks on the frame's fixed +/-2,500K axis — deliberately NO invented
## week-to-week variation. When a save-game ledger exists this becomes real.
func _draw_chart() -> void:
	var wk := int(_sum.get("weekly_balance", 0))
	if wk == 0:
		return
	var weeks := clampi(_week if _week > 0 else 1, 1, SEASON_WEEKS)
	var wpp := float(CHART_R - CHART_L) / float(SEASON_WEEKS)
	var up: bool = wk >= 0
	var span: int = (CHART_ZERO_Y - CHART_TOP_Y) if up else (CHART_BOT_Y - CHART_ZERO_Y)
	var hh: float = clampf(absf(float(wk)) / float(CHART_SCALE), 0.0, 1.0) * span
	for i in weeks:
		var bx := CHART_L + i * wpp
		if up:
			draw_rect(Rect2(bx, CHART_ZERO_Y - hh, maxf(1.0, wpp - 1.0), hh), C_BAR_POS, true)
		else:
			draw_rect(Rect2(bx, CHART_ZERO_Y + 1, maxf(1.0, wpp - 1.0), hh), C_BAR_NEG, true)
