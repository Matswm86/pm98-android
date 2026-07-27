extends Control
class_name InjuriesScreen
## PM98 INJURIES sub-screen (LINE-UP -> INJURED). Static chrome is the REAL game's
## resting frame baked verbatim below the shared barra
## (tools/re/build_lineup_subs_chrome_from_frames.py; binding frame run-2
## 034_162510 empty-list + witness 039_162530). See docs/re/injuries_screen_re.md.
## The scene draws ONLY the dynamic layer over the baked furniture:
##  - one row per INJURED player (Availability.gd: injured_weeks>0) in the manager's
##    squad, placed in his GOAL/DEF/MID/FOR section: PLAYER name + the Week (matches
##    still to sit out) value. Injuries are rolled for the manager's club only
##    (Availability scope), so this lists exactly that squad;
##  - the bottom PHYSIOTHERAPIST band: the hired physio's name, his rating in HALF-star
##    steps (the rating IS his quality byte / 2) and the "N PLAYERS" figure —
##    `FUN_00578b80` case 6 on that byte, so a 4.5-star physio reads 5 (witnessed);
##  - the per-row PHYS. treatment button (BOTONOFF grey cross / BOTONON red cross);
##    tapping it emits `treat_pressed` -> `Career.treat_injury`, the binary's
##    `FUN_00543080` -> `FUN_00584db0` (remaining = total x (20 - q) / 20, so a
##    five-star physio halves the lay-off).
##
## TYPE OF INJURY renders the game's own diagnosis (Availability.INJURY_TYPES,
## MANAGER.EXE @0x6622e8; closed 2026-07-23). The H / PRICE / INSUR. / COST cells
## are the row builder @0x543770-0x543d85, ported 2026-07-23:
##   H      = is_serious(diagnosis) ? "YES" (214,60,0) : "NO" (black)   @0x54389a
##   PRICE  = total injury weeks x £1,500                               @0x5439b4
##   INSUR. = "NO" when uninsured, else the policy digit                @0x543a48
##   COST   = PRICE - PRICE x payout% / 100, white; BLANK when 0        @0x543ca7
## A populated row also REPAINTS the panel strip it sits on (PHYS. button + name
## cell through COST). That strip is FRAME-CUT verbatim from wine witness
## 83_injuries_populated.png by tools/re/build_injuries_row_from_frame.py, so the
## furniture is original pixels and this scene overlays nothing but text. The
## INSURANCE button opens the real INSURANCE screen (InsuranceScreen.gd, ported
## 2026-07-18 from wine witnesses 33-39). Suspensions are NOT injuries, excluded.
##
## The INSURED row draws three things in the INSUR. cell, not one: the policy document
## sprite (@0x543b09, blitted at row-x 459 / row-y 5), the group number, and the group's
## PAYOUT percentage. CLOSED 2026-07-28 -- the sprite is frame-cut from the one witness
## that shows it (tools/re/build_injuries_insured_icon.py) and the two texts sit in the
## binary's own sub-rects.
## Native 640x480.

signal back_pressed        # RETURN -> Main reopens LINE-UP
signal insurance_pressed   # INSURANCE -> Main mounts the INSURANCE screen
signal treat_pressed(pid: int)   # the row's PHYS. "+" button -> send him to the physio

const W := 640
const H := 480
const BODY_Y0 := 62

const TITLE_XY := Vector2(253, 22)
# GOAL/DEF/MID/FOR row-fill tops (design y); rows grey (220) h16 (baker INJ_SECT_TOPS)
const SECT := [
	{"key": "gk", "tops": [105, 125, 145], "pos": ["GK"]},
	{"key": "def", "tops": [174, 194, 214, 234], "pos": ["DF"]},
	{"key": "mid", "tops": [262, 282, 302, 322], "pos": ["MF"]},
	{"key": "fwd", "tops": [350, 370, 390], "pos": ["FW"]},
]
const ROW_H := 16
const NAME_X := 63          # under the PLAYER header (witness 83 ink x63)
const NAME_W := 130.0
const TYPE_CELL := [183, 174] # TYPE OF INJURY value rect (@0x5437a7, row-x 155 + 28)
const WEEK_CELL := [355, 40] # Week column value cell (frame: grey box x358..385)

# A populated row repaints a strip of the resting panel: the PHYS. treatment
# button and everything from the name cell to COST. That strip is FRAME-CUT from
# witness 83 (tools/re/build_injuries_row_from_frame.py -> row_strip.png), so the
# furniture is original pixels and this scene overlays only text.
const STRIP_X := 28
const STRIP_DY := -1          # the strip carries the row's own top border

