extends Control
class_name DirectivaScreen
## PM98 BOARD OF DIRECTORS (DIRECTIVA) screen, rebuilt to match the real game (ma_14):
## the shared PMChrome plaque header + blue marble background over the MANAGER name box
## and the three segmented red/brown block meters (MANAGER RATING / DIRECTORS CONFIDENCE
## / SUPPORTERS CONFIDENCE), with the real APPLY FOR LOAN table and BONUS panel filling
## the bottom half (replacing the prior invented "THE BOARD EXPECTS / YOUR RECORD" text).
##
## The meter VALUES are derived from real career state (position vs the board objective +
## form) since the Career model stores no confidence stat. Display-only; tap to dismiss.
## Native 640x480; scales to fit its parent.

const W := 640
const H := 480

const C_BLACKBAR := Color(0.07, 0.08, 0.10)
const C_BARTXT := Color(0.94, 0.96, 1.0)
const C_NAMEBOX := Color(0.12, 0.20, 0.42)
const C_BLOCK_HI := Color(0.84, 0.20, 0.16)      # red end of the segmented meter
const C_BLOCK_LO := Color(0.56, 0.34, 0.18)      # brown end
const C_BLOCK_OFF := Color(0.28, 0.30, 0.34)
const C_VALUE := Color(0.10, 0.16, 0.30)
const C_LOAN_HDR := Color(0.20, 0.50, 0.28)      # green AMOUNT header
const C_LOAN_BLUE := Color(0.20, 0.34, 0.62)
const C_LOAN_CELL := Color(0.78, 0.86, 0.78)
const C_LOAN_YEARS := Color(0.82, 0.66, 0.16)    # gold YEARS cell
const C_LOAN_BLUECELL := Color(0.74, 0.82, 0.90)
const C_BONUS_BLUE := Color(0.20, 0.34, 0.62)
const C_BTN := Color(0.10, 0.16, 0.32)
const C_BTN_HI := Color(0.34, 0.46, 0.72)
const C_BTN_LO := Color(0.04, 0.08, 0.18)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)

# MANAGER + ratings row.
const MGR_LBL := Rect2(30, 92, 296, 16)
const MGR_BOX := Rect2(30, 110, 296, 22)
const RAT_LBL := Rect2(344, 92, 290, 16)
const RAT_BOX := Rect2(344, 110, 290, 22)
const DIR_LBL := Rect2(70, 144, 256, 16)
const DIR_BOX := Rect2(70, 162, 256, 22)
const SUP_LBL := Rect2(344, 144, 256, 16)
const SUP_BOX := Rect2(344, 162, 256, 22)
const LOAN_PANEL := Rect2(16, 206, 360, 188)
const BONUS_PANEL := Rect2(388, 206, 246, 128)
const BTN_RETURN := Rect2(520, 432, 114, 28)

var _ic_direct: Texture2D
var _ic_public: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _league: String = ""
var _cash: int = 0
var _directors: int = 50
var _supporters: int = 50
var _rating: int = 50
var _week: int = 0


func _ready() -> void:
	_ic_direct = load("res://art/screens/directiva/directiva.png") if ResourceLoader.exists("res://art/screens/directiva/directiva.png") else null
	_ic_public = load("res://art/screens/directiva/publico.png") if ResourceLoader.exists("res://art/screens/directiva/publico.png") else null
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


func setup(club: String, manager: String, season: String, cash: int,
		directors: int, supporters: int, rating: int,
		objective: String, record: String, position: String = "",
		week: int = 0, league: String = "") -> void:
	_club = club
	_manager = manager
	_season = season
	_league = league
	_cash = cash
	_directors = clampi(directors, 0, 100)
	_supporters = clampi(supporters, 0, 100)
	_rating = clampi(rating, 0, 100)
	_week = week
	queue_redraw()


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


func _centre(f: Font, r: Rect2, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)),
		s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## A black label bar with a centred white caption.
func _label_bar(r: Rect2, s: String) -> void:
	draw_rect(r, C_BLACKBAR, true)
	_centre(_f10, r, s, C_BARTXT, 11)


