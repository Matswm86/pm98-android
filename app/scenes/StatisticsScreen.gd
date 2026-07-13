extends Control
class_name StatisticsScreen
## PM98 STATISTICS sub-screen (LINE-UP -> STATISTICS). Static chrome is the REAL
## game's resting frame baked verbatim below the shared barra
## (tools/re/build_lineup_subs_chrome_from_frames.py; binding frames run-2
## 069_162642 XI visit / 042_162537 full-squad + run-1 zero-state 147_154839).
## See docs/re/statistics_screen_re.md. The scene draws ONLY the dynamic layer:
##  - the body title "STATISTICS FOR <CLUB>." (verbatim sprite for Manchester Utd,
##    navy text for any other club);
##  - one row per squad player: the # (shirt number) + PLAYER name.
##
## HONEST GAP (flagged, never invented — statistics_screen_re.md §Gap): the app's
## Career / match engine accumulates NO per-player season statistics (MP, MIN,
## RATING, MoM, G., SHOTS, PASSES, TAC., S., cards, injuries). Every one of those
## columns and the TEAM TOTAL row therefore stay at PM98's own pre-match zero state
## (the baked empty-slot furniture / dashes) — no number is faked. This mirrors the
## real game's fresh-season look (frame 147_154839). Native 640x480.

signal back_pressed        # RETURN -> Main reopens LINE-UP

const W := 640
const H := 480
const BODY_Y0 := 62
const MANUTD_ID := 40      # the club whose verbatim "STATISTICS FOR ..." sprite was baked

const TITLE_XY := Vector2(237, 22)
const TITLE_MANUTD_XY := Vector2(157, 71)
const BODY_TITLE_X := 182  # navy text start for a non-ManUtd club (after the shirt icon)
const BODY_TITLE_Y := 72
# 19 row-fill tops (design y) = 111+16i; rows h13 (baker ST_ROW_TOPS)
const ROW_TOPS := [111, 127, 143, 159, 175, 191, 207, 223, 239, 255,
	271, 287, 303, 319, 335, 351, 367, 383, 399]
const NUM_CELL := [18, 28]  # GDI-centred # cell (frame: number centre ~31)
const NAME_X := 66          # under the PLAYER header

const R_RETURN := Rect2(505, 446, 128, 30)

const C_TITLE := Color8(0, 0, 128)   # "STATISTICS FOR ..." navy (frame-sampled)
const C_NUM := Color8(0, 0, 128)     # # column navy (frame 042-sampled)
const C_NAME := Color8(0, 0, 0)
const C_PRESS := Color(1, 1, 1, 0.20)

var _club: Dictionary = {}
var _header: Dictionary = {}
var _players: Array = []
var _press := ""

var _f8: Font
var _f10: Font
var _chrome: Texture2D
var _title: Texture2D
var _title_manutd: Texture2D


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_chrome = load("res://art/screens/stats/chrome.png")
	_title = load("res://art/screens/stats/title.png")
	_title_manutd = load("res://art/screens/stats/title_manutd.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary, header: Dictionary = {}) -> void:
	_club = club
	_header = header
	if _header.is_empty():
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1))}
	_players = (club.get("players", []) as Array).duplicate()
	queue_redraw()


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()


func _hit(d: Vector2) -> String:
	return "return" if R_RETURN.has_point(d) else ""


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
	if was == "return" and _hit(d) == "return":
		back_pressed.emit()


# ---- drawing --------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "statistics", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))
	if _title != null:
		draw_texture(_title, TITLE_XY)

	# body title: verbatim sprite for Man Utd, redrawn navy text otherwise
	if int(_club.get("id", -1)) == MANUTD_ID and _title_manutd != null:
		draw_texture(_title_manutd, TITLE_MANUTD_XY)
	else:
		PMChrome.text(self, _f10, BODY_TITLE_X, BODY_TITLE_Y,
			"STATISTICS FOR %s." % PMChrome.title_case_name(str(_club.get("name", ""))).to_upper(),
			C_TITLE, 13, 0)

	# one row per player: # + name; the stat columns stay at the baked zero state (GAP)
	for i in mini(_players.size(), ROW_TOPS.size()):
		var p: Dictionary = _players[i]
		var y: int = ROW_TOPS[i]
		PMChrome.text(self, _f8, NUM_CELL[0], y + 1, str(int(p.get("squadNo", 0))),
			C_NUM, 11, 1, float(NUM_CELL[1]))
		PMChrome.text(self, _f8, NAME_X, y + 1,
			PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, 11, 0, 100.0)

	if _press == "return":
		draw_rect(R_RETURN, C_PRESS, true)