# Value-cell spans inside the strip, measured on witness 83. [x0, x1] inclusive.
const CELL_NAME := [60, 158]
const CELL_TYPE := [180, 356]
const CELL_WEEK := [358, 385]
const CELL_H := [387, 408]
const CELL_PRICE := [410, 482]
const CELL_INSUR := [484, 538]
# ...and the INSURED row's own three-part layout inside that cell, read off
# `FUN_00543960`'s insured branch (@0x543ae7-0x543c9b) rather than centred as one string.
# Row-relative x + the row widget's origin at STRIP_X (28) gives the screen x:
#   0x543b09  icon blit at (0x1cb, 5)                   -> screen x 487, row_top + 5
#   0x543b6b  group digit centred in (0x1d5 .. 0x1e0)    -> screen 497 .. 508
#   0x543c0b  payout "N%" centred in (0x1e1 .. 0x1ff)    -> screen 509 .. 539
# All three reproduce the only frame that witnesses an insured row (Giggs, Group 1, 0%,
# wine-captures-2026-07-24-cadence-season-store/07_injuries_row_insured_giggs.png): its
# icon sits at x487..494 / y266..275 with the row borders at y261/y278, its "1" at
# x500..503 and its "0%" at x518..527. Both texts are black (`mov dword [eax], 0`
# @0x543b5a / @0x543be2).
const INSURED_ICON_X := 487
const INSURED_ICON_DY := 4   # row-y 5 in the binary; the port's `y` is the row's fill top, one lower
const CELL_INSUR_GROUP := [497, 508]
const CELL_INSUR_PCT := [509, 539]
# DECLARED FACE. The payout percentage is the one piece of the insured row that does not
# land 0 px: its glyphs in the witness are 4 px wide and TEN rows tall (x518..527,
# y265..274 on `07_injuries_row_insured_giggs.png`) and no extracted bank reproduces them.
# Thirty face/size combinations were rendered and diffed against that cell on 2026-07-28 --
# proman8/10/12, calend8, calend12, euro8, futcon8, micro8, kkita, each at 8..12 and at its
# own native size -- and the best is euro8 at 9 (28 px inside the 30x16 sub-cell; proman8@8
# 42, calend8@9 31, futcon8@8 37). The digit and the document sprite beside it are both
# exactly 0 px, so this is the whole residual. The value itself is not in doubt: it is
# `FUN_0058c000` (Insurance.payout_pct), the same function the COST cell nets against.
# Same class of declared residual as the finance modal's text bands.
const PCT_FACE := "euro8"
const PCT_SIZE := 9
const CELL_COST := [540, 609]
const TEXT_DY := 3            # value baseline inside the row (witness ink y110..118)

# Row inks (frame-sampled on witness 83; the binary's own colour word in brackets,
# quantised by the original's 8-bit palette on the way to the frame).
const C_WEEK_INK := Color8(255, 255, 255)     # 0xffffff  @0x543815
const C_H_SERIOUS := Color8(214, 60, 0)       # d6 3c 00  @0x5438ae
const C_PRICE := Color8(30, 52, 98)           # 18 34 63  @0x54399b
const C_INSUR_NO := Color8(60, 80, 100)       # 39 51 63  @0x543a67
const C_COST_INK := Color8(255, 255, 255)     # 0xffffff  @0x543cc7

# physio band (frame 034 bottom): name x61..340 white band; count on the black band
const PHYS_NAME_X := 62
const PHYS_NAME_Y := 448
const PHYS_STAR_X0 := 220
const PHYS_STAR_PITCH := 14
const PHYS_STAR_Y := 449
const PHYS_COUNT_CELL := [239, 16]  # white digit on the black band (x239..255)
const PHYS_COUNT_Y := 429

# PHYS. treatment button — `LESIONADOS\BOTONOFF.BMP` / `BOTONON.BMP`, 21x18, drawn at
# x28, y = row_top - 1 (SAD 0 against wine witness 07_injuries_row_insured_giggs.png;
# tools/re/export_injuries_phys_button.py). This is the owner's "+ sign": a grey cross
# while untreated, a RED cross once the physio has him (`FUN_00543307` switches on
# player+0x6b). Tapping it runs FUN_00543080 -> FUN_00584db0, which recomputes the
# remaining weeks from the ORIGINAL total as total x (20 - q) / 20.
const PHYS_BTN_XY := Vector2(28, -1)     # y is relative to the row top
const PHYS_BTN_SIZE := Vector2(21, 18)