## A segmented red/brown block meter (0..10 blocks from a 0..100 value) + the value.
func _meter(box: Rect2, value: int) -> void:
	PMChrome.bevel(self, box, PMChrome.C_TBL, PMChrome.C_TBL_HI, PMChrome.C_TBL_LO)
	var blocks := 10
	var filled := int(round(value / 10.0))
	var bw := (box.size.x - 36) / float(blocks)
	for i in blocks:
		var bx := box.position.x + 4 + i * bw
		var col := C_BLOCK_OFF
		if i < filled:
			col = C_BLOCK_HI.lerp(C_BLOCK_LO, float(i) / float(blocks))
		draw_rect(Rect2(bx, box.position.y + 4, bw - 1, box.size.y - 8), col, true)
	_txt(_f12, int(box.end.x) - 8, int(box.position.y) + 4, str(filled), C_VALUE, 13, true)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "BOARD OF DIRECTORS", _manager, _club, _league, _season, _week)

	# MANAGER name + MANAGER RATING.
	_label_bar(MGR_LBL, "MANAGER")
	PMChrome.bevel(self, MGR_BOX, C_NAMEBOX, C_BTN_HI, C_BTN_LO)
	_centre(_f12, MGR_BOX, (_manager if _manager != "" else _club), C_PANEL_TXT, 13)
	_label_bar(RAT_LBL, "MANAGER RATING")
	_meter(RAT_BOX, _rating)

	# DIRECTORS / SUPPORTERS confidence, with their reversed icons.
	if _ic_direct != null:
		draw_texture(_ic_direct, Vector2(DIR_LBL.position.x - 34, DIR_LBL.position.y))
	_label_bar(DIR_LBL, "DIRECTORS CONFIDENCE")
	_meter(DIR_BOX, _directors)
	if _ic_public != null:
		draw_texture(_ic_public, Vector2(SUP_LBL.position.x - 34, SUP_LBL.position.y))
	_label_bar(SUP_LBL, "SUPPORTERS CONFIDENCE")
	_meter(SUP_BOX, _supporters)

	_draw_loan_table()
	_draw_bonus()

	PMChrome.bevel(self, BTN_RETURN, C_BTN, C_BTN_HI, C_BTN_LO)
	_centre(_f12, BTN_RETURN, "RETURN", C_GOLD, 13)


## The APPLY FOR LOAN form: N. | AMOUNT | YEARS | TO PAY | WEEK over a few empty rows
## (the real screen is an empty form until the manager applies).
func _draw_loan_table() -> void:
	PMChrome.draw_table_panel(self, LOAN_PANEL)
	var hb := Rect2(LOAN_PANEL.position.x + 2, LOAN_PANEL.position.y + 2, LOAN_PANEL.size.x - 4, 16)
	draw_rect(hb, C_BLACKBAR, true)
	_centre(_f10, hb, "APPLY FOR LOAN", C_BARTXT, 11)
	# column headers
	var cols := [["N.", 28, C_LOAN_BLUE], ["AMOUNT", 70, C_LOAN_HDR], ["YEARS", 158, C_BLOCK_HI],
		["TO PAY", 220, C_BLOCK_HI], ["WEEK", 310, C_LOAN_BLUE]]
	var hy := int(LOAN_PANEL.position.y) + 22
	for c in cols:
		_txt(_f8, int(LOAN_PANEL.position.x) + int(c[1]), hy, str(c[0]), c[2], 10)
	# 4 empty form rows
	var y := hy + 16
	for r in 4:
		var rowy := y + r * 24
		_form_cell(Rect2(LOAN_PANEL.position.x + 8, rowy, 20, 18), C_LOAN_BLUECELL)     # N.
		_form_cell(Rect2(LOAN_PANEL.position.x + 32, rowy, 110, 18), C_LOAN_CELL)       # AMOUNT
		_form_cell(Rect2(LOAN_PANEL.position.x + 146, rowy, 52, 18), C_LOAN_YEARS)      # YEARS
		_form_cell(Rect2(LOAN_PANEL.position.x + 202, rowy, 96, 18), C_LOAN_CELL)       # TO PAY
		_form_cell(Rect2(LOAN_PANEL.position.x + 302, rowy, 50, 18), C_LOAN_BLUECELL)   # WEEK


func _form_cell(r: Rect2, col: Color) -> void:
	PMChrome.bevel(self, r, col, col.lightened(0.2), col.darkened(0.3))


## The BONUS panel: win bonus + champion bonus, each with an OK action (board settings).
func _draw_bonus() -> void:
	PMChrome.draw_table_panel(self, BONUS_PANEL)
	var hb := Rect2(BONUS_PANEL.position.x + 2, BONUS_PANEL.position.y + 2, BONUS_PANEL.size.x - 4, 16)
	draw_rect(hb, C_BLACKBAR, true)
	_centre(_f10, hb, "BONUS", C_BARTXT, 11)
	_bonus_row(int(BONUS_PANEL.position.y) + 24, "Win bonus", 0)
	_bonus_row(int(BONUS_PANEL.position.y) + 76, "for Champion", 120_000)


func _bonus_row(y: int, label: String, amount: int) -> void:
	var lbl := Rect2(BONUS_PANEL.position.x + 8, y, 150, 20)
	PMChrome.bevel(self, lbl, C_BONUS_BLUE, C_BONUS_BLUE.lightened(0.25), C_BONUS_BLUE.darkened(0.4))
	_centre(_f10, Rect2(lbl.position.x, lbl.position.y - 1, lbl.size.x, 12), label, C_PANEL_TXT, 10)
	_centre(_f10, Rect2(lbl.position.x, lbl.position.y + 9, lbl.size.x, 12), fmt_money(amount), C_GOLD, 10)
	var ok := Rect2(BONUS_PANEL.position.x + 168, y, 68, 20)
	PMChrome.bevel(self, ok, C_BTN, C_BTN_HI, C_BTN_LO)
	_centre(_f10, ok, "OK", C_PANEL_TXT, 11)
