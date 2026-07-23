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
##  - the bottom PHYSIOTHERAPIST band: the hired physio's name + quality stars +
##    the "N PLAYERS" figure (= his quality), from Career.staff / Staff.gd.
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
## HONEST GAP: an INSURED injured row also draws a small document icon at row-x
## 459 (@0x543b09). No frame witnesses that sprite on THIS screen, so the port
## draws the policy digit alone rather than guess the art. PHYS. (the treatment
## checkbox) stays resting furniture.
## Native 640x480.

signal back_pressed        # RETURN -> Main reopens LINE-UP
signal insurance_pressed   # INSURANCE -> Main mounts the INSURANCE screen

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
var _row_strip: Texture2D


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/injuries/chrome.png")
	_title = load("res://art/screens/injuries/title.png")
	_phys_star = load("res://art/screens/injuries/phys_star.png")
	_row_strip = load("res://art/screens/injuries/row_strip.png")
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
	return ""


# ---- input ----------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
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
		_cell_text(CELL_INSUR, y, str(group), C_NAME)
	var cost := Insurance.injury_cost(total, group)
	if cost != 0:   # a fully-covered (GROUP 3) injury leaves the cell EMPTY (@0x543cd2)
		_cell_text(CELL_COST, y, FinanceScreen.fmt_money(cost), C_COST_INK)


func _cell_text(cell: Array, y: int, s: String, col: Color) -> void:
	PMChrome.text(self, _f8, int(cell[0]), y + TEXT_DY, s, col, 11, 1,
		float(cell[1] - cell[0] + 1))


## PHYSIOTHERAPIST band: name + quality stars + "N PLAYERS" (= physio quality;
## frame 034 pairs 5 stars with "5 PLAYERS"). Blank when no physio is hired.
func _draw_physio_band() -> void:
	var ph := _physio()
	if ph.is_empty():
		return
	var q := clampi(int(ph.get("quality", 0)), 0, 5)
	PMChrome.text(self, _f10, PHYS_NAME_X, PHYS_NAME_Y,
		PMChrome.title_case_name(str(ph.get("name", ""))), C_NAME, 12, 0, 150.0)
	for j in q:
		if _phys_star != null:
			draw_texture(_phys_star, Vector2(PHYS_STAR_X0 + PHYS_STAR_PITCH * j, PHYS_STAR_Y))
	PMChrome.text(self, _f8, PHYS_COUNT_CELL[0], PHYS_COUNT_Y, str(q),
		C_COUNT, 11, 1, float(PHYS_COUNT_CELL[1]))