const R_INSURANCE := Rect2(358, 434, 124, 34)
const R_RETURN := Rect2(500, 434, 134, 34)

const C_NAME := Color8(0, 0, 0)
const C_WEEK := Color8(0, 0, 0)
const C_COUNT := Color8(255, 255, 255)
const C_PRESS := Color(1, 1, 1, 0.20)

var _club: Dictionary = {}
var _staff: Array = []
var _header: Dictionary = {}
var _injured: Dictionary = {}   # section key -> Array[player]
var _press := ""

var _f8: Font
var _f10: Font
var _chrome: Texture2D
var _title: Texture2D
var _phys_star: Texture2D
var _phys_star_half: Texture2D
var _row_strip: Texture2D
var _phys_off: Texture2D
var _phys_on: Texture2D
var _f_pct: Font                  # the payout-percentage face (see the sweep below)
var _doc_icon: Texture2D          # the INSURED row's policy document sprite


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/injuries/chrome.png")
	_title = load("res://art/screens/injuries/title.png")
	_f_pct = PMChrome.font(PCT_FACE)
	_doc_icon = load("res://art/screens/injuries/insured_doc.png")
	_phys_star = load("res://art/screens/injuries/phys_star.png")
	_phys_star_half = load("res://art/screens/injuries/phys_star_half.png")
	_row_strip = load("res://art/screens/injuries/row_strip.png")
	_phys_off = load("res://art/screens/injuries/phys_off.png")
	_phys_on = load("res://art/screens/injuries/phys_on.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, staff: Array = [], header: Dictionary = {}) -> void:
	_club = club
	_staff = staff
	_header = header
	if _header.is_empty():
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1))}
	_injured = {"gk": [], "def": [], "mid": [], "fwd": []}
	for p in club.get("players", []):
		var pd: Dictionary = p
		if int(pd.get("injured_weeks", 0)) > 0:
			_injured[_section_of(pd)].append(pd)
	queue_redraw()


func _section_of(p: Dictionary) -> String:
	if bool(p.get("isGK", false)) or str(p.get("pos", "")) == "GK":
		return "gk"
	match str(p.get("pos", "")):
		"DF": return "def"
		"FW": return "fwd"
		_: return "mid"


## Physio (first hired PHYSIOTHERAPIST), or {} — the only staff role this screen shows.
func _physio() -> Dictionary:
	var m := Staff.members_in_role(_staff, Staff.PHYSIO)
	return m[0] if not m.is_empty() else {}


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()


func _hit(d: Vector2) -> String:
	if R_INSURANCE.has_point(d):
		return "insurance"
	if R_RETURN.has_point(d):
		return "return"
	for sect in SECT:
		var rows: Array = _injured.get(str(sect["key"]), [])
		var tops: Array = sect["tops"]
		for i in mini(rows.size(), tops.size()):
			var r := Rect2(PHYS_BTN_XY.x, int(tops[i]) + PHYS_BTN_XY.y,
				PHYS_BTN_SIZE.x, PHYS_BTN_SIZE.y)
			if r.has_point(d):
				return "treat:%d" % int((rows[i] as Dictionary).get("id", -1))
	return ""


# ---- input ----------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	if PMChrome.is_emulated_pointer_dup(e):
		return   # one finger tap arrives twice; see PMChrome.is_emulated_pointer_dup
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _hit(d):
		return
	if was.begins_with("treat:"):
		treat_pressed.emit(int(was.substr(6)))
		return
	match was:
		"return":
			back_pressed.emit()
		"insurance":
			insurance_pressed.emit()


# ---- drawing --------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "injuries", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))
	if _title != null:
		draw_texture(_title, TITLE_XY)

	_draw_rows()
	_draw_physio_band()

	for kr in [["insurance", R_INSURANCE], ["return", R_RETURN]]:
		if _press == str(kr[0]):
			draw_rect(kr[1], C_PRESS, true)


func _draw_rows() -> void:
	for sect in SECT:
		var rows: Array = _injured.get(str(sect["key"]), [])
		var tops: Array = sect["tops"]
		for i in mini(rows.size(), tops.size()):
			_draw_row(rows[i], int(tops[i]))


