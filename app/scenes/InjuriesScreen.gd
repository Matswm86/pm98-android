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
## MANAGER.EXE @0x6622e8; closed 2026-07-23). Remaining gaps (injuries_screen_re.md
## §Gaps): PHYS. (treatment checkbox) and this list's PRICE / INSUR. / COST columns
## are the DAT.PKF-driven insurance economy, still resting furniture. The INSURANCE button
## opens the real INSURANCE screen (InsuranceScreen.gd, ported 2026-07-18 from
## wine witnesses 33-39). Suspensions are NOT injuries and are excluded.
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
const NAME_X := 64          # under the PLAYER header
const NAME_W := 130.0
const TYPE_CELL := [209, 115] # TYPE OF INJURY column (header x209..324); the real diagnosis
const WEEK_CELL := [355, 40] # Week column value cell (frame: grey box x358..385)

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


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/injuries/chrome.png")
	_title = load("res://art/screens/injuries/title.png")
	_phys_star = load("res://art/screens/injuries/phys_star.png")
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
			var p: Dictionary = rows[i]
			var y: int = tops[i]
			PMChrome.text(self, _f8, NAME_X, y + 2,
				PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, 11, 0, NAME_W)
			# TYPE OF INJURY: the game's own diagnosis string (Availability.INJURY_TYPES),
			# blank only for legacy untyped injuries.
			var diag := Availability.injury_type_name(p)
			if diag != "":
				PMChrome.text(self, _f8, TYPE_CELL[0], y + 2, diag, C_NAME, 11, 0, float(TYPE_CELL[1]))
			PMChrome.text(self, _f8, WEEK_CELL[0], y + 2, str(int(p.get("injured_weeks", 0))),
				C_WEEK, 11, 1, float(WEEK_CELL[1]))


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