## One populated INJURIES row: the repainted cell grid (witness 83) plus every
## value the row builder @0x543770-0x543d85 writes into it.
func _draw_row(p: Dictionary, y: int) -> void:
	if _row_strip != null:
		draw_texture(_row_strip, Vector2(STRIP_X, y + STRIP_DY))
	# PHYS. button: BOTONON (red cross) once the physio has him, BOTONOFF otherwise.
	var btn := _phys_on if Availability.is_treated(p) else _phys_off
	if btn != null:
		draw_texture(btn, Vector2(PHYS_BTN_XY.x, y + PHYS_BTN_XY.y))
	PMChrome.text(self, _f8, NAME_X, y + TEXT_DY,
		PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, 11, 0, NAME_W)
	# TYPE OF INJURY: the game's own diagnosis string (Availability.INJURY_TYPES),
	# blank only for legacy untyped injuries.
	var diag := Availability.injury_type_name(p)
	if diag != "":
		PMChrome.text(self, _f8, TYPE_CELL[0], y + TEXT_DY, diag, C_NAME, 11, 0, float(TYPE_CELL[1]))
	# Week = the injury record's +0x68, the weeks STILL to sit out (@0x54382f).
	_cell_text(CELL_WEEK, y, str(int(p.get("injured_weeks", 0))), C_WEEK_INK)
	# H = is_serious(diagnosis): types 11..17 print YES in red, the rest NO in black.
	var ti := int(p.get("injury_type", -1))
	var serious := ti >= Availability.SERIOUS_MIN
	_cell_text(CELL_H, y, "YES" if serious else "NO", C_H_SERIOUS if serious else C_NAME)
	# PRICE / INSUR. / COST — the insurance economy (Insurance.gd).
	var total := Insurance.injury_total_weeks(p)
	var group := int(p.get("insurance_group", 0))
	_cell_text(CELL_PRICE, y, FinanceScreen.fmt_money(Insurance.injury_price(total)), C_PRICE)
	if group <= 0:
		_cell_text(CELL_INSUR, y, "NO", C_INSUR_NO)
	else:
		# The insured row is three pieces, not one centred digit: the policy document
		# sprite, the group number, and the group's PAYOUT percentage -- the last two in
		# their own sub-rects. `payout_pct` is FUN_0058c000, the same function the COST
		# cell below nets against, so the row can never disagree with itself.
		if _doc_icon != null:
			draw_texture(_doc_icon, Vector2(INSURED_ICON_X, y + INSURED_ICON_DY))
		_cell_text(CELL_INSUR_GROUP, y, str(group), C_NAME)
		_cell_text(CELL_INSUR_PCT, y, "%d%%" % Insurance.payout_pct(group), C_NAME, PCT_SIZE, _f_pct)
	var cost := Insurance.injury_cost(total, group)
	if cost != 0:   # a fully-covered (GROUP 3) injury leaves the cell EMPTY (@0x543cd2)
		_cell_text(CELL_COST, y, FinanceScreen.fmt_money(cost), C_COST_INK)


func _cell_text(cell: Array, y: int, s: String, col: Color, size: int = 11,
		font: Font = null) -> void:
	PMChrome.text(self, font if font != null else _f8, int(cell[0]), y + TEXT_DY, s, col, size, 1,
		float(cell[1] - cell[0] + 1))


## PHYSIOTHERAPIST band: name + quality stars + "N PLAYERS" (= physio quality;
## frame 034 pairs 5 stars with "5 PLAYERS"). Blank when no physio is hired.
func _draw_physio_band() -> void:
	var ph := _physio()
	if ph.is_empty():
		return
	PMChrome.text(self, _f10, PHYS_NAME_X, PHYS_NAME_Y,
		PMChrome.title_case_name(str(ph.get("name", ""))), C_NAME, 12, 0, 150.0)
	# Half-star steps: the rating IS the quality byte / 2, so a 4.5-star physio draws
	# four full stars and a half (witnessed, E. Wragg in 39_injuries.png).
	var halves := clampi(Staff.quality_byte(ph), 0, 10)
	for j in halves / 2:
		if _phys_star != null:
			draw_texture(_phys_star, Vector2(PHYS_STAR_X0 + PHYS_STAR_PITCH * j, PHYS_STAR_Y))
	if halves % 2 == 1 and _phys_star_half != null:
		draw_texture(_phys_star_half,
			Vector2(PHYS_STAR_X0 + PHYS_STAR_PITCH * (halves / 2), PHYS_STAR_Y))
	# "N PLAYERS" = FUN_00578b80 case 6 on his raw quality byte, NOT the star count.
	# Witnessed 2026-07-24: a 4.5-star physio (q=9) reads "5 PLAYERS".
	PMChrome.text(self, _f8, PHYS_COUNT_CELL[0], PHYS_COUNT_Y, str(Staff.physio_capacity(ph)),
		C_COUNT, 11, 1, float(PHYS_COUNT_CELL[1]))
